-- Active: 1769575924621@@localhost@3313@final_analytics

-- 원핫인코딩? 암튼 구별
WITH user_map AS (
  SELECT DISTINCT
    session_id,
    user_id
  FROM hackle_properties
  WHERE user_id IS NOT NULL
    AND TRIM(user_id) <> ''
),
user_funnel AS (
  SELECT
    um.user_id,
    MAX(CASE WHEN e.event_key = 'complete_signup' THEN 1 ELSE 0 END) AS signup,
    MAX(CASE WHEN e.event_key = 'complete_question' THEN 1 ELSE 0 END) AS question_complete,
    MAX(CASE WHEN e.event_key = 'click_question_start' THEN 1 ELSE 0 END) AS question_start,
    MAX(CASE WHEN e.event_key = 'complete_purchase' THEN 1 ELSE 0 END) AS purchase,
    MAX(CASE WHEN e.event_key IN ('click_friend_invite','click_invite_friend') THEN 1 ELSE 0 END) AS invite
  FROM hackle_events e
  JOIN user_map um
    ON e.session_id = um.session_id
  WHERE e.event_key IN (
    'complete_signup',
    'complete_question',
    'click_question_start',
    'complete_purchase',
    'click_friend_invite',
    'click_invite_friend'
  )
  GROUP BY um.user_id
)
SELECT *
FROM user_funnel
LIMIT 100;



WITH user_map AS (
  SELECT DISTINCT session_id, user_id
  FROM hackle_properties
  WHERE user_id IS NOT NULL
    AND TRIM(user_id) <> ''
),
user_stage AS (
  SELECT
    um.user_id,
    MIN(CASE WHEN e.event_key = 'complete_question' THEN e.event_datetime END) AS t_activate,
    MAX(CASE WHEN e.event_key = 'complete_signup' THEN 1 ELSE 0 END) AS signup,
    MAX(CASE WHEN e.event_key = 'complete_question' THEN 1 ELSE 0 END) AS activated,
    MAX(CASE WHEN e.event_key = 'complete_purchase' THEN 1 ELSE 0 END) AS purchase,
    MAX(CASE WHEN e.event_key IN ('click_friend_invite','click_invite_friend') THEN 1 ELSE 0 END) AS invite
  FROM hackle_events e
  JOIN user_map um
    ON e.session_id = um.session_id
  GROUP BY um.user_id
),
user_funnel AS (
  SELECT
    s.user_id,
    s.signup,
    s.activated,
    CASE
      WHEN s.activated = 1
        AND EXISTS (
          SELECT 1
          FROM hackle_events e2
          JOIN user_map um2
            ON e2.session_id = um2.session_id
          WHERE um2.user_id = s.user_id
            AND e2.event_datetime > s.t_activate
        )
      THEN 1 ELSE 0
    END AS retained,
    s.purchase,
    s.invite
  FROM user_stage s
),
base AS (
  SELECT
    SUM(signup) AS n_signup,
    SUM(CASE WHEN signup=1 AND activated=1 THEN 1 ELSE 0 END) AS n_activated,
    SUM(CASE WHEN signup=1 AND activated=1 AND retained=1 THEN 1 ELSE 0 END) AS n_retained,
    SUM(CASE WHEN signup=1 AND activated=1 AND retained=1 AND purchase=1 THEN 1 ELSE 0 END) AS n_purchase,
    SUM(CASE WHEN signup=1 AND activated=1 AND retained=1 AND purchase=1 AND invite=1 THEN 1 ELSE 0 END) AS n_invite
  FROM user_funnel
)
SELECT *
FROM (
  SELECT 'complete_signup' AS stage,
         n_signup AS user_cnt,
         1.00 AS conversion_rate,
         0.00 AS drop_rate
  FROM base

  UNION ALL
  SELECT 'complete_question',
         n_activated,
         n_activated / NULLIF(n_signup, 0),
         1 - (n_activated / NULLIF(n_signup, 0))
  FROM base

  UNION ALL
  SELECT 'retained_any_event_after_activation',
         n_retained,
         n_retained / NULLIF(n_activated, 0),
         1 - (n_retained / NULLIF(n_activated, 0))
  FROM base

  UNION ALL
  SELECT 'complete_purchase',
         n_purchase,
         n_purchase / NULLIF(n_retained, 0),
         1 - (n_purchase / NULLIF(n_retained, 0))
  FROM base

  UNION ALL
  SELECT 'friend_invite',
         n_invite,
         n_invite / NULLIF(n_purchase, 0),
         1 - (n_invite / NULLIF(n_purchase, 0))
  FROM base
) t
LIMIT 100;


SELECT event_key
FROM hackle_events



-- 기본 뼈대 퍼널 --
-- hp랑 he 조인, 유저아이디와 세션아이디 모두 공백 제거하고 
-- 이벤트키가 complete_signup인 사람들
WITH 
-- 1단계: Acquisition (유입)
acquisition_users AS (
    SELECT DISTINCT p.user_id
    FROM hackle_events e
    INNER JOIN hackle_properties p 
        ON e.session_id = p.session_id
    WHERE e.event_key = 'complete_signup'
      AND p.user_id IS NOT NULL
      AND p.user_id != ''
      AND e.session_id IS NOT NULL
      AND e.session_id != ''
),
-- 2단계: Activation (활성화) - Acquisition 유저 중
-- 같은 기준으로 이벤트키가 complete question
activation_users AS (
    SELECT DISTINCT p.user_id
    FROM acquisition_users a
    INNER JOIN hackle_properties p 
        ON a.user_id = p.user_id
    INNER JOIN hackle_events e 
        ON p.session_id = e.session_id 
        AND e.event_key = 'complete_question'
    WHERE p.user_id IS NOT NULL
      AND p.user_id != ''
      AND e.session_id IS NOT NULL
      AND e.session_id != ''
      AND e.event_datetime IS NOT NULL
),
-- Activation 시각 계산 (Retention 판단용)
-- 최초 이벤트 시간 확인
-- 리텐션 계산을 위해서
-- 근데 이걸 세션시간으로 봐야하나??
activation_time AS (
    SELECT 
        p.user_id,
        MIN(e.event_datetime) AS activation_time
    FROM activation_users a
    INNER JOIN hackle_properties p 
        ON a.user_id = p.user_id
    INNER JOIN hackle_events e 
        ON p.session_id = e.session_id 
        AND e.event_key = 'complete_question'
    WHERE p.user_id IS NOT NULL
      AND p.user_id != ''
      AND e.session_id IS NOT NULL
      AND e.session_id != ''
      AND e.event_datetime IS NOT NULL
    GROUP BY p.user_id
),
-- 3단계: Retention (유지) - Activation 유저 중
-- event datetime > active time
retention_users AS (
    SELECT DISTINCT at.user_id
    FROM activation_time at
    WHERE at.activation_time IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM hackle_properties p
        INNER JOIN hackle_events e 
            ON p.session_id = e.session_id
        WHERE p.user_id = at.user_id
          AND p.user_id IS NOT NULL
          AND p.user_id != ''
          AND e.session_id IS NOT NULL
          AND e.session_id != ''
          AND e.event_datetime IS NOT NULL
          AND e.event_datetime > at.activation_time
    )
),
-- 4단계: Revenue (수익) - Retention 유저 중
-- 이벤트키 complete purchase
revenue_users AS (
    SELECT DISTINCT p.user_id
    FROM retention_users r
    INNER JOIN hackle_properties p 
        ON r.user_id = p.user_id
    INNER JOIN hackle_events e 
        ON p.session_id = e.session_id 
        AND e.event_key = 'complete_purchase'
    WHERE p.user_id IS NOT NULL
      AND p.user_id != ''
      AND e.session_id IS NOT NULL
      AND e.session_id != ''
      AND e.event_datetime IS NOT NULL
),
-- 5단계: Referral (추천) - Revenue 유저 중
-- 이벤트키 2가지
referral_users AS (
    SELECT DISTINCT p.user_id
    FROM revenue_users rv
    INNER JOIN hackle_properties p 
        ON rv.user_id = p.user_id
    INNER JOIN hackle_events e 
        ON p.session_id = e.session_id 
        AND e.event_key IN ('click_friend_invite', 'click_invite_friend')
    WHERE p.user_id IS NOT NULL
      AND p.user_id != ''
      AND e.session_id IS NOT NULL
      AND e.session_id != ''
      AND e.event_datetime IS NOT NULL
),
-- 전체 유저 수 계산 (전체 대비 비율 계산용)
total_users AS (
    SELECT COUNT(*) AS total_count FROM acquisition_users
)
-- 최종 결과: 각 단계별 집계 및 전환율/이탈률 계산
SELECT 
    step_name,
    user_count,
    -- 이전 단계 대비 전환율/이탈율 계산
    COALESCE(ROUND(user_count / LAG(user_count) OVER (ORDER BY step_order), 4), 1.0) AS conversion_rate_from_previous,
    COALESCE(ROUND(1 - (user_count / LAG(user_count) OVER (ORDER BY step_order)), 4), 0.0) AS drop_rate_from_previous,
    -- 전체(Acquisition) 대비 전환율/이탈율 계산
    ROUND(user_count / (SELECT total_count FROM total_users), 4) AS conversion_rate_from_total,
    ROUND(1 - (user_count / (SELECT total_count FROM total_users)), 4) AS drop_rate_from_total
FROM (
    SELECT 'Acquisition' AS step_name, 1 AS step_order, COUNT(*) AS user_count FROM acquisition_users
    UNION ALL
    SELECT 'Activation', 2, COUNT(*) FROM activation_users
    UNION ALL
    SELECT 'Retention', 3, COUNT(*) FROM retention_users
    UNION ALL
    SELECT 'Revenue', 4, COUNT(*) FROM revenue_users
    UNION ALL
    SELECT 'Referral', 5, COUNT(*) FROM referral_users
) AS funnel
ORDER BY step_order;

-- 회원가입을 한 유저가 진짜 적나?
SELECT *
FROM hackle_events
WHERE event_key = 'complete_signup'

-- 회원가입을 한 유저가 진짜 적은지 유저맵에서 확인
-- hp랑 he session id 연결하고 user id 공백 제외
WITH user_map AS (
  SELECT DISTINCT session_id, user_id
  FROM hackle_properties
  WHERE user_id IS NOT NULL AND TRIM(user_id) <> ''
)
SELECT
  COUNT(*) AS total_events,
  COUNT(DISTINCT e.session_id) AS event_sessions,
  COUNT(DISTINCT CASE WHEN um.session_id IS NOT NULL THEN e.session_id END) AS matched_sessions,
  COUNT(DISTINCT CASE WHEN um.session_id IS NOT NULL THEN um.user_id END) AS matched_users
FROM hackle_events e
LEFT JOIN user_map um
  ON e.session_id = um.session_id;

-- 이벤트 별 유저 수
-- 회원가입이 어떤지 보려고
WITH user_map AS (
  SELECT DISTINCT session_id, user_id
  FROM hackle_properties
  WHERE user_id IS NOT NULL AND TRIM(user_id) <> ''
)
SELECT
  e.event_key,
  COUNT(*) AS event_cnt,
  COUNT(DISTINCT um.user_id) AS user_cnt
FROM hackle_events e
JOIN user_map um
  ON e.session_id = um.session_id
GROUP BY e.event_key
ORDER BY user_cnt DESC;



WITH user_map AS (
  SELECT DISTINCT
    session_id,
    user_id
  FROM hackle_properties
  WHERE user_id IS NOT NULL
    AND TRIM(user_id) <> ''
),
user_first_seen AS (
  SELECT
    um.user_id,
    MIN(e.event_datetime) AS first_seen_at
  FROM hackle_events e
  JOIN user_map um
    ON e.session_id = um.session_id
  GROUP BY um.user_id
)

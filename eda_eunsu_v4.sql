-- Active: 1769570532716@@localhost@3313@final_analytics


----------------- 유입 -----------------
-- 회원가입 완료자 수
SELECT COUNT(DISTINCT session_id)
FROM hackle_events
WHERE event_key = 'complete_signup';






----------------- 활성화 -----------------
-- 회원가입 완료자 중 첫 질문 완료자 수
WITH sign_users AS (
    SELECT DISTINCT session_id
    FROM hackle_events
    WHERE event_key = 'complete_signup'
)
SELECT COUNT(DISTINCT session_id)
FROM hackle_events
JOIN sign_users USING(session_id)
WHERE event_key = 'complete_question';

-- 회원가입 완료자 중 첫 질문 완료까지 걸린 시간
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
),
time_stamp_df AS (
	SELECT s.session_id, timestampdiff(SECOND, first_signup_time ,first_question_time) AS time_diff
	FROM sign_users AS s
	LEFT JOIN question_users AS q ON s.session_id = q.session_id
	WHERE q.session_id IS NOT NULL
)
SELECT *
FROM time_stamp_df
WHERE time_diff >= 0;






----------------- 리텐션 -----------------
-- 첫 질문 완료자 수 중 다시 들어온 사람
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
)
SELECT COUNT(DISTINCT session_id)
FROM hackle_events
JOIN sign_users USING(session_id)
JOIN question_users USING(session_id)
WHERE (event_datetime > first_signup_time) AND (event_datetime > first_question_time);

-- 첫 질문 완료부터 리텐션까지 얼마나 걸렸는지
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
),
retentuin_users AS (
    SELECT session_id, MIN(event_datetime) AS first_retention_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    JOIN question_users USING(session_id)
    WHERE (event_datetime > first_signup_time) AND (event_datetime > first_question_time)
    GROUP BY session_id
),
time_stamp_df AS (
	SELECT s.session_id, timestampdiff(SECOND, first_question_time ,first_retention_time) AS time_diff
	FROM sign_users AS s
	LEFT JOIN question_users AS q ON s.session_id = q.session_id
    LEFT JOIN retentuin_users AS r ON s.session_id = r.session_id
	WHERE q.session_id IS NOT NULL AND r.session_id IS NOT NULL
)
SELECT *
FROM time_stamp_df
WHERE time_diff >= 0;






----------------- 수익 -----------------
-- 리텐션 유저 중 구매한 사람
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
),
retentuin_users AS (
    SELECT DISTINCT session_id
    FROM hackle_events
    JOIN sign_users USING(session_id)
    JOIN question_users USING(session_id)
    WHERE (event_datetime > first_signup_time) AND (event_datetime > first_question_time)
)
SELECT COUNT(DISTINCT session_id)
FROM hackle_events
JOIN retentuin_users USING(session_id)
WHERE event_key = 'complete_purchase';

-- 리텐션부터 수익까지 얼마나 걸렸는지
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
),
retentuin_users AS (
    SELECT session_id, MIN(event_datetime) AS first_retention_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    JOIN question_users USING(session_id)
    WHERE (event_datetime > first_signup_time) AND (event_datetime > first_question_time)
    GROUP BY session_id
),
revenue_users AS (
    SELECT session_id, MIN(event_datetime) AS first_revenue_time
    FROM hackle_events
    JOIN retentuin_users USING(session_id)
    WHERE event_key = 'complete_purchase'
    GROUP BY session_id
),
time_stamp_df AS (
	SELECT s.session_id, timestampdiff(SECOND, first_retention_time ,first_revenue_time) AS time_diff
	FROM sign_users AS s
	LEFT JOIN question_users AS q ON s.session_id = q.session_id
    LEFT JOIN retentuin_users AS r ON s.session_id = r.session_id
    LEFT JOIN revenue_users AS v ON s.session_id = v.session_id
	WHERE q.session_id IS NOT NULL AND r.session_id IS NOT NULL AND v.session_id IS NOT NULL
)
SELECT *
FROM time_stamp_df
WHERE time_diff >= 0;







----------------- 추천 -----------------
-- 수익 유저 중 구매한 사람
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
),
retentuin_users AS (
    SELECT DISTINCT session_id
    FROM hackle_events
    JOIN sign_users USING(session_id)
    JOIN question_users USING(session_id)
    WHERE (event_datetime > first_signup_time) AND (event_datetime > first_question_time)
),
revenue_users AS (
    SELECT DISTINCT session_id
    FROM hackle_events
    JOIN retentuin_users USING(session_id)
    WHERE event_key = 'complete_purchase'
)
SELECT COUNT(DISTINCT session_id)
FROM hackle_events
JOIN revenue_users USING(session_id)
WHERE event_key = 'click_friend_invite' OR event_key = 'click_invite_friend';

-- 수익부터 추천까지 얼마나 걸렸는지
WITH sign_users AS (
    SELECT session_id, MIN(event_datetime) AS first_signup_time
    FROM hackle_events
    WHERE event_key = 'complete_signup'
    GROUP BY session_id
),
question_users AS (
    SELECT session_id, MIN(event_datetime) AS first_question_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
    GROUP BY session_id
),
retentuin_users AS (
    SELECT session_id, MIN(event_datetime) AS first_retention_time
    FROM hackle_events
    JOIN sign_users USING(session_id)
    JOIN question_users USING(session_id)
    WHERE (event_datetime > first_signup_time) AND (event_datetime > first_question_time)
    GROUP BY session_id
),
revenue_users AS (
    SELECT session_id, MIN(event_datetime) AS first_revenue_time
    FROM hackle_events
    JOIN retentuin_users USING(session_id)
    WHERE event_key = 'complete_purchase'
    GROUP BY session_id
),
referral_users AS (
    SELECT COUNT(DISTINCT session_id)
    FROM hackle_events
    JOIN revenue_users USING(session_id)
    WHERE event_key = 'click_friend_invite' OR event_key = 'click_invite_friend'
),
time_stamp_df AS (
	SELECT s.session_id, timestampdiff(SECOND, first_retention_time ,first_revenue_time) AS time_diff
	FROM sign_users AS s
	LEFT JOIN question_users AS q ON s.session_id = q.session_id
    LEFT JOIN retentuin_users AS r ON s.session_id = r.session_id
    LEFT JOIN revenue_users AS v ON s.session_id = v.session_id
	WHERE q.session_id IS NOT NULL AND r.session_id IS NOT NULL AND v.session_id IS NOT NULL
)
SELECT *
FROM time_stamp_df
WHERE time_diff >= 0;
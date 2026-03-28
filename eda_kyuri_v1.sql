SELECT 'hackle_events' AS table_name, COUNT(*) FROM hackle_events
UNION ALL
SELECT 'user_properties', COUNT(*) FROM user_properties
UNION ALL
SELECT 'device_properties', COUNT(*) FROM device_properties
UNION ALL
SELECT 'hackle_properties', COUNT(*) FROM hackle_properties;

DESCRIBE hackle_events

SELECT COUNT(DISTINCT id) as users_cnt
FROM hackle_events;

# event_key 
SELECT event_key, COUNT(*) as event_cnt
FROM hackle_events
GROUP BY event_key
ORDER BY event_cnt DESC;

SELECT MIN(event_datetime) as min_time, MAX(event_datetime) as max_time
FROM hackle_events;

# 날짜별 이벤트 수
SELECT DATE(event_datetime) as date, COUNT(*) as events
FROM hackle_events
GROUP BY DATE(event_datetime)
ORDER BY events DESC;

SELECT id, COUNT(*) as event_cnt
FROM hackle_events
GROUP BY id
ORDER BY event_cnt DESC
LIMIT 10;


SELECT COUNT(DISTINCT session_id) as sessions
FROM hackle_events;

SELECT session_id, COUNT(*) as event_cnt
FROM hackle_events
GROUP BY session_id
ORDER BY event_cnt DESC
LIMIT 20;

SELECT page_name, COUNT(*) as cnt
FROM hackle_events
WHERE page_name IS NOT NULL
GROUP BY page_name
ORDER BY cnt DESC;


SELECT item_name, COUNT(*) as cnt
FROM hackle_events
WHERE item_name IS NOT NULL 
GROUP BY item_name
ORDER BY cnt DESC;

SELECT MIN(friend_count), MAX(friend_count)
FROM hackle_events

SELECT MIN(votes_count), MAX(votes_count)
FROM hackle_events

SELECT MIN(heart_balance), MAX(heart_balance)
FROM hackle_events

SELECT session_id, heart_balance 
FROM hackle_events
ORDER BY heart_balance DESC
LIMIT 135

SELECT COUNT(id)
FROM hackle_events
WHERE heart_balance = 884999804

SELECT COUNT(DISTINCT session_id) as user_uuid
FROM hackle_events

DESCRIBE device_properties

SELECT d.device_vendor, COUNT(*) as event_cnt
FROM hackle_events e
JOIN device_properties d ON e.id=d.device_id
GROUP BY d.device_vendor
ORDER BY event_cnt DESC;

SELECT COUNT(*) as total_devices
FROM device_properties

SELECT COUNT(*) as total_rows, COUNT(device_id) as non_null_device_id, COUNT(*) - COUNT(device_id) as null_device_id
FROM device_properties;

SELECT device_vendor, COUNT(*) as cnt
FROM device_properties
GROUP BY device_vendor
ORDER BY cnt DESC

SELECT device_model, COUNT(*) as cnt
FROM device_properties
GROUP BY device_model
ORDER BY cnt DESC
LIMIT 20


SELECT device_vendor, device_model, COUNT(*) as cnt
FROM device_properties
GROUP BY device_vendor, device_model
ORDER BY cnt DESC
LIMIT 20

SELECT COUNT(DISTINCT device_id) as distinct_device_id, COUNT(*) as total_rows
FROM device_properties

SELECT device_vendor, COUNT(*) as cnt, ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER (), 2) as ratio_pct
FROM device_properties
GROUP BY device_vendor
ORDER BY CNT DESC

SELECT COUNT(*) as total_rows, COUNT(DISTINCT id) as distinct_user_id
FROM user_properties;

SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT user_id) as distinct_uesr,
    COUNT(DISTINCT session_id) as distinct_session,
    COUNT(DISTINCT device_id) as distinct_device
FROM hackle_properties


SELECT 
    COUNT(*) as total,
    SUM(user_id IS NULL) as null_user,
    SUM(session_id IS NULL) as null_session,
    SUM(device_id IS NULL) as null_device,
    SUM(language IS NULL) as null_language,
    SUM(osname IS NULL) as null_os
FROM hackle_properties

SELECT language, COUNT(*) as cnt
FROM hackle_properties
GROUP BY language
ORDER BY cnt DESC

SELECT osname, COUNT(*) as cnt
FROM hackle_properties
GROUP BY osname
ORDER BY cnt DESC

SELECT user_id, COUNT(DISTINCT session_id) as session_cnt
FROM hackle_properties
GROUP BY user_id
ORDER BY session_cnt DESC
LIMIT 20

SELECT device_id, COUNT(DISTINCT user_id) as user_cnt
FROM hackle_properties
GROUP BY device_id
ORDER BY user_cnt DESC
LIMIT 20

SELECT COUNT(*) as total_rows, COUNT(DISTINCT user_id) as distinct_user
FROM user_properties

SELECT 
    COUNT(*) as total,
    SUM(user_id IS NULL) as null_user,
    SUM(class IS NULL) as null_class,
    SUM(grade IS NULL) as null_grade,
    SUM(gender IS NULL) as null_gender,
    SUM(school_id IS NULL) as null_school
FROM user_properties

SELECT grade, COUNT(*) as cnt
FROM user_properties
GROUP BY grade
ORDER BY grade

SELECT class, COUNT(*) as cnt
FROM user_properties
GROUP BY class
ORDER BY cnt DESC

SELECT gender, COUNT(*) as cnt
FROM user_properties
GROUP BY gender

SELECT COUNT(DISTINCT school_id) as school_cnt
FROM user_properties

SELECT school_id, COUNT(*) as user_cnt
FROM user_properties
GROUP BY school_id
ORDER BY user_cnt DESC
LIMIT 20

SELECT school_id, grade, COUNT(*) as cnt
FROM user_properties
GROUP BY school_id, grade
ORDER BY cnt DESC
LIMIT 50

SELECT session_id, COUNT(*) as event_cnt
FROM hackle_events
GROUP BY session_id
ORDER BY event_cnt DESC
LIMIT 20

SELECT 
    SUM(event_key = '$session_start') as session_start_cnt,
    SUM(event_key = '$session_end') as session_end_cnt
FROM hackle_events

SELECT event_key, COUNT(*) as cnt
FROM hackle_events
WHERE event_key LIKE '%vote%'
GROUP BY event_key
ORDER BY cnt DESC

SELECT HOUR(event_datetime) as hour, COUNT(*) as cnt
FROM hackle_events
GROUP BY hour
ORDER BY hour

SELECT event_datetime AS utc_time, CONVERT_TZ(event_datetime, '+00:00', '+09:00') AS kst_time
FROM hackle_events
LIMIT 10;

# 
SELECT
  HOUR(event_datetime + INTERVAL 9 HOUR) AS hour_kst,
  COUNT(*) AS event_cnt
FROM hackle_events
GROUP BY hour_kst
ORDER BY hour_kst;


SELECT DAYOFWEEK(event_datetime) AS dow, COUNT(*) AS event_cnt
FROM hackle_events
GROUP BY dow
ORDER BY dow;


SELECT event_key, HOUR(event_datetime) AS hour_kst, COUNT(*) AS cnt
FROM hackle_events
GROUP BY event_key, hour_kst
ORDER BY event_key, cnt DESC;


SELECT
  MIN(events_per_session) AS min_evt,
  MAX(events_per_session) AS max_evt,
  AVG(events_per_session) AS avg_evt
FROM (
  SELECT session_id, COUNT(*) AS events_per_session
  FROM hackle_events
  GROUP BY session_id
) t;


SELECT p.user_id, COUNT(DISTINCT p.session_id) AS session_cnt, COUNT(e.event_id) AS event_cnt
FROM hackle_properties p
JOIN hackle_events e
  ON p.session_id = e.session_id
GROUP BY p.user_id
ORDER BY event_cnt DESC;



SELECT COUNT(session_id), COUNT(DISTINCT session_id)
FROM hackle_events

SELECT 
    COUNT(DISTINCT session_id) as total_session, 
    COUNT(DISTINCT
        CASE WHEN event_key LIKE '%vote%' THEN session_id END) as voted_sessions
FROM hackle_events

SELECT 
    COUNT(DISTINCT CASE WHEN event_key IN ('view_questions_tab', 'click_question_open') THEN session_id END) AS view_question_sessions,
    COUNT(DISTINCT CASE WHEN event_key LIKE '%vote%' THEN session_id END) AS voted_sessions
FROM hackle_events;

SELECT event_key, COUNT(*) AS cnt
FROM hackle_events
WHERE event_key LIKE '%vote%'
   OR event_key LIKE '%poll%'
   OR event_key LIKE '%ballot%'
GROUP BY event_key
ORDER BY cnt DESC;


SELECT event_key, COUNT(*) AS cnt
FROM hackle_events
GROUP BY event_key
ORDER BY cnt DESC
LIMIT 50;


# 세션당 질문 소비량
SELECT session_id, COUNT(*) as question_open_cnt
FROM hackle_events
WHERE event_key = 'click_question_open'
GROUP BY session_id
ORDER BY question_open_cnt DESC

SELECT
  COUNT(CASE WHEN event_key = 'click_question_open' THEN 1 END) AS open_cnt,
  COUNT(CASE WHEN event_key = 'skip_question' THEN 1 END) AS skip_cnt
FROM hackle_events;


SELECT
  COUNT(DISTINCT session_id) AS total_sessions,
  COUNT(DISTINCT CASE WHEN event_key = 'click_question_open' THEN session_id END) AS question_view_sessions,
  COUNT(DISTINCT CASE WHEN event_key = 'skip_question' THEN session_id END) AS skip_sessions
FROM hackle_events;


SELECT session_id, COUNT(*) AS open_cnt
FROM hackle_events
WHERE event_key = 'click_question_open'
GROUP BY session_id
ORDER BY open_cnt DESC
LIMIT 20;


SELECT
  session_id,
  SUM(CASE WHEN event_key = 'click_question_open' THEN 1 ELSE 0 END) AS open_cnt,
  SUM(CASE WHEN event_key = 'skip_question' THEN 1 ELSE 0 END) AS skip_cnt
FROM hackle_events
GROUP BY session_id
ORdER BY skip_cnt DESC open_cnt DESC


SELECT
  COUNT(DISTINCT session_id) AS total_sessions,
  COUNT(DISTINCT CASE WHEN event_key = 'view_questions_tab' THEN session_id END) AS view_questions,
  COUNT(DISTINCT CASE WHEN event_key = 'click_question_open' THEN session_id END) AS open_question,
  COUNT(DISTINCT CASE WHEN event_key = 'skip_question' THEN session_id END) AS skip_question
FROM hackle_events;


# 질문 단위로 오픈 편차가 있는가
SELECT
  question_id,
  COUNT(*) AS event_cnt,
  COUNT(DISTINCT session_id) AS session_cnt
FROM hackle_events
WHERE question_id IS NOT NULL
GROUP BY question_id
ORDER BY session_cnt DESC
LIMIT 20;


# 한 유저는 평균 몇 번 접속하는가
SELECT
  AVG(session_cnt) AS avg_sessions_per_user
FROM (
  SELECT user_id, COUNT(DISTINCT session_id) AS session_cnt
  FROM hackle_properties
  GROUP BY user_id
) t;

SELECT
  u.grade,
  COUNT(*) AS open_cnt
FROM hackle_events e
JOIN hackle_properties h ON e.session_id = h.session_id
JOIN user_properties u ON h.user_id = u.user_id
WHERE e.event_key = 'click_question_open'
GROUP BY u.grade
ORDER BY open_cnt DESC;


SELECT
  d.device_vendor,
  COUNT(*) AS open_cnt
FROM hackle_events e
JOIN hackle_properties h ON e.session_id = h.session_id
JOIN device_properties d ON h.device_id = d.device_id
WHERE e.event_key = 'click_question_open'
GROUP BY d.device_vendor
ORDER BY open_cnt DESC;


WITH question_sessions AS (
  SELECT DISTINCT session_id
  FROM hackle_events
  WHERE event_key = 'click_question_open'
),
vote_sessions AS (
  SELECT DISTINCT session_id
  FROM hackle_events
  WHERE event_key = 'complete_question'
)
SELECT
  COUNT(DISTINCT q.session_id) AS question_sessions,
  COUNT(DISTINCT v.session_id) AS voted_sessions,
  ROUND(
    COUNT(DISTINCT v.session_id) / COUNT(DISTINCT q.session_id), 3
  ) AS vote_conversion_rate
FROM question_sessions q
LEFT JOIN vote_sessions v
  ON q.session_id = v.session_id;


SELECT
  event_key,
  COUNT(DISTINCT session_id) AS session_cnt
FROM hackle_events
WHERE event_key IN ('complete_question', 'skip_question')
GROUP BY event_key;


WITH voted_user AS (
  SELECT DISTINCT hp.user_id
  FROM hackle_events he
  JOIN hackle_properties hp
    ON he.session_id = hp.session_id
  WHERE he.event_key = 'complete_question'
)
SELECT
  up.grade,
  COUNT(DISTINCT up.user_id) AS total_users,
  COUNT(DISTINCT vu.user_id) AS voted_users,
  ROUND(
    COUNT(DISTINCT vu.user_id) / COUNT(DISTINCT up.user_id), 3
  ) AS vote_rate
FROM user_properties up
LEFT JOIN voted_user vu
  ON up.user_id = vu.user_id
GROUP BY up.grade
ORDER BY up.grade;

SELECT
  dp.device_vendor,
  COUNT(DISTINCT he.session_id) AS total_sessions,
  COUNT(DISTINCT CASE
    WHEN he.event_key = 'complete_question'
    THEN he.session_id END) AS voted_sessions
FROM hackle_events he
JOIN hackle_properties hp
  ON he.session_id = hp.session_id
JOIN device_properties dp
  ON hp.device_id = dp.device_id
GROUP BY dp.device_vendor
ORDER BY voted_sessions DESC;


SELECT
  session_id,
  TIMESTAMPDIFF(
    SECOND,
    MIN(event_datetime),
    MAX(event_datetime)
  ) AS session_duration_sec
FROM hackle_events
GROUP BY session_id
ORDER BY session_duration_sec DESC


WITH session_duration AS (
  SELECT
    session_id,
    TIMESTAMPDIFF(
      SECOND,
      MIN(event_datetime),
      MAX(event_datetime)
    ) AS duration_sec
  FROM hackle_events
  GROUP BY session_id
)
SELECT
  COUNT(*) AS total_sessions,
  AVG(duration_sec) AS avg_sec,
  MIN(duration_sec) AS min_sec,
  MAX(duration_sec) AS max_sec,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration_sec) AS median_sec
FROM session_duration;


WITH session_duration AS (
  SELECT
    session_id,
    TIMESTAMPDIFF(
      SECOND,
      MIN(event_datetime),
      MAX(event_datetime)
    ) AS duration_sec
  FROM hackle_events
  GROUP BY session_id
),
user_duration AS (
  SELECT
    u.user_id,
    SUM(s.duration_sec) AS total_duration_sec,
    AVG(s.duration_sec) AS avg_session_duration_sec,
    COUNT(*) AS session_cnt
  FROM session_duration s
  JOIN user_properties u
    ON s.session_id = u.session_id
  GROUP BY u.user_id
)
SELECT
  COUNT(*) AS total_users,
  AVG(total_duration_sec) AS avg_user_total_duration_sec,
  MIN(total_duration_sec) AS min_user_total_duration_sec,
  MAX(total_duration_sec) AS max_user_total_duration_sec,
  AVG(avg_session_duration_sec) AS avg_session_duration_per_user,
  AVG(session_cnt) AS avg_session_cnt_per_user
FROM user_duration;


WITH session_duration AS (
  SELECT
    session_id,
    TIMESTAMPDIFF(
      SECOND,
      MIN(event_datetime),
      MAX(event_datetime)
    ) AS duration_sec
  FROM hackle_events
  GROUP BY session_id
),
user_duration AS (
  SELECT
    hp.user_id,
    SUM(sd.duration_sec) AS total_duration_sec,
    AVG(sd.duration_sec) AS avg_session_duration_sec,
    COUNT(*) AS session_cnt
  FROM session_duration sd
  JOIN hackle_properties hp
    ON sd.session_id = hp.session_id
  GROUP BY hp.user_id
)
SELECT
  COUNT(*) AS total_users,
  AVG(total_duration_sec) AS avg_user_total_duration_sec,
  MIN(total_duration_sec) AS min_user_total_duration_sec,
  MAX(total_duration_sec) AS max_user_total_duration_sec,
  AVG(avg_session_duration_sec) AS avg_session_duration_per_user,
  AVG(session_cnt) AS avg_session_cnt_per_user
FROM user_duration;

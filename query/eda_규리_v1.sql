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
SELECT
  hp.user_id,
  he.heart_balance,
  COUNT(*) AS event_cnt
FROM hackle_events he
JOIN hackle_properties hp
  ON he.session_id = hp.session_id
WHERE he.heart_balance IS NOT NULL
GROUP BY hp.user_id, he.heart_balance
ORDER BY hp.user_id, he.heart_balance;


# session id별 로그 수
SELECT
  hp.session_id,
  COUNT(*) AS event_cnt
FROM hackle_events he
JOIN hackle_properties hp
  ON he.session_id = hp.session_id
GROUP BY hp.session_id
ORDER BY event_cnt DESC
LIMIT 50;


WITH session_time AS (
  SELECT
    session_id,
    MIN(CASE WHEN event_key = '$session_start' THEN event_datetime END) AS session_start_time,
    MIN(CASE WHEN event_key = '$session_end' THEN event_datetime END) AS session_end_time
  FROM hackle_events
  GROUP BY session_id
)
SELECT
  session_id,
  TIMESTAMPDIFF(SECOND, session_start_time, session_end_time) AS session_duration_sec
FROM session_time
WHERE session_start_time IS NOT NULL
  AND session_end_time IS NOT NULL
ORDER BY session_duration_sec DESC;


SELECT
  votes_count,
  COUNT(*) AS cnt
FROM hackle_events
WHERE votes_count IS NOT NULL
GROUP BY votes_count
ORDER BY votes_count DESC
LIMIT 20;


SELECT
  device_id,
  COUNT(DISTINCT user_id) AS user_cnt
FROM hackle_properties
GROUP BY device_id
HAVING user_cnt > 1
ORDER BY user_cnt DESC
LIMIT 20;


WITH ses AS (
  SELECT
    session_id,
    MIN(CASE WHEN event_key = '$session_start' THEN event_datetime END) AS start_dt,
    MIN(CASE WHEN event_key = '$session_end'   THEN event_datetime END) AS end_dt
  FROM hackle_events
  WHERE session_id IS NOT NULL
  GROUP BY session_id
)
SELECT
  COUNT(*) AS total_sessions,
  SUM(start_dt IS NOT NULL) AS sessions_with_start,
  SUM(end_dt IS NOT NULL)   AS sessions_with_end,
  SUM(start_dt IS NOT NULL AND end_dt IS NOT NULL) AS sessions_with_both,
  AVG(TIMESTAMPDIFF(SECOND, start_dt, end_dt)) AS avg_duration_sec,
  MIN(TIMESTAMPDIFF(SECOND, start_dt, end_dt)) AS min_duration_sec,
  MAX(TIMESTAMPDIFF(SECOND, start_dt, end_dt)) AS max_duration_sec
FROM ses
WHERE start_dt IS NOT NULL
  AND end_dt IS NOT NULL
  AND end_dt >= start_dt;


SELECT
  session_id,
  MAX(friend_count) AS max_friend_count,
  MAX(votes_count)  AS max_votes_count
FROM hackle_events
 
 
SELECT
  session_id,
  MAX(friend_count) AS max_friend_count,
  MAX(votes_count)  AS max_votes_count
FROM hackle_events
WHERE session_id IS NOT NULL
GROUP BY session_id
ORDER BY max_votes_count DESC, max_friend_count DESC
LIMIT 200;

SELECT
  session_id,
  MAX(friend_count) AS max_friend_count
FROM hackle_events
WHERE session_id IS NOT NULL
GROUP BY session_id
ORDER BY max_friend_count DESC
LIMIT 200;

SELECT
  session_id,
  MAX(votes_count)  AS max_votes_count
FROM hackle_events
WHERE session_id IS NOT NULL
GROUP BY session_id
ORDER BY max_votes_count DESC
LIMIT 200;
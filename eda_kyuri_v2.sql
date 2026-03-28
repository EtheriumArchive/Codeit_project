SELECT 
    COUNT(*) as total_session_in_events,
    COUNT(DISTINCT e.session_id) as distinct_sessions_in_events,
    COUNT(DISTINCT hp.session_id) as distinct_sessions_in_hackle_properties,
    COUNT(DISTINCT CASE WHEN hp.user_id IS NOT NULL THEN e.session_id END) as sessions_mapped_to_user
FROM hackle_events e
LEFT JOIN hackle_properties hp
    on e.session_id = hp.session_id

# hackle_events 결측치
# null question id가 엄청 많음
SELECT
    COUNT(*) AS total_rows,

    SUM(event_id IS NULL OR TRIM(event_id) = '') AS bad_event_id,
    SUM(session_id IS NULL OR TRIM(session_id) = '') AS bad_session_id,
    SUM(event_key IS NULL OR TRIM(event_key) = '') AS bad_event_key,

    SUM(id IS NULL OR TRIM(id) = '') AS bad_id
FROM hackle_events;

SELECT
  COUNT(*) AS total_rows,
  SUM(event_datetime IS NULL) AS null_event_datetime
FROM hackle_events;


SELECT
  SUM(item_name IS NULL OR TRIM(item_name) = '') AS bad_item_name,
  SUM(page_name IS NULL OR TRIM(page_name) = '') AS bad_page_name,
  SUM(question_id IS NULL) AS null_question_id
FROM hackle_events;

SELECT
  SUM(friend_count IS NULL) AS null_friend_count,
  SUM(votes_count IS NULL) AS null_votes_count,
  SUM(heart_balance IS NULL) AS null_heart_balance
FROM hackle_events;


# hackle_properties
SELECT
  COUNT(*) AS total_rows,

  SUM(session_id IS NULL OR TRIM(session_id) = '') AS bad_session_id,
  SUM(user_id IS NULL OR TRIM(user_id) = '') AS bad_user_id,
  SUM(device_id IS NULL OR TRIM(device_id) = '') AS bad_device_id
FROM hackle_properties;

SELECT
  SUM(language IS NULL OR TRIM(language) = '') AS bad_language,
  SUM(osname IS NULL OR TRIM(osname) = '') AS bad_osname,
  SUM(osversion IS NULL OR TRIM(osversion) = '') AS bad_osversion,
  SUM(versionname IS NULL OR TRIM(versionname) = '') AS bad_versionname
FROM hackle_properties;


SELECT
  COUNT(*) AS total_rows,
  SUM(user_id IS NULL OR TRIM(user_id) = '') AS bad_user_id
FROM user_properties;

SELECT
  SUM(class IS NULL) AS null_class,
  SUM(grade IS NULL) AS null_grade,
  SUM(school_id IS NULL) AS null_school_id,
  SUM(gender IS NULL OR TRIM(gender) = '') AS bad_gender
FROM user_properties;

SELECT
  gender,
  COUNT(*) AS cnt
FROM user_properties
GROUP BY gender
ORDER BY cnt DESC;


SELECT
  COUNT(*) AS total_rows,
  SUM(device_id IS NULL OR TRIM(device_id) = '') AS bad_device_id
FROM device_properties;

SELECT
  event_key,
  COUNT(*) AS total_cnt,

  SUM(question_id IS NULL) AS null_question_id,
  ROUND(100 * SUM(question_id IS NULL) / COUNT(*), 2) AS null_qid_pct,

  SUM(item_name IS NULL) AS null_item_name,
  ROUND(100 * SUM(item_name IS NULL) / COUNT(*), 2) AS null_item_pct,

  SUM(page_name IS NULL) AS null_page_name,
  ROUND(100 * SUM(page_name IS NULL) / COUNT(*), 2) AS null_page_pct,

  SUM(friend_count IS NULL) AS null_friend_count,
  SUM(votes_count IS NULL) AS null_votes_count,
  SUM(heart_balance IS NULL) AS null_heart_balance
FROM hackle_events
GROUP BY event_key
ORDER BY total_cnt DESC
LIMIT 50;


SELECT COUNT(*)
FROM hackle_events
WHERE event_key = 'skip_question'
  AND question_id IS NULL
LIMIT 100;


SELECT
    heart_balance,
    COUNT(*) AS event_cnt
FROM hackle_events
WHERE heart_balance IS NOT NULL
GROUP BY heart_balance
ORDER BY heart_balance;


SELECT
  COUNT(*) AS total_rows,
  COUNT(heart_balance) AS non_null_heart,
  MIN(heart_balance) AS min_heart,
  MAX(heart_balance) AS max_heart,
  AVG(heart_balance) AS avg_heart
FROM hackle_events;


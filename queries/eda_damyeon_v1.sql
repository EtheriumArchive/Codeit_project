-- Active: 1769489305704@@localhost@3313@final_analytics

-- I. hackle_properties
-- 1-1. user_id 고유값 집계
SELECT COUNT(DISTINCT(user_id))
FROM hackle_properties
;

-- 1-2. user_id 별 방문 횟수
SELECT
    user_id,
    COUNT(*)
FROM hackle_properties
GROUP BY user_id
ORDER BY COUNT(*) DESC
;

-- 2. hackle 속성 중 언어별 집계
SELECT
    language,
    COUNT(*) AS count
FROM hackle_properties
GROUP BY language
ORDER BY COUNT(*) DESC
;

-- 3. hackle 속성 중 운영체제 집계
SELECT
    osname,
    COUNT(*) AS count,
    COUNT(*) / SUM(COUNT(*)) OVER() * 100 AS ratio
FROM hackle_properties
GROUP BY osname
ORDER BY count DESC
;

-- 4. 앱 버전별 방문수
SELECT versionname, COUNT(*)
FROM hackle_properties
GROUP BY versionname
;

-- 5. user_id와 device_id 집계 차이
SELECT 
    COUNT(DISTINCT(user_id)) AS user_count,
    COUNT(DISTINCT(device_id)) AS device_count
FROM hackle_properties
;

-- 6. 한 유저가 여러 기기를 사용하는지
SELECT user_id, COUNT(DISTINCT(device_id)) AS device_count
FROM hackle_properties
GROUP BY user_id
HAVING device_count > 1
ORDER BY device_count DESC
;

------------------------

-- II. device_properties
SELECT *
FROM device_properties
LIMIT 10
;

-- 1. device_id 고유값
SELECT COUNT(DISTINCT(device_id))
FROM device_properties
;

-- 2. device_model 고유값
SELECT DISTINCT(device_model)
FROM device_properties
;

-- 3. device_model 집계
SELECT
    CASE 
        WHEN device_model LIKE 'iPhone%' THEN 'iPhone'
        WHEN device_model LIKE 'iPad%' THEN 'iPad'
        WHEN device_model LIKE 'SM-%' THEN 'Samsung'
        ELSE 'ETC'
    END AS brand,
    COUNT(*) / SUM(COUNT(*)) OVER() * 100 AS ratio
FROM device_properties
GROUP BY brand
;

-- 4. 장치 제조사 비율
SELECT 
    DISTINCT(device_vendor) AS device_vendor,
    COUNT(*) / SUM(COUNT(*)) OVER() * 100 AS ratio
FROM device_properties
GROUP BY device_vendor
ORDER BY ratio DESC
;

-----------------

-- III. hackle_events
SELECT *
FROM hackle_events
LIMIT 10
;

-- 1. event_datetime 발생 분포 집계
-- 1-1. 일별 집계
SELECT
    DATE_FORMAT(event_datetime, '%Y-%m-%d') AS date,
    COUNT(*) AS count,
    COUNT(*) / SUM(COUNT(*)) OVER() * 100 AS ratio
FROM hackle_events
GROUP BY date
ORDER BY date ASC
;
-- 1-2. 시간별 집계
SELECT
    DATE_FORMAT(event_datetime, '%H') AS timeline,
    COUNT(*) AS count,
    COUNT(*) / SUM(COUNT(*)) OVER() * 100 AS ratio
FROM hackle_events
GROUP BY timeline
ORDER BY timeline ASC
;

-- 2. evnet_key 집계 -- 이벤트 목록 참고
SELECT
    event_key,
    COUNT(event_key) AS count,
    COUNT(event_key) / SUM(COUNT(event_key)) OVER() * 100 AS ratio
FROM hackle_events
WHERE event_key NOT IN ('button', 'click_appbar_setting', '$session_start', '$session_end') -- 이벤트 목록 중 전처리대상, 세션 시작/종료 제외
GROUP BY event_key
ORDER BY count DESC
;

-- 2-1. 가장 오래 머무른 event_key -> hackle_properties join 필요..
SELECT
    id,
    event_datetime,
    event_key
FROM hackle_events
ORDER BY id, event_datetime
;

-- 3. item_name 집계
SELECT 
    DISTINCT(item_name),
    COUNT(item_name) AS count,
    event_key,
    COUNT(*) / SUM(COUNT(event_key)) OVER() * 100 AS ratio
FROM hackle_events
GROUP BY item_name, event_key
HAVING item_name != ''
ORDER BY count DESC
;
-- 3-1. event_key에 click_purchase 중 누락 없는지 비교 -> 없음!
SELECT COUNT(event_key)
FROM hackle_events
WHERE event_key = 'click_purchase'
;

-- 4. page_name 집계
SELECT DISTINCT(page_name), COUNT(*)
FROM hackle_events
WHERE page_name != ''
GROUP BY page_name
;

-- 5. friend_count
SELECT friend_count
FROM hackle_events
ORDER BY friend_count DESC
LIMIT 10
;

-- 6. votes_count
SELECT *
FROM hackle_events
ORDER BY votes_count DESC
LIMIT 5
;

-- 7. question_id
SELECT question_id, event_key, COUNT(*)
FROM hackle_events
GROUP BY question_id, event_key
HAVING question_id IS NOT NULL
ORDER BY COUNT(*) DESC
;

-- hackle_event, hackle_properties join
SELECT
    user_id,
    p.session_id,
    event_datetime,
    event_key,
    question_id
FROM hackle_properties p
LEFT JOIN hackle_events e ON p.session_id = e.session_id
LIMIT 10
;

-- 시간차 집계를 돌려보고 싶은데 .. 안돌아가요 ..
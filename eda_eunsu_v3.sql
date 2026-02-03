-- Active: 1769570532716@@localhost@3313@final_analytics


-- 질문 세트 테이블 기간 확인
SELECT MIN(created_at) AS min_date,
    MAX(created_at) AS max_date
FROM polls_questionset;

-- 하트 개수 이상치 확인
SELECT *
FROM hackle_events
ORDER BY heart_balance DESC
LIMIT 10;





----------------- hackle_properties -----------------
SELECT *
FROM hackle_properties;

-- null값 모두 없음
SELECT COUNT(*)
FROM hackle_properties
WHERE device_id = '';






----------------- hackle_properties -----------------
SELECT *
FROM device_properties;


-- null값 모두 없음
SELECT COUNT(*)
FROM device_properties
WHERE device_vendor = '';





----------------- hackle_events -----------------
SELECT *
FROM hackle_events;

-- item_id 값이 있는 데이터는 로그가 무슨 종류일까 
SELECT DISTINCT event_key
FROM hackle_events
WHERE item_name <> '';

-- page_name 값이 있는 데이터는 로그가 무슨 종류일까 
SELECT event_key, page_name
FROM hackle_events
WHERE page_name <> ''
GROUP BY event_key, page_name
ORDER BY event_key, page_name;

-- question id가 NULL인 경우에는 어떤 로그가 찍혔을까
SELECT DISTINCT event_key
FROM hackle_events
WHERE question_id IS NULL;

-- question id가 NULL인 경우에는 어떤 로그가 찍혔을까
SELECT DISTINCT event_key
FROM hackle_events
WHERE question_id IS NOT NULL;

--
SELECT DISTINCT event_key
FROM hackle_events
WHERE event_key = 'click_question_open';

-- votes 파일에서 재확인
SELECT *
FROM hackle_events
WHERE event_key = 'click_question_open';

-- 하트가 NULL인 경우의 로그 확인
SELECT DISTINCT event_key
FROM hackle_events
WHERE heart_balance IS NULL;

-- 실제 구입한 하트 합계(유저별)
SELECT user_id, SUM(SUBSTRING_INDEX(`productId`, '.', -1)) AS total_hearts
FROM accounts_paymenthistory
GROUP BY user_id
ORDER BY total_hearts DESC;

-- 구매 성공, 실패 합친 테이블
WITH total_buy AS (
    SELECT *, 's' AS status
    FROM accounts_paymenthistory
    UNION ALL
    SELECT *, 'f' AS status
    FROM accounts_failpaymenthistory
),
fail_users AS (
    SELECT DISTINCT user_id
    FROM accounts_failpaymenthistory
)
SELECT *
FROM total_buy AS b
JOIN fail_users USING(user_id)
ORDER BY user_id, created_at ASC;

-- 무료충전을 한 유저 중 얼마나 많이 하트를 가지고 있는지, 얼마나 참여했는지
SELECT session_id, 
    AVG(heart_balance) AS avg_hearts, 
    COUNT(*) AS free_counts
FROM hackle_events
WHERE item_name LIKE '무료%'
GROUP BY session_id
ORDER BY AVG(heart_balance) DESC;

-- 무료 충전 가끔 1000씩 올라가는 거 확인
SELECT session_id, event_datetime, item_name, heart_balance
FROM hackle_events
WHERE item_name LIKE '무료%' AND session_id = '48749aac-4146-48a0-870a-adc6669a901c'
ORDER BY event_datetime;

SELECT session_id, event_datetime, item_name, heart_balance
FROM hackle_events
WHERE item_name LIKE '무료%' AND session_id = '040914e1-61ac-40ef-b76a-718066d880dc'
ORDER BY event_datetime;

-- 무료충전 이용 TOP10 유저의 무료충전 전체 이용 기록
WITH TOP_10_users AS (
	SELECT session_id
	FROM hackle_events
	WHERE item_name LIKE '무료%'
	GROUP BY session_id
	ORDER BY COUNT(*) DESC
	LIMIT 10
)
SELECT session_id, event_datetime, item_name, heart_balance
FROM hackle_events
JOIN TOP_10_users USING(session_id)
WHERE item_name LIKE '무료%'
ORDER BY session_id, event_datetime;









----------------- user_properties -----------------
SELECT *
FROM user_properties;

-- 중복값 확인
SELECT COUNT(*) - COUNT(DISTINCT(user_id))
FROM user_properties;

-- 결측값 확인
SELECT *
FROM user_properties
WHERE school_id = '';

-- 반 몇 개가 최대인가
SELECT MAX(class)
FROM user_properties;

-- 반마다 인원 수
SELECT class, COUNT(*)
FROM user_properties
GROUP BY class
ORDER BY class DESC;

-- 15반 이상 있는 학교를 대상으로 반 인원 및 구성 확인
WITH over_15c_schools AS (
    SELECT DISTINCT school_id
    FROM user_properties
    WHERE class > 14
)
SELECT school_id, class, COUNT(*) AS all_counts
FROM user_properties AS p
JOIN over_15c_schools USING(school_id)
GROUP BY school_id, class
ORDER BY school_id, class;

-- 학교 당 평균 불연속 적인 수치 (15개 반 이상인 학교)
WITH over_15c_schools AS (
    SELECT DISTINCT school_id
    FROM user_properties
    WHERE class >= 15
),
check_counts AS (
    SELECT school_id, class, COUNT(*) AS all_counts
    FROM user_properties AS p
    JOIN over_15c_schools USING(school_id)
    GROUP BY school_id, class
    ORDER BY school_id, class
), 
add_partition AS (
    SELECT school_id, class, 
    LAG(class) OVER (ORDER BY school_id, class) AS lag_class, 
    all_counts,
    ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY school_id, class) AS row_class
    FROM check_counts
),
cal_avg_per AS (
    SELECT school_id, AVG(class - lag_class) AS avg_class_diff
    FROM add_partition
    WHERE row_class > 1
    GROUP BY school_id
)
SELECT AVG(avg_class_diff) AS total_avg_class_diff
FROM cal_avg_per;

-- 학교 당 평균 불연속 적인 수치 (14개 반 이하인 학교)
WITH under_15c_schools AS (
    SELECT DISTINCT school_id
    FROM user_properties
    WHERE class <= 14
),
check_counts AS (
    SELECT school_id, class, COUNT(*) AS all_counts
    FROM user_properties AS p
    JOIN under_15c_schools USING(school_id)
    GROUP BY school_id, class
    ORDER BY school_id, class
), 
add_partition AS (
    SELECT school_id, class, 
    LAG(class) OVER (ORDER BY school_id, class) AS lag_class, 
    all_counts,
    ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY school_id, class) AS row_class
    FROM check_counts
),
cal_avg_per AS (
    SELECT school_id, AVG(class - lag_class) AS avg_class_diff
    FROM add_partition
    WHERE row_class > 1
    GROUP BY school_id
)
SELECT AVG(avg_class_diff) AS total_avg_class_diff
FROM cal_avg_per;

-- 10개, 11개, 12개 ... 20개의 반까지의 평균 반차이 비교
WITH RECURSIVE thresholds AS (
    SELECT 10 AS min_class
    UNION ALL
    SELECT min_class + 1
    FROM thresholds
    WHERE min_class <= 20
),
check_counts AS (
    SELECT DISTINCT school_id, class
    FROM user_properties
),
add_partition AS (
    SELECT
        school_id,
        class,
        LAG(class) OVER (PARTITION BY school_id ORDER BY class) AS lag_class
    FROM check_counts
),
school_avg_diff AS (
    SELECT
        school_id,
        AVG(class - lag_class) AS avg_class_diff
    FROM add_partition
    WHERE lag_class IS NOT NULL
    GROUP BY school_id
)
SELECT
    t.min_class,
    AVG(s.avg_class_diff) AS total_avg_class_diff
FROM thresholds t
JOIN school_avg_diff s
    ON EXISTS (
        SELECT 1
        FROM user_properties p
        WHERE p.school_id = s.school_id
          AND p.class >= t.min_class
    )
GROUP BY t.min_class
ORDER BY t.min_class;

-- 반마다 인원 수
SELECT school_id, class, COUNT(*)
FROM user_properties
GROUP BY school_id, class
ORDER BY school_id, class;


WITH null_users AS (
    SELECT user_id AS id
    FROM user_properties AS p
    LEFT JOIN accounts_school AS s ON p.school_id = s.id
    WHERE address IS NULL
)
SELECT *, JSON_LENGTH(friend_id_list) AS friends_counts
FROM accounts_user
JOIN null_users USING(id)
ORDER BY point DESC;

SELECT *
FROM hackle_events
WHERE heart_balance >= 880000000;



WITH null_users AS (
    SELECT user_id
    FROM user_properties AS p
    LEFT JOIN accounts_school AS s ON p.school_id = s.id
    WHERE address IS NULL
)
SELECT *
FROM accounts_userquestionrecord
JOIN null_users USING(user_id);

SELECT *
FROM accounts_userquestionrecord
WHERE user_id = 833041;


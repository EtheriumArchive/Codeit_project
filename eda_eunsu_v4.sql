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
    SELECT DISTINCT session_id
    FROM hackle_events
    WHERE event_key = 'complete_signup'
),
question_users AS (
    SELECT COUNT(DISTINCT session_id)
    FROM hackle_events
    JOIN sign_users USING(session_id)
    WHERE event_key = 'complete_question'
)
SELECT COUNT(DISTINCT session_id)
FROM hackle_events
JOIN sign_users USING(session_id)
WHERE event_key = 'complete_question';
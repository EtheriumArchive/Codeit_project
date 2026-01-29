-- Active: 1769570532716@@localhost@3313@final_analytics

----------------- accounts_timelinereport -----------------
-- 신고기록 테이블
SELECT * FROM accounts_timelinereport;

-- null 확인 (없음)
SELECT * 
FROM accounts_timelinereport
WHERE id = '' OR reason = '' OR reported_user_id = '' OR 
      user_id = '' OR user_question_record_id = '';

-- 누가 제일 많이 신고당했는가?
SELECT reported_user_id, COUNT(*) AS counts
FROM accounts_timelinereport
GROUP BY reported_user_id
ORDER BY counts DESC;

-- 신고 많이된 사유는 무엇인가?
SELECT reason, COUNT(*) AS counts
FROM accounts_timelinereport
GROUP BY reason
ORDER BY counts DESC;

-- 어느 투표에서 제일 많이 신고를 먹었는가?
SELECT user_question_record_id, COUNT(*) AS counts
FROM accounts_timelinereport
GROUP BY user_question_record_id
ORDER BY counts DESC;

-- 신고가 일어난 시간대
WITH convert_to_date AS (
    SELECT TIME_FORMAT(created_at, '%H') AS created_at, reason
    FROM accounts_timelinereport
)
SELECT created_at, COUNT(*) AS counts
FROM convert_to_date
GROUP BY created_at
ORDER BY created_at;

-- 신고 많이 당한 유저의 해당 질문과 사유
WITH who_is_best AS (
    SELECT reported_user_id, COUNT(*) AS counts
    FROM accounts_timelinereport
    GROUP BY reported_user_id
    HAVING counts >= 4
)
SELECT t.created_at, b.reported_user_id, question_text, reason
FROM who_is_best AS b
LEFT JOIN accounts_timelinereport AS t ON b.reported_user_id = t.reported_user_id
LEFT JOIN accounts_userquestionrecord AS u ON t.user_question_record_id = u.id
LEFT JOIN polls_question AS q ON u.question_id = q.id
ORDER BY counts DESC;






----------------- accounts_user -----------------
-- 유저 테이블
SELECT * FROM accounts_user;

-- superuser가 뭐지? staff는 관리자?
SELECT *
FROM accounts_user
WHERE is_superuser = 1 OR is_staff = 1;

SELECT * 
FROM accounts_group AS g
LEFT JOIN accounts_school AS s ON g.school_id = s.id
WHERE g.id = 122;

SELECT * FROM accounts_group;

-- 여자 남자 비율
SELECT 
    gender, 
    COUNT(*) AS counts, 
    COUNT(*) / (SELECT COUNT(*) FROM accounts_user) * 100 AS rate
FROM accounts_user
WHERE gender <> '(NULL)'
GROUP BY gender
ORDER BY counts DESC;

-- 친구 수
SELECT id, is_superuser, is_staff, gender, point, 
    (CHAR_LENGTH(friend_id_list)- CHAR_LENGTH(REPLACE(friend_id_list, ',', '')) + 1) AS friend_counts
FROM accounts_user
WHERE is_superuser = 1 OR is_staff = 1;

SELECT id,
    (CHAR_LENGTH(friend_id_list)- CHAR_LENGTH(REPLACE(friend_id_list, ',', '')) + 1) AS friend_counts
FROM accounts_user
ORDER BY friend_counts DESC
LIMIT 10;

-- is_push_on 비율
SELECT 
    CASE 
        WHEN is_push_on = 0 THEN '알람 설정 X'
        ELSE '알람 설정 0'
    END AS is_push_on, 
    COUNT(*) AS counts, 
    COUNT(*) / (SELECT COUNT(*) FROM accounts_user) * 100 AS rate
FROM accounts_user
GROUP BY is_push_on;

-- 차단한 유저가 있는 사람은?
SELECT id,
    (CHAR_LENGTH(block_user_id_list)- CHAR_LENGTH(REPLACE(block_user_id_list, ',', '')) + 1) AS block_user_counts
FROM accounts_user
ORDER BY block_user_counts DESC;

-- 차단되거나 탈퇴한 유저인지?
-- N, NB, W, RB 이게 뭐지?
-- 70764명이 탈퇴함
SELECT *
FROM accounts_user
WHERE id = 1380465;

SELECT *
FROM accounts_user
WHERE ban_status = 'RB';

SELECT block_user_id, COUNT(*) AS counts
FROM accounts_blockrecord
GROUP BY block_user_id
ORDER BY counts DESC;

-- 평균적으로 신고를 많이 당한 학급
WITH avg_count AS (
    SELECT group_id AS id, AVG(report_count) AS avg_report_count
    FROM accounts_user
    GROUP BY group_id
)
SELECT school_id, address, 
        CASE 
            WHEN school_type = 'M' THEN '중학교'
            WHEN school_type = 'H' THEN '고등학교'
            ELSE school_type
        END AS school_type, 
        grade, class_num, avg_report_count
FROM avg_count
LEFT JOIN accounts_group AS g USING(id)
LEFT JOIN accounts_school AS s ON g.school_id = s.id
ORDER BY avg_report_count DESC;

SELECT * FROM accounts_school;

-- 알람 갯수가 많은 사람은?
-- 안 읽은 채팅 수가 많은 사람은?
-- 확인 안한 투표 개수가 많은 사람은?
-- 위 세개에 해당하는 사람은 인싸로 볼 수 있을 듯 / 아님 유령 유저?
-- 그저 요주의 인물 3명이 나옴 -> 제일 신고 많이 당하고 유령유저 인 척하는 애들
-- 831962, 838541, 834358
SELECT *
FROM accounts_user
ORDER BY alarm_count DESC;

SELECT *
FROM accounts_user
ORDER BY pending_chat DESC;

SELECT *
FROM accounts_user
ORDER BY report_count DESC;


-- 어느 지역이 제일 많이 가입했는가?
SELECT address, COUNT(*) AS counts
FROM accounts_user AS u
LEFT JOIN accounts_group AS g ON u.group_id = g.id
LEFT JOIN accounts_school AS s ON g.school_id = s.id
GROUP BY address 
ORDER BY counts DESC;

-- 도 순위
WITH merge_all AS (
    SELECT SUBSTRING_INDEX(address, ' ', 1) AS address
    FROM accounts_user AS u
    LEFT JOIN accounts_group AS g ON u.group_id = g.id
    LEFT JOIN accounts_school AS s ON g.school_id = s.id
), change_name AS (
    SELECT 
        CASE
            WHEN address LIKE '%서울%' THEN '서울'
            WHEN address LIKE '%경기%' THEN '경기도'
            WHEN address LIKE '%인천%' THEN '인천'
            WHEN address LIKE '%부산%' THEN '부산'
            WHEN address LIKE '%대구%' THEN '대구'
            WHEN address LIKE '%광주%' THEN '광주'
            WHEN address LIKE '%대전%' THEN '대전'
            WHEN address LIKE '%울산%' THEN '울산'

            WHEN address LIKE '%경상북도%' OR address LIKE '%경북%' THEN '경상북도'
            WHEN address LIKE '%경상남도%' OR address LIKE '%경남%' THEN '경상남도'
            WHEN address LIKE '%충청북도%' OR address LIKE '%충북%' THEN '충청북도'
            WHEN address LIKE '%충청남도%' OR address LIKE '%충남%' THEN '충청남도'
            WHEN address LIKE '%전라북도%' OR address LIKE '%전북%' THEN '전라북도'
            WHEN address LIKE '%전라남도%' OR address LIKE '%전남%' THEN '전라남도'

            WHEN address LIKE '%강원%' THEN '강원도'
            WHEN address LIKE '%제주%' THEN '제주특별자치도'

            ELSE '기타'
        END AS address
    FROM merge_all
)
SELECT address, COUNT(*) AS counts
FROM change_name
GROUP BY address 
ORDER BY counts DESC;

-- 중학교/고등학교 중 어디가 더 많이 가입했는가
SELECT 
    CASE
        WHEN s.school_type = 'M' THEN '중학교'
        WHEN s.school_type = 'H' THEN '고등학교'
        ELSE s.school_type
    END AS school_type, 
    g.grade, 
    COUNT(*) AS counts
FROM accounts_user AS u
LEFT JOIN accounts_group AS g ON u.group_id = g.id
LEFT JOIN accounts_school AS s ON g.school_id = s.id
WHERE school_type <> '(NULL)'
GROUP BY school_type, g.grade
ORDER BY counts DESC;





----------------- accounts_userquestionrecord -----------------
-- 투표 기록 테이블
DESCRIBE accounts_userquestionrecord;
SELECT * FROM accounts_userquestionrecord;
SELECT * FROM accounts_userquestionrecord WHERE created_at IS NULL;

-- 질문 중복값 있는 지 확인 -> 없음
SELECT question_piece_id, COUNT(*)
FROM accounts_userquestionrecord
GROUP BY question_piece_id
ORDER BY COUNT(*) DESC;

-- 답변 상태 비교
SELECT answer_status, COUNT(*)
FROM accounts_userquestionrecord
GROUP BY answer_status
ORDER BY COUNT(*) DESC;

-- 답변 A, P -> Y로 통일 후 비율 비교
WITH change_status AS (
    SELECT 
        CASE
            WHEN answer_status = 'A' THEN 'Y' 
            WHEN answer_status = 'P' THEN 'Y' 
            ELSE answer_status
        END AS answer_status
    FROM accounts_userquestionrecord
)
SELECT 
    answer_status,
    COUNT(*) AS counts,
    COUNT(*) / (SELECT COUNT(*) FROM accounts_userquestionrecord) * 100 AS rate
FROM change_status
GROUP BY answer_status
ORDER BY counts DESC;

-- 어느 질문을 제일 많이 물어봤는지?
SELECT question_text, COUNT(*) AS counts
FROM accounts_userquestionrecord AS a
LEFT JOIN polls_question AS q ON a.question_id = q.id
GROUP BY question_text
ORDER BY counts DESC;

-- 읽었는데 답변 안한 비율?
WITH change_status AS (
    SELECT *,
        CASE
            WHEN answer_status = 'A' THEN 'Y' 
            WHEN answer_status = 'P' THEN 'Y' 
            ELSE answer_status
        END AS changed_answer_status
    FROM accounts_userquestionrecord
), 
read_rate AS (
    SELECT 
        has_read,
        changed_answer_status,
        COUNT(*) AS counts,
        COUNT(*) / (SELECT COUNT(*) FROM accounts_userquestionrecord WHERE has_read = 1) * 100 AS rate
    FROM change_status
    WHERE has_read = 1
    GROUP BY changed_answer_status
),
no_read_rate AS (
    SELECT 
        has_read,
        changed_answer_status,
        COUNT(*) AS counts,
        COUNT(*) / (SELECT COUNT(*) FROM accounts_userquestionrecord WHERE has_read = 0) * 100 AS rate
    FROM change_status
    WHERE has_read = 0
    GROUP BY changed_answer_status
)
SELECT * FROM read_rate
UNION ALL 
SELECT * FROM no_read_rate;

-- 신고 횟수 확인
SELECT *
FROM accounts_userquestionrecord
WHERE report_count >= 3;

-- 신고를 제일 많이 받은 질문은 이유가 뭐였을까
SELECT u.id, t.created_at, q.question_text, 
        u.user_id AS '선택한 유저', u.chosen_user_id AS '선택받은 유저', 
        t.user_id AS '신고한 유저', u.report_count, t.reason, u.answer_status, u.status
FROM accounts_userquestionrecord AS u
LEFT JOIN accounts_timelinereport AS t ON u.id = t.user_question_record_id
LEFT JOIN polls_question AS q ON u.question_id = q.id
WHERE report_count >= 3

-- 답변을 공개할 수록 신고를 많이 받는 편인가?
SELECT 
    CASE
        WHEN answer_status = 'A' THEN '답변 공개' 
        WHEN answer_status = 'P' THEN '답변 비공개' 
        ELSE '미답변'
    END AS answer_status, 
    AVG(report_count) AS avg_report_count
FROM accounts_userquestionrecord
GROUP BY answer_status
ORDER BY avg_report_count DESC;

-- 이니셜이 공개되면 신고를 많이 받는 편인가?
SELECT 
    CASE
        WHEN status = 'I' THEN '초성 공개' 
        WHEN status = 'B' THEN '차단' 
        ELSE '닫힘'
    END AS status, 
    AVG(report_count) AS avg_report_count
FROM accounts_userquestionrecord
GROUP BY status
ORDER BY avg_report_count DESC;

-- 답변 완료한 시간대
WITH convert_to_date AS (
    SELECT TIME_FORMAT(answer_updated_at, '%H') AS answer_updated_at, answer_status
    FROM accounts_userquestionrecord
)
SELECT answer_updated_at, COUNT(*) AS counts
FROM convert_to_date
WHERE answer_status <> 'N'
GROUP BY answer_updated_at
ORDER BY answer_updated_at;

-- 어느 성별이 더 활발하게 답변 잘 해주는가?




----------------- accounts_userwithdraw -----------------
-- 탈퇴 기록 테이블
SELECT * FROM accounts_userwithdraw;

SELECT DISTINCT reason FROM accounts_userwithdraw;

-- 탈퇴 이유 순위
SELECT reason, COUNT(*) AS counts 
FROM accounts_userwithdraw
GROUP BY reason
ORDER BY counts DESC;

-- 2023-05-28 15:07:43
SELECT * FROM accounts_userwithdraw WHERE reason = 'admin';





----------------- event_receipts -----------------
-- 포인트 이벤트 참여 테이블
SELECT * FROM event_receipts;

----------------- events -----------------
-- 포인트 이벤트 참여 테이블
SELECT * FROM events;

-- 위 두개 테이블 merge -> 어느 이벤트를 가장 많이 참여했는지 확인
-- 유저 별 이벤트 참여한 횟수를 봐도 좋을 듯
WITH merge_all AS (
    SELECT r.id, r.created_at, r.user_id, r.event_id, e.title, r.plus_point
    FROM event_receipts AS r
    LEFT JOIN events AS e ON r.event_id = e.id
)
SELECT title, MAX(plus_point) AS plus_point, COUNT(*) AS counts
FROM merge_all
GROUP BY title
ORDER BY counts DESC;





----------------- polls_question -----------------
-- 질문 내용 테이블
SELECT * FROM polls_question;

----------------- polls_questionpiece -----------------
-- 질문 테이블
SELECT * FROM polls_questionpiece;

-- 가장 많이 스킵된 질문
SELECT question_text, COUNT(*) AS counts
FROM polls_questionpiece AS qp
LEFT JOIN polls_question AS q ON qp.question_id = q.id
WHERE is_skipped = 1
GROUP BY question_text
ORDER BY counts DESC;

SELECT question_text, COUNT(*) AS counts
FROM polls_questionpiece AS qp
LEFT JOIN polls_question AS q ON qp.question_id = q.id
WHERE is_voted = 0
GROUP BY question_text
ORDER BY counts DESC;







----------------- polls_questionreport -----------------
-- 질문에 대한 신고 기록 테이블
SELECT * FROM polls_questionreport;

SELECT DISTINCT reason FROM polls_questionreport;

SELECT question_text, COUNT(*) AS counts
FROM polls_questionreport AS pq
LEFT JOIN polls_question AS q ON pq.question_id = q.id
WHERE reason LIKE '어떻게 이런%'
GROUP BY question_text
ORDER BY counts DESC;


SELECT question_text, COUNT(*) AS counts
FROM polls_questionreport AS pq
LEFT JOIN polls_question AS q ON pq.question_id = q.id
WHERE reason LIKE '%불쾌%'
GROUP BY question_text
ORDER BY counts DESC;

SELECT question_text, COUNT(*) AS counts
FROM polls_questionreport AS pq
LEFT JOIN polls_question AS q ON pq.question_id = q.id
WHERE reason LIKE '그냥%'
GROUP BY question_text
ORDER BY counts DESC;


SELECT reason, COUNT(*) AS counts
FROM polls_questionreport
GROUP BY reason
ORDER BY counts DESC;




----------------- polls_questionset -----------------
-- 질문 세트 데이블 
SELECT * FROM polls_questionset;

SELECT * FROM polls_questionset WHERE status = 'C';

-- 질문 세트 개수 10개가 맞음
SELECT *, (CHAR_LENGTH(question_piece_id_list) - CHAR_LENGTH(REPLACE(question_piece_id_list, ',', '')) + 1) AS question_counts
FROM polls_questionset;

-- seconds_diff에서 음수 개수 확인
WITH add_diff AS (
    SELECT *, TIMESTAMPDIFF(SECOND, created_at, opening_time) AS seconds_diff
    FROM polls_questionset
)
SELECT status, COUNT(*) AS minus_counts
FROM add_diff
WHERE seconds_diff < 0
GROUP BY status;

-- 각 status마다 걸린 기간 확인
WITH add_diff AS (
    SELECT *, TIMESTAMPDIFF(SECOND, created_at, opening_time) AS seconds_diff
    FROM polls_questionset
)
SELECT 
    status, 
    ROUND(AVG(seconds_diff)/60, 2) AS avg_minutes_diff, 
    ROUND(MIN(seconds_diff)/60, 2) AS min_minutes_diff,
    ROUND(MAX(seconds_diff)/60, 2) AS max_minutes_diff
FROM add_diff
WHERE seconds_diff >= 0
GROUP BY status;






----------------- polls_usercandidate -----------------
-- 질문에 등장하는 유저들 테이블
SELECT * FROM polls_usercandidate;

-- 한 질문 당 최대 몇 개씩 등장하나
WITH distinct_users AS (
    SELECT question_piece_id, user_id, COUNT(*) AS counts
    FROM polls_usercandidate
    GROUP BY question_piece_id, user_id
)
SELECT question_piece_id, COUNT(*) AS counts
FROM distinct_users
GROUP BY question_piece_id
ORDER BY counts DESC;


SELECT * FROM polls_usercandidate WHERE question_piece_id = 28856618
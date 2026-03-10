-- Active: 1769570532716@@localhost@3313@final_analytics


SELECT * FROM accounts_blockrecord;

-- 무슨 사유로 제일 많이 차단당했나?
SELECT reason, COUNT(*)
FROM accounts_blockrecord
GROUP BY reason;

-- 차단 많이 당한 사람 TOP10
SELECT block_user_id, COUNT(*) AS counts
FROM accounts_blockrecord
GROUP BY block_user_id
ORDER BY counts DESC
LIMIT 10;

-- 차단된 유저 TOP 5의 사유
WITH block_users AS (
    SELECT block_user_id, COUNT(*) AS counts
    FROM accounts_blockrecord
    GROUP BY block_user_id
    ORDER BY counts DESC
    LIMIT 5
)
SELECT bu.block_user_id, ab.reason, COUNT(*)
FROM block_users AS bu
LEFT JOIN accounts_blockrecord AS ab ON bu.block_user_id = ab.block_user_id
GROUP BY bu.block_user_id, ab.reason
ORDER BY bu.block_user_id, COUNT(*) DESC;

-- 모르는 사유만 있는 유저 확인 877266
SELECT *
FROM accounts_blockrecord
WHERE block_user_id = 877266;

-- 877266 대상으로 유저 별 신고 횟수
SELECT block_user_id, user_id, COUNT(*)
FROM accounts_blockrecord
WHERE block_user_id = 877266
GROUP BY block_user_id, user_id;

-- 여자, 포인트:9019, 그룹 아이디:78209, ban_status=N, 신고당한 횟수:0, 친구수:777
SELECT *,
    CHAR_LENGTH(friend_id_list) - CHAR_LENGTH(REPLACE(friend_id_list, ',', '')) AS friends
FROM accounts_user
WHERE id = 877266;

SELECT status, COUNT(*) 
FROM accounts_friendrequest
WHERE send_user_id = 877266
GROUP BY status;

-- 한 사람에게 보낸 친구요청 수
SELECT receive_user_id, COUNT(*)
FROM accounts_friendrequest
WHERE send_user_id = 877266
GROUP BY receive_user_id
ORDER BY COUNT(*) DESC;


SELECT * 
FROM accounts_blockrecord 
WHERE block_user_id = 877266;

-- 신고한 유저들에게 평균적으로 몇 번 친구요청 보냈는지
WITH how_many_time AS (
    SELECT receive_user_id, COUNT(*) AS counts
    FROM accounts_friendrequest
    WHERE send_user_id = 877266
    GROUP BY receive_user_id
    ORDER BY COUNT(*) DESC
)
SELECT AVG(counts)
FROM accounts_blockrecord AS b
LEFT JOIN how_many_time AS h ON b.user_id = h.receive_user_id
WHERE block_user_id = 877266;

WITH how_many_time AS (
    SELECT receive_user_id, COUNT(*) AS counts
    FROM accounts_friendrequest
    WHERE send_user_id = 898020
    GROUP BY receive_user_id
    ORDER BY COUNT(*) DESC
)
SELECT AVG(counts)
FROM accounts_blockrecord AS b
LEFT JOIN how_many_time AS h ON b.user_id = h.receive_user_id
WHERE block_user_id = 898020 AND reason LIKE '모르는%';


-- 전체적으로 친구요청을 평균적으로 몇 번 하면 신고받는지?
WITH all_counts AS (
    SELECT b.block_user_id, b.user_id, COUNT(*) AS counts
    FROM accounts_blockrecord AS b
    LEFT JOIN accounts_friendrequest AS h 
    ON b.user_id = h.receive_user_id AND 
        b.block_user_id = h.send_user_id
    WHERE reason LIKE '모르는%' AND status IS NOT NULL
    GROUP BY b.block_user_id, b.user_id
    ORDER BY b.block_user_id, counts DESC
)
SELECT AVG(counts)
FROM all_counts;

-- 왜 null이 있지? -> 친구 요청도 안보냈는데 왜 차단했을까 >> 모르겠음
SELECT *
FROM accounts_blockrecord AS b
LEFT JOIN accounts_friendrequest AS h 
ON b.user_id = h.receive_user_id AND 
    b.block_user_id = h.send_user_id
WHERE reason LIKE '모르는%' AND status IS NULL;

-- 차단 안 당한 유저는 몇 번 친구 요청을 보내나? 
WITH no_ban AS (
    SELECT h.id
    FROM accounts_blockrecord AS b
    LEFT JOIN accounts_friendrequest AS h 
    ON b.user_id = h.receive_user_id AND 
        b.block_user_id = h.send_user_id
    WHERE reason LIKE '모르는%'
), 
all_counts AS (
    SELECT send_user_id, receive_user_id, COUNT(*) AS counts
    FROM accounts_friendrequest
    LEFT JOIN no_ban USING(id)
    GROUP BY send_user_id, receive_user_id
)
SELECT AVG(counts)
FROM all_counts;




-- 데이터 기간 확인 -> 다른 기록들은 만들어진 날 등록됨 -> 출석 기록이 제일 최신일듯
SELECT
    MIN(j.date_val) AS min_date,
    MAX(j.date_val) AS max_date
FROM accounts_attendance t
JOIN JSON_TABLE(
    t.attendance_date_list,
    '$[*]' COLUMNS (
        date_val DATE PATH '$'
    )
) j;
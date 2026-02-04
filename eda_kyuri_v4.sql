-- Active: 1769575924621@@localhost@3313@final_analytics

# account_attendance

# 생김새
SELECT *
FROM accounts_attendance
LIMIT 5
# attendance_date_list 어떻게 확인하지

# 결측치, 빈값
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS null_id,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN attendance_date_list IS NULL THEN 1 ELSE 0 END) AS null_attendance_list,
  SUM(CASE WHEN attendance_date_list = '' THEN 1 ELSE 0 END) AS empty_string_attendance_list,
  SUM(CASE WHEN TRIM(attendance_date_list) = '' THEN 1 ELSE 0 END) AS blank_attendance_list
FROM accounts_attendance;


# user_id 중복 확인
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT user_id) AS distinct_users,
  COUNT(*) - COUNT(DISTINCT user_id) AS duplicated_rows_est
FROM accounts_attendance
WHERE user_id IS NOT NULL;

# id 중복 확인
SELECT id, COUNT(*) AS cnt
FROM accounts_attendance
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 50;

# user_id 음수 혹은 0인 경우
SELECT
  SUM(CASE WHEN user_id <= 0 THEN 1 ELSE 0 END) AS non_positive_user_id
FROM accounts_attendance
WHERE user_id IS NOT NULL;

# id도 확인
SELECT
  SUM(CASE WHEN id <= 0 THEN 1 ELSE 0 END) AS non_positive_id
FROM accounts_attendance;

# attendance_date_list 길이가 너무 짧거나 너무 길거나
# 공백은 제외
SELECT
  CASE
    WHEN attendance_date_list IS NULL OR TRIM(attendance_date_list) = '' THEN 'NULL/BLANK'
    WHEN LENGTH(attendance_date_list) < 5 THEN '<5'
    WHEN LENGTH(attendance_date_list) < 20 THEN '5-19'
    WHEN LENGTH(attendance_date_list) < 100 THEN '20-99'
    WHEN LENGTH(attendance_date_list) < 500 THEN '100-499'
    ELSE '500+'
  END AS len_bucket,
  COUNT(*) AS cnt
FROM accounts_attendance
GROUP BY len_bucket
ORDER BY cnt DESC;

# 리스트 안에 아무것도 없는 경우가 많은가?
# 하이픈이 있는가
SELECT id, user_id, attendance_date_list
FROM accounts_attendance
WHERE attendance_date_list IS NOT NULL
  AND TRIM(attendance_date_list) <> ''
  AND attendance_date_list NOT LIKE '%-%'
LIMIT 50;


# 박스플롯
# gpt
WITH base AS (
  SELECT
    user_id,
    CASE
      WHEN attendance_date_list IS NULL OR TRIM(attendance_date_list) = '' THEN 0
      ELSE JSON_LENGTH(attendance_date_list)
    END AS attendance_cnt
  FROM accounts_attendance
),
ranked AS (
  SELECT
    attendance_cnt,
    ROW_NUMBER() OVER (ORDER BY attendance_cnt) AS rn,
    COUNT(*) OVER () AS n
  FROM base
)
SELECT
  MAX(CASE WHEN rn = FLOOR(0.25*(n+1)) THEN attendance_cnt END) AS q1,
  MAX(CASE WHEN rn = FLOOR(0.75*(n+1)) THEN attendance_cnt END) AS q3
FROM ranked;
# 5명밖에 안나옴

# 다시 공백 몇명인지 확인
SELECT
  id, user_id, attendance_date_list
FROM accounts_attendance
WHERE attendance_date_list IS NULL OR TRIM(attendance_date_list) = '';
# ? 아 출석이 없으면 공백이 아니라 [] 이렇게 뜨는구나

# 완전 공백, 출석 없음, 값 있음
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN attendance_date_list IS NULL THEN 1 ELSE 0 END) AS null_cnt,
  SUM(CASE WHEN TRIM(attendance_date_list) = '[]' THEN 1 ELSE 0 END) AS empty_array_cnt,
  SUM(CASE
        WHEN attendance_date_list IS NOT NULL
         AND TRIM(attendance_date_list) <> '[]'
        THEN 1 ELSE 0
      END) AS non_empty_array_cnt
FROM accounts_attendance;


# user_id 기준으로 attendance cnt 조회
# 근데 user_id 중복이 있지 않을까...
# 이 테이블에서 유저 아이디는 식별자가 아니어서
SELECT
  attendance_cnt,
  COUNT(DISTINCT user_id) AS user_cnt
FROM (
  SELECT
    user_id,
    CASE
      WHEN attendance_date_list IS NULL THEN NULL
      WHEN TRIM(attendance_date_list) = '[]' THEN 0
      ELSE JSON_LENGTH(attendance_date_list)
    END AS attendance_cnt
  FROM accounts_attendance
) t
GROUP BY attendance_cnt
ORDER BY attendance_cnt;



# 만약 유저아이디가 중복일 수 있으니까, keep=last 조건을 걸었는데
# 이건 gpt 사용 그러나 ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY id DESC) AS rn
# 이 줄을 정확하게 활용하는 방법은 모르겠음
WITH latest AS (
  SELECT
    user_id,
    attendance_date_list,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY id DESC) AS rn
  FROM accounts_attendance
  WHERE user_id IS NOT NULL
)
SELECT
  attendance_cnt,
  COUNT(*) AS user_cnt
FROM (
  SELECT
    user_id,
    CASE
      WHEN attendance_date_list IS NULL THEN NULL
      WHEN TRIM(attendance_date_list) = '[]' THEN 0
      ELSE JSON_LENGTH(attendance_date_list)
    END AS attendance_cnt
  FROM latest
  WHERE rn = 1
) t
GROUP BY attendance_cnt
ORDER BY attendance_cnt;


# 차라리 user_id로 그룹을 묶고, 2개 이상인 user_id를 확인(user_id 중복을 확인)
SELECT COUNT(user_id) as user_cnt
FROM accounts_attendance
GROUP BY user_id
HAVING user_cnt > 1
# 122번 쿼리 신뢰도 확보



WITH latest AS (
  SELECT
    user_id,
    attendance_date_list,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY id DESC) AS rn
  FROM accounts_attendance
  WHERE user_id IS NOT NULL
),
base AS (
  SELECT
    user_id,
    CASE
      WHEN attendance_date_list IS NULL THEN NULL
      WHEN TRIM(attendance_date_list) = '[]' THEN 0
      ELSE JSON_LENGTH(attendance_date_list)
    END AS attendance_cnt
  FROM latest
  WHERE rn = 1
),
ordered AS (
  SELECT
    attendance_cnt,
    ROW_NUMBER() OVER (ORDER BY attendance_cnt) AS rnum,
    COUNT(*) OVER () AS n
  FROM base
  WHERE attendance_cnt IS NOT NULL
)
SELECT
  MAX(CASE WHEN rnum = FLOOR(0.25 * (n + 1)) THEN attendance_cnt END) AS q1,
  MAX(CASE WHEN rnum = FLOOR(0.50 * (n + 1)) THEN attendance_cnt END) AS q2,
  MAX(CASE WHEN rnum = FLOOR(0.75 * (n + 1)) THEN attendance_cnt END) AS q3
FROM ordered;


# latest: 유저 중복 제거 (keep=last 옵션은 ROW_NUMBER 이용)
# base: attendance_cnt 만들기, 빈 리스트는 0으로 설정
# ordered: attendance_cnt를 정렬(q1, q2, q3을 찾으려면 필요)
# quartiles: q1, q2, q3값 뽑기
# SELECT: 구간별 유저 수 세기
WITH latest AS (
  SELECT
    user_id,
    attendance_date_list,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY id DESC) AS rn
  FROM accounts_attendance
  WHERE user_id IS NOT NULL
),
base AS (
  SELECT
    user_id,
    CASE
      WHEN attendance_date_list IS NULL THEN NULL
      WHEN TRIM(attendance_date_list) = '[]' THEN 0
      ELSE JSON_LENGTH(attendance_date_list)
    END AS attendance_cnt
  FROM latest
  WHERE rn = 1
),
ordered AS (
  SELECT
    attendance_cnt,
    ROW_NUMBER() OVER (ORDER BY attendance_cnt) AS rnum,
    COUNT(*) OVER () AS n
  FROM base
  WHERE attendance_cnt IS NOT NULL
),
quartiles AS (
  SELECT
    MAX(CASE WHEN rnum = FLOOR(0.25 * (n + 1)) THEN attendance_cnt END) AS q1,
    MAX(CASE WHEN rnum = FLOOR(0.50 * (n + 1)) THEN attendance_cnt END) AS q2,
    MAX(CASE WHEN rnum = FLOOR(0.75 * (n + 1)) THEN attendance_cnt END) AS q3
  FROM ordered
)
SELECT
  MAX(q.q1) AS q1,
  MAX(q.q2) AS q2,
  MAX(q.q3) AS q3,
  SUM(CASE WHEN b.attendance_cnt <= q.q1 THEN 1 ELSE 0 END) AS users_le_q1,
  SUM(CASE WHEN b.attendance_cnt >  q.q1 AND b.attendance_cnt <= q.q2 THEN 1 ELSE 0 END) AS users_q1_to_q2,
  SUM(CASE WHEN b.attendance_cnt >  q.q2 AND b.attendance_cnt <= q.q3 THEN 1 ELSE 0 END) AS users_q2_to_q3,
  SUM(CASE WHEN b.attendance_cnt >  q.q3 THEN 1 ELSE 0 END) AS users_gt_q3,
  COUNT(*) AS total_users
FROM base b
CROSS JOIN quartiles q
WHERE b.attendance_cnt IS NOT NULL;

# iqr, upper fence까지 계산
WITH latest AS (
  SELECT
    user_id,
    attendance_date_list,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY id DESC) AS rn
  FROM accounts_attendance
  WHERE user_id IS NOT NULL
),
base AS (
  SELECT
    user_id,
    CASE
      WHEN attendance_date_list IS NULL THEN NULL
      WHEN TRIM(attendance_date_list) = '[]' THEN 0
      ELSE JSON_LENGTH(attendance_date_list)
    END AS attendance_cnt
  FROM latest
  WHERE rn = 1
),
ordered AS (
  SELECT
    attendance_cnt,
    ROW_NUMBER() OVER (ORDER BY attendance_cnt) AS rnum,
    COUNT(*) OVER () AS n
  FROM base
  WHERE attendance_cnt IS NOT NULL
),
quartiles AS (
  SELECT
    MAX(CASE WHEN rnum = FLOOR(0.25 * (n + 1)) THEN attendance_cnt END) AS q1,
    MAX(CASE WHEN rnum = FLOOR(0.50 * (n + 1)) THEN attendance_cnt END) AS q2,
    MAX(CASE WHEN rnum = FLOOR(0.75 * (n + 1)) THEN attendance_cnt END) AS q3
  FROM ordered
)
SELECT
  MAX(q.q1) AS q1,
  MAX(q.q2) AS q2,
  MAX(q.q3) AS q3,
  (MAX(q.q3) - MAX(q.q1)) AS iqr,
  (MAX(q.q3) + 1.5 * (MAX(q.q3) - MAX(q.q1))) AS upper_fence,
  SUM(CASE WHEN b.attendance_cnt <= q.q1 THEN 1 ELSE 0 END) AS users_le_q1,
  SUM(CASE WHEN b.attendance_cnt >  q.q1 AND b.attendance_cnt <= q.q2 THEN 1 ELSE 0 END) AS users_q1_to_q2,
  SUM(CASE WHEN b.attendance_cnt >  q.q2 AND b.attendance_cnt <= q.q3 THEN 1 ELSE 0 END) AS users_q2_to_q3,
  SUM(CASE WHEN b.attendance_cnt >  q.q3 THEN 1 ELSE 0 END) AS users_gt_q3,
  -- 상한(IQR) 기준 이상치 유저 수
  SUM(CASE WHEN b.attendance_cnt > (q.q3 + 1.5 * (q.q3 - q.q1)) THEN 1 ELSE 0 END) AS users_gt_upper_fence,
  COUNT(*) AS total_users
FROM base b
CROSS JOIN quartiles q
WHERE b.attendance_cnt IS NOT NULL;



# accounts_blockrecord

# 생김새
SELECT *
FROM accounts_blockrecord
LIMIT 5;

# 여기도 유저 아이디 중복 있는지 확인
SELECT COUNT(user_id) as user_cnt
FROM accounts_blockrecord
GROUP BY user_id
HAVING user_cnt > 1
# 여긴 유저 아이디 중복이 많음
# 아마 한명이 여러번 신고를 한 것으로 예상

# 결측치 확인
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN block_user_id IS NULL THEN 1 ELSE 0 END) AS null_block_user_id,
  SUM(CASE WHEN reason IS NULL THEN 1 ELSE 0 END) AS null_reason,
  SUM(CASE WHEN TRIM(reason) = '' THEN 1 ELSE 0 END) AS blank_reason,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at
FROM accounts_blockrecord;


# id 중복, 비정상 값
SELECT
  id,
  COUNT(*) AS cnt
FROM accounts_blockrecord
GROUP BY id
HAVING cnt > 1;

SELECT
  COUNT(*) AS non_positive_id_cnt
FROM accounts_blockrecord
WHERE id <= 0;
# 둘 다 없음 pk지만 계속 확인

# 셀프 차단
SELECT COUNT(*) AS self_block_cnt
FROM accounts_blockrecord
WHERE user_id = block_user_id;
# ??? 이게 있다고??? 진짜 어이가 없네

# 같은 유저가 같은 상대를 여러 번 차단했는지
SELECT user_id, block_user_id, COUNT(*) AS block_cnt
FROM accounts_blockrecord
GROUP BY user_id, block_user_id
HAVING block_cnt > 1
ORDER BY block_cnt DESC
# 특이사항 없음
# 가장 많이 차단한게 20번이라는 것 정도?

# reason 분포 확인
SELECT reason, COUNT(*) AS cnt
FROM accounts_blockrecord
GROUP BY reason
ORDER BY cnt DESC;
# 이건 선택형이었을 것으로 예상

# 시간 확인용
# 지금보다 나중 시점
SELECT COUNT(*) AS future_created_at_cnt
FROM accounts_blockrecord
WHERE created_at > NOW()
# 없음

# 날짜 분포 확인
SELECT
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at
FROM accounts_blockrecord;
# 딱히 이상은 없음

# 총 차단받은 수
SELECT
  block_cnt,
  COUNT(*) AS user_cnt
FROM (
  SELECT
    user_id,
    COUNT(*) AS block_cnt
  FROM accounts_blockrecord
  GROUP BY user_id
) t
GROUP BY block_cnt
ORDER BY block_cnt;
# 유저 1명이 서로 다른 171명을 차단했다

# 유저 아이디 중복 확인
SELECT COUNT(DISTINCT user_id) as user_cnt
FROM accounts_blockrecord
GROUP BY user_id
HAVING user_cnt > 1
# 없음

# 하루에 몇 명의 서로 다른 유저가 차단을 했는지?
SELECT
  DATE(created_at) AS block_date,
  COUNT(DISTINCT user_id) AS blocked_user_cnt
FROM accounts_blockrecord
WHERE created_at IS NOT NULL
GROUP BY block_date
ORDER BY block_date;


# 하루에 차단 로그가 몇 번 발생하는지?
SELECT
  DATE(created_at) AS block_date,
  COUNT(*) AS block_event_cnt
FROM accounts_blockrecord
WHERE created_at IS NOT NULL
GROUP BY block_date
ORDER BY block_date;

# accounts_failpaymenthistory

# 유저 아이디 중복 확인
SELECT COUNT(DISTINCT user_id) as user_cnt
FROM accounts_failpaymenthistory
GROUP BY user_id
HAVING user_cnt > 1
# 없음

# 결측치 확인
SELECT
  COUNT(*) AS total_rows,
  SUM(user_id IS NULL) AS null_user_id,
  SUM(productId IS NULL) AS null_productId,
  SUM(phone_type IS NULL) AS null_phone_type,
  SUM(created_at IS NULL) AS null_created_at
FROM accounts_failpaymenthistory;
# productId 결측치 107건

# productId 결측치 확인
SELECT *
FROM accounts_failpaymenthistory
WHERE productId IS NULL

SELECT * FROM accounts_failpaymenthistory LIMIT 10

# phone type 값 체크
SELECT phone_type, COUNT(*) AS cnt
FROM accounts_failpaymenthistory
GROUP BY phone_type
ORDER BY cnt DESC;

# created_at
SELECT
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at
FROM accounts_failpaymenthistory;

# 유저별 결제 실패 횟수 분포
SELECT fail_cnt, COUNT(*) AS user_cnt
FROM (
  SELECT user_id, COUNT(*) AS fail_cnt
  FROM accounts_failpaymenthistory
  GROUP BY user_id
) t
GROUP BY fail_cnt
ORDER BY fail_cnt
# 분포가 생각보다 정상적이네?
# 결제 실패 1번: 157명, 결제 실패 2번: 3명

# 결제 실패한 사람이 총 몇명인지
SELECT
  COUNT(DISTINCT user_id) AS total_failed_users
FROM accounts_failpaymenthistory;
# 160명

# distinct 빼면
SELECT
  COUNT(user_id) AS total_failed_users
FROM accounts_failpaymenthistory;
# 163명
# 숫자는 맞음

# 2번 실패한 유저 로그
SELECT *
FROM accounts_failpaymenthistory
WHERE user_id IN (
    SELECT user_id
    FROM accounts_failpaymenthistory
    GROUP BY user_id
    HAVING COUNT(*) = 2
)

# accounts_friendrequest

SELECT COUNT(DISTINCT send_user_id) as user_cnt
FROM accounts_friendrequest
GROUP BY send_user_id
HAVING user_cnt > 1

# 결측
SELECT
  COUNT(*) AS total_rows,
  SUM(send_user_id IS NULL) AS null_send_user,
  SUM(receive_user_id IS NULL) AS null_receive_user,
  SUM(status IS NULL) AS null_status,
  SUM(created_at IS NULL) AS null_created_at,
  SUM(updated_at IS NULL) AS null_updated_at
FROM accounts_friendrequest;


# status 값 체크
SELECT status, COUNT(*) AS cnt
FROM accounts_friendrequest
GROUP BY status;
# P: 3938608
# A: 12878407
# R: 330160
# 흠 총 몇명이지


# 셀프 친추
SELECT COUNT(*) AS self_request_cnt
FROM accounts_friendrequest
WHERE send_user_id = receive_user_id;

# 같은 사람이 같은 사람에게 여러번 요청?
SELECT send_user_id, receive_user_id, COUNT(*) AS req_cnt
FROM accounts_friendrequest
GROUP BY send_user_id, receive_user_id
HAVING COUNT(*) > 1
ORDER BY req_cnt DESC;
# 파헤칠게 많음!!

# 1분 이내 중복 요청한 건이 있는지
SELECT
  send_user_id,
  receive_user_id,
  COUNT(*) AS cnt,
  MIN(created_at) AS first_time,
  MAX(created_at) AS last_time
FROM accounts_friendrequest
GROUP BY send_user_id, receive_user_id
HAVING TIMESTAMPDIFF(SECOND, MIN(created_at), MAX(created_at)) <= 60
   AND COUNT(*) > 1
# 417건

# 990693
SELECT
  send_user_id,
  receive_user_id,
  COUNT(*) AS cnt,
  MIN(created_at) AS first_time,
  MAX(created_at) AS last_time
FROM accounts_friendrequest
WHERE send_user_id = 990693
GROUP BY send_user_id, receive_user_id
HAVING TIMESTAMPDIFF(SECOND, MIN(created_at), MAX(created_at)) <= 60
   AND COUNT(*) > 1


# 친구요청
SELECT
  status,
  COUNT(*) AS cnt,
  AVG(TIMESTAMPDIFF(MINUTE, created_at, updated_at)) AS avg_response_sec
FROM accounts_friendrequest
WHERE status IN ('A', 'R')
GROUP BY status;
# 친구 수락한 유저는 평균 2433분, 거절한 유저는 평균 5010분 시간이 소요됨


# 친구 중복 요청과 관련해서 더 보기
# 30초 이내 중복 요청?
SELECT
  send_user_id,
  receive_user_id,
  COUNT(*) AS cnt,
  MIN(created_at) AS first_time,
  MAX(created_at) AS last_time
FROM accounts_friendrequest
GROUP BY send_user_id, receive_user_id
HAVING TIMESTAMPDIFF(SECOND, MIN(created_at), MAX(created_at)) <= 30
   AND COUNT(*) > 1


# 친구 요청 후 결과까지 소요시간 다시 확인
SELECT id, send_user_id, receive_user_id, status, created_at, updated_at,
  TIMESTAMPDIFF(SECOND, created_at, updated_at) AS response_sec
FROM accounts_friendrequest
WHERE status IN ('A', 'R')
  AND created_at IS NOT NULL
  AND updated_at IS NOT NULL
  AND updated_at >= created_at;


SELECT
  MIN(response_sec) AS min_sec,
  MAX(response_sec) AS max_sec,
  AVG(response_sec) AS avg_sec
FROM (
  SELECT TIMESTAMPDIFF(SECOND, created_at, updated_at) AS response_sec
  FROM accounts_friendrequest
  WHERE status IN ('A', 'R')
    AND updated_at >= created_at
) t;


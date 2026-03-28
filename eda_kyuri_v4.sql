-- Active: 1769491384549@@localhost@3306@final

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

# 전체 분포 요약
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

# 응답 소요시간 분포
SELECT
  CASE
    WHEN response_sec < 10 THEN '<10s'
    WHEN response_sec < 60 THEN '10s~1m'
    WHEN response_sec < 300 THEN '1~5m'
    WHEN response_sec < 3600 THEN '5m~1h'
    WHEN response_sec < 86400 THEN '1h~1d'
    WHEN response_sec < 604800 THEN '1d~7d'
    ELSE '7d+'
  END AS time_bucket,
  COUNT(*) AS req_cnt
FROM (
  SELECT TIMESTAMPDIFF(SECOND, created_at, updated_at) AS response_sec
  FROM accounts_friendrequest
  WHERE status IN ('A', 'R')
    AND updated_at >= created_at
) t
GROUP BY time_bucket
ORDER BY
  MIN(response_sec);


# 수락/거절별 응답 시간 분포
SELECT
  status,
  CASE
    WHEN response_sec < 60 THEN '<1m'
    WHEN response_sec < 3600 THEN '1m~1h'
    WHEN response_sec < 86400 THEN '1h~1d'
    ELSE '1d+'
  END AS time_bucket,
  COUNT(*) AS cnt
FROM (
  SELECT
    status,
    TIMESTAMPDIFF(SECOND, created_at, updated_at) AS response_sec
  FROM accounts_friendrequest
  WHERE status IN ('A', 'R')
    AND updated_at >= created_at
) t
GROUP BY status, time_bucket
ORDER BY status, cnt DESC;


# 너무 빠른 처리
# 수락/거절/대기와 상관없이 3초 미만
SELECT COUNT(*) AS fast_cnt
FROM accounts_friendrequest
WHERE status IN ('A', 'R') AND TIMESTAMPDIFF(SECOND, created_at, updated_at) < 3
# 1898건

# 너무 느린 처리
# 한달 이상
SELECT COUNT(*) AS slow_cnt
FROM accounts_friendrequest
WHERE status IN ('A', 'R') AND TIMESTAMPDIFF(DAY, created_at, updated_at) >= 30
# 78055명

# 너무 빠른 + 너무 느린 합치기
SELECT send_user_id, receive_user_id, status,
  TIMESTAMPDIFF(SECOND, created_at, updated_at) AS response_sec
FROM accounts_friendrequest
WHERE status IN ('A', 'R')
  AND created_at IS NOT NULL
  AND updated_at IS NOT NULL
  AND updated_at >= created_at
  AND TIMESTAMPDIFF(SECOND, created_at, updated_at) >= 3
  AND TIMESTAMPDIFF(DAY, created_at, updated_at) < 30;


# accounts_group

SELECT COUNT(DISTINCT school_id) as school_cnt
FROM accounts_group
GROUP BY school_id
HAVING school_cnt >1

# 결측
SELECT
  COUNT(*) AS total_rows,
  SUM(grade IS NULL) AS null_grade,
  SUM(class_num IS NULL) AS null_class_num,
  SUM(school_id IS NULL) AS null_school_id
FROM accounts_group;

# 학년 이상치
SELECT grade, COUNT(*) AS cnt
FROM accounts_group
GROUP BY grade
ORDER BY grade;

SELECT *
FROM accounts_group
WHERE grade <= 0 OR grade >= 7;

SELECT *
FROM accounts_group
WHERE school_id = '3867'

SELECT *
FROM accounts_group
WHERE grade = 4

SELECT *
FROM accounts_group
WHERE school_id = 4658


# 반 이상치
SELECT class_num, COUNT(*) AS cnt
FROM accounts_group
GROUP BY class_num
ORDER BY class_num;


# 같은 학교, 학년, 반인 학생
SELECT school_id, grade, class_num, COUNT(*) AS cnt
FROM accounts_group
GROUP BY school_id, grade, class_num
HAVING COUNT(*) > 1;
# 2명씩밖에 겹쳐지지 않음


# accounts_nearbyschool

SELECT COUNT(school_id) as sch_cnt
FROM accounts_nearbyschool
GROUP BY school_id
HAVING sch_cnt >1
# 왜 학교 아이디가 여러개지?

SELECT COUNT(nearby_school_id) as nsi_cnt
FROM accounts_nearbyschool
GROUP BY nearby_school_id
HAVING nearby_school_id >1
# 이것도 여러개

SELECT *
FROM accounts_nearbyschool
ORDER BY school_id
LIMIT 20
# 하나의 학교에 근접 학교 9개씩 연결되어있는 것처럼 보임
# 하나는 학교 본인(?)

# 일단 결측치 먼저
SELECT
  COUNT(*) AS total_rows,
  SUM(school_id IS NULL) AS null_school_id,
  SUM(nearby_school_id IS NULL) AS null_nearby_school_id,
  SUM(distance IS NULL) AS null_distance
FROM accounts_nearbyschool;

# 거리 이상치 확인
SELECT COUNT(*) AS non_positive_distance_cnt
FROM accounts_nearbyschool
WHERE distance = 0
# 거리가 음수 아니면 0인 곳이 6214곳
# 음수는 0곳 (= 거리가 0인 곳이 6214곳)

SELECT COUNT(school_id) as near_cnt
FROM accounts_group
GROUP BY school_id
ORDER BY near_cnt
# 근처 학교가 9개씩 묶여있는줄 알았는데 아닌가..?


# 일단 거리 분포 확인
SELECT
  MIN(distance) AS min_distance,
  MAX(distance) AS max_distance,
  AVG(distance) AS avg_distance
FROM accounts_nearbyschool
WHERE distance IS NOT NULL;

# 거리 분포 확인
# 근데 가 0.5미터일 수는 없으니 km단위로 추청
SELECT
  CASE
    WHEN distance IS NULL THEN 'NULL'
    WHEN distance < 0 THEN '<0'
    WHEN distance = 0 THEN '=0'
    WHEN distance < 0.5 THEN '<0.5'
    WHEN distance < 1 THEN '0.5-1'
    WHEN distance < 2 THEN '1-2'
    WHEN distance < 5 THEN '2-5'
    WHEN distance < 10 THEN '5-10'
    ELSE '10+'
  END AS dist_bucket,
  COUNT(*) AS cnt
FROM accounts_nearbyschool
GROUP BY dist_bucket
ORDER BY cnt DESC;

SELECT COUNT(*) AS self_pair_cnt
FROM accounts_nearbyschool
WHERE school_id = nearby_school_id;
# 자기 자신이 6214일줄 알았는데 5950이 나옴

# school id, nearby school id 중복 관계 확인
SELECT school_id, nearby_school_id, COUNT(*) AS cnt
FROM accounts_nearbyschool
GROUP BY school_id, nearby_school_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 50;
# ??? 

# 헷갈리는 것 알고싶은 것
# 학교별 근처학교 개수 분포
SELECT near_cnt, COUNT(*) AS school_cnt
FROM (
  SELECT school_id, COUNT(*) AS near_cnt
  FROM accounts_nearbyschool
  GROUP BY school_id
) t
GROUP BY near_cnt
ORDER BY near_cnt;

# 중복 확인 다시
SELECT nearby_school_id, COUNT(*) AS appear_cnt
FROM accounts_nearbyschool
GROUP BY nearby_school_id
HAVING COUNT(*) > 1
ORDER BY appear_cnt DESC;
# 이게 제대로된 결과일거 같음
# appear cnt

# 6214건과 5950건 차이에 이유가 있는건지 아니면 오류인지 확인
SELECT school_id, nearby_school_id, distance
FROM accounts_nearbyschool
WHERE distance = 0 AND school_id <> nearby_school_id
# 정체를 찾았다
# 264건은 학교 아이디랑 near 학교 아이디랑 다른데, 거리는 0

# 학교별로 근처 학교 개수 분포
SELECT near_cnt, COUNT(*) AS school_cnt
FROM (
  SELECT school_id, COUNT(*) AS near_cnt
  FROM accounts_nearbyschool
  GROUP BY school_id
) t
GROUP BY near_cnt
ORDER BY near_cnt;
# 학교 수는 5950, 주변 학교 수는 10개가 맞음

# 셀프 카운트는 같은데..?
SELECT
  COUNT(*) AS self_cnt,
  SUM(distance = 0) AS self_distance_zero_cnt
FROM accounts_nearbyschool
WHERE school_id = nearby_school_id;

# 다른 학교인데 distance가 0인 이상치 개수
SELECT
  COUNT(*) AS zero_dist_other_school_cnt
FROM accounts_nearbyschool
WHERE distance = 0
  AND school_id <> nearby_school_id
# 264건
# 오케이 알았음

# accounts_paymenthistory

SELECT *
FROM accounts_paymenthistory
LIMIT 5;


# 결측치
SELECT
  COUNT(*) AS total_rows,
  SUM(id IS NULL) AS null_id,
  SUM(user_id IS NULL) AS null_user_id,
  SUM(productId IS NULL) AS null_productId,
  SUM(TRIM(productId) = '') AS blank_productId,
  SUM(phone_type IS NULL) AS null_phone_type,
  SUM(TRIM(phone_type) = '') AS blank_phone_type,
  SUM(created_at IS NULL) AS null_created_at
FROM accounts_paymenthistory;


# id 중복
SELECT id, COUNT(*) AS cnt
FROM accounts_paymenthistory
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 50;

# 여러번 결제한 사람
SELECT user_id, productId, created_at, COUNT(*) AS cnt
FROM accounts_paymenthistory
GROUP BY user_id, productId, created_at
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 50;
# 472건

# 유저별 결제 횟수 분포
SELECT pay_cnt, COUNT(*) AS user_cnt
FROM (
  SELECT user_id, COUNT(*) AS pay_cnt
  FROM accounts_paymenthistory
  GROUP BY user_id
) t
GROUP BY pay_cnt
ORDER BY pay_cnt;
#최대 60번 결제한 유저가 있음

# 폰 타입 분포
SELECT phone_type, COUNT(*) AS cnt
FROM accounts_paymenthistory
GROUP BY phone_type
ORDER BY cnt DESC;
# 아이폰이 약 2배 많다는 것 말곤 특이사항 없음


# productId 분포
SELECT productId, COUNT(*) AS cnt
FROM accounts_paymenthistory
WHERE productId IS NOT NULL AND TRIM(productId) <> ''
GROUP BY productId
ORDER BY cnt DESC
LIMIT 50;
# 하트 4000개는 꽤 비쌌을 텐데도 2천명이 넘게 구매

# created_at
SELECT
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at
FROM accounts_paymenthistory;
# 23/5/13~24/5/8

# 시간 이상치
SELECT *
FROM accounts_paymenthistory
WHERE created_at > NOW()
ORDER BY created_at DESC
LIMIT 50;


# 구매 테이블에는 있는데 구매 실패에 없는 항목
# 하트 4000이 없었던 것 같아서
SELECT DISTINCT p.productId
FROM accounts_paymenthistory p
LEFT JOIN accounts_failpaymenthistory f
  ON p.productId = f.productId
WHERE p.productId IS NOT NULL
  AND f.productId IS NULL
LIMIT 50
# 하트 4000은 구매 실패 테이블에는 없음

# 반대
SELECT DISTINCT f.productId
FROM accounts_failpaymenthistory f
LEFT JOIN accounts_paymenthistory p
  ON f.productId = p.productId
WHERE f.productId IS NOT NULL
  AND p.productId IS NULL
LIMIT 50
# 없음

# 별다른 이상치는 없어보이고,
# 결제를 많이 한 유저들을 조금 더 보기
SELECT pay_cnt, COUNT(*) AS user_cnt
FROM (
  SELECT user_id, COUNT(*) AS pay_cnt
  FROM accounts_paymenthistory
  GROUP BY user_id
) t
GROUP BY pay_cnt
ORDER BY pay_cnt;

SELECT user_id, COUNT(*) AS pay_cnt
FROM accounts_paymenthistory
GROUP BY user_id
HAVING pay_cnt = 60;

# 60번 결제한 사람의 구매 이력
SELECT *
FROM accounts_paymenthistory
WHERE user_id = 1527451
ORDER BY created_at
# 2023/5/28 14번 결제, 아침부터 밤까지, 이상 로그는 아닌 것으로 보임
# 2023/5/29 22번 결제, 새벽 4시부터 결제 부지런 or 관리자?
# 2023/6/1 부터는 4번으로, 그 뒤에도 줄어드는 추세

SELECT user_id, COUNT(*) AS pay_cnt
FROM accounts_paymenthistory
GROUP BY user_id
HAVING pay_cnt = 51

SELECT *
FROM accounts_paymenthistory
WHERE user_id = 1246471
ORDER BY created_at
# 2023/5/23 18번
# 2023/5/24 14번


SELECT COUNT(DISTINCT user_id) as user_cnt
FROM accounts_paymenthistory
GROUP BY user_id
HAVING user_cnt >1

# accounts_pointhistory

SELECT *
FROM accounts_pointhistory
LIMIT 10;


SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN delta_point IS NULL THEN 1 ELSE 0 END) AS null_delta_point,
  SUM(CASE WHEN delta_point = 0 THEN 1 ELSE 0 END) AS zero_delta_point,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at,
  SUM(CASE WHEN user_question_record_id IS NULL THEN 1 ELSE 0 END) AS null_question_id
FROM accounts_pointhistory;

SELECT COUNT(DISTINCT user_id) as user_cnt
FROM accounts_pointhistory

# 포인트 값 분포 확인
SELECT delta_point, COUNT(*) AS cnt
FROM accounts_pointhistory
GROUP BY delta_point
ORDER BY delta_point;

# 유저별 포인트 총합
SELECT user_id, SUM(delta_point) AS total_point, COUNT(*) AS event_cnt
FROM accounts_pointhistory
GROUP BY user_id
ORDER BY total_point DESC
# 최대 포인트 32378
# 가장 적은 사람은 -18045 

# 포인트가 음수인 사람
SELECT user_id, SUM(delta_point) AS total_point, COUNT(*) AS event_cnt
FROM accounts_pointhistory
GROUP BY user_id
HAVING total_point <0
ORDER BY total_point DESC
# 2049명이나 음수 포인트
# 포인트 차감 시스템이 잘 운영되었나봄

# 포인트 로그 분포
SELECT event_cnt, COUNT(*) AS user_cnt
FROM (
  SELECT user_id, COUNT(*) AS event_cnt
  FROM accounts_pointhistory
  GROUP BY user_id
) t
GROUP BY event_cnt
ORDER BY event_cnt;
# 포인트 이벤트 로그가 가장 많은 유저는 2976번이나 되었음
# 2천번을 넘는 이용자가 꽤 있음


SELECT
  CASE
    WHEN user_question_record_id IS NULL THEN 'non_question'
    ELSE 'question_based'
  END AS type,
  COUNT(*) AS cnt,
  SUM(delta_point) AS total_point
FROM accounts_pointhistory
GROUP BY type;

# 시간 분포, 이상치
SELECT DATE(created_at) AS dt, COUNT(*) AS cnt
FROM accounts_pointhistory
GROUP BY dt
ORDER BY dt;
# 2023/04/28~2024/05/08
# 이상치는 없는 듯
# 23/4~6에는 로그가 굉장히 많고, 그 뒤로 8월, 9월도 많았지만
# 그 뒤로 줄어드는 추세


# 음수 포인트 로그 수
SELECT COUNT(*) AS neg_rows, COUNT(DISTINCT user_id) AS neg_users
FROM accounts_pointhistory
WHERE delta_point < 0;
# 음수 로그는 108583행, 유저는 4609명

# 음수 로그 횟수가 많은 유저
SELECT user_id, COUNT(*) AS neg_event_cnt, SUM(delta_point) AS neg_point_sum  
FROM accounts_pointhistory
WHERE delta_point < 0
GROUP BY user_id
ORDER BY neg_event_cnt DESC
# 4609명, 포인트 값도 매우 다양

# 포인트 차감 폭이 큰 순서대로
SELECT user_id, COUNT(*) AS neg_event_cnt, SUM(delta_point) AS neg_point_sum
FROM accounts_pointhistory
WHERE delta_point < 0
GROUP BY user_id
ORDER BY neg_point_sum ASC
LIMIT 50;


# 가장 차감폭이 컸던? 유저 확인
SELECT *
FROM accounts_pointhistory
WHERE user_id = 1185764
ORDER BY created_at;
# 300씩 차감되는게 일반적인듯

# 음수만 보기
SELECT id, user_id, user_question_record_id, delta_point, created_at
FROM accounts_pointhistory
WHERE user_id = 1185764     -- ← 대상 유저
  AND delta_point < 0
ORDER BY created_at;
# -1000도 있고, -200, -500도 있음

SELECT delta_point, COUNT(*) AS cnt, COUNT(DISTINCT user_id) AS user_cnt
FROM accounts_pointhistory
WHERE delta_point < 0
GROUP BY delta_point
ORDER BY delta_point;


# poll question

# 결측 확인
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN question_text IS NULL THEN 1 ELSE 0 END) AS null_question,
  SUM(CASE WHEN TRIM(question_text) = '' THEN 1 ELSE 0 END) AS blank_question,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at
FROM polls_question
# 없음

# 아이디 중복
SELECT COUNT(id) as id_cnt
FROM polls_question
GROUP BY id
HAVING id_cnt >2
# 1번 아이디가 5025번 중복
# 아마 질문을 등록한 개발자 아이디일 것

# 질문 중복 여부
SELECT question_text, COUNT(*) AS cnt
FROM polls_question
GROUP BY question_text
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 20
# 질문이 아닌 'vote'가 있음
# 일반 질문들은 2~3번 중복되는데, vote는 56건

# 질문 생성 시점
SELECT DATE(created_at) AS dt, COUNT(*) AS question_cnt
FROM polls_question
GROUP BY dt
ORDER BY dt
# 2023/03/31~2023/06/06

# 질문 생성 시점
# 초단위
SELECT
  created_at,
  LAG(created_at) OVER (ORDER BY created_at) AS prev_created_at,
  TIMESTAMPDIFF(SECOND,
    LAG(created_at) OVER (ORDER BY created_at),
    created_at
  ) AS diff_sec
FROM polls_question
ORDER BY created_at
LIMIT 200;

# 질문 생성 시각 이상치
SELECT *
FROM polls_question
WHERE created_at > NOW()
ORDER BY created_at DESC
LIMIT 50

SELECT MIN(created_at) AS min_created_at, MAX(created_at) AS max_created_at
FROM polls_question
# 위에서 확인한 것과 시점 같음


# 질문 길이
SELECT id, question_text, created_at
FROM polls_question
WHERE question_text IS NOT NULL AND LENGTH(TRIM(question_text)) < 10
ORDER BY created_at DESC
LIMIT 50;
# 질문 내용에 '좋아해', '포인트', '실물파', '토끼상'이 있음
# 질문도 학생들이 만들 수 있는 것으로 보임

# 학생들이 질문을 만들 수 있다면 오타도 있을까
# 공백 두번
SELECT id, question_text
FROM polls_question
WHERE question_text REGEXP '  +'
LIMIT 50
# '퀸동주가 롤모델일 것  같은 사람은?' 이 질문으로 봤을 때, 학생들끼리 소속감도 소외감도 느낄 수 있었을 듯
# '퀸동주가 롤모델일 것  같은 사람은?', '혓바닥이 가장 분홍색일 것  같은 사람은?' 이 질문은 두개 씩 있음


# 너무 긴 질문
SELECT id, LENGTH(question_text) AS len, question_text, created_at
FROM polls_question
WHERE question_text IS NOT NULL AND LENGTH(question_text) >= 180
ORDER BY len DESC
LIMIT 50;
# 없음

# 질문 생성 시간대
SELECT
  HOUR(created_at) AS hour,
  COUNT(*) AS cnt
FROM polls_question
WHERE created_at IS NOT NULL
GROUP BY hour
ORDER BY hour;
# 보통 아침 8시



# polls_questionpiece

SELECT *
FROM polls_questionpiece
LIMIT 5

SELECT id, COUNT(*) AS cnt
FROM polls_questionpiece
GROUP BY id
HAVING cnt > 2
# 아이디 중복 1265476

SELECT question_id, COUNT(*) AS piece_cnt
FROM polls_questionpiece
GROUP BY question_id
# question id 중복 확인
# 중복 많음

# 결측
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN question_id IS NULL THEN 1 ELSE 0 END) AS null_question_id,
  SUM(CASE WHEN is_voted IS NULL THEN 1 ELSE 0 END) AS null_is_voted,
  SUM(CASE WHEN is_skipped IS NULL THEN 1 ELSE 0 END) AS null_is_skipped,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at
FROM polls_questionpiece
# 없음

# 이상치
SELECT
  SUM(CASE WHEN is_voted NOT IN (0,1) THEN 1 ELSE 0 END) AS invalid_is_voted,
  SUM(CASE WHEN is_skipped NOT IN (0,1) THEN 1 ELSE 0 END) AS invalid_is_skipped
FROM polls_questionpiece
# 없음

# 투표를 하면서 스킵한 사람(있을 수 없음)
SELECT *
FROM polls_questionpiece
WHERE is_voted = 1 AND is_skipped = 1
# ? 1127건
# 둘다 1일 수 있는건가?

# question id 기준으로 확인
SELECT
  question_id,
  SUM(is_voted = 1) AS voted_piece_cnt,
  SUM(is_skipped = 1) AS skipped_piece_cnt,
  COUNT(*) AS piece_cnt
FROM polls_questionpiece
GROUP BY question_id
HAVING voted_piece_cnt > 0 AND skipped_piece_cnt > 0
ORDER BY piece_cnt DESC
# question id 기준으로 투표와 스킵 모두 보려고 했는데 원하는 결과는 아닌 것 같음,,


# 조각 1개인 질문
SELECT question_id
FROM polls_questionpiece
GROUP BY question_id
HAVING COUNT(*) = 1;


# 투표도 스킵도 안한 경우
# 이건 아직 행동을 안한거라서 그럴 순 있을 듯
SELECT COUNT(*) AS neither_cnt
FROM polls_questionpiece
WHERE is_voted = 0 AND is_skipped = 0
# 46789건

# question id 중복 로그
SELECT question_id, COUNT(*) AS piece_cnt
FROM polls_questionpiece
GROUP BY question_id
HAVING COUNT(*) > 1
ORDER BY piece_cnt DESC
LIMIT 50
# 같은 질문 조각에 로그가 여러번 찍혔는지
# 중복은 굉장히 많음
# 나중에 다른 question 테이블(user_question_record?)와 조인해도 좋을듯

# 질문과 질문 조각 차이가 뭔지 아직 잘 감이 안옴
SELECT piece_cnt, COUNT(*) AS question_cnt
FROM (
  SELECT
    question_id,
    COUNT(*) AS piece_cnt
  FROM polls_questionpiece
  GROUP BY question_id
) t
GROUP BY piece_cnt
ORDER BY piece_cnt
# 피스 1개인 질문 202개, 2개인 질문 235개, 3개인 질문 191개, ..., 2030개인 질문 1개
# 질문 조각이 뭘까?

# 시간 이상치
SELECT *
FROM polls_questionpiece
WHERE created_at > NOW()
ORDER BY created_at DESC
LIMIT 50

# polls questionreport

SELECT *
FROM polls_questionreport
LIMIT 5

SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS null_id,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN question_id IS NULL THEN 1 ELSE 0 END) AS null_question_id,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at,
  SUM(CASE WHEN reason IS NULL THEN 1 ELSE 0 END) AS null_reason,
  SUM(CASE WHEN reason = '' THEN 1 ELSE 0 END) AS empty_reason,
  SUM(CASE WHEN TRIM(reason) = '' THEN 1 ELSE 0 END) AS blank_reason
FROM polls_questionreport;

SELECT COUNT(id) as id_cnt
FROM polls_questionreport
GROUP BY id
HAVING id_cnt>1

SELECT user_id, COUNT(*) AS cnt
FROM polls_questionreport
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
# id는 PK, user_id는 중복신고했을 수 있으니까 여러번?

# 같은 유저가 같은 질문을 여러 번 신고했는지
SELECT
  user_id,
  question_id,
  COUNT(*) AS report_cnt,
  MIN(created_at) AS first_report_at,
  MAX(created_at) AS last_report_at
FROM polls_questionreport
WHERE user_id IS NOT NULL AND question_id IS NOT NULL
GROUP BY user_id, question_id
HAVING COUNT(*) > 1
ORDER BY report_cnt DESC
LIMIT 50
# 4949건, 똑같은 질문에 가장 많이 신고한 사람은 17번 신고

SELECT
  user_id,
  COUNT(*) AS report_cnt,
  MIN(created_at) AS first_report_at,
  MAX(created_at) AS last_report_at
FROM polls_questionreport
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY report_cnt DESC
LIMIT 50
# 질문에 상관없이 신고 수만 봤을 때는, 가장 많이 신고한 사람이 865번 신고함


SELECT *
FROM polls_questionreport
WHERE user_id = 1309630
# 질문을 가장 많이 신고한 사람의 신고 사유는 모두 그냥 싫어

SELECT *
FROM polls_questionreport
WHERE user_id = 1441146 AND reason = '그냥 싫어'
# 최다 신고자 신고 사유도 모두 그냥 싫어

# 1분 이내에 2번 이상 신고 
# 중복 신고
WITH pair_reports AS (
  SELECT
    user_id,
    question_id,
    created_at,
    LAG(created_at) OVER (PARTITION BY user_id, question_id ORDER BY created_at) AS prev_created_at
  FROM polls_questionreport
)
SELECT
  user_id,
  question_id,
  COUNT(*) AS fast_dup_cnt
FROM pair_reports
WHERE prev_created_at IS NOT NULL
  AND TIMESTAMPDIFF(SECOND, prev_created_at, created_at) <= 3
GROUP BY user_id, question_id
HAVING fast_dup_cnt >=2
ORDER BY fast_dup_cnt DESC
# 10초로 줄여서 봤고, 1086명의 유저가 중복 신고
# 신고 횟수는 최대가 8번

# 시간 이상치
SELECT MIN(created_at) AS min_created_at, MAX(created_at) AS max_created_at
FROM polls_questionreport
# 시간 범위는 23/4/19~24/5/5

SELECT *
FROM polls_questionreport
WHERE created_at > NOW()
ORDER BY created_at DESC

# 날짜별 신고량
SELECT
  DATE(created_at) AS dt,
  COUNT(*) AS report_cnt,
  COUNT(DISTINCT user_id) AS reporter_cnt,
  COUNT(DISTINCT question_id) AS reported_question_cnt
FROM polls_questionreport
WHERE created_at IS NOT NULL
GROUP BY dt
ORDER BY dt
# 23/4/19~24/5/5까지 기록
# report cnt: 신고 로그 수
# reporter cnt: 그 날 신고에 참여한 서로 다른 유저 수
# reported question cnt: 그날 신고된 서로 다른 질문 수

# 신고한 유저 목록 + 신고 횟수
SELECT DATE(created_at) AS dt, user_id, COUNT(*) AS report_cnt
FROM polls_questionreport
WHERE user_id IS NOT NULL
GROUP BY dt, user_id
ORDER BY report_cnt DESC, user_id

# 가장 신고가 많이 들어온 날짜 순
SELECT DATE(created_at) AS dt, COUNT(*) AS report_cnt
FROM polls_questionreport
WHERE user_id IS NOT NULL
GROUP BY dt, user_id
ORDER BY report_cnt DESC
# 가장 많이 신고가 있었던 횟수는 343건

# 그냥 전체 기간 동안 신고를 많이 한 유저
SELECT
  user_id,
  COUNT(*) AS total_report_cnt,
  COUNT(DISTINCT question_id) AS distinct_question_cnt
FROM polls_questionreport
GROUP BY user_id
ORDER BY total_report_cnt DESC
# 1441146유저 총 865번, 774개 질문에 신고
# 이후 200번대로 줄어듦


# polls_questionset

SELECT *
FROM polls_questionset
LIMIT 5


SELECT
  COUNT(*) AS total_rows,
  SUM(id IS NULL) AS null_id,
  SUM(user_id IS NULL) AS null_user_id,
  SUM(status IS NULL) AS null_status,
  SUM(TRIM(status) = '') AS blank_status,
  SUM(opening_time IS NULL) AS null_opening_time,
  SUM(created_at IS NULL) AS null_created_at,
  SUM(question_piece_id_list IS NULL) AS null_piece_list,
  SUM(TRIM(question_piece_id_list) = '') AS blank_piece_list,
  SUM(TRIM(question_piece_id_list) = '[]') AS empty_json_list
FROM polls_questionset
# 결측 없음

# id 중복
SELECT id, COUNT(*) AS cnt
FROM polls_questionset
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 50

# user id 중복 확인
SELECT user_id, opening_time, COUNT(*) AS cnt
FROM polls_questionset
WHERE user_id IS NOT NULL AND opening_time IS NOT NULL
GROUP BY user_id, opening_time
HAVING COUNT(*) > 1
ORDER BY cnt DESC
# 중복이 2개씩??

# status 값 확인
SELECT status, COUNT(*) AS cnt
FROM polls_questionset
GROUP BY status
ORDER BY cnt DESC
# F 종료: 153411
# O 열림: 4407
# C 닫힘: 566

# 시간 확인
SELECT
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at,
  MIN(opening_time) AS min_opening_time,
  MAX(opening_time) AS max_opening_time
FROM polls_questionset
# created at, opening time: 23/4/28~24/5/7

# 당연히 생성이 오픈보다 먼저여야 함
SELECT *
FROM polls_questionset
WHERE created_at IS NOT NULL
  AND opening_time IS NOT NULL
  AND opening_time < created_at
ORDER BY (TIMESTAMPDIFF(SECOND, opening_time, created_at)) DESC
# create가 open보다 더 늦은 질문세트 679건

# 미래시간
SELECT *
FROM polls_questionset
WHERE opening_time > NOW() OR created_at > NOW()
ORDER BY GREATEST(opening_time, created_at) DESC
# 없음

# piece list sample은 어떻게 생겼는지
SELECT id, user_id, status, opening_time, created_at, LEFT(question_piece_id_list, 200) AS piece_list_sample
FROM polls_questionset
WHERE question_piece_id_list IS NOT NULL
ORDER BY id

# accounts attendance처럼 리스트 길이 확인
SELECT
  CASE
    WHEN question_piece_id_list IS NULL OR TRIM(question_piece_id_list) = '' THEN 'NULL/BLANK'
    WHEN TRIM(question_piece_id_list) = '[]' THEN 'EMPTY_LIST'
    WHEN LENGTH(question_piece_id_list) < 10 THEN '<10'
    WHEN LENGTH(question_piece_id_list) < 50 THEN '10-49'
    WHEN LENGTH(question_piece_id_list) < 200 THEN '50-199'
    WHEN LENGTH(question_piece_id_list) < 1000 THEN '200-999'
    ELSE '1000+'
  END AS len_bucket,
  COUNT(*) AS cnt
FROM polls_questionset
GROUP BY len_bucket
ORDER BY cnt DESC
# 50~199 158384건



# create가 open보다 나중인것, 얼마나 차이 나는지
SELECT
  CASE
    WHEN diff_sec < 1 THEN '<1s'
    WHEN diff_sec < 3 THEN '1-2s'
    WHEN diff_sec < 10 THEN '3-9s'
    WHEN diff_sec < 60 THEN '10-59s'
    WHEN diff_sec < 300 THEN '1-4m'
    WHEN diff_sec < 3600 THEN '5-59m'
    WHEN diff_sec < 86400 THEN '1-23h'
    ELSE '1d+'
  END AS diff_bucket,
  COUNT(*) AS cnt
FROM (
  SELECT
    TIMESTAMPDIFF(SECOND, opening_time, created_at) AS diff_sec
  FROM polls_questionset
  WHERE created_at IS NOT NULL
    AND opening_time IS NOT NULL
    AND opening_time < created_at
) t
GROUP BY diff_bucket
ORDER BY cnt DESC
# 1~2초 644건, 3~9초 25건, 10~59초 10건
# 모두 1분 내에 찍히긴 했음

# create > open을 status별로 확인
SELECT
  status,
  COUNT(*) AS total_cnt,
  SUM(CASE WHEN opening_time IS NOT NULL AND created_at IS NOT NULL AND opening_time < created_at THEN 1 ELSE 0 END) AS open_lt_create_cnt
FROM polls_questionset
GROUP BY status
ORDER BY open_lt_create_cnt DESC
# close 상태에서는 아예 없고, open은 8건 finish는 671건
# 모수가 많아서 그런건지, 로직때문인지

# 질문 조각 리스트 개수
SELECT piece_cnt, COUNT(*) AS questionset_cnt
FROM (
  SELECT
    CASE
      WHEN question_piece_id_list IS NULL THEN NULL
      WHEN TRIM(question_piece_id_list) = '' THEN NULL
      WHEN TRIM(question_piece_id_list) = '[]' THEN 0
      WHEN JSON_VALID(question_piece_id_list) = 1 THEN JSON_LENGTH(question_piece_id_list)
      ELSE NULL
    END AS piece_cnt
  FROM polls_questionset
) t
GROUP BY piece_cnt
ORDER BY piece_cnt
# 모두 10개?? 위 결과랑은 다름

# 질문 조각 개수 10개 맞는지 상태별로 다시 확인
SELECT
  status,
  JSON_LENGTH(question_piece_id_list) AS piece_cnt,
  COUNT(*) AS cnt
FROM polls_questionset
WHERE question_piece_id_list IS NOT NULL
  AND JSON_VALID(question_piece_id_list) = 1
  AND JSON_LENGTH(question_piece_id_list) IN (0, 10)
GROUP BY status, piece_cnt
ORDER BY piece_cnt, cnt DESC
# 맞긴 함

# 질문 세트가 열린 수 + 생성 유저 수
# open time 기준
SELECT
  DATE(opening_time) AS dt,
  COUNT(*) AS opened_set_cnt,
  COUNT(DISTINCT user_id) AS creator_user_cnt
FROM polls_questionset
WHERE opening_time IS NOT NULL
GROUP BY dt
ORDER BY dt;
# 23/4/28-23/8/5
# 점점 활성화된 질문이 많아지다가 줄어듦

# polls_usercandidate

# 결측
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user,
  SUM(CASE WHEN question_piece_id IS NULL THEN 1 ELSE 0 END) AS null_piece,
  SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created
FROM polls_usercandidate;


# 같은 유저한테 같은 질문 조각이 여러번 노출됐는지
SELECT user_id, question_piece_id, COUNT(*) AS exposure_cnt
FROM polls_usercandidate
GROUP BY user_id, question_piece_id
HAVING COUNT(*) > 1
ORDER BY exposure_cnt DESC
# 최대 4번
# 대부분 2번 = 새로고침 혹은 중복로그일 듯

WITH dup AS (
  SELECT user_id, question_piece_id, created_at,
    LAG(created_at) OVER (PARTITION BY user_id, question_piece_id ORDER BY created_at) AS prev_created_at
  FROM polls_usercandidate
)
SELECT
  TIMESTAMPDIFF(SECOND, prev_created_at, created_at) AS diff_sec,
  COUNT(*) AS cnt
FROM dup
WHERE prev_created_at IS NOT NULL
GROUP BY diff_sec
ORDER BY diff_sec;
# 시간 차이 0~2초 정도면 중복이라고 생각했는데, 0초가 487건
# 최대가 877초인 경우, 4건
# 몇 초 사이에 중복이 되든, 4건 혹은 8건인 경우가 너무 많다


# 유저 기준 하루 노출 이상치
SELECT
  DATE(created_at) AS dt,
  user_id,
  COUNT(*) AS exposure_cnt
FROM polls_usercandidate
GROUP BY dt, user_id
HAVING COUNT(*) > 50
ORDER BY exposure_cnt DESC
# 한 유저가 하루에 질문 조각이 가장 많이 노출된 수 1113
# 860304 23/5/6

SELECT DATE(created_at) AS dt, COUNT(*) AS exposure_cnt
FROM polls_usercandidate
WHERE user_id = 860304
GROUP BY dt
ORDER BY dt;


# 전체 투표율
SELECT
  COUNT(*) AS exposure_cnt,
  SUM(CASE WHEN qp.is_voted = 1 THEN 1 ELSE 0 END) AS voted_cnt,
  ROUND(
    SUM(CASE WHEN qp.is_voted = 1 THEN 1 ELSE 0 END) / COUNT(*),
    4
  ) AS vote_rate
FROM polls_usercandidate uc
JOIN polls_questionpiece qp
  ON uc.question_piece_id = qp.id;
# 노출되면 무조건 투표를 한다?
# 조인을 잘못한거 같음

SELECT is_voted, COUNT(*) AS cnt
FROM polls_questionpiece
GROUP BY is_voted

# 노출 수는 투표한 사람들한테서만 집계되는건가??
SELECT qp.is_voted, COUNT(*) AS exposure_cnt
FROM polls_usercandidate uc
JOIN polls_questionpiece qp ON uc.question_piece_id = qp.id
GROUP BY qp.is_voted;


# 유저 1인당 평균 노출 수
SELECT
  AVG(exposure_cnt) AS avg_exposure_per_user
FROM (
  SELECT user_id, COUNT(*) AS exposure_cnt
  FROM polls_usercandidate
  GROUP BY user_id
) t;
# 238.552개

# created at
SELECT
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at
FROM polls_usercandidate
WHERE created_at IS NOT NULL
# 23/4/28 - 24/5/8


# 미래
SELECT *
FROM polls_usercandidate
WHERE created_at > NOW()
ORDER BY created_at


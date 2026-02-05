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

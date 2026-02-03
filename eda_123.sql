-- Active: 1769573056417@@localhost@3313@final_analytics
SELECT * FROM events;


SHOW TABLES;

DESC accounts_attendance;
DESC accounts_user_contacts;
DESC accounts_paymenthistory;

# 출석테이블

-- 가입후 연속 출석수 확인
SELECT 
    CASE 
        WHEN max_streak_days >= 30 THEN '30일 이상 (신)'
        WHEN max_streak_days >= 14 THEN '14일~29일 (습관 형성)'
        WHEN max_streak_days >= 7 THEN '7일~13일 (1주일 달성)'
        WHEN max_streak_days >= 3 THEN '3일~6일 (작심삼일 돌파)'
        WHEN max_streak_days >= 1 THEN '1일~2일 (초심자)'
        ELSE '기록 없음'
    END AS streak_range,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT user_id) FROM accounts_attendance), 2) AS percentage
FROM saved_streaks
GROUP BY streak_range
ORDER BY 
    FIELD(streak_range, '30일 이상 (신)', '14일~29일 (습관 형성)', '7일~13일 (1주일 달성)', '3일~6일 (작심삼일 돌파)', '1일~2일 (초심자)', '기록 없음');

-- (선택) 다 봤으면 테이블 삭제
DROP TABLE saved_dates;
DROP TABLE saved_streaks;
 -------
SELECT 
    DAYNAME(jt.attendance_date) AS day_of_week, -- 요일 이름
    COUNT(*) AS visit_count,                    -- 해당 요일 총 방문 수
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage -- 전체 대비 비율
FROM accounts_attendance
JOIN JSON_TABLE(
    attendance_date_list, 
    "$[*]" COLUMNS(attendance_date DATE PATH "$")
) AS jt
GROUP BY day_of_week
ORDER BY visit_count DESC;

SELECT 
    DAYNAME(jt.attendance_date) AS day_of_week,
    COUNT(*) AS visit_count,
    -- 전체 대비 비율 (%)
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM accounts_attendance
JOIN JSON_TABLE(
    attendance_date_list, 
    "$[*]" COLUMNS(attendance_date DATE PATH "$")
) AS jt
-- [조건] 헤비 유저만 필터링 (여기만 바꾸면 됩니다)
WHERE JSON_LENGTH(attendance_date_list) >= 50
GROUP BY day_of_week
ORDER BY visit_count DESC;


SELECT 
    DAYNAME(jt.attendance_date) AS day_of_week,
    COUNT(*) AS visit_count,
    -- 전체 대비 비율 (%)
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM accounts_attendance
JOIN JSON_TABLE(
    attendance_date_list, 
    "$[*]" COLUMNS(attendance_date DATE PATH "$")
) AS jt
-- [조건] 라이트 유저만 필터링
WHERE JSON_LENGTH(attendance_date_list) < 10
GROUP BY day_of_week
ORDER BY visit_count DESC;







SELECT
  DATE(attendance_date_list) AS date,
  COUNT(*) AS attendance_cnt
FROM accounts_attendance
GROUP BY date
ORDER BY date;
------------------------------------------------------------------------------------------------------------------------------------------------

-- 차단기록테이블 EDA

SELECT * FROM accounts_blockrecord;

SELECT 
    -- 차단 당한 횟수 구간 (피차단 수)
    CASE 
        WHEN blocked_count >= 50 THEN '1. Villain (50명 이상이 차단함)'
        WHEN blocked_count >= 10 THEN '2. Nuisance (10~49명 이상이 차단함)'
        WHEN blocked_count >= 3 THEN '3. Warning (3~9명 이상이 차단함)'
        ELSE '4. Normal (1~2명)'
    END AS risk_level,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT block_user_id) FROM accounts_blockrecord), 2) AS percentage
FROM (
    -- [1단계] 유저별 '차단 당한 횟수' 집계
    SELECT 
        block_user_id,
        COUNT(*) AS blocked_count
    FROM accounts_blockrecord
    GROUP BY block_user_id
) AS blocked_stats
GROUP BY risk_level
ORDER BY risk_level;
SELECT *
FROM (
    -- 유저별 '차단 당한 횟수' 집계
    SELECT 
        block_user_id,
        COUNT(*) AS blocked_count
    FROM accounts_blockrecord
    GROUP BY block_user_id
) AS blocked_stats
WHERE blocked_stats.blocked_count >= 10
ORDER BY blocked_count DESC;

--- 
SELECT 
    -- 차단자 ID
    user_id,
    COUNT(*) AS total_blocks,
    MAX(blocks_in_minute) AS max_blocks_per_minute,
    
    CASE 
        WHEN MAX(blocks_in_minute) >= 10 THEN '🤖 Bot Suspected (1분에 10명 이상 차단)'
        WHEN COUNT(*) >= 50 THEN '😡 Sensitive (누적 50명 이상 차단)'
        ELSE '🙂 Normal'
    END AS blocker_type
FROM (
    -- [서브쿼리] 유저별 + 분(Minute)별 차단 횟수 집계
    SELECT 
        user_id,
        DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') AS block_time_min,
        COUNT(*) AS blocks_in_minute
    FROM accounts_blockrecord
    GROUP BY user_id, block_time_min
) AS min_stats
GROUP BY user_id
-- 봇 의심이거나, 예민한 유저만 필터링하여 확인 (상위 50명)
HAVING total_blocks >= 10 OR max_blocks_per_minute >= 5
ORDER BY max_blocks_per_minute DESC, total_blocks DESC
LIMIT 50;

--- 

SELECT 
    -- 차단 사유 (NULL이면 '미입력' 처리)
    IFNULL(reason, 'Reason Not Provided') AS block_reason,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_blockrecord), 2) AS percentage

FROM accounts_blockrecord
GROUP BY block_reason
ORDER BY count DESC;


--- 
SELECT 
    -- 가입 후 차단까지 걸린 시간 구간
    CASE 
        WHEN DATEDIFF(b.created_at, u.created_at) = 0 THEN '0. Same Day (가입 당일 차단당함)'
        WHEN DATEDIFF(b.created_at, u.created_at) <= 7 THEN '1. Within 1 Week (신규 유저)'
        WHEN DATEDIFF(b.created_at, u.created_at) <= 30 THEN '2. Within 1 Month'
        ELSE '3. Old User (기존 유저)'
    END AS time_to_be_blocked,
    COUNT(*) AS blocked_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_blockrecord), 2) AS percentage
FROM accounts_blockrecord b
-- [중요] 유저 테이블과 조인 (차단 '당한' 사람의 가입일을 알기 위해)
JOIN accounts_user u ON b.block_user_id = u.id 
GROUP BY time_to_be_blocked
ORDER BY time_to_be_blocked;

------------------------------------------------------------------------------------------------------------

SELECT * FROM accounts_failpaymenthistory;

# 기술 점검] OS 및 상품별 실패 분포
# 어디서(OS), 무엇을(Product) 살 때 문제가 생기는지 범인을 좁힙니다.
SELECT 
    -- 1. 기기 타입 (보통 A:Android, I:iOS)
    IFNULL(phone_type, 'Unknown') AS os_type,
    productId,
    COUNT(*) AS fail_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_failpaymenthistory), 2) AS percentage

FROM accounts_failpaymenthistory
GROUP BY phone_type, productId
ORDER BY fail_count DESC
LIMIT 20;

#② [매출 구조대] "제발 돈 좀 받아줘요" (재시도 유저 발굴)
#여러 번 결제를 시도했으나 결국 실패 기록만 남은 **"구매 의지 최상위 유저"**를 찾습니다.
SELECT 
    -- 유저 ID
    user_id,
    -- 시도한 횟수 (간절함의 척도)
    COUNT(*) AS retry_count,
    -- 주로 구매하려던 상품
    MAX(productId) AS target_product,
    -- 마지막 시도 시간
    MAX(created_at) AS last_attempt_at,
    -- 긴급도 진단
    CASE 
        WHEN COUNT(*) >= 10 THEN '🚨 Emergency (10회 이상 시도)'
        WHEN COUNT(*) >= 5 THEN '🔥 High Intent (5~9회 시도)'
        ELSE '⚠️ Normal'
    END AS urgency_level
FROM accounts_failpaymenthistory
GROUP BY user_id
-- 최소 3번 이상 시도한 사람만 추출
HAVING retry_count >= 3
ORDER BY retry_count DESC
LIMIT 50;

# 결과 없음
----
#[시간 분석] 언제 서버가 아파하는가?
#특정 시간대에 실패가 몰리는지 확인합니다.

SELECT 
    -- 시간대 (00~23시)
    DATE_FORMAT(created_at, '%H') AS hour_of_day,
    COUNT(*) AS fail_count,
    -- 시각적 확인을 위한 막대 그래프 표현 (텍스트)
    RPAD('', CEIL(COUNT(*) * 20 / (SELECT COUNT(*) FROM accounts_failpaymenthistory)), '■') AS visual_bar

FROM accounts_failpaymenthistory
GROUP BY hour_of_day
ORDER BY hour_of_day;

--------------------------------------------------------------------------------------------

SELECT * FROM accounts_friendrequest;

---

# 1. "내 마음을 받아줘" (수락률 분석)
-- A:수락   / P:허용    / R:거부
SELECT 
    IFNULL(status, 'Unknown') AS request_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_friendrequest), 2) AS percentage
FROM accounts_friendrequest
GROUP BY status
ORDER BY count DESC;


# 2. "인싸" vs "마당발" 발굴 (Top User Analysis)

-- [Top Receivers] 인기가 많은 유저 (상위 20명)
SELECT 
    receive_user_id AS user_id,
    COUNT(*) AS received_requests,
    'Popular (인싸)' AS type
FROM accounts_friendrequest
GROUP BY receive_user_id
ORDER BY received_requests DESC
LIMIT 20;
-- [Top Senders] 활동적인 유저 혹은 봇 (상위 20명)
SELECT 
    send_user_id AS user_id,
    COUNT(*) AS sent_requests,
    'Active/Spammer (마당발)' AS type
FROM accounts_friendrequest
GROUP BY send_user_id
ORDER BY sent_requests DESC
LIMIT 20;

----

# 3. "밀당의 시간" (반응 속도 분석)

SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(HOUR, created_at, updated_at) < 1 THEN '1. 1시간 이내 (즉답)'
        WHEN TIMESTAMPDIFF(HOUR, created_at, updated_at) < 24 THEN '2. 하루 이내'
        WHEN TIMESTAMPDIFF(HOUR, created_at, updated_at) < 72 THEN '3. 3일 이내'
        ELSE '4. 장기 대기 (3일 이상)' 
    END AS response_time,
    COUNT(*) AS count
FROM accounts_friendrequest
-- status가 '수락'이나 '거절' 등으로 종결된 건만 대상 (대기중 제외)
WHERE status IN ('A', 'R') -- (실제 DB 코드값에 맞춰 수정 필요: A=Accept, R=Reject 가정)
  AND updated_at IS NOT NULL
GROUP BY response_time
ORDER BY response_time;

---

# "짝사랑꾼" 찾기 (거절률이 높은 보낸이)

SELECT 
    send_user_id,
    COUNT(*) AS total_sent,
    -- 수락된 횟수 (status 코드가 'A'가 수락이라고 가정)
    SUM(CASE WHEN status = 'A' THEN 1 ELSE 0 END) AS accepted_count,
    -- 수락률 (%)
    ROUND(SUM(CASE WHEN status = 'A' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM accounts_friendrequest
GROUP BY send_user_id
-- 최소 10번 이상 요청을 보낸 사람만 (통계적 유의미성)
HAVING total_sent >= 10
-- 수락률이 낮은 순서대로 정렬 (0%에 가까울수록 의심)
ORDER BY success_rate ASC, total_sent DESC
LIMIT 30;

-----------------------------------------------------------------------------------------


SELECT 
    school_scale,
    COUNT(*) AS school_count,
    -- 전체 학교 수 대비 비율 (%)
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT school_id) FROM accounts_group), 2) AS percentage
FROM (
    -- [안쪽 쿼리] 학교별 학급 수 집계 및 등급 산정
    SELECT 
        school_id,
        CASE 
            WHEN COUNT(*) >= 30 THEN '1. Large (대형: 30학급 이상)'
            WHEN COUNT(*) >= 10 THEN '2. Medium (중형: 10~29학급)'
            ELSE '3. Small (소형: 10학급 미만)' 
        END AS school_scale
    FROM accounts_group
    GROUP BY school_id
) AS school_stats
GROUP BY school_scale
ORDER BY school_scale;

----
SELECT * FROM accounts_group;

# 🏫 학교 규모별 분포 (대/중/소 개수 파악)
SELECT 
    grade,
    COUNT(*) AS total_classes,
    -- 전체 대비 비율
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_group), 2) AS percentage
FROM accounts_group
GROUP BY grade
ORDER BY grade ASC;


---

# 2. "초등학교인가, 고등학교인가?" (학년 분포 분석)
SELECT 
    grade,
    MAX(class_num) AS max_class_number,
    AVG(class_num) AS avg_class_number
FROM accounts_group
GROUP BY grade
ORDER BY grade;


----

# 3. "콩나물 시루" 찾기 (최대 반 번호 분석)


SELECT 
    grade,
    MAX(class_num) AS max_class_number,
    AVG(class_num) AS avg_class_number
FROM accounts_group
GROUP BY grade
ORDER BY grade;


---


# 4. [중요] 데이터 무결성 검사 (중복 반 찾기)

SELECT 
    school_id,
    grade,
    class_num,
    COUNT(*) AS duplicate_count
FROM accounts_group
GROUP BY school_id, grade, class_num
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

----------------------------------------------------------------------------------------------------


SELECT * FROM accounts_nearbyschool;
# 1. "학군 밀집도" 분석 (Urban vs Rural)
SELECT 
    CASE 
        WHEN nearby_count >= 20 THEN '1. High Density (도심/학군지)'
        WHEN nearby_count >= 10 THEN '2. Medium (일반 주거지)'
        WHEN nearby_count >= 1 THEN '3. Low (교외/시골)'
        ELSE '4. Isolated (나홀로 학교)' 
    END AS density_level,
    COUNT(*) AS school_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT school_id) FROM accounts_nearbyschool), 2) AS percentage
FROM (
    -- 학교별 이웃 학교 수 집계
    SELECT 
        school_id,
        COUNT(*) AS nearby_count
    FROM accounts_nearbyschool
    GROUP BY school_id
) AS density_stats
GROUP BY density_level
ORDER BY density_level;

---
# 2. "이웃의 정의" 파악 (거리 분포 분석)
SELECT 
    -- 거리 구간 (단위를 모르니 일단 값 자체로 구간핑)
    -- 만약 값이 1, 2.5 처럼 작으면 km, 1000, 2500 처럼 크면 m 입니다.
    -- 아래는 'km' 단위라고 가정했을 때의 예시입니다. (값이 크면 숫자를 조정하세요)
    CASE 
        WHEN distance < 1 THEN '0~1km (도보권)'
        WHEN distance < 3 THEN '1~3km (자전거/마을버스)'
        WHEN distance < 5 THEN '3~5km (대중교통)'
        WHEN distance < 10 THEN '5~10km (차량 이동)'
        ELSE '10km+ (멀음)' 
    END AS distance_range,
    COUNT(*) AS count,
    ROUND(AVG(distance), 2) AS avg_distance
FROM accounts_nearbyschool
GROUP BY distance_range
ORDER BY avg_distance;

---

# 3. "가장 가까운 학교" 찾기 (최단 거리 분석)
SELECT 
    school_id,
    MIN(distance) AS closest_distance,
    COUNT(*) AS nearby_count
FROM accounts_nearbyschool
GROUP BY school_id
ORDER BY closest_distance ASC
LIMIT 30;

----

# 4. 데이터 대칭성(Symmetry) 검사
SELECT 
    'Asymmetry Check' AS check_name,
    COUNT(*) AS total_records,
    -- (A->B)는 있는데 (B->A)는 없는 케이스 수 추정 (간단 검증용)
    -- 정확한 검증은 Self Join이 필요하지만, 전체 개수가 짝수인지 홀수인지로 1차 간음 가능
    MOD(COUNT(*), 2) AS is_odd_number
FROM accounts_nearbyschool;

--------------------------------------------------------------------------------------------------
# 지불기록 테이블 살펴보기
SELECT COUNT(*) FROM accounts_paymenthistory;

SELECT
  COUNT(DISTINCT user_id) AS paying_users
FROM accounts_paymenthistory;

SELECT
  HOUR(created_at) AS hour_of_day, -- 시간대 추출 (0~23)
  COUNT(id) AS transaction_count
FROM accounts_paymenthistory
GROUP BY HOUR(created_at)
ORDER BY hour_of_day;

-- MySQL 예시: 시간을 9시간 더해서 조회
SELECT
  HOUR(DATE_ADD(created_at, INTERVAL 9 HOUR)) AS hour_of_day_kst,
  COUNT(id) AS transaction_count
FROM accounts_paymenthistory
GROUP BY hour_of_day_kst
ORDER BY hour_of_day_kst;

SELECT * FROM accounts_attendance;

--------------------------------------------------------------------------------------------------


SELECT * FROM accounts_user_contacts;

# 1. 연락처 얼마나 많이있는지

SELECT 
    CASE 
        WHEN contacts_count >= 500 THEN '1. Mega Hub (500명+)'
        WHEN contacts_count >= 100 THEN '2. Super Connector (100~499명)'
        WHEN contacts_count >= 30 THEN '3. Networker (30~99명)'
        WHEN contacts_count >= 1 THEN '4. Normal (1~29명)'
        ELSE '5. Loner (0명)'
    END AS network_size_group,
    COUNT(*) AS user_count,
    -- 그룹별 평균 연락처 수
    ROUND(AVG(contacts_count), 0) AS avg_contacts,
    -- 전체 대비 비중
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_user_contacts), 2) AS percentage
FROM accounts_user_contacts
GROUP BY network_size_group
ORDER BY network_size_group;


----

# 2. 초대의 힘
SELECT 
    -- 가입 경로 구분 (JSON 길이가 0이면 자발적, 아니면 초대)
    CASE 
        WHEN JSON_LENGTH(invite_user_id_list) > 0 THEN 'Invited (초대받음)'
        ELSE 'Organic (스스로 가입)' 
    END AS acquisition_source,
    COUNT(*) AS user_count,
    -- 평균 연락처 보유수 (활동성 지표)
    ROUND(AVG(contacts_count), 1) AS avg_contacts_count,
    -- 최대 연락처 보유수
    MAX(contacts_count) AS max_contacts
FROM accounts_user_contacts
GROUP BY acquisition_source;

----

# 3. 영업왕(누가 초대를 많이 했나?)

SELECT 
    -- JSON 배열 안에 있는 '초대자 ID'를 꺼냄
    inviter_id,
    -- 초대에 성공한 횟수
    COUNT(*) AS successful_invites,
    -- 그들이 데려온 사람들의 퀄리티 (평균 연락처 수)
    ROUND(AVG(c.contacts_count), 1) AS avg_invitee_quality
FROM accounts_user_contacts c
JOIN JSON_TABLE(
    c.invite_user_id_list,
    "$[*]" COLUMNS(inviter_id BIGINT PATH "$")
) AS jt
GROUP BY inviter_id
ORDER BY successful_invites DESC
LIMIT 20;

---

# 4. 여러명이 초대하면 더 높은 확률로 서비스에 진입하나?

SELECT 
    -- 초대를 몇 명에게 받았는지 카운트
    CASE 
        WHEN JSON_LENGTH(invite_user_id_list) = 0 THEN '0. No Invite'
        WHEN JSON_LENGTH(invite_user_id_list) = 1 THEN '1. Single Invite'
        WHEN JSON_LENGTH(invite_user_id_list) = 2 THEN '2. Double Invites'
        ELSE '3. Many Invites (3명 이상에게 받음)' 
    END AS social_pressure,
    COUNT(*) AS user_count,
    -- 해당 그룹의 평균 연락처 수
    ROUND(AVG(contacts_count), 1) AS avg_contacts_size
    
FROM accounts_user_contacts
GROUP BY social_pressure
ORDER BY social_pressure;


------------------------------------------------------------------------------------

SELECT * FROM accounts_pointhistory;

# 1. "얼마짜리 행동인가?" (보상 체계 분석)

SELECT 
    delta_point AS point_amount,
    COUNT(*) AS frequency,
    -- 전체 지급 횟수 대비 비율
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_pointhistory), 2) AS percentage
FROM accounts_pointhistory
GROUP BY delta_point
ORDER BY frequency DESC;

----

# 2. 누가 부자인가? feat.헤비유저 분석

SELECT 
    CASE 
        WHEN total_points >= 10000 THEN '1. VIP (1만 포인트 이상)'
        WHEN total_points >= 1000 THEN '2. Gold (1천~1만 포인트)'
        WHEN total_points >= 100 THEN '3. Silver (100~1천 포인트)'
        ELSE '4. Bronze (100 포인트 미만)'
    END AS user_grade,
    
    COUNT(*) AS user_count,
    ROUND(AVG(total_points), 0) AS avg_points_held
FROM (
    -- 유저별 총 포인트 합계
    SELECT 
        user_id,
        SUM(delta_point) AS total_points
    FROM accounts_pointhistory
    GROUP BY user_id
) AS user_stats
GROUP BY user_grade
ORDER BY user_grade;



# vip목록

SELECT user_id
FROM (
    -- 유저별 총 포인트 합계
    SELECT 
        user_id,
        SUM(delta_point) AS total_points
    FROM accounts_pointhistory
    GROUP BY user_id
) AS user_stats
WHERE total_points >= 10000;


--- 

# 3. 포인트를 너무 자주 발리 받으면 봇 아닌가?

SELECT 
    user_id,
    -- 행동이 발생한 '분(Minute)' 시간대
    DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') AS activity_minute,
    -- 1분 동안 획득한 횟수 (클릭 수)
    COUNT(*) AS clicks_per_minute,
    -- 1분 동안 획득한 총 포인트
    SUM(delta_point) AS points_per_minute
FROM accounts_pointhistory
GROUP BY user_id, activity_minute
-- 1분에 30회 이상 (2초에 1번 꼴) 클릭한 경우만 추출 (기준은 조정 가능)
HAVING clicks_per_minute >= 15
ORDER BY clicks_per_minute DESC
LIMIT 50;

---

# 서비스가 성장하고 있는가? 서비스내의 경제 규모 변화

SELECT 
    DATE(created_at) AS date,
    -- 그날 지급된 총 포인트 양
    SUM(delta_point) AS daily_total_points,
    -- 그날 포인트를 획득한 유저 수 (DAU 근사치)
    COUNT(DISTINCT user_id) AS active_users,
    -- 1인당 평균 획득 포인트 (Labor Productivity)
    ROUND(SUM(delta_point) / COUNT(DISTINCT user_id), 1) AS avg_points_per_user
FROM accounts_pointhistory
GROUP BY date
ORDER BY date DESC; 

------------------------------------------------------------------------------------------------------------------------------------------------
# 10. 학교 테이블 분석
SELECT * FROM accounts_school;

# 1. "중학교 vs 고등학교" 시장 점유율 분석

SELECT 
    CASE 
        WHEN school_type = 'M' THEN 'Middle School (중학교)'
        WHEN school_type = 'H' THEN 'High School (고등학교)'
        ELSE 'Unknown'
    END AS school_category,
    -- 학교 수
    COUNT(*) AS total_schools,
    -- 총 학생 수 (잠재적 시장 규모)
    SUM(student_count) AS total_students,
    -- 학교당 평균 학생 수
    ROUND(AVG(student_count), 0) AS avg_students_per_school
FROM accounts_school
GROUP BY school_category;

-----

# 2. 2. "지역별 학군" 분석 (주소 파싱)

SELECT 
    -- 주소의 첫 번째 단어 추출 (예: '충청북도 충주시' -> '충청북도')
    SUBSTRING_INDEX(address, ' ', 1) AS region,
    COUNT(*) AS school_count,
    -- 해당 지역의 총 학생 수
    SUM(student_count) AS total_local_students,
    -- 시각적 확인을 위한 막대 그래프
    RPAD('', CEIL(COUNT(*) * 20 / (SELECT COUNT(*) FROM accounts_school)), '■') AS visual_bar
FROM accounts_school
GROUP BY region
ORDER BY school_count DESC;



-----

# 3. "매머드급 학교" 찾기 (규모별 등급 분석)

SELECT 
    CASE 
        WHEN student_count >= 1000 THEN '1. Giant (1000명+)'
        WHEN student_count >= 500 THEN '2. Large (500~999명)'
        WHEN student_count >= 200 THEN '3. Medium (200~499명)'
        WHEN student_count >= 1 THEN '4. Small (1~199명)'
        ELSE '5. Zero/Error (0명)'
    END AS size_grade,
    COUNT(*) AS school_count,
    -- 해당 그룹의 평균 학생 수
    ROUND(AVG(student_count), 0) AS avg_students
    
FROM accounts_school
GROUP BY size_grade
ORDER BY size_grade;

# 4. 상세 지역 타겟팅 (세부 주소 분석)

SELECT 
    -- 주소 앞 두 단어 추출 (MySQL 기준)
    -- 예: '경기도 성남시 분당구...' -> '경기도 성남시'
    TRIM(SUBSTRING_INDEX(address, ' ', 2)) AS local_area,
    
    COUNT(*) AS school_count,
    SUM(student_count) AS total_students

FROM accounts_school
GROUP BY local_area
ORDER BY school_count DESC
LIMIT 20;


------------------------------------------------------------------------------------------------------------------------


SELECT * FROM accounts_user_contacts;

SELECT 
    -- 1. 유저 가입 경로 구분
    CASE 
        WHEN JSON_LENGTH(c.invite_user_id_list) > 0 THEN '💌 Invited (초대받음)'
        ELSE '🌱 Organic (자발적 가입)' 
    END AS user_segment,
    -- 2. 유저 수
    COUNT(DISTINCT c.user_id) AS user_count,
    -- 3. 인당 평균 포인트 활동 횟수 (얼마나 자주 앱을 켰나?)
    ROUND(COUNT(p.id) / COUNT(DISTINCT c.user_id), 1) AS avg_activity_count,
    -- 4. 인당 평균 누적 포인트 (얼마나 많은 가치를 창출했나?)
    -- (COALESCE는 포인트 기록이 없는 유저를 0 처리)
    ROUND(SUM(COALESCE(p.delta_point, 0)) / COUNT(DISTINCT c.user_id), 0) AS avg_total_points
FROM accounts_user_contacts c
-- [Join] 유저의 연락처 정보와 포인트 기록을 합침
LEFT JOIN accounts_pointhistory p ON c.user_id = p.user_id
GROUP BY user_segment;



SELECT 
    -- 초대받은 횟수 (0회, 1회, 2회...)
    JSON_LENGTH(invite_user_id_list) AS invite_received_count,
    -- 해당되는 유저 수
    COUNT(*) AS user_count,
    -- 전체 대비 비율
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts_user_contacts), 2) AS percentage,
    -- 해당 그룹의 평균 활동성
    ROUND(AVG(contacts_count), 1) AS avg_activity
FROM accounts_user_contacts
GROUP BY invite_received_count
ORDER BY invite_received_count ASC;



-----------------

SELECT 
    -- [초대 KPI] ----------------------------------
    -- 1. 전체 총 초대 발생 건수 (우리 서비스 내에서 일어난 총 친구 초대 수)
    SUM(JSON_LENGTH(invite_user_id_list)) AS kpi_total_invites,
    -- 2. 사용자 인당 평균 초대 수 (K-Factor 근사치)
    -- (전체 초대 수 / 전체 유저 수)
    ROUND(SUM(JSON_LENGTH(invite_user_id_list)) / COUNT(*), 4) AS kpi_avg_invites_per_user,
    -- [활동 KPI] ----------------------------------
    -- 3. 인당 평균 출석 일수 (활동 기간 내)
    (SELECT ROUND(COUNT(DISTINCT CONCAT(user_id, DATE(created_at))) / COUNT(DISTINCT user_id), 1) 
     FROM accounts_pointhistory) AS kpi_avg_attendance_days,
    -- 4. 인당 평균 결제(포인트 소비) 횟수
    (SELECT ROUND(COUNT(*) / COUNT(DISTINCT user_id), 1) 
     FROM accounts_pointhistory 
     WHERE delta_point < 0) AS kpi_avg_payment_count,
    -- 5. 인당 평균 포인트 활동 횟수
    (SELECT ROUND(COUNT(*) / COUNT(DISTINCT user_id), 0) 
     FROM accounts_pointhistory) AS kpi_avg_activity_count

FROM accounts_user_contacts;


SELECT * FROM accounts_pointhistory;

SELECT * FROM accounts_userquestionrecord;

SELECT 
    -- 1. 유저 그룹 분류 (초대 여부 기준)
    CASE 
        WHEN JSON_LENGTH(c.invite_user_id_list) > 0 THEN '💌 Invited (초대받음)'
        ELSE '🌱 Organic (자발적 가입)' 
    END AS user_segment,
    -- 2. 그룹별 유저 수
    COUNT(c.user_id) AS total_users,
    -- 3. 인당 평균 투표 참여 횟수 (Vote Participation)
    -- (COALESCE는 기록이 없는 유저를 0으로 처리하여 평균의 정확도를 높임)
    ROUND(AVG(COALESCE(q.vote_count, 0)), 1) AS avg_vote_participation,
    -- 4. 인당 평균 포인트 활동 횟수 (Point Activity)
    ROUND(AVG(COALESCE(p.point_activity_count, 0)), 1) AS avg_point_activity,
    -- 5. 인당 평균 출석 일수 (Attendance Days)
    ROUND(AVG(COALESCE(p.attendance_days, 0)), 1) AS avg_attendance_days
FROM accounts_user_contacts c
-- [Join 1] 투표 기록 집계 (유저별 투표 횟수 미리 계산)
LEFT JOIN (
    SELECT 
        user_id, 
        COUNT(*) AS vote_count
    FROM accounts_userquestionrecord
    GROUP BY user_id
) q ON c.user_id = q.user_id
-- [Join 2] 포인트 및 출석 기록 집계 (유저별 활동/출석 미리 계산)
LEFT JOIN (
    SELECT 
        user_id,
        -- 포인트 활동 횟수 (적립 + 사용 로그 수)
        COUNT(*) AS point_activity_count,
        -- 출석 일수 (날짜 중복 제거)
        COUNT(DISTINCT DATE(created_at)) AS attendance_days
    FROM accounts_pointhistory
    GROUP BY user_id
) p ON c.user_id = p.user_id
GROUP BY user_segment;
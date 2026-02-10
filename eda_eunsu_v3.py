#!/usr/bin/env python
# coding: utf-8

import pandas as pd
import numpy as np
import koreanize_matplotlib
import matplotlib.pyplot as plt
import seaborn as sns 
from datetime import timedelta
import ast


## 모든 테이블 전처리 요소 확인

### 1. hackle
device_properties = pd.read_csv('./dumps/hackle_csv/device_properties.csv')
hackle_events = pd.read_csv('./dumps/hackle_csv/hackle_events.csv')
hackle_properties = pd.read_csv('./dumps/hackle_csv/hackle_properties.csv')
user_properties = pd.read_csv('./dumps/hackle_csv/user_properties.csv')


#### 1-1. device_properties
device_properties.head(5)


# 결측값 없음
device_properties.isnull().sum()
device_properties['device_id'].nunique()


# 전체 중복값 없음 (id 빼고 확인)
columns = ['device_id',	'device_model',	'device_vendor']
device_properties[device_properties[columns].duplicated(keep=False)]


# device_id 중복값 있음 
# 전체 1320개 -> keep='first'하면 660개 (2개씩 중복)
device_properties[device_properties['device_id'].duplicated(keep=False)]


# 맨 마지막 id일수록 최신인가?
# 이부분은 ai의 힘을 빌림
device_model_info = [
    # Samsung S Series
    ['SM-G935K', 2016, 1], ['SM-G950N', 2017, 2], ['SM-G960N', 2018, 1],
    ['SM-G965N', 2018, 1], ['SM-G970N', 2019, 1], ['SM-G973N', 2019, 1],
    ['SM-G975N', 2019, 1], ['SM-G977N', 2019, 2], ['SM-G981N', 2020, 1],
    ['SM-G986N', 2020, 1], ['SM-G986B', 2020, 1], ['SM-G988N', 2020, 1],
    ['SM-G781N', 2020, 4], ['SM-G991N', 2021, 1], ['SM-G996N', 2021, 1],
    ['SM-G998N', 2021, 1], ['SM-S901N', 2022, 1], ['SM-S908N', 2022, 1],
    ['SM-S911N', 2023, 1], ['SM-S916N', 2023, 1], ['SM-S918N', 2023, 1],

    # Samsung Note & Z Series
    ['SM-N935K', 2017, 3], ['SM-N935S', 2017, 3], ['SM-N950N', 2017, 3],
    ['SM-N950F', 2017, 3], ['SM-N960N', 2018, 3], ['SM-N971N', 2019, 3],
    ['SM-N976N', 2019, 3], ['SM-N981N', 2020, 3], ['SM-N986N', 2020, 3],
    ['SM-F700N', 2020, 1], ['SM-F707N', 2020, 3], ['SM-F711N', 2021, 3],
    ['SM-F926N', 2021, 3], ['SM-F721N', 2022, 3], ['SM-F936N', 2022, 3],
    ['SM-F731N', 2023, 3], ['SM-F946N', 2023, 3],

    # Samsung A / M / E Series
    ['SM-A710L', 2016, 1], ['SM-A530N', 2018, 1], ['SM-G885S', 2018, 2],
    ['SM-G611K', 2018, 1], ['SM-A750N', 2018, 4], ['SM-G887N', 2018, 4],
    ['SM-A920N', 2018, 4], ['SM-A305N', 2019, 2], ['SM-A405S', 2019, 2],
    ['SM-A505N', 2019, 2], ['SM-A202K', 2019, 2], ['SM-A908N', 2019, 3],
    ['SM-A315N', 2020, 2], ['SM-A217N', 2020, 2], ['SM-A516N', 2020, 2],
    ['SM-A716S', 2020, 2], ['SM-A125N', 2021, 1], ['SM-A325N', 2021, 1],
    ['SM-A426N', 2021, 1], ['SM-A326K', 2021, 2], ['SM-A826S', 2021, 2],
    ['SM-A226L', 2021, 2], ['SM-E426S', 2021, 3], ['SM-A528N', 2021, 3],
    ['SM-G525N', 2021, 1], ['SM-A135F', 2022, 1], ['SM-A136S', 2022, 1],
    ['SM-A235N', 2022, 1], ['SM-A336N', 2022, 2], ['SM-A536N', 2022, 1],
    ['SM-M336K', 2022, 2], ['SM-M236L', 2022, 3], ['SM-M536S', 2022, 2],
    ['SM-A245N', 2023, 2], ['SM-A346N', 2023, 1], ['SM-A546S', 2023, 1],

    # Apple iPhone
    ['iPhone8,1', 2015, 4], ['iPhone9,3', 2016, 4], ['iPhone9,4', 2016, 4],
    ['iPhone10,1', 2017, 4], ['iPhone10,4', 2017, 4], ['iPhone10,5', 2017, 4],
    ['iPhone10,6', 2017, 4], ['iPhone11,2', 2018, 3], ['iPhone11,6', 2018, 3],
    ['iPhone11,8', 2018, 4], ['iPhone12,1', 2019, 3], ['iPhone12,3', 2019, 3],
    ['iPhone12,5', 2019, 3], ['iPhone12,8', 2020, 2], ['iPhone13,1', 2020, 4],
    ['iPhone13,2', 2020, 4], ['iPhone13,3', 2020, 4], ['iPhone13,4', 2020, 4],
    ['iPhone14,2', 2021, 4], ['iPhone14,3', 2021, 4], ['iPhone14,4', 2021, 4],
    ['iPhone14,5', 2021, 4], ['iPhone14,6', 2022, 1], ['iPhone14,7', 2022, 4],
    ['iPhone14,8', 2022, 4], ['iPhone15,2', 2022, 4], ['iPhone15,3', 2022, 4],

    # Tablets (iPad & Galaxy Tab)
    ['iPad7,5', 2018, 1], ['iPad8,1', 2018, 4], ['SM-P200', 2019, 2],
    ['SM-P610', 2020, 2], ['SM-P615N', 2020, 2], ['iPad12,1', 2021, 4],
    ['SM-X200', 2022, 1], ['SM-X700', 2022, 1], ['SM-X800', 2022, 1],
    ['SM-X806N', 2022, 1], ['SM-X900', 2022, 1], ['iPad13,16', 2022, 2],
    ['iPad11,6', 2022, 3], ['iPad13,18', 2022, 4], ['iPad14,3', 2022, 4],
    ['iPad14,4', 2022, 4], ['iPad14,5', 2022, 4], ['iPad14,6', 2022, 4],
    ['SM-X810', 2023, 3],

    # Others
    ['LM-G900N', 2020, 2], ['LM-Q920N', 2020, 3],
    ['Lenovo TB-J606F', 2021, 1], ['23021RAA2Y', 2023, 1]
]

device_model_df = pd.DataFrame(device_model_info, columns=['device_model', 'release_year', 'Q'])

# 중복된 행만 있는 device_properties에 출시년도를 맵핑함
dup_device_properties = device_properties[device_properties['device_id'].duplicated(keep=False)]
dup_device_properties.sort_values(by='id', inplace=True)
dup_device_properties = pd.merge(dup_device_properties, device_model_df, on='device_model', how='left')

# 출시년도 NULL값 없음
dup_device_properties[dup_device_properties['release_year'].isnull()]

dup_device_properties


# 같은 device_id 별 출시년도 합치기
release_year_list = dup_device_properties.groupby('device_id')['release_year'].apply(list).reset_index(name='release_year_list')
release_year_list['release_year_diff'] = release_year_list['release_year_list'].apply(lambda x: x[1] - x[0])

# 출시년도 년도 차이가 양수인가? (신제품으로 바꾼건가?) -> 아님!!!!
# 오히려 출시년도가 낮아진 애들 있음 (135개)
release_year_list[release_year_list['release_year_diff'] < 0]



# 낮아진 유저들은 뭘 썼나?
lower_version_ids = release_year_list[release_year_list['release_year_diff'] < 0]['device_id'].unique()
lower_version = dup_device_properties[dup_device_properties['device_id'].isin(lower_version_ids)]
lower_version.groupby('device_id')['device_model'].apply(list).reset_index(name='device_model')


# 출시년도 같은 애들 device_id 확인
same_release_year_ids = release_year_list[release_year_list['release_year_diff'] == 0]['device_id'].unique()
same_release_year = dup_device_properties[dup_device_properties['device_id'].isin(same_release_year_ids)]
same_release_year.sort_values(by='id', inplace=True)

# 분기를 비교해봄
release_Q = same_release_year.groupby('device_id')['Q'].apply(list).reset_index(name='Q_list')
release_Q['Q_diff'] = release_Q['Q_list'].apply(lambda x: x[1] - x[0])

# 같은 출시년도이지만, 출시 분기가 낮아진 애들 있음 (7개)
release_Q[release_Q['Q_diff'] < 0]



# 같은 출시년도, 같은 분기 애들 있음 (12개)
# 패드/탭 -> 폰 OR 조금이나마 UP된 model로 바꿈
# 이 id들도 마지막 데이터로 보면 될듯
same_year_Q_ids = release_Q[release_Q['Q_diff'] == 0]['device_id'].unique()
same_year_Q = dup_device_properties[dup_device_properties['device_id'].isin(same_year_Q_ids)]
same_year_Q


# [device_properties]
# - 출시년도가 낮아진 id들이 있음(135개)
# - 출시년도는 같은데 분기가 낮아진 id가 있음(7개)
# - 출시년도, 분기가 모두 같은 id(12개)
#     - 얘네들은 패드/탭 -> 폰 OR 조금이나마 UP된 model로 바꿈
# -----------------------------------------------------------------------------------
# - 중복값(660개) 중 약 22%, 전체 id 값(251,720개) 중 약 0.06%만 출시년도가 애매
# - <mark>출시 낮아진 기종으로 바꾼 사람들 그냥 무시하고 keep=last해도 좋을 듯




#### 1-2. hackle_events
hackle_events.head(3)

# 용량이 너무 커서 데이터 개수 안보임
hackle_events.info()


# 결측값 있지만 특정 로그에만 찍히는 것으로 확인 -> 처리 안해도 될 듯
hackle_events.isnull().sum()
hackle_events[hackle_events['votes_count'].isnull()]



# 제대로 가입이 안된 유저
# 유저 id가 이상한 애들은 가입하다 말았나?
# user_id가 session_id랑 같음
# 아래의 해당 유저는 앱 실행, 세션시작 2가지 로그만 있음
# 근데 하트 소유기록이 NULL이 아니라 353? 이라고 하트 소유 중
hackle_events[hackle_events['session_id'] == 'W1aCtAm0P9Nc8OYFfuOexSwwn1e2']
hackle_properties[hackle_properties['session_id'] == 'W1aCtAm0P9Nc8OYFfuOexSwwn1e2']



# 전체 중복값 있음 (id 빼고 확인)
# 전체 345,665개 -> keep='first'하면 195,247개 (2개 이상 중복)
columns = hackle_events.columns
columns = columns.drop(['event_id', 'id'])

hackle_events[hackle_events[columns].duplicated(keep=False)].sort_values(by=['session_id', 'event_datetime'])


# [hackle_events]
# - id 빼고 전체 중복값 있음 -> 서버 문제인 듯
# - 그냥 <mark>keep='first' 하면 될 듯





#### 1-3. hackle_properties
hackle_properties.head(5)


# user_id에서 결측치 확인 (82,255개) -> 없는 건 비회원?
hackle_properties.info()


# 전체 중복값 없음 (id 빼고 확인)
columns = hackle_events.columns
columns = columns.drop(['id'])

hackle_properties[hackle_properties.duplicated(keep=False)]



# session_id 중복값 있음 (id 빼고 확인)
hackle_properties[hackle_properties['session_id'].duplicated(keep=False)].sort_values(by='session_id')


# 중복값 애들만 따로 뺌
dup_hackle_properties = hackle_properties[hackle_properties['session_id'].duplicated(keep=False)].sort_values(by='session_id')

# session_id가 몇 개씩 같은지?
# 9개씩 같은 session_id가 있기도 함 -> user_id 기준으로 보면 됨
dup_hackle_properties['session_id'].value_counts().reset_index()


# 중복값 중 하나 찍어봄
# user_id가 잘 있다가 갑자기 NULL이 왜 나왔을까?
# 탈퇴 회원은 관련 정보를 다 삭제한다고 피그마에 나와있는데
# 탈퇴해서 없나?
dup_hackle_properties[dup_hackle_properties['session_id'] == 'zzwdcJbazOPmYWLKoUFQKhvZTRu1']


# user 내부데이터를 보니 기록 남아있음
# NULL이 뜬 건 탈퇴해서가 아닌 듯 -> 그럼 그냥 에러?
accounts_user[accounts_user['id'] == 1122713]




# 유저 테이블도 이벤트 테이블과 마찬가지로
# 친구 22명 똑같이 나옴
a = accounts_user.iloc[256747]['friend_id_list'].replace('[', '')
a = a.replace(']', '')
a = a.split(',')
len(a)


# 이벤트 찍힌 걸 살펴봄
# 5월 또는 그 이전에 가입을 한거로 나오는데
# 이벤트에서는 신규회원처럼 처음에 친구 수, 하트 수, 질문 수가 안보임
hackle_events[hackle_events['session_id'] == 'zzwdcJbazOPmYWLKoUFQKhvZTRu1'].sort_values(by='event_datetime')


# 중복값이 아닌 유저들
no_dup_hp = hackle_properties[~hackle_properties['id'].isin(dup_hackle_properties['id'].unique())]

# 중복값이 아니지만 user_id 없는 사람들
no_dup_hp[no_dup_hp['user_id'].isnull()]['session_id']  


# 중복값 없는 유저들 중 user_id가 NULL인건 뭘까?
# 이벤트 로그가 모두 회원가입, 로그인, 세션 시작/끝 밖에 없음
# 중복값 아니고, user_id가 NULL인 유저 -> 모두 비회원 유저!!!!!!!!!!!!!!!!
no_user_ids = no_dup_hp[no_dup_hp['user_id'].isnull()]['session_id'].unique()
hackle_events[hackle_events['session_id'].isin(no_user_ids)]['event_key'].unique()


# 비회원 유저 한명 찍어봄
# 아니 근데 비회원 유저인데 
# 왜 친구 수, 투표 수, 하트 수가 있는거지??????   -> 일단 보류
hackle_events[hackle_events['session_id'] == 'F9EA195C-862F-4572-80A5-C3AE06F83310']




# device_properties 전처리
# 임시 기준이지만, keep=last로 진행함
processed_device_properties = device_properties[~device_properties.duplicated(keep='last')]


# 다시 중복값 있는 유저로 넘어와서,
# 중복값인데, user_id가 NULL인 애들은 뭘까?

# 전체 중복값 중 user_id null인 애들 테이블 + device 정보 merge
dup_null_user_id_session_ids = dup_hackle_properties[dup_hackle_properties['user_id'].isnull()]['session_id'].unique() # null 담긴 session 정보 가져오기
dup_null_user_id = dup_hackle_properties[dup_hackle_properties['session_id'].isin(dup_null_user_id_session_ids)].sort_values(by=['session_id', 'id']) # user_id, null 모두 가져오기
dup_null_user_id = pd.merge(dup_null_user_id, processed_device_properties[['device_id', 'device_model', 'device_vendor']], on='device_id', how='left')


# 임시로 a, b로 만듦
# session_id 별 user_id, device_model set으로 묶음 (중복값 없앰)
a = dup_null_user_id.groupby('session_id')['user_id'].apply(set).reset_index()
b = dup_null_user_id.groupby('session_id')['device_model'].apply(set).reset_index()

a['user_id'] = a['user_id'].apply(list)
b['device_model'] = b['device_model'].apply(list)

dup_null_user_id_groupby = pd.merge(a, b, on='session_id', how='left')
dup_null_user_id_groupby['model_counts'] = dup_null_user_id_groupby['device_model'].apply(lambda x: len(x))
dup_null_user_id_groupby['user_counts'] = dup_null_user_id_groupby['user_id'].apply(lambda x: len(x))


# 중복값 중 user_id null만 있는 애들의 이벤트 로그 확인
# 얘네들도 비회원 유저인가봄
# 이벤트 로그들이 회원가입, 로그인, 세션 시작/끝 밖에 없음
dup_only_null_users = dup_null_user_id_groupby[dup_null_user_id_groupby['user_counts'] == 1]['session_id'].unique()
hackle_events[hackle_events['session_id'].isin(dup_only_null_users)]['event_key'].unique()


dup_null_user_id[dup_null_user_id['session_id'] == '0097C74A-28FB-4D38-B32F-4081AF89AF34']






# - hackle_properties에서 user_id가 <mark>NULL 하나만 있는 기록들은 모두 비회원 유저!!! (중복값 포함)
# - 다들 실행하다가 가입 안 하고 나간 듯
# - 비회원 유저인데 중복값이 있는 건, 앱 버전 버그 문제인 것 같음





# 중복값 중 user_id, null만 있는 애들의 이벤트 로그 확인 (count가 2개인 애들)
a = dup_null_user_id_groupby.loc[dup_null_user_id_groupby['user_counts'] == 2][['user_id']]
a['first'] = a['user_id'].apply(lambda x: x[0])
a['second'] = a['user_id'].apply(lambda x: x[1])

# 하나의 user_id에 session_id가 여러개
# -> session_id는 유저를 구분하는 고유 번호
# -> session_id가 바뀌는 순간은
# 로그아웃, token 만료, 재설치, 서버 강제 세션 만료, 다른 기기 로그인 (정책에 따라) 등이 있음
a[a['second'] == '1441487']


# session_id가 여러개인 특정 유저 뜯어보기
cond1 = dup_null_user_id['session_id'] == '0013C616-D3D6-4628-B928-25DD7E6ABB3F'
cond2 = dup_null_user_id['session_id'] == '1C1AFB1D-DA51-492A-969F-6124212CD539'
cond3 = dup_null_user_id['session_id'] == 'C05ED16D-8829-4BFE-A78D-85B43F7918C6'

dup_null_user_id[cond1 | cond2 | cond3]




cond1 = hackle_events['session_id'] == '0013C616-D3D6-4628-B928-25DD7E6ABB3F'
cond2 = hackle_events['session_id'] == '1C1AFB1D-DA51-492A-969F-6124212CD539'
cond3 = hackle_events['session_id'] == 'C05ED16D-8829-4BFE-A78D-85B43F7918C6'

test = hackle_events[cond1 | cond2 | cond3].sort_values(by='event_datetime')

# 이벤트 로그 어느 지점에서 session_id가 바꼈나?? 
for i in range(len(test)):
    if i != 0:
        if test.iloc[i]['session_id'] != test.iloc[i - 1]['session_id']:
            print(i)




test.iloc[0:6]




test.iloc[18:27]


# 세션이 바뀔 때마다 NULL이 찍힘
# 그래서 NULL은 재로그인/재부팅 과정에서 찍힌 거??

# 비회원일 때는 마지막 $session_start에서도 NULL임
# 그럼 NULL이 있는 이유는
# 1. 비회원이거나,
# 2. 재로그인/재부팅 하다가 찍힌것??
test.iloc[55:62]


# 유저 테이블 확인해보니 가입되어 있었음
# 그럼 session_id에 user_id, NULL 둘다 찍혀있으면
# 재로그인하든 부팅하든 앱 실행 과정에서 오류!!!
accounts_user[accounts_user['id'] == 1441487]




# 다른 사람으로 테스트 해보자
a[a['second'] == '1173457']


hackle_properties[hackle_properties['session_id'] == 'zzn8O2xYZyNm879WgW9JN3HHfF32']


accounts_user[accounts_user['id'] == 1173457]


# 1173457 이 유저도 미리 가입되어 있었고,
# 앱 부팅 과정에서 오류 난 듯
hackle_events[hackle_events['session_id'] == 'zzn8O2xYZyNm879WgW9JN3HHfF32'].sort_values(by='event_datetime').head(10)


# 다른 애들 모두 똑같은 양상을 보임
# '1469627', '1347933', '1173457' <- 모두 NULL, user_id 모두 있는 애들


# 혹시나 싶어서 user_id는 있는데
# NULL은 안 찍힌 유저로 다시 테스트해봄
hackle_properties[hackle_properties['session_id'] == 'XVYNT6zfhFWqIg9omwg2AHDjTLx2']




# 부팅에서 NULL이 보였기 때문에
# 부팅 로그만 찍어봄

cond1 = hackle_events['session_id'] == 'XVYNT6zfhFWqIg9omwg2AHDjTLx2'
cond2 = hackle_events['event_key'] == 'launch_app'
cond3 = hackle_events['event_key'] == '$session_start'
cond4 = hackle_events['event_key'] == '$session_end'
cond5 = hackle_events['event_key'] == 'view_login'

# 역시 부팅 오류 안난 유저였음
hackle_events[cond1 & (cond2 | cond3 | cond4 | cond5)]




# 정확하게 보기 위해서 user_id, NULL이 있는 session_id 모두
# 부팅 이벤트에서 NULL이 있는지 확인하려고 함
a = dup_null_user_id_groupby.loc[dup_null_user_id_groupby['user_counts'] == 2][['user_id']]
a['changed_id'] = a['user_id'].apply(lambda x: [0 if (v is None or (isinstance(v, float) and np.isnan(v))) else v for v in x])  # 이거 나중에 알아보기

def safe_max(x):
    nums = []
    for v in x:
        try:
            nums.append(int(v))
        except (TypeError, ValueError):
            nums.append(0)
    return str(max(nums)) if nums else str(0)

a['max'] = a['changed_id'].apply(safe_max)
a


a = hackle_properties[hackle_properties['user_id'].isin(a['max'].unique())]
a = hackle_events[hackle_events['session_id'].isin(a['session_id'].unique())]

cond1 = a['event_key'] == 'launch_app'
cond2 = a['event_key'] == '$session_start'
cond3 = a['event_key'] == '$session_end'
cond4 = a['event_key'] == 'view_login'


b = a[cond1 | cond2 | cond3 | cond4].sort_values(by=['session_id', 'event_datetime'])

cond1 = b['item_name'].isnull()
cond2 = b['page_name'].isnull()
cond3 = b['friend_count'].isnull()
cond4 = b['votes_count'].isnull()
cond5 = b['heart_balance'].isnull()
cond6 = a['question_id'].isnull()

b = b[cond1 & cond2 & cond3 & cond4 & cond5 & cond6]


# session_id 비교 결과,
# 거의 대부분이 부팅과정에서 NULL값이 있었음!
# 거의 98%의 session_id가 부팅과정에서 NULL 값이 존재했음
a['session_id'].nunique(), b['session_id'].nunique()


# 중복값 없는 애들한테서도 부팅과정에서 NULL 값 오류가 있는지 확인하려고 함
not_null_user_id = hackle_properties[hackle_properties['user_id'].isnull()]['session_id'].unique()
not_null_user_id = hackle_properties[~hackle_properties['session_id'].isin(not_null_user_id)].sort_values(by=['session_id', 'id'])
not_null_user_id = pd.merge(not_null_user_id, processed_device_properties[['device_id', 'device_model', 'device_vendor']], on='device_id', how='left')

# 임시로 a, b로 만듦
# session_id 별 user_id, device_model set으로 묶음 (중복값 없앰)
a = not_null_user_id.groupby('session_id')['user_id'].apply(set).reset_index()
b = not_null_user_id.groupby('session_id')['device_model'].apply(set).reset_index()

a['user_id'] = a['user_id'].apply(list)
b['device_model'] = b['device_model'].apply(list)

not_null_user_id_groupby = pd.merge(a, b, on='session_id', how='left')
not_null_user_id_groupby['model_counts'] = not_null_user_id_groupby['device_model'].apply(lambda x: len(x))
not_null_user_id_groupby['user_counts'] = not_null_user_id_groupby['user_id'].apply(lambda x: len(x))
not_null_user_id_groupby


not_null_user_id_groupby[not_null_user_id_groupby['user_counts'] > 1]




hackle_properties[hackle_properties['session_id'] == '001384f2-7407-479c-a260-c5b525549274']


# 중복값 없는 애들에선
# 부팅에서 NULL이 떠도 user_id에 NULL이 없는 경우 발견
a = hackle_events[hackle_events['session_id'] == '001384f2-7407-479c-a260-c5b525549274'].sort_values(by='event_datetime')

cond1 = a['event_key'] == 'launch_app'
cond2 = a['event_key'] == '$session_start'
cond3 = a['event_key'] == '$session_end'
cond4 = a['event_key'] == 'view_login'

a[cond1 | cond2 | cond3 | cond4]


# - 한 세션 당 똑같은 user_id, NULL 모두 찍혀있는 경우는,
# - 앱 부팅 과정에서 생긴 오류로 추정
# - 이런 경우는 <mark>user_id만 남기고 NULL 정보는 제거하면 될듯



# os가 바뀐 유저들이 있음 (127명)
os_kind = dup_hackle_properties.groupby('session_id')['osname'].apply(set).reset_index()
os_kind['osname'] = os_kind['osname'].apply(list)
os_kind['osname_count'] = os_kind['osname'].apply(lambda x: len(x))
os_kind['osname_count'].value_counts().reset_index()


# 하나의 장치를 여러 계정이 쓰는 것을 확인
ex = hackle_properties[hackle_properties['device_id'].isin(processed_device_properties['device_id'].unique())]
ex = ex.groupby('device_id')['user_id'].apply(set).reset_index()
ex['user_id'] = ex['user_id'].apply(list)
ex['user_counts'] = ex['user_id'].apply(lambda x: len(x))

# session_id처럼 생긴 이상한 user_id는 본인인듯 
# 오류로 인해 두개로 찍힌 듯
# 그렇담 3개 이상부터 봐야 할듯
ex


# 하나의 장치를 여러 계정이 씀!!
# 최대 6개의 계정이 사용
ex[ex['user_counts'] > 3]


# 4명이서 쓰는 장치 모델 확인
device_properties[device_properties['device_id'] == 'B941F9F9-CF53-4DAE-A204-75E666B5D277']


# [hackle_properties]
# - session_id 중복에서,
# - user_id가 NULL 하나만 있는 기록들은 모두 비회원 유저
# - user_id, NULL 모두 찍혀있는 경우는 앱 부팅 오류 -> <mark>NULL 정보는 제거하면 될듯
# - device 하나를 여럿이서 사용했던 기록 확인






#### 1-4. user_properties

user_properties.head(5)



# 결측값 없음
user_properties.info()



# 전체 중복값 없음
user_properties[user_properties.duplicated(keep=False)]


user_properties[user_properties['user_id'].duplicated(keep=False)]




# - 컬럼 별 고유값 확인
user_properties['grade'].unique()
user_properties['gender'].unique()
user_properties['class'].unique()



# - 반 분포 및 이상치 확인

ax = sns.countplot(data=user_properties, x='class')
ax.bar_label(ax.containers[0], fontsize=8)
ax.set_title('반 별 총 인원 수')
plt.show()



max_class = user_properties.groupby('school_id')['class'].max().reset_index(name='max_class')



# set은 중복값을 자동으로 없애주니
# 먼저 set으로 만들고 나중에 list로 바꾸기
class_list = user_properties.groupby('school_id')['class'].apply(set).reset_index(name='class_list')
class_list['class_list'] = class_list['class_list'].apply(list)
class_list



school_info = pd.merge(class_list, max_class, on='school_id', how='left')
school_info




# 학교 별 평균 반 차이 구하기 -> total 리스트에 저장
total = []
for i in range(len(school_info)):  
    cal = []
    for j in range(len(school_info['class_list'].iloc[i])):
        if j != 0:
            now_list = school_info['class_list'].iloc[i]
            minus = now_list[j] - now_list[j - 1]
            cal.append(abs(minus))  # 반 차이 절대값 해줌
    total.append(np.mean(cal))




# 학교 별 반 구성, max 반 번호, 평균 반 차이를 구함
school_info['avg_class_diff'] = total
school_info




# 반이 한 개만 있는 학교는 반 차이가 NULL임.
# 어떻게 계산해야 할까??? 
# -> max_class 가 1인 학교는 1로 치환
# 나머지 학교는 우선 무시
school_info[school_info['avg_class_diff'].isnull()]['max_class'].value_counts().reset_index().sort_values(by='max_class')




# max class 가 1인 학교의 평균 반차이를 1로 바꿔줌
school_info.loc[school_info['max_class'] == 1, 'avg_class_diff'] = 1




# max 반 번호마다의 평균 반 차이를 구함
# 높은 반 번호를 가질 수록 가짜 반일 확률이 높음
# 높은 반 번호일 수록 반 차이도 많이 날 것임 <- 가설
avg_per_max_num = []
for i in range(1, 21):
    avg = school_info[school_info['max_class'] == i]['avg_class_diff'].mean()
    avg_per_max_num.append(avg)

avg_per_max_df = pd.DataFrame({
    'class': np.arange(1, 21),
    'avg_per_max_num': avg_per_max_num
})

ax = sns.barplot(data=avg_per_max_df, x='class', y='avg_per_max_num')
ax.set_title('max_class에 따른 평균 반 차이')
plt.show()


# [user_properties]
# - 반이 20반까지 존재했음 (저출산 시대에 무슨 일)
# - 학교 별 평균 반 차이를 구했더니 15반부터 수치가 크게 올라감
# - <mark>15반 이상부터는 이상치가 확실하다고 볼 수 있을 듯 

# ## 2. votes

accounts_attendance = pd.read_csv('./dumps/votes_csv/accounts_attendance.csv')
accounts_blockrecord = pd.read_csv('./dumps/votes_csv/accounts_blockrecord.csv')
accounts_failpaymenthistory = pd.read_csv('./dumps/votes_csv/accounts_failpaymenthistory.csv')
accounts_friendrequest = pd.read_csv('./dumps/votes_csv/accounts_friendrequest.csv')

accounts_group = pd.read_csv('./dumps/votes_csv/accounts_group.csv')
accounts_nearbyschool = pd.read_csv('./dumps/votes_csv/accounts_nearbyschool.csv')
accounts_paymenthistory = pd.read_csv('./dumps/votes_csv/accounts_paymenthistory.csv')
accounts_pointhistory = pd.read_csv('./dumps/votes_csv/accounts_pointhistory.csv')

accounts_school = pd.read_csv('./dumps/votes_csv/accounts_school.csv')
accounts_timelinereport = pd.read_csv('./dumps/votes_csv/accounts_timelinereport.csv')
accounts_user_contacts = pd.read_csv('./dumps/votes_csv/accounts_user_contacts.csv')
accounts_user = pd.read_csv('./dumps/votes_csv/accounts_user.csv')

accounts_userquestionrecord = pd.read_csv('./dumps/votes_csv/accounts_userquestionrecord.csv')
accounts_userwithdraw = pd.read_csv('./dumps/votes_csv/accounts_userwithdraw.csv')
event_receipts = pd.read_csv('./dumps/votes_csv/event_receipts.csv')
events = pd.read_csv('./dumps/votes_csv/events.csv')

polls_question = pd.read_csv('./dumps/votes_csv/polls_question.csv')
polls_questionpiece = pd.read_csv('./dumps/votes_csv/polls_questionpiece.csv')
polls_questionreport = pd.read_csv('./dumps/votes_csv/polls_questionreport.csv')
polls_questionset = pd.read_csv('./dumps/votes_csv/polls_questionset.csv')
polls_usercandidate = pd.read_csv('./dumps/votes_csv/polls_usercandidate.csv')





#### 2-1. accounts_user


accounts_user.info()
accounts_user.head(5)




# gender, group_id에 NULL 있음
accounts_user.isnull().sum()


# NULL값인 유저들 2명 staff (gender, school_id 없음)
# 유저 1명은 school_id만 없네 -> 왜지?
accounts_user[accounts_user['group_id'].isnull()]


# 2023-07-18 ~ 2023-08-10
# 이 기간에 안 들어왔나봄
hackle_properties[hackle_properties['user_id'] == '995177']



# - 중복값 확인
columns = accounts_user.columns
columns = columns.drop('id')

# 중복값 없음 (id 제외)
# hackle에서 한 세션에서 여러 user_id가 발견됐었는데  
# 그냥 여러 친구들이 한 기종으로 로그인한듯 (추정)   
# 학교에서 폰 돌려보기?   
accounts_user[accounts_user[columns].duplicated(keep=False)]


# - 친구 수 분포 확인

def friend_counts_status(x):
    if x > 1000:
        return ('1001 ~')
    elif x > 500 and x <= 1000:
        return ('501 ~ 1000')
    elif x > 300 and x <= 500:
        return ('301 ~ 500')
    elif x > 100 and x <= 300:
        return ('101 ~ 300')
    elif x > 70 and x <= 100:
        return ('71 ~ 100')
    elif x > 50 and x <= 70:
        return ('51 ~ 70')
    elif x > 30 and x <= 50:
        return ('31 ~ 50')
    elif x > 10 and x <= 30:
        return ('11 ~ 30')
    else:
        return ('~ 10')
    
# 친구 이상치 확인
accounts_user['friend_id_list'] = accounts_user['friend_id_list'].apply(lambda x: ast.literal_eval(x))
accounts_user['friend_counts'] = accounts_user['friend_id_list'].apply(lambda x: len(x))

friend_counts = accounts_user[['id', 'friend_counts']]
friend_counts['friend_counts_status'] = friend_counts['friend_counts'].apply(lambda x: friend_counts_status(x))
friend_counts = friend_counts['friend_counts_status'].value_counts().reset_index()
idx_map = {
    '1001 ~': 1, '501 ~ 1000': 2, '301 ~ 500': 3, '101 ~ 300': 4, 
    '71 ~ 100': 5, '51 ~ 70': 6, '31 ~ 50': 7, '11 ~ 30': 8, 
    '~ 10': 9
}

# 친구 300명 이상부터 거의 유저 없음
# 친구 1000여명 넘어가는 유저는 이상치인가?
friend_counts['idx'] = friend_counts['friend_counts_status'].map(idx_map)
friend_counts.sort_values(by='idx', inplace=True)
friend_counts[['friend_counts_status', 'count']]




fig, axes = plt.subplots(1, 2, figsize=(10, 4))
ax1, ax2 = axes.flatten()

ax1 = sns.boxplot(data=accounts_user['friend_counts'], ax=ax1)
ax1.set_title('friend_counts 분포')

ax2.hist(accounts_user['friend_counts'], bins=100)
ax2.set_title('friend_counts 히스토그램')

plt.tight_layout()
plt.show()


# - 친구 수 이상치 기준 분석

q3 = accounts_user['friend_counts'].quantile(0.75)
q1 = accounts_user['friend_counts'].quantile(0.25)
iqr = q3 - q1

upper_bound = q3 + iqr * 1.5

# 이상치 경계 upper에서 128.5가 나옴
# 이상치를 가진 유저들은 전체의 약 2.4%정도 됨
upper_bound


len(accounts_user[accounts_user['friend_counts'] >= 128.5]) / len(accounts_user) * 100


# 친구 1000여명 넘어가는 유저(7명) 중
# 정지 먹은 유저가 있음 (id: 1192441) -> 보류
# RB
accounts_user[accounts_user['friend_counts'] >= 1000]


# - superuser 분석

# superuser인 유저 2명
# 그 중 한 명은 staff -> 이 사람은 제거 필요
# 나머지 한 명인 찐 superuser는 친구가 없네? -> 활동 패턴 확인 필요
accounts_user[accounts_user['is_superuser'] > 0]




# superuser 행동패턴 보려고 했더니
# hackle 데이터에 없음 -> hackle 기간 동안 활동 안 함 -> 지금보니 가입시기가 9월 23일! 없을만도!

# superuser인데 친구, 질문 수도 없고,
# 회원가입 때 받은 포인트 300밖에 없는 신규가입자 위치에서 벗어나지 않은듯
hackle_properties[hackle_properties['user_id'] == '1580626']


# superuser씨는 
# 출석도, 친구요청 활동도, 결제, 초대, 질문도 하지 않음
# 유령회원같음 -> staff ??
accounts_attendance[accounts_attendance['user_id'] == 1580626]
accounts_paymenthistory[accounts_paymenthistory['user_id'] == 1580626]

accounts_friendrequest[accounts_friendrequest['receive_user_id'] == 1580626] # 친구 요청받은 것도, 보낸 것도 없음
accounts_friendrequest[accounts_friendrequest['send_user_id'] == 1580626]

accounts_user_contacts[accounts_user_contacts['user_id'] == 1580626] 
accounts_user_contacts[accounts_user_contacts['invite_user_id_list'].apply(lambda x: '1580626' in x)] # 초대를 받지도, 초대를 하지도 않음
accounts_userquestionrecord[accounts_userquestionrecord['user_id'] == 1580626]



accounts_school.rename(columns={'id': 'school_id'}, inplace=True)
school_total_info = pd.merge(accounts_group, accounts_school, on='school_id', how='left')

# superuser의 학교 정보도 없음
school_total_info[school_total_info['id']==122]


# - staff 유저 분석

# staff인 유저 3명 -> 제거하면 될 듯
# staff 중 유일하게 친구를 만든 유저가 있네? (id: 831956)
 것으로 보아 정말 staff가 맞음 (또는 테스트 계정)
accounts_user[accounts_user['is_staff'] > 0]



# 831956 staff도 아무런 활동 기록이 없음 (출석도, 친구요청 활동도, 결제, 초대, 질문도 하지 않음)
accounts_attendance[accounts_attendance['user_id'] == 831956]
accounts_paymenthistory[accounts_paymenthistory['user_id'] == 831956]

accounts_friendrequest[accounts_friendrequest['receive_user_id'] == 831956] # 친구 요청받은 것도, 보낸 것도 없음
accounts_friendrequest[accounts_friendrequest['send_user_id'] == 831956]

accounts_user_contacts[accounts_user_contacts['user_id'] == 831956] 
accounts_user_contacts[accounts_user_contacts['invite_user_id_list'].apply(lambda x: '831956' in x)] # 초대를 받지도, 초대를 하지도 않음
accounts_userquestionrecord[accounts_userquestionrecord['user_id'] == 831956]


# staff의 친구들은 뭘까
staff_friends = accounts_user.iloc[0]['friend_id_list']
accounts_user[accounts_user['id'].isin(staff_friends)]


# staff 친구 중 유일하게 친구수가 3밖에 안되는 유저가 있음 (id: 1292473)
# 이 사람도 활동 기록 아예 없음
# 친구 요청 기록 딱 1개만 있음
accounts_attendance[accounts_attendance['user_id'] == 1292473]
accounts_paymenthistory[accounts_paymenthistory['user_id'] == 1292473]
accounts_friendrequest[accounts_friendrequest['receive_user_id'] == 1292473]

accounts_user_contacts[accounts_user_contacts['user_id'] == 1292473] 
accounts_user_contacts[accounts_user_contacts['invite_user_id_list'].apply(lambda x: '1292473' in x)] # 초대를 받지도, 초대를 하지도 않음
accounts_userquestionrecord[accounts_userquestionrecord['user_id'] == 1292473]

accounts_friendrequest[accounts_friendrequest['send_user_id'] == 1292473]  # 친구 요청을 한 기록


# 1292473의 학교 정보
# 학교 정보가 있긴 하지만,
# 딱히 큰 특징은 없음
school_total_info[school_total_info['id'] == 62370]


# 1292473 유저가 유일하게 친구 요청을 한 
# 1097845 유저의 학교 정보
# 그냥 같은 학교 출신이라 친구였는 듯 -> 별 의미 없었음
accounts_user[accounts_user['id'] == 1097845]
school_total_info[school_total_info['id'] == 17907]




# - point 분포 및 이상치 분석
# point Top 5
accounts_user[['id', 'gender', 'point', 'is_push_on', 'friend_counts', 'group_id', 'report_count', 'alarm_count', 'pending_chat', 'pending_votes']].sort_values(by='point', ascending=False).head(5)



# 출석 테이블의 출석일수 컬럼 추가
accounts_attendance['attendance_date_count'] = accounts_attendance['attendance_date_list'].apply(lambda x: len(ast.literal_eval(x)))
accounts_attendance


# 친구 요청, 구매, 초대, 질문 기록을 담은 df를 만들어주는 함수
def user_action(user_list):
    user_info = []
    for i in user_list:
        friend_receive = len(accounts_friendrequest[accounts_friendrequest['receive_user_id'] == i]) # 친구 요청 받은 수
        friend_send = len(accounts_friendrequest[accounts_friendrequest['send_user_id'] == i]) # 친구 요청한 수

        pay = len(accounts_paymenthistory[accounts_paymenthistory['user_id'] == i]) # 구매 이력

        invite = len(accounts_user_contacts[accounts_user_contacts['invite_user_id_list'].apply(lambda x: 'i' in x)]) # 초대 보냄
        invited = len(accounts_user_contacts[accounts_user_contacts['contacts_count'] == i]) # 초대 받음

        question_set = len(polls_questionset[polls_questionset['user_id'] == i]) # 참여한 질문 세트 수
        question = len(accounts_userquestionrecord[accounts_userquestionrecord['user_id'] == i]) # 참여한 질문 수

        report = len(accounts_timelinereport[accounts_timelinereport['user_id'] == i]) # 신고함
        reported = len(accounts_timelinereport[accounts_timelinereport['reported_user_id'] == i]) # 신고 받음 

        user_info.append([friend_receive, friend_send, 
                          pay, invited, invite, question_set, 
                          question, report, reported])
        
        user_df = pd.DataFrame({'user_id': user_list.tolist()})
        data_df = pd.DataFrame(user_info, columns=['friend_receive', 'friend_send', 'pay', 'invite', 'invited',
                                                   'question_set', 'question', 'report', 'reported'])
        result = user_df.join(data_df)
    return result


# point Top 5
# 제일 높은 포인트를 가진 유저의 하트 구매 -> 비싼 거(4000)로 2번이나 샀지만, 포인트가 너무 높다. -> 이상치 가능성

point_top10 = accounts_user.sort_values(by='point', ascending=False).head(10)[['id', 'point']]
point_top10.rename(columns={'id': 'user_id'}, inplace=True)

point_top10 = pd.merge(point_top10, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left')
data_df = user_action(point_top10['user_id'].unique())

pd.merge(point_top10, data_df, on='user_id', how='left')


hackle_properties[hackle_properties['user_id'] == '833041']


# 딱히 특별한 이벤트 키가 없음 -> 그럼 어떻게 저렇게 모았을까 -> 일단 보류...
hackle_events[hackle_events['session_id'] == 'NnVWxmwjHcfnMENN9y4SrTPfcG82']['event_key'].unique()


accounts_user['hide_user_count'] = accounts_user['hide_user_id_list'].apply(lambda x: len(ast.literal_eval(x)))
accounts_user['block_user_count'] = accounts_user['block_user_id_list'].apply(lambda x: len(ast.literal_eval(x)))

# 나머지 수치형 컬럼만 확인
columns = ['is_push_on', 'friend_counts', 'hide_user_count', 'block_user_count', 'report_count', 'alarm_count', 'pending_chat', 'pending_votes']
accounts_user[columns].describe()





# - hide 유저 수 분포 및 이상치 분석
ax = sns.boxplot(data=accounts_user['hide_user_count'])
ax.set_title('hide_user_count 분포')
plt.show()




# 숨김 처리만 왕창 해놨네

over_2000_hide = accounts_user[accounts_user['hide_user_count'] > 2000][['id', 'hide_user_count', 'block_user_count', 'report_count', 'friend_counts', 'point']]
over_2000_hide.rename(columns={'id': 'user_id'}, inplace=True)

over_2000_hide = pd.merge(over_2000_hide, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left').sort_values(by='hide_user_count', ascending=False)
over_2000_hide


hide_result = user_action(over_2000_hide['user_id'])

# 친목 활동만 했나봄
# 신고도 한번도 안했음
# 질문 기록이 없는데 포인트는 어케 많이 모았지
pd.merge(over_2000_hide[['user_id', 'hide_user_count', 'point']], hide_result, on='user_id', how='left')


# - block 유저 수 분포 및 이상치 분석



ax = sns.boxplot(data=accounts_user['block_user_count'])
ax.set_title('block_user_count 분포')
plt.show()




# 차단만 하고 친구는 없는 유저도 있음 (1등)
# 차단은 뭐 땜에 한거지

over_50_block = accounts_user[accounts_user['block_user_count'] > 50][['id', 'block_user_count', 'hide_user_count', 'report_count', 'friend_counts', 'point']]
over_50_block.rename(columns={'id': 'user_id'}, inplace=True)

over_50_block = pd.merge(over_50_block, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left').sort_values(by='block_user_count', ascending=False)
over_50_block




block_result = user_action(over_50_block['user_id'])

# 차단을 하면서 신고는 안했네
# 차단만 주구장창 한건가
# 아니면 조용히 차단만 하는 스타일?? -> 근데 질문 기록도 없는데 뭐지
pd.merge(over_50_block[['user_id', 'block_user_count', 'point']], block_result, on='user_id', how='left')


# - report 유저 수 분포 및 이상치 분석



ax = sns.boxplot(data=accounts_user['report_count'])
ax.set_title('report_count 분포')
plt.show()


# 신고 많이한 애들은 은근 출석을 많이 안 했네

over_50_report = accounts_user[accounts_user['report_count'] > 50][['id', 'report_count', 'block_user_count', 'hide_user_count', 'friend_counts', 'point']]
over_50_report.rename(columns={'id': 'user_id'}, inplace=True)

over_50_report = pd.merge(over_50_report, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left').sort_values(by='report_count', ascending=False)
over_50_report


report_result = user_action(over_50_report['user_id'])

# 신고 횟수는 높은데
# 막상 신고한 기록은 안남았음
# 뭐지??
pd.merge(over_50_report[['user_id', 'report_count', 'point']], report_result, on='user_id', how='left')


# - alarm 유저 수 분포 및 이상치 분석



ax = sns.boxplot(data=accounts_user['alarm_count'])
ax.set_title('alarm_count 분포')
plt.show()




def alarm_range_cal(x):
        if x > 100:
            return ('101 ~')
        elif x > 50 and x <= 100:
            return ('51 ~ 100')
        elif x > 30 and x <= 50:
            return ('31 ~ 50')
        elif x > 10 and x <= 30:
            return ('11 ~ 30')
        else:
            return ('~ 10')


alarm_range = accounts_user[['id', 'alarm_count']]
alarm_range['alarm_range'] = alarm_range['alarm_count'].apply(lambda x: alarm_range_cal(x))
alarm_range_counts = alarm_range['alarm_range'].value_counts().reset_index()

alarm_range_idx = {'101 ~': 1, '51 ~ 100': 2, '31 ~ 50': 3, '11 ~ 30': 4, '~ 10': 5}
alarm_range_counts['idx'] = alarm_range_counts['alarm_range'].map(alarm_range_idx)

# 알람 횟수 분포도 확인
alarm_range_counts.sort_values(by='idx')[['alarm_range', 'count']]


# 알람 횟수 900회부터 확 뜀
# 채팅을 안 봐서 알람 수가 많아진 듯 (TOP3 유저들 해당)
# 1등은 출석 데이터에 존재조차 없네
# 제일 알람 기록이 많았던 유저는 staff를 제외한 첫 유저인 듯. index가 1번임

over_100_alarm = accounts_user[accounts_user['alarm_count'] > 100][['id', 'alarm_count', 'pending_chat', 'pending_votes', 'point']]
over_100_alarm.rename(columns={'id': 'user_id'}, inplace=True)

over_100_alarm = pd.merge(over_100_alarm, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left').sort_values(by='alarm_count', ascending=False)
over_100_alarm


alarm_result = user_action(over_100_alarm['user_id'])


# 아니 알람 기록이 그렇게 많이 왔는데
# 질문 기록이 왜 없지???????????????????
# 포인트 9백만개??????????
pd.merge(over_100_alarm[['user_id', 'alarm_count', 'point']], alarm_result, on='user_id', how='left')


# - pending_chat 수 분포 및 이상치 분석



ax = sns.boxplot(data=accounts_user['pending_chat'])
ax.set_title('pending_chat 분포')
plt.show()




def pending_chat_range_cal(x):
        if x > 100:
            return ('101 ~')
        elif x > 50 and x <= 100:
            return ('51 ~ 100')
        elif x > 30 and x <= 50:
            return ('31 ~ 50')
        elif x > 10 and x <= 30:
            return ('11 ~ 30')
        else:
            return ('~ 10')


pending_chat_range = accounts_user[['id', 'pending_chat']]
pending_chat_range['pending_chat_range'] = pending_chat_range['pending_chat'].apply(lambda x: pending_chat_range_cal(x))
pending_chat_counts = pending_chat_range['pending_chat_range'].value_counts().reset_index()

pending_chat_idx = {'101 ~': 1, '51 ~ 100': 2, '31 ~ 50': 3, '11 ~ 30': 4, '~ 10': 5}
pending_chat_counts['idx'] = pending_chat_counts['pending_chat_range'].map(pending_chat_idx)

# 대기중인 채팅 수 분포도 확인
pending_chat_counts.sort_values(by='idx')[['pending_chat_range', 'count']]




# 알람 TOP3 가 그대로 있음
# 이 3명의 유저는 활동을 접었거나 
# 채팅을 잘 보지 않는 타입이거나 
# 알람을 확인 안 하는 타입이거나
over_100_pending_chat = accounts_user[accounts_user['pending_chat'] > 100][['id', 'pending_chat', 'alarm_count', 'point']].sort_values(by='pending_chat', ascending=False)
over_100_pending_chat.rename(columns={'id': 'user_id'}, inplace=True)

over_100_pending_chat = pd.merge(over_100_pending_chat, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left').sort_values(by='pending_chat', ascending=False)
over_100_pending_chat




pending_chat_result = user_action(over_100_pending_chat['user_id'])

# 대기중인 채팅이 많은 유저들도
# 질문 기록이 없음
# 아니 왜ㅐㅐㅐㅐㅐㅐㅐ
pd.merge(over_100_pending_chat[['user_id', 'pending_chat', 'point']], pending_chat_result, on='user_id', how='left')


# - pending_votes 수 분포 및 이상치 분석



ax = sns.boxplot(data=accounts_user['pending_votes'])
ax.set_title('pending_votes 분포')
plt.show()




def pending_chat_range_cal(x):
        if x > 2000:
            return ('2001 ~')
        elif x > 1000 and x <= 2000:
            return ('1001 ~ 2000')
        elif x > 500 and x <= 1000:
            return ('501 ~ 1000')
        elif x > 300 and x <= 500:
            return ('301 ~ 500')
        elif x > 100 and x <= 300:
            return ('101 ~ 300')
        elif x > 50 and x <= 100:
            return ('51 ~ 100')
        elif x > 10 and x <= 50:
            return ('11 ~ 50')
        else:
            return ('~ 10')


pending_votes_range = accounts_user[['id', 'pending_votes']]
pending_votes_range['pending_votes_range'] = pending_votes_range['pending_votes'].apply(lambda x: pending_chat_range_cal(x))
pending_votes_counts = pending_votes_range['pending_votes_range'].value_counts().reset_index()

pending_votes_idx = {'2001 ~': 1, '1001 ~ 2000': 2, '501 ~ 1000': 3, '301 ~ 500': 4, '101 ~ 300': 5,
                     '51 ~ 100': 6, '11 ~ 50': 7, '~ 10': 8}
pending_votes_counts['idx'] = pending_votes_counts['pending_votes_range'].map(pending_votes_idx)

# 대기중인 채팅 수 분포도 확인
pending_votes_counts.sort_values(by='idx')[['pending_votes_range', 'count']]




# pending_vote가 많아도 알람, 채팅 수에는 영향을 별로 안 주나?
# 여전히 출석 기록 조차 없는 유저가 있음 (1등)

over_100_pending_votes = accounts_user[accounts_user['pending_votes'] > 2000][['id', 'pending_votes', 'alarm_count', 'pending_chat', 'point']]
over_100_pending_votes.rename(columns={'id': 'user_id'}, inplace=True)

over_100_pending_votes = pd.merge(over_100_pending_votes, accounts_attendance[['user_id', 'attendance_date_count']], on='user_id', how='left').sort_values(by='pending_votes', ascending=False)
over_100_pending_votes




pending_votes_result = user_action(over_100_pending_votes['user_id'])

# 왜 이렇게 질문 기록이 없지?!?!?!?
pd.merge(over_100_pending_votes[['user_id', 'pending_votes', 'point']], pending_votes_result, on='user_id', how='left')


# 하도 활동기록들이 안나와서 테이블 별 유저수를 봐야겠음
# 얼마나 기록을 안했길래 각 컬럼별 상위권 유저들이 안나오는거지???

# accounts_friendrequest['receive_user_id']              친구 요청 받은 수
# accounts_friendrequest['send_user_id']                 친구 요청한 수
# accounts_paymenthistory['user_id']                     구매 이력
# accounts_user_contacts['invite_user_id_list']          초대 보냄
# accounts_user_contacts['contacts_count']               초대 받음
# polls_questionset['user_id']                           참여한 질문 세트 수
# accounts_userquestionrecord['user_id']                 참여한 질문 수
# accounts_timelinereport['user_id']                     신고함
# accounts_timelinereport['reported_user_id']            신고 받음 


texts = ['친구 요청 받은 유저', '친구 요청한 유저', '구매 이력 유저', '초대 보낸 유저', '초대 기록에 있는 유저', 
           '참여한 질문 세트가 있는 유저', '참여한 질문이 있는 유저', '신고한 유저', '신고 받은 유저']

total_list = [len(accounts_friendrequest),
            len(accounts_friendrequest),            
            len(accounts_paymenthistory),                    
            len(accounts_user_contacts),       
            len(accounts_user_contacts),              
            len(polls_questionset),                  
            len(accounts_userquestionrecord),             
            len(accounts_timelinereport),                  
            len(accounts_timelinereport)]

data_list = [accounts_friendrequest['receive_user_id'].nunique(),
            accounts_friendrequest['send_user_id'].nunique(),            
            accounts_paymenthistory['user_id'].nunique(),                    
            accounts_user_contacts['invite_user_id_list'].apply(ast.literal_eval).explode().nunique(),       
            accounts_user_contacts['user_id'].nunique(),              
            polls_questionset['user_id'].nunique(),                  
            accounts_userquestionrecord['user_id'].nunique(),             
            accounts_timelinereport['user_id'].nunique(),                  
            accounts_timelinereport['reported_user_id'].nunique()]

check_num = pd.DataFrame({
    'text': texts, 
    'origin': total_list,
    'nunique': data_list
})

# 기록 인원이 너무 적어서 안 나올만 한건가?
# 기록은 왜 잘 안되어있을까
# 서버 문제?? 메모리 문제?? 진짜 활동을 많이 안한 것??
check_num['account_rate'] = check_num['nunique'] / len(accounts_user)
check_num


# [account_user]
# - <mark>id를 user_id로 미리 변경하면 다른 테이블과 merge하기 편할 듯
# - 결측값 있지만 1명 빼고 모두 staff -> <mark>제거해도 될 듯   
# 
# 	- 나머지 1명은 학교 기록이 없음 -> <mark>처리 방향 의논 필요
# - superuser 중 일반기록, staff 기록 딱 1개씩 있음
# 	- superuser는 신규가입자마냥 활동기록이 없음 -> <mark>처리 방향 의논 필요
# - 친구 수, 숨김처리 수, 차단 수, 신고 수, 알람 수, 채팅 대기 수, 질문 대시 수 모두 <mark>앱 활동기록이 0에 가까움   
# 
# 	-> 알고보니, 활동 기록에 유저 수가 매우 적게 기록되어 있음   
# 	-> 서버 문제?? 메모리 문제?? 진짜 활동을 많이 안한 것??
# - 포인트는 질문 완료 시 200p씩 받는다고 나와있지만(from. 피그마) 습득 기록이 명확하지 않음
# - 그리고, 포인트의 이상치가 비정상적으로 높은 유저들이 존재    
# 	-> <mark>user_id 당 총 구매 금액보다 높으면 이상치로 볼지 or 그대로 놔둘지      
# 
# 	-> <mark>처리 방향 의논 필요   

# ### 2-2. accounts_userquestionrecord

# - 결측값 확인

# 결측값 없음
accounts_userquestionrecord.info()


accounts_userquestionrecord.head(5)


# - 중복값 확인

columns = accounts_userquestionrecord.columns
columns = columns.drop('id')

# 중복값 없음 (id 제외)
accounts_userquestionrecord[accounts_userquestionrecord[columns].duplicated(keep=False)]


# - 답변 시간대 그래프


# datetime형으로 바꾸기
accounts_userquestionrecord['answer_updated_at'] = pd.to_datetime(accounts_userquestionrecord['answer_updated_at'])

accounts_userquestionrecord['answer_updated_date'] = accounts_userquestionrecord['answer_updated_at'].dt.date
accounts_userquestionrecord['answer_updated_time'] = accounts_userquestionrecord['answer_updated_at'].dt.hour



# 시간대 확인
# 확실히 한국인의 활동 시간대와는 다른 양상을 보인다
# 제일 활발해야 하는 저녁 시간대가 수치가 매우 낮음 -> UTC 시간대인 것으로 추정!
time_counts = accounts_userquestionrecord['answer_updated_time'].value_counts().reset_index(name='time_counts')
ax = sns.lineplot(data=time_counts, x='answer_updated_time', y='time_counts')
ax.set_xticks(range(0, 24))
ax.set_xlabel('시간대')
ax.set_title('답변 완료 시간대')


# KST시간대로 변경
accounts_userquestionrecord['answer_updated_KST'] = accounts_userquestionrecord['answer_updated_at'] + timedelta(hours=9)

accounts_userquestionrecord['answer_updated_date'] = accounts_userquestionrecord['answer_updated_KST'].dt.date
accounts_userquestionrecord['answer_updated_time'] = accounts_userquestionrecord['answer_updated_KST'].dt.hour

accounts_userquestionrecord[['answer_updated_at', 'answer_updated_KST', 'answer_updated_date', 'answer_updated_time']]


time_counts = accounts_userquestionrecord['answer_updated_time'].value_counts().reset_index(name='time_counts')

# 학교 등교하면서 잠깐 했다가
# 학교 수업 시간 시작(1교시 9시)에 맞춰서 확 사그러들었다
# 점점 증가하는 추세를 볼 수 있음
ax = sns.lineplot(data=time_counts, x='answer_updated_time', y='time_counts')
ax.set_xticks(range(0, 24))
ax.set_xlabel('시간대')
ax.set_title('답변 완료 시간대(KST)')


# - has_read, answer_status 분석


cond1 = accounts_userquestionrecord['has_read'] == 0
cond2 = accounts_userquestionrecord['answer_status'] == 'N'

# 읽지도 않고, 답변도 하지 않았는데 선택된 유저 id에 NULL이 없음 -> 답변으로 채택된 유저들이 있다는 의미!
# has_read, answer_status는 채팅에 대한 내용이지 않을까? (추정)
accounts_userquestionrecord[cond1 | cond2]['chosen_user_id'].isnull().sum()



# has_read, answer_status 비율 확인
# 거의 대부분이 미답변, 절반 정도 읽지 않음 -> 질문에 대한 내용 아님!!
has_read_counts = accounts_userquestionrecord['has_read'].value_counts().reset_index()
has_read_map = {0: '읽지 않음', 1: '읽음'}
has_read_counts['has_read'] = has_read_counts['has_read'].map(has_read_map)

answer_status_counts = accounts_userquestionrecord['answer_status'].value_counts().reset_index()
answer_status_map = {'N': '미답변', 'P': '비공개', 'A': '공개'}
answer_status_counts['answer_status'] = answer_status_counts['answer_status'].map(answer_status_map)

fig, axes = plt.subplots(1, 2, figsize=(10, 5))
ax1, ax2 = axes

ax1.pie(x=has_read_counts['count'], labels=has_read_counts['has_read'], autopct= '%.f%%', colors=sns.set_palette('pastel'))
ax1.set_title('has_read 비율 (전체)')

ax2.pie(x=answer_status_counts['count'], labels=answer_status_counts['answer_status'], autopct= '%.f%%', colors=sns.set_palette('pastel'))
ax2.set_title('answer_status 비율 (전체)')

plt.show()


# - 초성 열은 질문 분석

# 뭐가 그렇게 흥미로운 질문이었길래 초성을 열었을까
# 호감을 드러내는 질문에 많은 관심을 보였음
# vote는 뭐지?? 커스텀 질문내용인가? -> 아닌거로!!
# 커스텀 질문들은 그냥 텍스트로 이미 포함되어 있다고 함! 

open_hint = accounts_userquestionrecord[accounts_userquestionrecord['status'] == 'I']
polls_question.rename(columns={'id': 'question_id'}, inplace=True) # id 컬럼명을 question_id로 바꿔줌
open_hint = pd.merge(open_hint, polls_question, on='question_id', how='left')
open_hint.isnull().sum() # merge하고서 결측치 없음

open_hint['question_text'].value_counts().reset_index()


# 전체 질문 활동 기록에서도 vote가 제일 많네
# vote는 뭐지...?  ->  보류
a = accounts_userquestionrecord['question_id'].value_counts().reset_index()
a = pd.merge(accounts_userquestionrecord, polls_question, on='question_id', how='left')
a['question_text'].value_counts().reset_index()


# 확실히 초성을 확인한 유저들의 채팅 활동성이 높았음
# status = C, B를 확인한 결과 
# has_read의 비율은 반반이었고, 미답변 비율은 90%가 넘어감

has_read_counts = open_hint['has_read'].value_counts().reset_index()
has_read_map = {0: '읽지 않음', 1: '읽음'}
has_read_counts['has_read'] = has_read_counts['has_read'].map(has_read_map)

answer_status_counts = open_hint['answer_status'].value_counts().reset_index()
answer_status_map = {'N': '미답변', 'P': '비공개', 'A': '공개'}
answer_status_counts['answer_status'] = answer_status_counts['answer_status'].map(answer_status_map)

fig, axes = plt.subplots(1, 2, figsize=(10, 5))
ax1, ax2 = axes

ax1.pie(x=has_read_counts['count'], labels=has_read_counts['has_read'], autopct= '%.f%%', colors=sns.set_palette('pastel'))
ax1.set_title('has_read 비율 (초성 open 질문)')

ax2.pie(x=answer_status_counts['count'], labels=answer_status_counts['answer_status'], autopct= '%.f%%', colors=sns.set_palette('pastel'))
ax2.set_title('answer_status 비율 (초성 open 질문)')

plt.show()


# 최대 3번까지 같은 질문을 열었음 -> 이상치 없음
accounts_userquestionrecord['opened_times'].max()

# 초성을 연 질문들은 유저의 관심도가 높음
accounts_userquestionrecord.groupby('status')['opened_times'].mean().reset_index()


# - 신고횟수 분석

# 신고횟수는 0, 1에 몰려있음
# 2번 이상부터는 거의 없음
# 밑의 히스토그램은 2 이상부터 일부터 잘라서 봄 (0, 1 포함하면 안보여서)
plt.hist(x=accounts_userquestionrecord[accounts_userquestionrecord['report_count'] > 1]['report_count'], bins=15)
plt.show()


# 신고횟수 최대 14번 -> 이상치인가?
# 신고 내용 확인
max_userquestionrecord = accounts_userquestionrecord[accounts_userquestionrecord['report_count'] == 14]
max_userquestionrecord_id = max_userquestionrecord['id'].unique()
a = accounts_timelinereport[accounts_timelinereport['user_question_record_id'].isin(max_userquestionrecord_id)]

max_userquestionrecord.rename(columns={'id': 'user_question_record_id'}, inplace=True)
a = pd.merge(a[['reason', 'created_at', 'reported_user_id', 'user_id', 'user_question_record_id']], 
             max_userquestionrecord[['user_question_record_id', 'status', 'chosen_user_id', 'user_id', 'question_id', 'has_read', 'answer_status', 'opened_times']], 
             on='user_question_record_id', how='left')
a = pd.merge(a[['reason', 'created_at', 'reported_user_id', 'user_id_x', 'status', 'chosen_user_id', 'user_id_y', 'question_id', 'has_read', 'answer_status', 'opened_times']], 
             polls_question[['question_id', 'question_text']], 
             on='question_id', how='left')
a.rename(columns={'reported_user_id': '신고받은 사람', 'user_id_x': '신고한 사람', 
                  'chosen_user_id': '질문 채택된 사람', 'user_id_y': '답변한 사람'}, inplace=True)

# 질문 답변한 사람이 오히려 신고했음 (신고 당한게 아님!)
# 질문 오픈 횟수는 0번이고,
# 채팅 읽음, 답변 공개한 내용을 보아
# 채팅으로 둘이 얘기하다가 신고한 듯   ->   14번 신고는 이상치가 아닌거로!
a


# [accounts_userquestionrecord]
# - 시간대가 UTC로 되어있음 -> <mark>KST로 변경해야 할 듯
# - has_read, answer_status는 질문에 대한 컬럼이 아니라 채팅에 대한 내용으로 추정
# - 질문자 힌트를 사용한 유저들의 채팅 활동성이 높았음
# - 한 사람이 동일인물을 여러번 신고 가능
# - 제일 많이 신고한 질문과 질문자, 답변자를 분석한 결과 채팅 과정에서 이루어진 것으로 보임 -> <mark>신고 수 이상치로 보기는 힘듦 






#### 2-3. accounts_userwithdraw
accounts_userwithdraw.info()
accounts_userwithdraw.head(5)



# 결측값 없음
accounts_userwithdraw.isnull().sum()


# - 중복값 확인
columns = accounts_userwithdraw.columns
columns = columns.drop('id')

accounts_userwithdraw[accounts_userwithdraw[columns].duplicated(keep=False)]




accounts_userwithdraw[accounts_userwithdraw[columns].duplicated(keep='first')]


# 최대 3번까지 찍힌 로그가 찍힘
a = accounts_userwithdraw[accounts_userwithdraw[columns].duplicated(keep=False)]
a.groupby(['reason', 'created_at'])['id'].count().reset_index(name='count').sort_values(by='count', ascending=False)


# [accounts_userwithdraw]
# - 중복값 있음 -> <mark>keep='first'로 보면 될듯




#### 2-4. event_receipts & events
event_receipts.info()
event_receipts.head(5)


# - 결측치 확인

# 결측치 없음
event_receipts.isnull().sum()


# - 중복값 확인


# 중복값 없음
columns = event_receipts.columns
columns = columns.drop('id')

event_receipts[event_receipts[columns].duplicated(keep=False)]



events.info()



events


# id -> event_id로 컬럼명 변경
events.rename(columns={'id': 'event_id'}, inplace=True)



total_events = pd.merge(event_receipts, events[['event_id', 'title', 'event_type']], on='event_id', how='left')

# 합치면서 NULL 값 없음
total_events.isnull().sum()
total_events


# - 각 event 별 참여 시간 이상치 확인



# event_id = 1인 이벤트는
# 2023-06-22 ~ 2023-07-31 까지 진행

event_1 = total_events[total_events['event_id'] == 1]['created_at'].sort_values()
event_1.head(1), event_1.tail(1)




# 2023-08-08 ~ 2023-08-20
event_2 = total_events[total_events['event_id'] == 2]['created_at'].sort_values()
event_2.head(1), event_2.tail(1)


# 3개의 이벤트 모두 이벤트 시작 시간 이전에 기록된 건 없음
# 2023-09-27 ~ 2023-11-21
event_3 = total_events[total_events['event_id'] == 3]['created_at'].sort_values()
event_3.head(1), event_3.tail(1)




event_per_user = total_events.groupby(['event_id', 'user_id'])['title'].count().reset_index(name='count').sort_values(by='count', ascending=False)
event_1 = event_per_user[event_per_user['event_id'] == 1] 
event_2 = event_per_user[event_per_user['event_id'] == 2]  
event_3 = event_per_user[event_per_user['event_id'] == 3]  

# 각 이벤트 별 참여한 인원 수
nums = [len(event_1), len(event_2), len(event_3)]

for i, num in zip(range(len(events)), nums):
    print(f'{events.iloc[i]["title"]}: {num}명')


# - event_type 고유값 확인

# FCFS: 선착순 참여
total_events['event_type'].unique()


# - event 참여 횟수 분포 확인

# 한 이벤트를 2번 참여한 유저
accounts_user[accounts_user['id'] == 1577954]


# [event_receipts & events]
# - <mark>id를 event_id로 변경하면 좋을 듯
# - 참여 시간 이상치(이벤트 시작 전으로 찍힌 로그)는 없었음

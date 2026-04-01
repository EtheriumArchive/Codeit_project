#!/usr/bin/env python
# coding: utf-8

# # 1. 환경설정

# In[2]:


import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import koreanize_matplotlib
import seaborn as sns



# In[3]:


# 지수표현 없애기
pd.options.display.float_format = '{:.2f}'.format


# # 2. 데이터 불러오기
# 

# In[4]:


hackle_device_path = 'dumps/hackle_csv/device_properties.csv'
hackle_events_path = 'dumps/hackle_csv/hackle_events.csv'
hackle_prop_path = 'dumps/hackle_csv/hackle_properties.csv'
hackle_user_path = 'dumps/hackle_csv/user_properties.csv'


# In[5]:


raw_hackle_device = pd.read_csv(hackle_device_path)
raw_hackle_events = pd.read_csv(hackle_events_path)
raw_hackle_propeties = pd.read_csv(hackle_prop_path)
raw_hackle_user = pd.read_csv(hackle_user_path, dtype={0: str})


# In[340]:


attendance_path = 'dumps/vote_csv/accounts_attendance.csv'
blockrecord_path = 'dumps/vote_csv/accounts_blockrecord.csv'
failpayment_path = 'dumps/vote_csv/accounts_failpaymenthistory.csv'
friendrequest_path = 'dumps/vote_csv/accounts_friendrequest.csv'
group_path = 'dumps/vote_csv/accounts_group.csv'
nearbyschool_path = 'dumps/vote_csv/accounts_nearbyschool.csv'
payment_path = 'dumps/vote_csv/accounts_paymenthistory.csv'
point_path = 'dumps/vote_csv/accounts_pointhistory.csv'
school_path = 'dumps/vote_csv/accounts_school.csv'
timeline_path = 'dumps/vote_csv/accounts_timelinereport.csv'
user_contacts_path = 'dumps/vote_csv/accounts_user_contacts.csv'
vote_user_path = 'dumps/vote_csv/accounts_user.csv'
user_question_path = 'dumps/vote_csv/accounts_userquestionrecord.csv'
userwithdraw_path = 'dumps/vote_csv/accounts_userwithdraw.csv'
vote_event_receipts_path = 'dumps/vote_csv/event_receipts.csv'
vote_events_path = 'dumps/vote_csv/events.csv'
polls_question_path = 'dumps/vote_csv/polls_question.csv'
polls_question_piece_path = 'dumps/vote_csv/polls_questionpiece.csv'
polls_question_report_path = 'dumps/vote_csv/polls_questionreport.csv'
polls_questionset_path = 'dumps/vote_csv/polls_questionset.csv'
polls_user_candidate_path = 'dumps/vote_csv/polls_usercandidate.csv'


# In[341]:


raw_attendance = pd.read_csv(attendance_path)
raw_blockrecord = pd.read_csv(blockrecord_path)
raw_failpayment = pd.read_csv(failpayment_path)
raw_friendrequest = pd.read_csv(friendrequest_path)
raw_group = pd.read_csv(group_path)
raw_nearbyschool = pd.read_csv(nearbyschool_path)
payment_path = pd.read_csv(payment_path)
raw_point = pd.read_csv(point_path)
raw_school = pd.read_csv(school_path)
raw_timeline = pd.read_csv(timeline_path)
raw_user_contacts = pd.read_csv(user_contacts_path)
raw_vote_user = pd.read_csv(vote_user_path)
raw_user_question = pd.read_csv(user_question_path)
raw_userwithdraw = pd.read_csv(userwithdraw_path)
raw_vote_event_recipts = pd.read_csv(vote_event_receipts_path)
raw_vote_events = pd.read_csv(vote_events_path)
raw_polls_question = pd.read_csv(polls_question_path)
raw_polls_question_piece = pd.read_csv(polls_question_piece_path)
raw_polls_question_report = pd.read_csv(polls_question_report_path)
raw_polls_questionset = pd.read_csv(polls_questionset_path)
raw_polls_user = pd.read_csv(polls_user_candidate_path)


# # 3. 데이터 확인

# ## 3-1. hackle table

# ### 3-1-1. 기기 설정

# In[8]:


raw_hackle_device.head()


# In[9]:


# 결측치 없음
raw_hackle_device.info()


# In[10]:


# 전체중복값은 없음
raw_hackle_device.duplicated().sum()


# In[11]:


# device_id 고유값이 다르다 = 중복값이 있다!
raw_hackle_device['device_id'].nunique()


# In[12]:


# device 중복행 660개
raw_hackle_device['device_id'].duplicated().sum()


# In[13]:


# 기기가 바뀌었음. 모델은 상관 없으니까 keep=last로 남겨도 되나?
raw_hackle_device[raw_hackle_device['device_id'].duplicated(keep=False)].sort_values(by=['device_id', 'id']).head(10)


# In[14]:


device_id_count = raw_hackle_device.groupby(by='device_id').agg(id_count=('id', 'count')).reset_index()
one_device_more_id = device_id_count['id_count'] > 1
print(f"device_id 최대 중복횟수 : {device_id_count[one_device_more_id]['id_count'].max()}회")
# 기기가 바뀐 이력은 최대 1번
# 그냥 keep=last 하면 될듯!


# In[15]:


raw_hackle_device['device_model'].nunique()


# ### 3-1-2. 해클 속성
# 

# In[16]:


# hackle table merge
raw_hackle_merge = pd.merge(raw_hackle_propeties, raw_hackle_events, on='session_id')


# In[17]:


raw_hackle_propeties.info()


# In[18]:


raw_hackle_propeties.describe()


# In[19]:


# 전체 중복행 없음
raw_hackle_propeties.duplicated().sum()


# In[20]:


# 행은 50만개인데 session은 27만개
# 이게 이상해서 찾기 시작한건데 생각해보니까 당연함.. session 내에 이벤트로그마다 행이 찍혔을테니까..ㅋㅎㅋㅎ
raw_hackle_propeties['session_id'].duplicated().sum()


# In[21]:


# 다 똑같은데 왜 user_id가 두개지..? #id 282908, 518234
raw_hackle_propeties[raw_hackle_propeties['session_id'].duplicated(keep=False)].sort_values(by=['session_id', 'id']).head(10)


# In[22]:


# 핸드폰도 안바꿨음 ..
raw_hackle_device[raw_hackle_device['device_id'] == '00057831-A672-4163-9C02-AB920A371F2C']


# In[23]:


# hackle event 안에서 서치..
userid_duplicated_in_merge = raw_hackle_merge[raw_hackle_merge['session_id'] == '00057831-A672-4163-9C02-AB920A371F2C']
userid_duplicated_in_merge.sort_values(by='event_datetime')[['event_datetime', 'user_id', 'osname', 'osversion', 'versionname', 'device_id', 'event_key', 'question_id']].head(30)


# In[24]:


# 완전히 중복된 로그.. 아오
userid_duplicated_in_merge.groupby(by='user_id').agg(count=('event_key', 'count'))


# In[25]:


# 행동에 이상은 없어보임
userid_duplicated_in_merge['event_key'].unique()


# - 미치겠네 urser_id 중복 상상도못한 정체; 이걸 어케찾지

# In[26]:


# 하나의 session_id에 user_id가 2개 이상인 경우는 몇 건인지?
# 2만건은 잘못 계산했던거..
session_duplicated_user = raw_hackle_merge.groupby(by='session_id').agg(user_count=('user_id', 'nunique')).reset_index().sort_values(by='user_count', ascending=False)
sdu_cond1 = session_duplicated_user['user_count'] > 1
session_duplicated_user[sdu_cond1]


# In[27]:


# 한 session에 user_id가 5개?
userid_duplicated_in_merge = raw_hackle_merge[raw_hackle_merge['session_id'] == '040914e1-61ac-40ef-b76a-718066d880dc']
userid_duplicated_in_merge.sort_values(by='event_datetime')[['event_datetime', 'user_id', 'osname', 'osversion', 'versionname', 'device_id', 'event_key']].head(30)


# In[28]:


userid_duplicated_in_merge.groupby(by='user_id').agg(count=('event_key', 'count'))


# - 같은 로그가 버전별로(2.0.3, 2.0.5) 남기도 하고, 결측치로 남기도 하고..난리브루스네
# - 이러면 hackle_events에서 결측치가 비회원일거라는 보장도 없음
# - android랑 ios의 차이도 있나?

# In[29]:


# 한 session_id에서 여러개의 user_id가 있는 중복 로그로 추정되는 로그들의 기기는 ios가 더 많았다.
session_duplicated_user_list = session_duplicated_user[sdu_cond1]['session_id'].unique()
filtered_session_duplicated_user = raw_hackle_merge[raw_hackle_merge['session_id'].isin(session_duplicated_user_list)]
session_os_info = filtered_session_duplicated_user.drop_duplicates('session_id', keep='last')
session_os_info['osname'].value_counts()


# In[30]:


# 그럼 앱 버전은?
# ['versionname'].value_counts()
# 이건.. 모르겠네요 ..


# - user_id를 하나만 남기는 방법이 뭐가 있을까
# - 한 session_id 내에서 device_id를 기준으로 event_key가 가장 많이 찍힌 user_id만 남긴다?

# In[31]:


# 내부데이터 중 유저아이디랑 비교
print(f"내부데이터 유저아이디 행: {len(raw_vote_user)}")
print(f"내부데이터 유저아이디 고유값: {raw_vote_user['id'].nunique()}")


# In[32]:


raw_vote_user.duplicated().sum()


# In[33]:


raw_vote_user.describe()


# In[34]:


raw_vote_user['id'].info()


# In[35]:


raw_vote_user['id'] = raw_vote_user['id'].astype(str)


# In[36]:


raw_vote_user['id'].info()


# In[37]:


# 내부데이터의 user list 추출해서 hackle event에 필터링
vote_user_list = raw_vote_user['id'].unique()
duple_user_condition = raw_hackle_merge['user_id'].isin(vote_user_list)
filtered_hackle_merge = raw_hackle_merge[duple_user_condition] # 필터링된 hackle 속성&이벤트 merge dataframe
print(f"내부데이터로 필터링된 hackle 이벤트 유저아이디 고유값: {filtered_hackle_merge['user_id'].nunique()}")


# In[38]:


filtered_hackle_merge.head()


# In[39]:


filtered_session_duplicated_user = filtered_hackle_merge.groupby(by='session_id').agg(user_count=('user_id', 'nunique')).reset_index().sort_values(by='user_count', ascending=False)
filtered_sdu_cond1 = filtered_session_duplicated_user['user_count'] > 1
filtered_hackle_merge_duplicated_user = filtered_session_duplicated_user[filtered_sdu_cond1]
print(f"필터링된 해클 이벤트에서 한 세션당 여러개의 유저아이디를 가진 세션 개수: {len(filtered_hackle_merge_duplicated_user)}")


# In[40]:


filtered_hackle_merge_duplicated_user.head(10)
# 가장 많았던 5건은 그대로 있음. 동시로그가 많이 찍혔던거라 에러가 맞음!


# In[41]:


# 한 session_id에 user_id 3개 기록된 내용
userid_duplicated_in_merge = filtered_hackle_merge[filtered_hackle_merge['session_id'] == 'B941F9F9-CF53-4DAE-A204-75E666B5D277']
userid_duplicated_in_merge.sort_values(by='event_datetime')[['event_datetime', 'user_id', 'osname', 'osversion', 'versionname', 'device_id', 'event_key']].head(30)


# In[42]:


userid_duplicated_in_merge.groupby(by='user_id').agg(count=('event_key', 'count'))


# - 하나의 세션에 여러개의 유저아이디가 기록된건 대부분 에러인 것으로 추정.
# - 내부데이터에도 중복기재된 아이디이기때문에 이 아이디 목록은 내부데이터에서도 삭제할 필요 있음

# In[43]:


# vote table user list로 필터링 & 중복 오류 포함된 session_id 제거한 hackle_merge dataframe 생성(= 전처리)
error_session_list = filtered_hackle_merge_duplicated_user['session_id'].unique()
processed_hackle_merge = filtered_hackle_merge[~filtered_hackle_merge['session_id'].isin(error_session_list)].reset_index(drop=True)


# In[44]:


print(f"1️⃣ raw data version count\
      \n {raw_hackle_merge['versionname'].value_counts()}")
print('-' * 10)


# In[45]:


print(f"2️⃣ filtered version count\
      \n {filtered_hackle_merge['versionname'].value_counts()}")
print('-' * 10)
print(f"3️⃣ processed version count\
      \n {processed_hackle_merge['versionname'].value_counts()}")


# ### 3-1-3. 해클 이벤트

# In[46]:


raw_hackle_events.info()


# In[47]:


raw_hackle_events.head()


# ## 3-2. vote table

# - hackle_event에서 이상치가 컸던 heart_balance의 확인을 위해 vote_table의 구매이력 확인
# - 오류 방지를 위해 위에서 계산한 user_id filter 먼저 수행

# ### 3-2-1. 유저

# In[48]:


# hackle에서 삭제한 session_id에 해당하는 user_id 제거
duplicated_session_list = filtered_hackle_merge_duplicated_user['session_id'].unique()


# ### 3-2-2. 유저 컨택

# In[49]:


raw_user_contacts.info()


# In[50]:


raw_user_contacts.head()


# In[51]:


raw_user_contacts.describe()


# In[52]:


raw_user_contacts.isna().sum()


# In[53]:


# 이 전화번호를 초대했던 유저 아이디 고유값
# 928명이 초대를 했었다?
raw_user_contacts['invite_user_id_list'].nunique()


# In[54]:


raw_user_contacts['invite_user_id_list'].explode().nunique()


# - list 안에 있는 객체들을 nunique로 셀 수 있는건가? -> 아님! 셀 수 없음! 하나의 리스트를 통으로 구분!
# - explode()로 객체들을 끊어서 구분 할 수 있게 만들고 unique를 집계해야함
# - 둘 다 928로 값이 똑같음? info에 문자열로 기재되어있으면 리스트인척 하는 문자열인건가?

# In[55]:


print(type(raw_user_contacts['invite_user_id_list'].iloc[2])) 


# In[56]:


# 리스트 같은 모양으로 구성된 문자열을 진짜 리스트로 변환
# 파이썬 내장 라이브러리 ast.literal_eval
# 문자열로 된 파이썬 구조(리스트, 딕셔너리 등)를 실제 객체로 변환해줌!
# 제미나이 굿~

import ast
def convert_to_list(x):
    try:
        if pd.isna(x) or x == "": return []
        return ast.literal_eval(x)
    except (ValueError, SyntaxError):
        return []

raw_user_contacts['invite_user_id_list'] = raw_user_contacts['invite_user_id_list'].apply(convert_to_list)

# 형변환 확인용 코드
print(type(raw_user_contacts['invite_user_id_list'].iloc[2])) 


# In[57]:


# info에서는 똑같이 object라고 나옴. type으로 세부확인이 꼭 필요할듯!
raw_user_contacts.info()


# In[58]:


raw_user_contacts['invite_user_id_list'].explode().nunique()


# - 이제 제대로 구분됨. 초대를 했던 유저는 1122명

# In[59]:


# 초대를 가장 많이 보낸 유저
raw_user_contacts['invite_user_id_list'].explode().dropna().value_counts().head(5)


# In[60]:


# 유저별로 나를 초대한 사람이 몇 명인지 계산
raw_user_contacts['inviter_count'] = raw_user_contacts['invite_user_id_list'].map(len)

# 가장 많은 '초대자'를 보유한(가장 많이 초대된) 유저 확인
raw_user_contacts.sort_values(by='inviter_count', ascending=False).head(5)


# In[61]:


# 초대수는 거의 0에 가까움
raw_user_contacts['inviter_count'].describe()


# In[62]:


# 그럼 초대를 받은 사람들의 분포는?
# 전체 5000명 중 초대를 받은 유저는 1158명, 약 20%
inviter_codition = raw_user_contacts['inviter_count'] > 0
invited_user = raw_user_contacts[inviter_codition]
invited_user


# In[63]:


fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(12, 5))

sns.boxplot(
    data=raw_user_contacts['inviter_count'], 
    ax=axes[0]
)
axes[0].set_title('한 명에게 수신된 초대 기록')

sns.boxplot(
    data=invited_user['inviter_count'],
    ax=axes[1]
)
axes[1].set_title('초대 기록이 있는 유저들의 기록 분포')

plt.tight_layout()
plt.show()


# In[64]:


# user_id 중복값 없음!
raw_user_contacts['user_id'].nunique()


# In[65]:


# contacts_count 유저 아이디의 전화번호를 가지고 있는 유저 수
# 요즘은 인스타로 연락하는 경우가 많다보니 아예 없는것도 그렇게 이상한 수치는 아니라고 생각
raw_user_contacts['contacts_count'].describe()


# In[66]:


plt.figure()
sns.boxplot(
    data = raw_user_contacts['contacts_count']
)
plt.title('유저 아이디의 전화번호를 가지고 있는 유저 수')
plt.show()


# ### 3-2-3. 포인트 기록
# 

# In[67]:


# raw_point = pd.read_csv(point_path)


# In[68]:


raw_point.info()


# In[69]:


raw_point.isna().sum()


# In[70]:


raw_point.describe()


# In[71]:


raw_point.head()


# In[72]:


# 전처리
raw_point['created_at'] = pd.to_datetime(raw_point['created_at']).dt.floor('s') # 시간컬럼 변환
raw_point.drop(columns='id', inplace=True) # id컬럼 삭제


# In[73]:


raw_point['user_question_record_id'] = raw_point['user_question_record_id'].astype('Int64').astype(str)
# 문자형으로 변환해도 자꾸 소수점이 있는 모양으로 저장됨. 판다스전용 정수형 Int64로 변환하여 소수점 삭제


# In[74]:


raw_point.info()


# In[75]:


# 이 테이블의 기록은 230428 ~ 230508 약 10일
raw_point.describe()


# In[76]:


raw_point = raw_point.sort_values(by='created_at')
raw_point


# In[77]:


# 전체 중복값
raw_point[raw_point.duplicated()]


# In[78]:


# 전부 중복되는 내용은 일단 드롭
# 이 테이블의 정확한 집계를 위해서 일단 여기서만 드롭함!
raw_point.drop_duplicates(keep='last')


# In[79]:


raw_point['user_question_record_id'].value_counts()


# In[80]:


# 위에서 str로 형변환한것 때문에 결측치까지 문자열로 바뀌어버림.
# 바뀐 문자열 다시 결측치로 변환
raw_point['user_question_record_id'] = raw_point['user_question_record_id'].replace('<NA>', np.nan)


# In[81]:


raw_point['user_question_record_id'].isna().sum()


# In[82]:


# 질문아이디 없이 기록된 포인트
# 구매로 인한 내역인가? 아니면 포인트 이벤트? 이것도 다른 테이블이랑 merge해봐야 알 수 있을듯.
no_question_point = raw_point[raw_point['user_question_record_id'].isna()]
no_question_point['delta_point'].value_counts()


# In[83]:


plt.figure()
sns.boxplot(
    data = no_question_point['delta_point']
)
plt.title('질문아이디가 없는 point_delta 분포')
plt.show()


# In[84]:


raw_hackle_events['item_name'].unique()


# In[85]:


point_negative_condition = raw_point['delta_point'] < 0
raw_point[point_negative_condition]['delta_point'].describe()


# In[86]:


plt.figure()
sns.boxplot(
    data = raw_point[point_negative_condition]['delta_point']
)
plt.title('마이너스 포인트 분포')
plt.show()

# 마이너스 포인트는 잘못 지급된 포인트를 정정하기 위함이었을까?


# ### 3-2-4. 학교

# In[87]:


raw_school.info()


# In[88]:


raw_school.describe()


# In[89]:


raw_school.isna().sum()


# In[90]:


raw_school.head()


# In[91]:


# 학교 주소가 제각각인듯
raw_school['address'].value_counts()


# In[92]:


# 2026년 1월 기준 대한민국의 시·군·구 기초자치단체는 총 226개
# 비슷한 이름이 중복되었을 수 있음
# 위에서 서울 노원구 1건, 아래 Unique list 중 서울특별시 노원구 존재 -> 이런 식으로 중복됐을 가능성 아아아주 높음~
print(f"주소지 고유값 : {raw_school['address'].nunique()}")
print(f"{raw_school['address'].unique()}")


# In[201]:


# 텍스트 정리
def clean_address(addr):
    if pd.isna(addr) or addr == '-':
        return None

    # 1. 불필요한 앞머리 제거 (예: 대한민국 강원도 -> 강원도)
    addr = addr.replace('대한민국 ', '')

    # 2. 광역지자체 매핑 사전
    city_map = {
        '서울 ': '서울특별시 ',
        '경기 ': '경기도 ',
        '인천 ': '인천광역시 ',
        '대전 ': '대전광역시 ',
        '대구 ': '대구광역시 ',
        '부산 ': '부산광역시 ',
        '울산 ': '울산광역시 ',
        '광주 ': '광주광역시 ',
        '강원 ': '강원도 ',
        '충남 ': '충청남도 ',
        '충북 ': '충청북도 ',
        '경남 ': '경상남도 ',
        '경북 ': '경상북도 ',
        '전남 ': '전라남도 ',
        '전북 ': '전라북도 ',
        '제주 ': '제주특별자치도 '
    }

    # 3. 매핑 적용
    for short, long in city_map.items():
        if addr.startswith(short):
            addr = addr.replace(short, long)
            break

    return addr


# In[257]:


# 주소지 값 정리 및 전처리
processed_school = raw_school.copy()
processed_school['address'] = raw_school['address'].apply(clean_address)
processed_school.dropna(subset=['address'], inplace=True)
processed_school.drop(columns='id', inplace=True)


# In[260]:


processed_school.reset_index(drop=False, inplace=True)


# In[261]:


processed_school.rename(columns={'index' : 'school_id'}, inplace=True)


# In[262]:


processed_school.info()


# In[263]:


processed_school['address'].nunique()


# - 2026년 1월 기준 대한민국의 시·군·구 기초자치단체는 총 226개
# - 정제된 주소의 unique가 251개인 것은 기초자치단체에 포함되지 않는 일반구(비자치구)와 행정시가 섞여있기 때문
#     - 일반구(비자치구) 예시: '수원시'가 1개의 기초자치단체이나 인구가 많아 '시' 아래에 '구'를 두고있음(수원시 팔달구, 수원시 영통구 등)
#     - 행정시 예시: 제주시와 서귀포시는 법적 자치권이 없는 행정시 -> '제주도'라는 하나의 광역단체 안에 묶여있음

# In[264]:


# 주소지별 학교 분포 상위 10개
top10_school = processed_school['address'].value_counts().head(10)
top10_school


# In[265]:


plt.figure()
sns.barplot(
    x=top10_school.values,
    y=top10_school.index
)
plt.show()


# In[ ]:


# 광역지자체별 구분
processed_school['city_root'] = processed_school['address'].str.split().str[0]
processed_school['city_root'].value_counts()


# In[299]:


city_school = processed_school['city_root'].value_counts()
plt.figure()
sns.barplot(
    x=city_school.index,
    y=city_school.values
)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()


# In[266]:


# 학교 종류
print(f"학교 종류 목록: {processed_school['school_type'].unique()}")
print(f"학교 종류 개수: {processed_school['school_type'].value_counts()}")


# - H: High school, M: Middle school
# - 중학교의 비율이 높음

# In[532]:


fixed_schooltype_order = ['H', 'M']
fixed_schooltype_colors = {'H': '#1f77b4', 'M': '#ff7f0e'}


# In[534]:


school_counts = processed_school['school_type'].value_counts().reindex(fixed_schooltype_order)

plt.figure()
plt.pie(
    x=school_counts.values, 
    labels=school_counts.index,
    autopct='%.1f%%',
    startangle=90,
    counterclock=False,
    colors=[fixed_schooltype_colors[label] for label in school_counts.index]
)
plt.title('학교 비율')
plt.show()


# In[268]:


processed_school.duplicated().sum()


# In[269]:


processed_school[processed_school.duplicated(keep=False)]


# In[270]:


# 학생 수
processed_school['student_count'].describe()


# In[271]:


# 학생이 아예 없는 학교
no_student_condition = processed_school['student_count'] == 0
processed_school[no_student_condition]


# In[272]:


# 학교 당 인원 40명 미만인 학교
# 2051개, 거의 40%나 활성화가 안됐네
low_student_condition = processed_school['student_count'] < 40
low_school = processed_school[low_student_condition]
low_school


# In[273]:


# 활성화 여부 컬럼 추가
# 40명미만: 0(False), 40명 이상: 1(True)
processed_school['enable'] = (processed_school['student_count'] >= 40).astype(int)
processed_school.sort_values('school_id')


# In[294]:


schooltype_enable = processed_school.groupby(['school_type', 'enable']).size().unstack(fill_value=0)

ax = schooltype_enable.plot(kind='bar', stacked=True, color=['#ff9999', '#66b3ff']) # stacked=True 옵션이 누적 막대를 만들어줌

plt.title('학교급별 학생 수 충족 현황')
plt.xticks(rotation=0)
plt.legend(title='Enable Status', labels=['미달', '충족'], loc='upper left')


# In[ ]:


schooltype_enable = processed_school.groupby(['address', 'enable']).size().unstack(fill_value=0)
schooltype_enable


# In[302]:


city_school.index


# In[305]:


# 도시별 학생 수 충족 현황

# 광역지자체와 enable 상태로 그룹화하여 데이터 재구성
city_enable_df = processed_school.groupby(['city_root', 'enable']).size().unstack(fill_value=0)
city_enable_df_sorted = city_enable_df.reindex(city_school.index, fill_value=0)

# 그래프 그리기
ax = city_enable_df_sorted.plot(kind='bar', stacked=True, color=['#ff9999', '#66b3ff'])

# 그래프 디테일 설정
plt.title('광역지자체별 학생 수 충족 현황')
plt.xlabel('광역지자체')
plt.ylabel('학교 수')
plt.xticks(rotation=45)
plt.legend(title='Enable Status', labels=['미달', '충족'], loc='upper right')

plt.tight_layout()
plt.show()


# - 실질적으로 활성화된건 고등학교
# - 지역별 실질적 활성화수에도 차이가 있는편
#     - 그럼에도 불구하고 경기도, 서울이 압도적인 것은 인구수 밀집에 의한 결과

# ### 3-2-5. 유저 신고 기록 테이블

# In[501]:


raw_timeline.info()


# In[505]:


# 전처리
processed_timeline = raw_timeline.copy()
processed_timeline.drop(columns='id', inplace=True)
processed_timeline['created_at'] = pd.to_datetime(raw_timeline['created_at']).dt.floor('s') # 시간컬럼 변환

# id 컬럼 형변환
processed_timeline['reported_user_id'] = processed_timeline['reported_user_id'].astype(str)
processed_timeline['user_id'] = processed_timeline['user_id'].astype(str)
processed_timeline['user_question_record_id'] = processed_timeline['user_question_record_id'].astype(str)


# In[ ]:


# 질문이 뭐였는지 매칭하기 위해 user_question_record, question 테이블 merge
rename_user_qustion = raw_user_question.reset_index().rename(columns={'id':'user_question_record_id'}) # 질문 기록 테이블과
rename_polls_question = raw_polls_question.reset_index().rename(columns={'id':'question_id'}) # 질문 내용 테이블 id 이름 변환


# In[ ]:


user_question_record = rename_user_qustion[['user_question_record_id', 'question_id']]
question = rename_polls_question[['question_id', 'question_text']]
question_id_merge = pd.merge(user_question_record, question, on='question_id')
question_id_merge.head()


# In[504]:


question_id_merge.info()


# In[506]:


question_id_merge['user_question_record_id'] = question_id_merge['user_question_record_id'].astype(str)
question_id_merge['question_id'] = question_id_merge['question_id'].astype(str)


# In[507]:


# 질문목록 중 vote라는 내용 null 변환 및 삭제
question_id_merge['question_text'] = question_id_merge['question_text'].replace('vote', None)
question_id_merge.dropna(subset='question_text', inplace=True)


# In[508]:


# vote 삭제 확인
question_id_merge[question_id_merge['question_id'] == 'vote']


# In[509]:


# 질문 텍스트 확인을 위해 병합
processed_timeline = pd.merge(processed_timeline.copy(), question_id_merge[['user_question_record_id', 'question_text']], on='user_question_record_id')


# In[510]:


processed_timeline.describe()


# In[511]:


processed_timeline.head()


# In[512]:


# 전체중복행 없음
processed_timeline.duplicated().sum()


# In[513]:


# 가장 많은 신고 사유
processed_timeline['reason'].value_counts()


# In[514]:


# 신고사유1. 허위사실 언급
reason_1 = processed_timeline[processed_timeline['reason'] == '허위 사실 언급']
print(f"이 신고를 많이 한 유저: {reason_1['user_id'].value_counts().head(3)}")
print(f"이 신고를 많이 당한 유저: {reason_1['reported_user_id'].value_counts().head(3)}")
print(f"이 신고가 많이 들어온 질문: {reason_1['question_text'].value_counts().head(5)}")


# In[ ]:


# 신고사유2. 친구를 비하하거나 조롱하는 어투
reason_2 = processed_timeline[processed_timeline['reason'] == '친구를 비하하거나 조롱하는 어투']
print(f"이 신고를 많이 한 유저: {reason_2['user_id'].value_counts().head(3)}")
print(f"이 신고를 많이 당한 유저: {reason_2['reported_user_id'].value_counts().head(3)}")
print(f"이 신고가 많이 들어온 질문: {reason_2['question_text'].value_counts().head(5)}")


# In[516]:


# 신고사유3. 선정적이거나 폭력적인 내용 
reason_3 = processed_timeline[processed_timeline['reason'] == '선정적이거나 폭력적인 내용']
print(f"이 신고를 많이 한 유저: {reason_3['user_id'].value_counts().head(3)}")
print(f"이 신고를 많이 당한 유저: {reason_3['reported_user_id'].value_counts().head(3)}")
print(f"이 신고가 많이 들어온 질문: {reason_3['question_text'].value_counts().head(5)}")


# In[ ]:


# 신고사유4. 타인을 사칭함 
reason_4 = processed_timeline[processed_timeline['reason'] == '타인을 사칭함']
print(f"이 신고를 많이 한 유저: {reason_4['user_id'].value_counts().head(3)}")
print(f"이 신고를 많이 당한 유저: {reason_4['reported_user_id'].value_counts().head(3)}")
print(f"이 신고가 많이 들어온 질문: {reason_4['question_text'].value_counts().head(5)}")


# In[ ]:


# 신고사유5. 광고
reason_5 = processed_timeline[processed_timeline['reason'] == '광고']
print(f"이 신고를 많이 한 유저: {reason_5['user_id'].value_counts().head(3)}")
print(f"이 신고를 많이 당한 유저: {reason_5['reported_user_id'].value_counts().head(3)}")
print(f"이 신고가 많이 들어온 질문: {reason_5['question_text'].value_counts().head(5)}")


# - 신고내용 상위5개
#     - 1. 허위 사실 언급
#     - 2. 친구를 비하하거나 조롱하는 어투
#     - 3. 선정적이거나 폭력적인 내용
#     - 4. 타인을 사칭함
#     - 5. 광고
# - 1, 3, 4는 신고 건수도 적을 뿐더러 질문이 그렇게 유해하지 않다고 판단, 친구들끼리의 장난일 가능성 높음
# - 2번 신고는 특정 질문에 대해 한달동안 14건 접수
#     - 공부 잘하는 친구들이 긁혔나?
# - 5번 광고는 데이터 수집기간(1달) 중 유독 신고를 많이 당한 유저가 없어서 진짜 광고계정일 확률은 적을 것으로 예상

# In[489]:


# 가장 많이 신고한 유저 top5
processed_timeline['user_id'].value_counts().head(5)


# In[521]:


processed_timeline[processed_timeline['user_id'] == '1343904']


# - 많이 신고한 유저 확인결과 신고 내용 2위이 한 번에 한 명이 한 명에게 14번 신고했던 기록과 같음
# - 화가 많이난듯

# In[522]:


# 가장 많이 신고당한 유저 top5
processed_timeline['reported_user_id'].value_counts().head(5)


# In[524]:


processed_timeline[processed_timeline['reported_user_id'] == '1156031']


# In[525]:


processed_timeline[processed_timeline['reported_user_id'] == '1187305']


# - 신고를 가장 많이 당한 유저는 아까 신고를 가장 많이 했던 유저의 타겟이었음.
# - 2위, 3위 유저도 한 명이 다른 투표에 대해 같은 사람을 지속적으로 신고.
# - 한 달이라는 기간동안 특정 인물에게 반복되는 접수가 아님
#     - 따라서 실제 문제(괴롭힘 등)가 있는 신고사례이기보다 친구들끼리의 단발성 장난에 가까운 것으로 추정

# In[526]:


# 가장 많은 신고가 발생한 질문 top5
processed_timeline['question_text'].value_counts().head(5)


# In[527]:


processed_timeline[processed_timeline['question_text'] == '따뜻하게 말해줘서 고마운 사람은?']


# In[528]:


processed_timeline[processed_timeline['question_text'] == '말을 이쁘게 해서 가끔 설레게 되는 친구는?']


# - 모든 신고 기록이 한 명이 다른 한 명에 대한 신고를 우다다 눌렀던 기록
# - 이놈새기들. 이모를 힘들게해.
# - 이 테이블을 써야한다면.. 사실 데이터 별로 없어서 이상하게 많은 count에 대해 하나씩 쳐나가도 될것같음
#     - 아니면 question_text, user_id, reported_user_id를 기준으로 duplicated(keep='last')도 방법일듯

# In[ ]:





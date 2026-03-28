#!/usr/bin/env python
# coding: utf-8

# [ accounts_school ]
# 1. 주소 정제
#     담연님 코드 참고('서울'과 '서울 ' 구분 주의)
# 2. 학생 수가 40명이 넘는 곳과 그렇지 않는 곳을 구분하고자 한다고 말씀주셔서, 추가 컬럼 생성
#     is_active_school: 학생 수가 40 이상이면 True, 미만이면 False 

# In[1]:


import pandas as pd
from pathlib import Path

# 0) 경로
ROOT = Path.cwd()
DATA_DIR = ROOT / "dump_vote_ver2"
OUT_DIR = ROOT / "clean_vote_ver2"


# In[27]:


# 1) 로드
df = pd.read_csv(DATA_DIR / "accounts_school.csv")

print("shape:", df.shape)
df.head()
df.dtypes


# In[28]:


# 결측 재확인
null_summary = df.isna().sum().to_frame("null_cnt")
null_summary["null_ratio"] = null_summary["null_cnt"] / len(df)

null_summary


# In[4]:


# 완전 중복행 확인
dup_all_cnt = df.duplicated(keep=False).sum()
print("완전 동일 행 중복 수:", dup_all_cnt)


# In[5]:


# 2) 주소 정제

def clean_address(addr):
    if pd.isna(addr) or addr == '-':
        return None

    addr = addr.replace('대한민국 ', '')

    city_map = {
        '서울 ': '서울특별시',
        '경기 ': '경기도',
        '인천 ': '인천광역시',
        '대전 ': '대전광역시',
        '대구 ': '대구광역시',
        '부산 ': '부산광역시',
        '울산 ': '울산광역시',
        '광주 ': '광주광역시',
        '강원 ': '강원도',
        '충남 ': '충청남도',
        '충북 ': '충청북도',
        '경남 ': '경상남도',
        '경북 ': '경상북도',
        '전남 ': '전라남도',
        '전북 ': '전라북도',
        '제주 ': '제주특별자치도'
    }

    for short, long in city_map.items():
        if addr.startswith(short):
            return addr.replace(short, long, 1)

    return addr

df["address_clean"] = df["address"].apply(clean_address)


# In[6]:


changed_cnt = (df["address"] != df["address_clean"]).sum()
print("주소가 변경된 행 수:", changed_cnt)
# 주소 변경 완료


# In[7]:


df["address_clean"].value_counts().head(10)


# In[30]:


# 3) student_count 기준 컬럼 생성

df["is_active_school"] = df["student_count"] >= 40


# In[33]:


df.head(10)


# In[10]:


# 4) 저장

out_path = OUT_DIR / "accounts_school_clean.csv"
df.to_csv(out_path, index=False, encoding="utf-8-sig")

print("saved:", out_path)


#!/usr/bin/env python
# coding: utf-8

# [ polls_questionset ]
# 1. create at 시간 파싱
#     ns 제거
# 2. create > open 이상치 679건 제거

# In[1]:


import pandas as pd
import numpy as np
from pathlib import Path

# 0) 경로

ROOT = Path.cwd()
DATA_DIR = ROOT / "dump_vote_ver2"
OUT_DIR = ROOT / "clean_vote_ver2"

csv_path = DATA_DIR / "polls_questionset.csv"


# In[2]:


# 1) 로드

df = pd.read_csv(csv_path)

print("shape:", df.shape)
df.head()
df.dtypes


# In[3]:


# 2) 시간 파싱 + ns 제거

for col in ["created_at", "opening_time"]:
    df[col] = (
        pd.to_datetime(df[col], errors="coerce")
        .dt.floor("s")
    )


# In[ ]:


# kst 변환
from datetime import timedelta

df['created_at'] = df['created_at'] + timedelta(hours=9)


# In[4]:


# 3) 시간 이상치 확인

print("created_at null:", df["created_at"].isna().sum())
print("opening_time null:", df["opening_time"].isna().sum())


# In[5]:


# 4) created_at > opening_time → 삭제

invalid_time = df["created_at"] > df["opening_time"]

print("created_at > opening_time 건수:", invalid_time.sum())

df_clean = df.loc[~invalid_time].reset_index(drop=True)

print("원본 행 수:", len(df))
print("정리 후 행 수:", len(df_clean))
print("삭제된 행 수:", len(df) - len(df_clean))


# In[11]:


# 5) 저장

out_path = OUT_DIR / "polls_questionset_clean.csv"
df_clean.to_csv(out_path, index=False, encoding="utf-8-sig")

print("saved:", out_path)


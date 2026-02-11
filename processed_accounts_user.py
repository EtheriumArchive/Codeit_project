#!/usr/bin/env python
# coding: utf-8

# [ accounts user ]
# 1. id -> user_id 컬럼명 변경, str로 형변환
# 2. is_superuser, is_staff 컬럼 drop
#     gender, group_id 결측 자연스럽게 사라짐
# 3. friend_id_list 형변환
# 4. friend_count 컬럼 생성

# In[77]:


import pandas as pd
import numpy as np
from pathlib import Path
import ast


# 0) 경로 세팅

ROOT = Path.cwd()
DATA_DIR = ROOT / "dump_vote_ver2"
OUT_DIR = ROOT / "clean_vote_ver2"


csv_path = DATA_DIR / "accounts_user.csv"


# In[78]:


# 1) 로드

df = pd.read_csv(csv_path)
print("shape:", df.shape)

df.dtypes


# In[79]:


df.head()


# In[81]:


# 2) is_staff, is_superuser 값이 1인 유저 삭제

print("제거 전 행 수:", len(df))

before = len(df)

df = df[(df["is_staff"] == 0) & (df["is_superuser"] == 0)].copy()

after = len(df)

print("제거 후 행 수:", after)
print("제거된 행 수:", before - after)


# In[82]:


print("group_id 결측 제거 전 행 수:", len(df))
before = len(df)

df = df[df["group_id"].notna()].copy()

after = len(df)
print("group_id 결측 제거 후 행 수:", after)
print("제거된 행 수:", before - after)


# In[83]:


df.info()


# In[84]:


null_summary = pd.DataFrame({
    "null_cnt": df.isna().sum()
}).sort_values("null_cnt", ascending=False)

null_summary


# In[85]:


# staff, superuser 이별
df = df.drop(columns=["is_staff", "is_superuser"], errors="ignore")

print("삭제 후 컬럼:", df.columns.tolist())


# In[86]:


dup_all_cnt = df.duplicated(keep=False).sum()
print("완전 동일 행 중복 수:", dup_all_cnt)

if dup_all_cnt > 0:
    display(df[df.duplicated(keep=False)].head(20))


# In[87]:


# 2) 컬럼/타입 정리

# id -> user_id, 그리고 str로
df = df.rename(columns={"id": "user_id"})
df["user_id"] = df["user_id"].astype("Int64").astype("string")  # 결측 안전


# In[88]:


# 3) created_at datetime + ns 제거
df["created_at"] = pd.to_datetime(df["created_at"], errors="coerce").dt.floor("s")


# In[89]:


# kst 변환

from datetime import timedelta

df['created_at'] = df['created_at'] + timedelta(hours=9)


# In[90]:


# 3) 리스트처럼 생긴 문자열 -> 리스트

# '[1,2]' / '[]' / '' / NaN -> list or NaN
# 빈 값/빈 리스트는 NaN으로

def parse_listlike(x):

    if pd.isna(x):
        return np.nan
    s = str(x).strip()

    if s == "" or s == "[]" or s.lower() == "nan":
        return np.nan

    try:
        v = ast.literal_eval(s)
        if isinstance(v, list):
            out = []
            for i in v:
                if i is None or (isinstance(i, float) and np.isnan(i)):
                    continue
                try:
                    out.append(int(i))
                except Exception:
                    out.append(i)
            return out if len(out) > 0 else np.nan
        return np.nan
    except Exception:
        return np.nan


# In[91]:


# friend_count 생성
if "friend_id_list" in df.columns:
    df["friend_id_list"] = df["friend_id_list"].apply(parse_listlike)
    df["friend_count"] = df["friend_id_list"].apply(lambda x: len(x) if isinstance(x, list) else 0)


# In[92]:


df.head(20)


# In[93]:


print("gender 결측:", df["gender"].isna().sum())
print("group_id 결측:", df["group_id"].isna().sum())


# In[94]:


# 5) 저장

out_path = OUT_DIR / "accounts_user_clean.csv"
df.to_csv(out_path, index=False, encoding="utf-8-sig")
print("saved:", out_path)


# In[ ]:





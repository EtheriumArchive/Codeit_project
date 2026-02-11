#!/usr/bin/env python
# coding: utf-8

# [ accounts_paymenthistory ]
# 1. 데이터 수집 기간
#     min   2023-05-13 21:28:34
#     max   2024-05-08 14:12:45
# 2. create_at 파싱
#     ns 삭제

# In[1]:


import pandas as pd
from pathlib import Path

# 0) 경로 세팅

ROOT = Path.cwd()
DATA_DIR = ROOT / "dump_vote_ver2"
OUT_DIR = ROOT / "clean_vote_ver2"

csv_path = DATA_DIR / "accounts_paymenthistory.csv"


# In[2]:


# 1) 로드

df = pd.read_csv(csv_path)

print("shape:", df.shape)
df.head()
df.dtypes


# In[3]:


# 2) 전체 결측 / 중복 재확인

summary = pd.DataFrame([{
    "row_cnt": len(df),
    "null_user_id": df["user_id"].isna().sum(),
    "null_productId": df["productId"].isna().sum(),
    "null_phone_type": df["phone_type"].isna().sum(),
    "null_created_at": df["created_at"].isna().sum(),
    "duplicate_all_rows": df.duplicated(keep=False).sum(),
    "duplicate_user_id": df.duplicated(subset=["user_id"], keep=False).sum(),
}])

summary


# In[6]:


df["user_id"].nunique()


# In[6]:


# 2) created_at datetime 파싱 + ns 제거

df["created_at"] = (
    pd.to_datetime(df["created_at"], errors="coerce").dt.floor("s")
)

# 확인
print("created_at dtype:", df["created_at"].dtype)
print("created_at min/max:")
df["created_at"].agg(["min", "max"])


# In[7]:


# 3) 저장

out_path = OUT_DIR / "accounts_paymenthistory_clean.csv"

df[["user_id", "productId", "phone_type", "created_at"]].to_csv(
    out_path,
    index=False,
    encoding="utf-8-sig"
)
print("saved:", out_path)


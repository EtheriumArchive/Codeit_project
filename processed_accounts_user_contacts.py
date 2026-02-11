#!/usr/bin/env python
# coding: utf-8

# [ accounts_user_contacts ]
# 1. 유저 아이디 형변환: int -> str
# 2. 그냥 아이디는 그대로 둠
# 3. invite user id list는 리스트로 형변환, 빈 리스트는 null로 대체
# 4. invite cnt 생성

# In[20]:


import pandas as pd
import numpy as np
from pathlib import Path
import ast

# 0) 경로 세팅
ROOT = Path.cwd()
DATA_DIR = ROOT / "dump_vote_ver2"
OUT_DIR = ROOT / "clean_vote_ver2"
OUT_DIR.mkdir(parents=True, exist_ok=True)

csv_path = DATA_DIR / "accounts_user_contacts.csv"


# In[21]:


# 1) 로드
df = pd.read_csv(csv_path)

print("shape:", df.shape)
display(df.head())
display(df.dtypes)


# In[22]:


# 2) 기본 결측 재확인
summary = pd.DataFrame([{
    "row_cnt": len(df),
    "null_id": df["id"].isna().sum(),
    "null_user_id": df["user_id"].isna().sum(),
    "null_contacts_count": df["contacts_count"].isna().sum(),
    "null_invite_user_id_list": df["invite_user_id_list"].isna().sum(),
}])
display(summary)


# In[23]:


# 유저 아이디 형변환
df["user_id"] = df["user_id"].astype("Int64").astype("string")


# In[24]:


# 형변환 확인
print(df["user_id"].dtype)
display(df[["user_id"]].head())


# In[25]:


# 3) contacts_count 타입/이상치 재확인

# 음수 여부
neg_contacts = df[df["contacts_count"] < 0]
print("contacts_count 음수 건수:", len(neg_contacts))
display(neg_contacts.head(20))


# In[26]:


# 4) invite_user_id_list: 리스트처럼 보이는 문자열 -> 리스트
# "[1,2]" -> [1,2]
# "123" 같은 문자열도 int로

def parse_listlike(x):
    if pd.isna(x):
        return []
    s = str(x).strip()
    if s == "" or s == "[]":
        return []
    try:
        v = ast.literal_eval(s)  
        if isinstance(v, list):
            # 내부 값이 숫자면 int로 정리
            out = []
            for i in v:
                if i is None:
                    continue
                try:
                    out.append(int(i))
                except Exception:
                    pass
            return out
        return []
    except Exception:
        return []

df["invite_user_id_list"] = df["invite_user_id_list"].apply(parse_listlike)


# In[27]:


# 빈 리스트는 null
df["invite_user_id_list"] = df["invite_user_id_list"].apply(
    lambda x: np.nan if isinstance(x, list) and len(x) == 0 else x
)


# In[28]:


# 변환 확인
display(df[["invite_user_id_list"]].head(20))


# In[31]:


# 파싱 결과 길이 분포(잘 반영이 된건지)
df["invite_cnt"] = df["invite_user_id_list"].apply(
    lambda x: len(x) if isinstance(x, list) else 0
)
# 최대 초대수 10명, 대부분은 초대하지 않은 유저임


# In[32]:


type(df.loc[0, "invite_user_id_list"])


# In[33]:


# 5) 중복 체크 

# 완전 중복 행
dup_cols = ["id", "user_id", "contacts_count"]

dup_all_cnt = df.duplicated(subset=dup_cols, keep=False).sum()
print("완전 동일 행 중복 수:", dup_all_cnt)

# 유저아이디 중복
dup_user_cnt = df.duplicated(subset=["user_id"], keep=False).sum()
print("user_id 중복 행 수:", dup_user_cnt)


# In[34]:


df.head(20)


# In[ ]:


# 6) 저장

out_path = OUT_DIR / "accounts_user_contacts_clean.csv"

df_out = df[["id", "user_id", "contacts_count", "invite_user_id_list", "invite_cnt"]].copy()

df_out.to_csv(out_path, index=False, encoding="utf-8-sig")
print("saved:", out_path)


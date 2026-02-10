# %% [markdown]
# [accounts_failpaymenthistory 전처리 기준]
# 
# 1. 전체 row 중복: 없음
# 2. user_id 기준 중복 결제 기록 존재
#     중복 시 최신 created_at 기준 keep='last'
# 3. 컬럼 유지: id, user_id, productId, phone_type, created_at
# 4. 결과 저장 위치: clean_vote_ver2/

# %%
import pandas as pd
import numpy as np
from pathlib import Path

# 0) 데이터 불러오기

ROOT = Path.cwd()
DATA_DIR = ROOT / "dump_vote_ver2"
OUT_DIR = ROOT / "clean_vote_ver2"
OUT_DIR.mkdir(parents=True, exist_ok=True)

csv_path = DATA_DIR / "accounts_failpaymenthistory.csv"


# 1) 로드

df = pd.read_csv(csv_path)

print("shape:", df.shape)
display(df.head())
display(df.dtypes)

# %%
# 2) 타입/결측 기본 점검 (재확인용)

# created_at 파싱 (문자열 -> datetime)
# 나노초 → 초 단위로
df["created_at"] = (pd.to_datetime(df["created_at"], errors="coerce").dt.floor("s"))

summary = pd.DataFrame([{
    "row_cnt": len(df),
    "null_id": df["id"].isna().sum(),
    "null_user_id": df["user_id"].isna().sum(),
    "null_productId": df["productId"].isna().sum(),
    "null_phone_type": df["phone_type"].isna().sum(),
    "null_created_at": df["created_at"].isna().sum(),
    "non_positive_id": (df["id"] <= 0).sum(),
    "non_positive_user_id": (df["user_id"] <= 0).sum(),
}])
display(summary)

# %%
### created_at 전처리 잘 됐는지 확인
### 데이터 수집 기간도 함께 확인

bad_dt = df[df["created_at"].isna()][["id", "user_id", "productId", "phone_type", "created_at"]]

print("created_at 파싱 실패 건수:", len(bad_dt))
display(bad_dt.head(20))

# 데이터 수집 기간
print("created_at min:", df["created_at"].min())
print("created_at max:", df["created_at"].max())


# %%
# 4) 전체 행 완전 동일 중복 재확인
dup_all_cnt = df.duplicated(keep=False).sum()
print("완전 동일 행 중복(keep=False):", dup_all_cnt)

# %%
# 5) 유저 기준 중복 제거
# user_id 기준
# created_at 기준으로 최신(keep='last')만 유지

df_clean = (
    df.sort_values(["user_id", "created_at"], ascending=[True, True])
    .drop_duplicates(subset=["user_id"], keep="last")
    .reset_index(drop=True)
)

print("원본 행 수:", len(df))
print("정리 후 행 수:", len(df_clean))
print("제거된 행 수:", len(df) - len(df_clean))
print("user_id unique?:", df_clean["user_id"].is_unique)

# %%
# 6) 저장

out_path = OUT_DIR / "accounts_failpaymenthistory_clean.csv"
df_clean[["id", "user_id", "productId", "phone_type", "created_at"]].to_csv(out_path, index=False, encoding="utf-8-sig")

print("saved:", out_path)


# %%




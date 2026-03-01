# Phase 6：ウィンドウ関数（実務の上級常用）（ec-v1）

> このPhaseでは、ウィンドウ関数を「実務の定番パターン」として使えるようにします。  
> JOIN/GROUP BYで作った集計に対して、順位・最新・累積・移動平均・差分などを追加できるのが強みです。

---

## 0. ゴール

- PARTITION BY / ORDER BY を使って「グループ内の順序」を扱える
- ROW_NUMBER / RANK / DENSE_RANK の違いがわかる
- 「最新1件（各ユーザーの最新注文など）」をウィンドウ関数で取れる
- 累積（running total）とフレーム（ROWS/RANGE）の感覚がつく
- LAG/LEAD で前後差分（増減）を出せる
- NTILE / PERCENT_RANK などで分位や相対位置を作れる

---

## 1. 対象ファイル（Phase 6）

- `sql/060_window_basics_row_number_rank.sql`
- `sql/061_window_latest_per_group.sql`
- `sql/062_window_running_totals_frames.sql`
- `sql/063_window_lag_lead_diff.sql`
- `sql/064_window_ntile_percent_rank.sql`

---

## 2. 事前準備（共通）

### 2.1 DB起動確認

```bash
docker compose ps
```

### 2.2 `.env` 読み込み（Git Bash）

```bash
set -a
source .env
set +a
```

---

## 3. 実行手順（psql：CLI）

### 3.1 実行

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/060_window_basics_row_number_rank.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/061_window_latest_per_group.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/062_window_running_totals_frames.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/063_window_lag_lead_diff.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/064_window_ntile_percent_rank.sql
```

---

## 4. ポイント

- ウィンドウ関数は「GROUP BYで行を潰さずに、集計結果を列として付ける」のが強み
- PARTITION BY（グループ）と ORDER BY（順序）がセットで重要
- ROW_NUMBERは必ず連番、RANKは同率で飛び番、DENSE_RANKは同率でも飛ばない
- 「各グループ最新1件」は row_number() over (partition ... order ...) を使うのが定番
- フレーム指定（ROWS BETWEEN ...）で「移動平均」などが作れる

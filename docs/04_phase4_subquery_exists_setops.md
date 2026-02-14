# Phase 4：サブクエリ・EXISTS・集合演算（ec-v1）

> このPhaseでは、実務で頻出の「サブクエリ」「EXISTS / NOT EXISTS」「集合演算（UNION等）」を、ec-v1のデータで一通り触れます。  
> JOINと集約に慣れてきた前提で、「別の書き方（思考の引き出し）」を増やすのが目的です。

---

## 0. ゴール

- サブクエリの代表形（スカラー / IN / FROM内派生表）を使える
- EXISTS と IN の使い分けの感覚がつく（特に「存在判定」）
- NOT EXISTS（アンチJOIN）で「〜が存在しない」を安全に書ける
- 集合演算（UNION / UNION ALL / INTERSECT / EXCEPT）の基本を使える
- WITH（CTE）で「読みやすいレポートSQL」に分解できる

---

## 1. 対象ファイル（Phase 4）

- `sql/040_subquery_basics.sql`
- `sql/041_exists_correlated.sql`
- `sql/042_not_exists_anti_join.sql`
- `sql/043_set_operations.sql`
- `sql/044_cte_with_examples.sql`

---

## 2. 事前準備（共通）

### 2.1 DB起動確認

```bash
docker compose ps
```

### 2.2 .env 読み込み（Git Bash）

```bash
set -a
source .env
set +a
```

---

## 3. 実行手順（psql：CLI）

### 3.1 実行

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/040_subquery_basics.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/041_exists_correlated.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/042_not_exists_anti_join.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/043_set_operations.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/044_cte_with_examples.sql
```

---

## 4. ポイント

- 「存在するか？」は JOIN より EXISTS のほうが意図が明確なことが多い
- NOT IN はNULLが混ざると意図通り動かないことがある（NOT EXISTSが安全）
- 集合演算は「列数・型」を揃える必要がある（最後にまとめてORDER BYする）
- WITH（CTE）は、複雑なレポートSQLを「分解して読みやすく」できる

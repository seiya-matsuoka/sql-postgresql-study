# Phase 3：集約・レポート系

> このドキュメントは、集約（GROUP BY）を使って「レポートっぽい結果」を作るための手順ログです。
> COUNT/SUM/AVG などの基本から、HAVING、DISTINCT、条件付き集計（CASE / FILTER）まで扱います。

---

## 0. ゴール

- GROUP BY の基本（集約関数 + グルーピング）が書ける
- HAVING（集約結果の絞り込み）が書ける
- DISTINCT / COUNT(DISTINCT ...) の使い所が分かる
- 条件付き集計（CASE版）を書ける（汎用性が高い）
- FILTER句（書ける場合は簡潔）も体験する（PostgreSQLで実行可能）

---

## 1. 対象ファイル（Phase 3）

- `sql/030_groupby_basics.sql`
- `sql/031_having_and_distinct.sql`
- `sql/032_conditional_aggregation_case.sql`
- `sql/033_reporting_orders.sql`
- `sql/034_filter_clause.sql`
- `sql/035_report_revenue_by_prefecture.sql`
- `sql/036_report_payment_methods.sql`
- `sql/037_report_shipment_leadtime.sql`
- `sql/038_report_revenue_by_tag.sql`

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
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/030_groupby_basics.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/031_having_and_distinct.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/032_conditional_aggregation_case.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/033_reporting_orders.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/034_filter_clause.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/035_report_revenue_by_prefecture.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/036_report_payment_methods.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/037_report_shipment_leadtime.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/038_report_revenue_by_tag.sql
```

---

## 4. ポイント

- COUNT(\*) と COUNT(column) の違い（NULLの扱い）
- WHERE は「集約前の絞り込み」、HAVING は「集約後の絞り込み」
- DISTINCT は便利だが、意味（“何を一意にしたいか”）を常に意識する
- 条件付き集計は実務頻出：CASE版は汎用、FILTER版は簡潔（ただしDB差あり）
- JOINしてから集約すると「1対多で行が増える」前提でレポートを作れる

---

## 5. DBeaver（GUI）での確認

- 033/034 は結果がレポートっぽくなるので、GUIで眺めると理解が速い

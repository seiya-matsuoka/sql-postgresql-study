# Phase 12：性能（ec-perf-v1）

> このPhaseでは、性能学習のための専用データセット `ec-perf-v1` を使って、同じクエリを段階的に改善していきます。

このPhaseの主な流れは以下です。

- EXPLAIN で実行計画を見る（予想）
- EXPLAIN ANALYZE で実測する（実際）
- 索引（INDEX）を追加して差を見る
- クエリの書き方（JOIN / EXISTS / CTE / ウィンドウ）を比較する
- 統計情報・テーブルサイズ・索引利用状況を見る

---

## 0. ゴール

- `EXPLAIN` と `EXPLAIN ANALYZE` の違いを説明できる
- 実行計画で最低限以下を読める
  - Seq Scan / Index Scan / Bitmap Heap Scan
  - Hash Join / Nested Loop
  - Sort / Aggregate
  - rows / actual time / loops
- 索引追加の前後で「何が変わったか」を比較できる
- `JOIN DISTINCT` と `EXISTS` の使い分けを性能面でも体感できる
- CTE の比較（通常 / MATERIALIZED / NOT MATERIALIZED）を体験できる
- `pg_stat_*` / `pg_size_*` で観察できる

---

## 1. 事前準備（データセット切替）

このPhaseは `ec-perf-v1` を使います。  
これまでの `ec-v1` とは別のデータセットです。

### 1.1 `.env` の `DBSET` を変更

```
DBSET=ec-perf-v1
```

### 1.2 既存コンテナ停止 + ボリューム削除（重要）

※ `down -v` を使うので、現在のDBデータは消えます（学習データはSQLファイルに残っていれば再構築可能）。

```bash
docker compose down -v
```

### 1.3 PostgreSQL起動（init SQLが自動実行される）

```bash
docker compose up -d
```

### 1.4 起動確認

```bash
docker compose ps
docker compose logs -f db
```

### 1.5 `.env` 読み込み（Git Bash）

```bash
set -a
source .env
set +a
```

---

## 2. 実行順（psql：CLI）

### 2.1 データ件数・分布の確認

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/120_ec_perf_v1_sanity.sql
```

### 2.2 EXPLAINの基本（まずは読み方）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/121_perf_explain_basics.sql
```

### 2.3 単一テーブルの絞り込み + 並び替え（索引で改善）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/122_perf_filter_sort_index_tuning.sql
```

### 2.4 JOIN + 集約のベースライン

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/123_perf_join_aggregate_baseline.sql
```

### 2.5 JOIN + 集約の索引改善

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/124_perf_join_aggregate_index_tuning.sql
```

### 2.6 EXISTS と JOIN DISTINCT の比較

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/125_perf_exists_vs_join_distinct.sql
```

### 2.7 CTEの比較（通常 / MATERIALIZED / NOT MATERIALIZED）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/126_perf_cte_materialization_compare.sql
```

### 2.8 ウィンドウ関数 vs DISTINCT ON（PostgreSQL特有）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/127_perf_window_vs_distinct_on.sql
```

### 2.9 統計・サイズ・索引利用状況の確認

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/128_perf_stats_and_plan_reading.sql
```

### 2.10 （任意）Phase 12で追加した索引を掃除

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/129_perf_phase12_cleanup_optional.sql
```

---

## 3. psqlで便利な操作

psqlで直接入って観察する場合、以下が便利です。

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

接続後:

```sql
\timing on
\dt
\d public.customer_order
\d public.order_item
\di
\x auto
```

---

## 4. 実行計画を見るときの最低限ポイント

### 4.1 まず見る項目

- ノード種類（Seq Scan / Index Scan / Hash Join / Sort など）
- `cost=...`（見積）
- `rows=...`（見積行数）
- `actual time=...`（実測）
- `loops=...`

### 4.2 rows のズレに注目

- 見積 rows と 実際 rows が大きくズレていると、統計情報やデータ偏りの影響を疑う
- `ANALYZE` で改善することがある

### 4.3 まずは「同じクエリ」で比較

- クエリを書き換える前に、まず索引だけ追加して変化を見る
- その後、書き方の違い（EXISTS / CTE / ウィンドウ）を比較する

---

## 5. 方言メモ（PostgreSQL特有）

このPhaseは性能学習の都合上、PostgreSQL特有の要素を意図的に使っています。

- `EXPLAIN (ANALYZE, BUFFERS)`
- `MATERIALIZED / NOT MATERIALIZED`（CTE）
- `DISTINCT ON (...)`（Phase 127で比較用に使用）
- `pg_stat_user_tables`, `pg_stat_user_indexes`, `pg_total_relation_size`

ただし、比較の軸としては以下の汎用的な考え方を重視しています。

- 索引設計（複合索引）
- EXISTS と JOIN DISTINCT の使い分け
- 先に絞る / 後でJOINする
- 集約・ソートのコストを意識する

---

## 6. 次フェーズへの繋がり（Phase 13）

Phase 12で得た内容は、次の運用寄りフェーズ（Phase 13）にそのまま繋がります。

- 統計情報の更新（ANALYZE）
- 索引の監視
- 遅いクエリ調査の手順
- 変更の前後比較（再現性）

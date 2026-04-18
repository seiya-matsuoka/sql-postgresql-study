# Phase 9：ビュー / マテビュー（ec-v1 + view_labスキーマ）

> このPhaseでは、ec-v1（public）のレポート系SQLを `view_lab` スキーマにビューとして固定し、その後にマテビュー（Materialized View）を作成・更新（REFRESH）して、使いどころを体験します。

- ビュー: SQLの再利用・見せたい形の固定化
- マテビュー: 集計結果のスナップショット化（性能・再利用のため）

---

## 0. ゴール

- `CREATE VIEW` / `CREATE OR REPLACE VIEW` を使ってレポートSQLを固定化できる
- ビューを通して SELECT し、再利用しやすくなる感覚を掴む
- `CREATE MATERIALIZED VIEW` で結果を保存できることを理解する
- `REFRESH MATERIALIZED VIEW` で更新されることを体験する
- `REFRESH MATERIALIZED VIEW CONCURRENTLY` の前提（ユニークインデックス）を理解する
- メタ情報（information_schema / pg_matviews / pg_indexes）で構造を確認できる

---

## 1. 対象ファイル（Phase 9）

- `sql/090_view_lab_reset.sql`
- `sql/091_view_lab_views.sql`
- `sql/092_view_lab_view_usage.sql`
- `sql/093_view_lab_materialized_views.sql`
- `sql/094_view_lab_materialized_view_refresh_demo.sql`
- `sql/095_view_lab_introspection.sql`

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

### 2.3 前提

- ec-v1（public）は Phase 3〜6で使ってきたデータセット
- lab は Phase 7〜8で使った実験用スキーマ（Phase 8完了済みならOK）
- このPhaseでは ec-v1本体は基本的に更新しない（温存）
- REFRESH差分の体験だけ、lab.transfer にデモデータを1件追加する

---

## 3. 実行手順（psql：CLI）

### 3.1 view_lab を作り直す（何度でもやり直しOK）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/090_view_lab_reset.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/091_view_lab_views.sql
```

### 3.2 ビューを使ってSELECTする

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/092_view_lab_view_usage.sql
```

### 3.3 マテビューを作成する

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/093_view_lab_materialized_views.sql
```

### 3.4 REFRESHを体験する（lab側のデータ変更 → REFRESH）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/094_view_lab_materialized_view_refresh_demo.sql
```

### 3.5 構造を見える化する（推奨）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/095_view_lab_introspection.sql
```

---

## 4. psql上の確認コマンド

psqlで接続した状態で、以下が便利です。

```sql
\dn
\dt view_lab.*
\dv view_lab.*
\dm view_lab.*
\d+ view_lab.v_order_totals
\d+ view_lab.mv_ec_daily_revenue
\d+ view_lab.mv_lab_transfer_status_counts
```

---

## 5. ポイント

- ビューは「クエリを名前付きで再利用できる」のが本質（データを持たない）
- マテビューは「実行結果を保持する」ので、元テーブルを更新しても自動では変わらない
- 変化を反映するには `REFRESH MATERIALIZED VIEW` が必要
- `CONCURRENTLY` は便利だが、ユニークインデックスなど前提がある（PostgreSQL特有）
- Phase 12（性能）では「どのクエリをマテビュー化すると効くか」に繋がる

---

## 6. 補足（標準SQL / PostgreSQL）

- `CREATE VIEW` は比較的汎用的（多くのRDBMSで共通）
- `CREATE MATERIALIZED VIEW` / `REFRESH MATERIALIZED VIEW` はDBごとに差がある
  （PostgreSQLの書き方として学ぶ）
- `pg_matviews`, `pg_get_viewdef` などの確認SQLは PostgreSQL のシステムカタログ

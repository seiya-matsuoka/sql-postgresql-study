# Phase 5：CTE（WITH）と読みやすさ・再帰（ec-v1）

> このPhaseでは、CTE（WITH）を「複雑なSQLを分解して読みやすくする道具」として使えるようにします。  
> 後半で再帰CTEの入口も触れます（ツリーや連番生成など）。

---

## 0. ゴール

- WITHで部品を作り、複雑なレポートSQLを段階的に組み立てられる
- CTEの層（layer）を増やしても見失わずに書ける
- 1つのSQLを「中間結果を確認しながら」育てる感覚がつく
- 再帰CTEの基本形（アンカー + 再帰部）を理解する
- 再帰CTEで「階層」「連番」「日付系列」を作れる

---

## 1. 対象ファイル（Phase 5）

- `sql/050_cte_refactor_basics.sql`
- `sql/051_cte_layering_reports.sql`
- `sql/052_cte_materialization_notes.sql`
- `sql/053_recursive_cte_hierarchy.sql`
- `sql/054_recursive_cte_dates.sql`

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
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/050_cte_refactor_basics.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/051_cte_layering_reports.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/052_cte_materialization_notes.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/053_recursive_cte_hierarchy.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/054_recursive_cte_dates.sql
```

---

## 4. ポイント

- CTEは「読みやすさのための命名・分解」が主目的
- 層を分けると、どこで絞るか・どこで集約するかが明確になる
- 再帰CTEは「アンカー（初期行）」＋「再帰（次の行を作る）」の2部構成
- 再帰CTEは実務では階層や系列（カレンダー）で出番がある

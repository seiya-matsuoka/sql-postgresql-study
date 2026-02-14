# Phase 1：SELECT基礎 + CASE

> このドキュメントは、SELECTの基礎とCASE式の基本パターンを、実際にSQLを実行しながら一通り触れるための手順ログです。

---

## 0. ゴール

- SELECTの基本形（列指定、別名、式、並び替え、件数制限）が実行できる
- WHEREの基本条件（比較、AND/OR、IN、BETWEEN、LIKE、NULL）が実行できる
- よく使う関数（文字列/数値/日時）と型変換が実行できる
- CASE式の代表パターン（searched CASE / simple CASE）が実行できる

---

## 1. 対象ファイル（Phase 1）

- `sql/010_select_basics.sql`
- `sql/011_where_filters.sql`
- `sql/012_functions_cast_datetime.sql`
- `sql/013_case_basics.sql`

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
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/010_select_basics.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/011_where_filters.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/012_functions_cast_datetime.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/013_case_basics.sql
```

### 3.2 ポイント

- 「SQLを書いた通りの列が出ているか（列指定・別名・式）」
- 「WHEREの条件で結果が絞れているか（条件の書き方の違いで結果が変わるか）」
- 「LIKE / ILIKE の違い（大文字小文字）」
- 「日時関数・型変換で結果の型や表示がどう変わるか」
- 「CASE式でラベル付けできるか（条件の順序が結果に影響する）」

---

## 4. 実行手順（DBeaver：GUI）

### 4.1 事前

- DBeaverで対象DB（`localhost:${PG_PORT}`）に接続済みであること

### 4.2 実行

- SQL Editorを開く
- ファイル内容を貼って実行（またはファイルを開いて実行）

### 4.3 ポイント

- 結果セットの列順・型（数字/文字/日時）が想定通りか
- 実行結果を眺めやすい（GUIの強み）ので、値の変化を目視で確認する

# Phase 0：環境・基本操作

> このドキュメントは「学習に着手できる状態」を作るための手順ログです。  
> **psql（CLI）** と **DBeaver（GUI）** の両方で、Docker上のPostgreSQLに接続し、基本操作とEXPLAINまで一度通します。

---

## 0. ゴール

- DockerでPostgreSQLが起動している（`docker compose ps` で確認できる）
- Git Bash から `psql` で接続できる
- SQLファイルを `psql -f` で実行できる
- `EXPLAIN` / `EXPLAIN (ANALYZE, BUFFERS)` が出せる
- DBeaverからも同じDBに接続・実行できる

---

## 1. 前提

- Windows + Docker Desktop + Git Bash
- リポジトリ名：`sql-postgresql-study`
- `.env` はコミットしない（`.env.example` のみコミット）
- `docker-compose.yml` は環境変数（`.env`）で接続情報を受け取る

---

## 2. 事前確認（バージョン）

### 2.1 コマンド

```bash
docker --version
docker compose version
git --version
psql --version
```

### 2.2 期待値

- `docker compose` が実行できる
- `psql` が実行できる（ローカルインストール済み）

---

## 3. DockerでPostgreSQL起動（初回）

### 3.1 コマンド（起動）

```bash
docker compose up -d
docker compose ps
```

### 3.2 補助（ログ確認）

```bash
docker logs -f pg-study
```

補足：

- `pg-study` は `docker-compose.yml` の `PG_CONTAINER_NAME` に合わせて変更してください

---

## 4. psqlで接続（Git Bash）

### 4.1 `.env` の読み込み（Git Bash）

パスワードをコマンドに直書きしたくないため、まず `.env` を現在のシェルに読み込みます。

```bash
set -a
source .env
set +a
```

### 4.2 接続コマンド

```bash
PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

### 4.3 接続後に最初に打つ（便利設定）

psql内で実行：

```sql
\set ON_ERROR_STOP on
\timing on
\x auto
```

- `ON_ERROR_STOP`：エラーが出たら止まる（ログが壊れにくい）
- `\timing`：実行時間が出る（性能学習の入口）
- `\x auto`：横長結果が見やすい

---

## 5. psql基本メタコマンド

psql内で順に実行：

```sql
\conninfo
\l
\dt
\d app_user
\d product
\di
```

- `\dt`：テーブル一覧
- `\d <table>`：テーブル定義表示
- `\di`：インデックス一覧

---

## 6. SQLファイル実行（再現性の練習）

### 6.1 ファイル

- `sql/000_phase0_sanity.sql`

### 6.2 実行コマンド（psql）

`.env` を読み込んだ状態で：

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/000_phase0_sanity.sql
```

### 6.3 見るポイント

- `version()` が返る
- `app_user / product / customer_order / order_item` の件数が返る
- `product` が一覧で表示される

---

## 7. EXPLAINの入口（実行計画を出す）

### 7.1 ファイル

- `sql/001_phase0_explain.sql`

### 7.2 実行（psql）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/001_phase0_explain.sql
```

### 7.3 見るポイント（「慣れる」が目的）

- `EXPLAIN` の結果が出る（`Seq Scan` / `Index Scan` などの文字が見える）
- `EXPLAIN (ANALYZE, BUFFERS)` は「実際に実行して計測する」ので、結果が増えても驚かない
  - 今はデータが少ないので速いが、以後の性能学習の基礎になる

---

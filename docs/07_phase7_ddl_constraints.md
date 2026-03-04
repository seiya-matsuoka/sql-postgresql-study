# Phase 7：DDL・テーブル設計・制約（ec-v1 + labスキーマ）

> このPhaseでは、ec-v1を壊さずに学ぶために、同じDB内に `lab` スキーマ（実験場）を作り、そこでDDL（CREATE/ALTER/DROP）と制約（PK/FK/UNIQUE/CHECK/NOT NULL/DEFAULT）を一通り体験します。

---

## 0. ゴール

- `lab`スキーマを作り、テーブルを定義できる（DDLの基本）
- 主キー（`PK`）、外部キー（`FK`）、一意制約（`UNIQUE`）、チェック制約（`CHECK`）、`NOT NULL`、`DEFAULT` を体験する
- 制約違反が起きたときのエラーメッセージを読める
- 「見える化」（`constraints/index/columns` をメタ情報から確認）できる
- labスキーマを 一発リセット できる（`DROP SCHEMA ... CASCADE`）

---

## 1. 対象ファイル（Phase 7）

- `sql/070_lab_reset.sql`
- `sql/071_lab_schema.sql`
- `sql/072_lab_seed.sql`
- `sql/073_lab_constraint_violation_demo.sql`
- `sql/074_lab_alter_table_practice.sql`
- `sql/075_lab_introspection.sql`

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

まずは 作り直し可能 を前提に、毎回リセットしてから進めるのを推奨します。

### 3.1 初期化（labを作り直す）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/070_lab_reset.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/071_lab_schema.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/072_lab_seed.sql
```

### 3.2 見える化でメタ情報確認

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/075_lab_introspection.sql
```

### 3.3 制約違反デモ（エラーを 安全に 眺める）

このSQLは、内部で例外を捕まえて `NOTICE` を出すので、`ON_ERROR_STOP=1` でも止まりません。

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/073_lab_constraint_violation_demo.sql
```

### 3.4 `ALTER TABLE`（後から制約を足す/変更する）練習

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/074_lab_alter_table_practice.sql
```

---

## 4. psql上の確認コマンド（手で見たい場合）

psqlで接続した状態で、以下が便利です。

```sql
\dn
\dt lab.*
\d lab.customer
\d lab.account
\d lab.transfer
\d lab.simple_order
\d lab.simple_order_line
```

---

## 5. ポイント

- `PK/FK/UNIQUE/CHECK/NOT NULL/DEFAULT` は「データの正しさ」をDBに守らせる仕組み
- 制約は アプリのバリデーションの代わり ではなく 最後の砦
- `FK`列には（必要に応じて）インデックスを貼るのが定番（PostgreSQLは自動では貼られない）
- 「追加（`ALTER`）」はデータが既にあると失敗することがある → 直してから制約を入れる
- いつでも `sql/070_lab_reset.sql` でやり直せる状態を保つ

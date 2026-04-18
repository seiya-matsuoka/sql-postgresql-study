# Phase 11：トリガ（必要最小）（labスキーマの専用題材）

> このPhaseでは、`lab` スキーマにトリガ学習用の小さなテーブル群を作って、
> トリガの基本と注意点を体験します。

扱う題材は以下の3つです。

- 監査ログ（audit）
  - UPDATE / DELETE の前後データを `lab.trg_audit_log` に保存
- updated_at 自動更新
  - UPDATE時に `updated_at` を自動更新
- 在庫連動
  - 注文ステータスを `draft -> paid` に変更したときに在庫を減らす

※ ec-v1 本体にはトリガを貼らず、学習用の `lab` 内で完結させます。

---

## 0. ゴール

- トリガ関数（RETURNS trigger）を作れる
- BEFORE / AFTER、FOR EACH ROW の違いを体験できる
- `TG_OP` / `TG_TABLE_NAME` / `OLD` / `NEW` を使える
- 更新時に `updated_at` を自動更新できる
- 監査ログテーブルに UPDATE / DELETE の履歴を残せる
- トリガで副作用（在庫減算）が起きることを体感できる
- トリガの有効化 / 無効化（ENABLE / DISABLE）を試せる
- `pg_trigger` などでトリガを見える化できる

---

## 1. 対象ファイル（Phase 11）

- `sql/110_lab_phase11_trigger_fixture_prepare.sql`
- `sql/111_lab_triggers_create_functions.sql`
- `sql/112_lab_triggers_create_triggers.sql`
- `sql/113_lab_triggers_usage_updated_at_audit.sql`
- `sql/114_lab_triggers_usage_inventory.sql`
- `sql/115_lab_triggers_introspection.sql`
- `sql/116_lab_triggers_disable_enable_demo.sql`

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

- `lab` スキーマが存在していること（Phase 7〜10で使用済み）
- このPhaseで使う `lab.trg_*` テーブルは、専用題材として新規作成する
- 既存の `lab.customer` / `lab.account` などには影響しない構成にする

---

## 3. 実行手順（psql：CLI）

### 3.1 専用題材テーブル + seed を作る（何度でも再実行OK）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/110_lab_phase11_trigger_fixture_prepare.sql
```

### 3.2 トリガ関数を作成

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/111_lab_triggers_create_functions.sql
```

### 3.3 トリガ本体を作成

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/112_lab_triggers_create_triggers.sql
```

### 3.4 updated_at 自動更新 + audit を体験

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/113_lab_triggers_usage_updated_at_audit.sql
```

### 3.5 在庫連動トリガを体験（成功 / 在庫不足）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/114_lab_triggers_usage_inventory.sql
```

### 3.6 トリガの見える化（推奨）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/115_lab_triggers_introspection.sql
```

### 3.7 トリガの無効化 / 有効化（注意点の体験）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/116_lab_triggers_disable_enable_demo.sql
```

---

## 4. psql上の確認コマンド

psqlで接続した状態で、以下が便利です。

```sql
\dt lab.trg_*
\d+ lab.trg_product
\d+ lab.trg_order
\d+ lab.trg_audit_log
\df lab.fn_trg_*
\df+ lab.fn_trg_*
```

---

## 5. ポイント

- トリガは「SQLを書いた本人が明示的に呼ばなくても動く」
  - 便利だが、見えにくい（副作用の把握が難しい）
- `BEFORE UPDATE` は列値の書き換え（`updated_at`）に向いている
- `AFTER UPDATE/DELETE` は監査ログの記録に向いている
- 在庫連動のような業務処理をトリガでやると便利だが、
  - どこで在庫が減ったか追いにくい
  - 例外時に何が起きたか把握しづらい
  - アプリ側の処理と責務が分散しやすい
- つまり、トリガは「使いどころを絞る」のが大事

---

## 6. 補足（標準SQL / PostgreSQL）

- トリガの概念は多くのRDBMSにあるが、文法・記法はDBごとの差が大きい
- 今回の `LANGUAGE plpgsql` / `TG_OP` / `TG_TABLE_NAME` / `to_jsonb()` などは PostgreSQL 寄り
- 実務では「監査ログ」「updated_at自動更新」あたりは比較的使いやすく、
  「在庫連動」のような重い業務ロジックは慎重に使うことが多い

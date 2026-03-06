# Phase 8：更新系（DML）とトランザクション（labスキーマ）

> このPhaseでは、Phase 7で作成した `lab` スキーマを使って、DML（INSERT / UPDATE / DELETE）とトランザクション（BEGIN / COMMIT / ROLLBACK / SAVEPOINT）を実際に動かして学びます。  
> ec-v1（public側）は引き続き温存し、更新系の学習は `lab` で安全に進めます。

---

## 0. ゴール

- INSERT / UPDATE / DELETE の基本形を使える
- INSERT ... SELECT / UPDATE ... FROM / DELETE ... USING（および標準寄りの代替）を体験する
- ON CONFLICT（PostgreSQL）と MERGE（標準SQL系）の考え方を理解する
- RETURNING（PostgreSQL）の便利さを知る
- BEGIN / COMMIT / ROLLBACK / SAVEPOINT を使って更新の確定・取り消しを体験する
- 2セッションでロック待ち（ブロック）を体験する
- `SELECT ... FOR UPDATE` の役割を理解する

---

## 1. 対象ファイル（Phase 8）

- `sql/080_lab_phase8_fixture_prepare.sql`
- `sql/081_lab_dml_insert_update_delete.sql`
- `sql/082_lab_dml_upsert_merge_returning.sql`
- `sql/083_lab_transaction_basic_savepoint.sql`
- `sql/084_lab_transaction_lock_session_a.sql`
- `sql/085_lab_transaction_lock_session_b.sql`

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

### 2.3 labスキーマがない/壊れている場合の再作成（Phase 7の再実行）

必要なら以下を先に実行してください。

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/070_lab_reset.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/071_lab_schema.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/072_lab_seed.sql
```

---

## 3. 実行手順（psql：CLI）

### 3.1 Phase 8用のデモデータを準備（何度でも再実行OK）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/080_lab_phase8_fixture_prepare.sql
```

### 3.2 DML（基本）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/081_lab_dml_insert_update_delete.sql
```

### 3.3 UPSERT / MERGE / RETURNING（PostgreSQLと標準寄り）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/082_lab_dml_upsert_merge_returning.sql
```

### 3.4 トランザクション（COMMIT / ROLLBACK / SAVEPOINT）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/083_lab_transaction_basic_savepoint.sql
```

---

## 4. 2セッションでロック待ちを体験（重要）

この手順だけは、ターミナル（またはDBeaverのSQLエディタ）を2つ使います。

### 4.1 セッションA（先に実行）

別ターミナルAで実行：

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/084_lab_transaction_lock_session_a.sql
```

### 4.2 セッションB（Aの実行中に実行）

Aが `pg_sleep(20)` に入っている間に、別ターミナルBで実行：

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/085_lab_transaction_lock_session_b.sql
```

ポイント：

- セッションBのUPDATEが、セッションAのCOMMITまで待たされる（ブロックされる）
- これが「ロックで整合性を守る」体験
- Session Bは最後にROLLBACKするので、データは元に戻る

---

## 5. DBeaverでやる場合

- 同じ接続でSQLエディタを2つ開く
- セッションA用SQLを片方、セッションB用SQLを片方に貼る
- Aを実行してから、Bを実行する
- 結果と待ち時間を確認する

---

## 6. ポイント

- DMLは「更新できる」だけでなく、「どこまでを1つの処理として確定するか」が大事（トランザクション）
- 送金のような複数UPDATEは、BEGIN〜COMMITでまとめて1つの意味にする
- SAVEPOINTを使うと、トランザクション全体を落とさずに 途中だけ戻す ができる
- ロックは怖いものではなく、整合性を守るための基本機能
- PostgreSQLの便利機能（ON CONFLICT / RETURNING）は強力だが、標準寄りの書き方（MERGEなど）も知っておくと応用しやすい

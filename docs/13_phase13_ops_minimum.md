# Phase 13：運用寄り（最低限）

> このPhaseは、これまで作ってきたSQLスキルを「運用で困らない最低限の型」に落とすための内容です。  
> 対象は PostgreSQL（Docker運用）です。

扱うテーマ：

- バックアップ/リストア（pg_dump / pg_restore）
- 権限（ROLE / GRANT の基礎）
- メンテ（VACUUM / ANALYZE の役割）
- 調査（pg_stat_activity / ロックの見え方）

※このPhaseは “知識だけ” ではなく、実際にコマンドとSQLを動かして体験する前提です。

---

## 0. 事前準備（共通）

### 0.1 DB起動確認

```bash
docker compose ps
```

### 0.2 `.env` 読み込み（Git Bash）

```bash
set -a
source .env
set +a
```

---

## 1. まずは現状確認（テーブル・サイズ・統計）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/130_ops_precheck.sql
```

---

## 2. 権限（ROLE / GRANT）を体験

このPhaseでは「既存の public を触らずに」学ぶため、`ops_lab` スキーマを作ってそこで練習します。

### 2.1 セットアップ（スキーマ/テーブル/ロール作成・GRANT）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/131_ops_roles_grants_setup.sql
```

### 2.2 検証（SET ROLE して “できる/できない” を確認）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/132_ops_roles_grants_verify.sql
```

ポイント：

- 実務では「最小権限」が基本
- テーブルだけでなく、シーケンスやスキーマのUSAGEなども絡む
- 新規作成分にも自動で権限を付けるなら ALTER DEFAULT PRIVILEGES

---

## 3. メンテ（VACUUM / ANALYZE）を体験

### 3.1 実行（ops_lab の小さなテーブルで差を見やすく）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/133_ops_vacuum_analyze.sql
```

ポイント：

- ANALYZE：統計情報を更新 → 実行計画（EXPLAIN）の精度に影響
- VACUUM：死んだ行（MVCC）を掃除して膨張を抑える（物理的な回収の話も含む）
- ふだんは autovacuum が動くが、「何をしているか」を読めるのが最低限

---

## 4. 調査（pg_stat_activity / ロック）を眺める

### 4.1 今動いているSQL・待ち状態を確認

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/134_ops_activity_and_locks.sql
```

補足：

- ここは「日常の調査の型」なので、Phase 8（ロック体験）と繋がります
- “待っている理由” が分かるだけで事故率が下がります

---

## 5. バックアップ/リストア（pg_dump / pg_restore）

ここは「概念だけ」ではなく、実際に dump を取って restore までやります。  
ただし、Windows環境では pg_dump がローカルに無い可能性があるので、2パターン用意します。

### 5.1 まずおすすめ（ローカルに pg_dump がある場合）

1. dump（カスタム形式：復元が柔軟）

```bash
pg_dump -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -F c -f backups/phase13_db.dump
```

2. dump（プレーンSQL：中身が読める）

```bash
pg_dump -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -F p -f backups/phase13_db.sql
```

### 5.2 pg_dump がローカルに無い場合（コンテナ内で実行）

※ service名が `db` でない場合は、あなたの docker-compose のサービス名に置換してください。

1. コンテナ内に dump を作る

```bash
docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -F c -f /tmp/phase13_db.dump
```

2. コンテナID取得

```bash
docker compose ps -q db
```

3. docker cp でホストへコピー（<container_id> は上の出力を使う）

```bash
docker cp <container_id>:/tmp/phase13_db.dump backups/phase13_db.dump
```

### 5.3 リストア（別DBに戻す練習）

リストア先DB（例：phase13_restore）を作る。

1. DB作成（postgres DBへ接続して実行するのが安全）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS phase13_restore;"
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE phase13_restore;"
```

2. リストア（カスタム形式）

```bash
pg_restore -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d phase13_restore backups/phase13_db.dump
```

3. 復元確認（件数を見る）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d phase13_restore -c "SELECT COUNT(\*) FROM public.customer_order;"
```

※ pg_restore がローカルに無い場合は、pg_dumpと同様にコンテナ内で実行できます。

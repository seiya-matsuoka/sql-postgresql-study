# Phase 10：関数・プロシージャ（ストアド）（labスキーマ中心）

> このPhaseでは、PostgreSQLのストアドルーチン（関数 / プロシージャ）を学びます。  
> 学習の主役は「データ内容」よりも、「どう作るか」「どこで使うか」です。

- 関数（FUNCTION）: SELECTの中で使える。値や表を返す
- プロシージャ（PROCEDURE）: CALLで実行する。処理手順をまとめる

このPhaseでは以下の2系統を扱います。

- 参照系関数: レポートSQLの部品化（期間指定、集計など）
- 更新系プロシージャ: 送金処理 / 注文確定のような手順のまとめ

---

## 0. ゴール

- SQL関数 / PLpgSQL関数を作って使える
- RETURNS TABLE / RETURN QUERY の使い方を体験する
- CREATE PROCEDURE / CALL を使って更新処理をまとめられる
- 例外（RAISE EXCEPTION）で入力チェックできる
- プロシージャの更新が、呼び出し側トランザクション（BEGIN/ROLLBACK）に乗ることを確認する
- information_schema / pg_proc で関数・プロシージャを見える化できる

---

## 1. 対象ファイル（Phase 10）

- `sql/100_lab_phase10_fixture_prepare.sql`
- `sql/101_lab_routines_create_functions.sql`
- `sql/102_lab_routines_create_procedures.sql`
- `sql/103_lab_routines_usage_functions.sql`
- `sql/104_lab_routines_usage_procedures.sql`
- `sql/105_lab_routines_introspection.sql`

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

- Phase 7〜8 の `lab` スキーマが存在していること
- Phase 9 の `view_lab` スキーマが存在していること（参照系関数の一部で利用）
- もし壊れていたら、必要に応じて Phase 7/8/9 を再実行

---

## 3. 実行手順（psql：CLI）

### 3.1 Phase 10用のデモデータ準備

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/100_lab_phase10_fixture_prepare.sql
```

### 3.2 関数を作成

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/101_lab_routines_create_functions.sql
```

### 3.3 プロシージャを作成

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/102_lab_routines_create_procedures.sql
```

### 3.4 関数を使ってみる

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/103_lab_routines_usage_functions.sql
```

### 3.5 プロシージャを使ってみる（成功・失敗・ROLLBACK）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/104_lab_routines_usage_procedures.sql
```

### 3.6 ルーチンの見える化（推奨）

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/105_lab_routines_introspection.sql
```

---

## 4. psql上の確認コマンド

psqlで接続した状態で、以下が便利です。

```sql
\df lab.*
\df+ lab.*
\sf lab.fn_simple_order_total_yen
\sf lab.fn_ec_daily_revenue_between
\dfp+ lab.*
```

※ `\dfp` は環境によって表示差があることがあります。表示できない場合は `sql/105_lab_routines_introspection.sql` の結果で確認してください。

---

## 5. ポイント

- 関数は「SELECTの部品化」に強い（再利用しやすい）
- プロシージャは「更新手順のまとまり」に向いている（CALLで実行）
- 入力チェックや業務ルールをDB側に寄せると、呼び出し元がシンプルになる
- ただし、ロジックをDBに寄せすぎると見通しが悪くなることもあるので、役割分担が大事
- PostgreSQLのPL/pgSQLは便利だが、DB方言寄りの知識（汎用SQLとは別軸）になる

---

## 6. 補足（標準SQL / PostgreSQL）

- `CREATE FUNCTION` / `CREATE PROCEDURE` 自体は多くのRDBMSにあるが、文法・言語・機能差が大きい
- 今回の `LANGUAGE plpgsql` / `RETURN QUERY` / `RAISE EXCEPTION` / `FOUND` などは PostgreSQL寄り
- その代わり、実務で「DBに処理を持たせる」感覚を掴むのに非常に良い

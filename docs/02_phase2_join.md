# Phase 2：JOINを実務レベルにする

> このドキュメントは、JOINを実務で迷わないレベルにするための手順ログです。  
> INNER/LEFTの基本、ONとWHEREの違い、多段JOIN、行数が増える（重複する）理由、自己JOINの入口まで扱います。

---

## 0. ゴール

- INNER JOIN / LEFT JOIN の違いを結果で説明できる
- ON と WHERE の置き方で結果が変わる典型パターンを体験する
- 「1対多」でJOINすると行が増える理由を体験する
- 多段JOIN（注文 → 明細 → 商品）をスムーズに書ける
- 自己JOINの基本形が分かる（同じテーブルを別名でJOIN）

---

## 1. 対象ファイル（Phase 2）

- `sql/020_join_inner_left_basics.sql`
- `sql/021_join_on_vs_where.sql`
- `sql/022_join_multiplication_and_distinct.sql`
- `sql/023_join_multi_table_ec.sql`
- `sql/024_self_join_examples.sql`

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
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/020_join_inner_left_basics.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/021_join_on_vs_where.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/022_join_multiplication_and_distinct.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/023_join_multi_table_ec.sql
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f sql/024_self_join_examples.sql
```

---

## 4. ポイント

- LEFT JOINなのに WHEREで右テーブル条件を書くと、結果がINNER JOINみたいに減る（典型的な罠）
- JOINすると行が増えるのは「1対多」だから（注文に明細が複数あるなど）
- DISTINCTで“見た目だけ”重複を消すのは便利だが、意味が変わる可能性がある（集約で解決すべき場面もある）
- 多段JOINでは「どのキーで繋いでいるか」を常に意識する
- 自己JOINは「同じ表を別名で2回使う」だけ（難しさは“条件”）

---

## 5. DBeaver（GUI）での確認

- 結果セットを見比べるのが楽なので、020〜023あたりはGUIで眺めると理解が速い
- 021の「ON vs WHERE」の差を、結果行数で確認する

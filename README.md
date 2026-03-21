# SQL / PostgreSQL - Study

<p>
  <img alt="SQL Study" src="https://img.shields.io/badge/SQL-Study%20-336791?logo=postgresql&logoColor=ffffff">
  <img alt="PostgreSQL" src="https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=ffffff">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-Local%20DB-2496ED?logo=docker&logoColor=ffffff">
  <img alt="psql" src="https://img.shields.io/badge/psql-CLI-336791?logo=postgresql&logoColor=ffffff">
  <img alt="DBeaver" src="https://img.shields.io/badge/DBeaver-GUI-372923">
</p>

PostgreSQL を使って SQL / データベースを体系的に学習した記録と成果物をまとめたリポジトリ。  
Docker でローカルに DB 環境を構築し、基礎的な SELECT から、JOIN、集約、ウィンドウ関数、DDL/DML、トランザクション、VIEW、関数・プロシージャ、トリガ、性能、運用の最低限までを一通り学習した。

このリポジトリは、以下の役割を兼ねている。

- SQL / DB 学習の記録
- 再実行可能な教材置き場
- 検証用の SQL / schema / seed の保存場所
- 各学習フェーズの手順メモ置き場

> **学習用リポジトリ**として、実際に試した内容を蓄積していくことを目的にしている。  
> あくまで **「学習の流れを残すこと」「後から見返して再現できること」** を重視している。

---

## 概要

学習の流れは、以下のイメージ。

- 前半  
  SELECT / JOIN / 集約 / サブクエリ / CTE / ウィンドウ関数など、SQL を書いて読む
- 中盤  
  DDL / 制約 / DML / トランザクション / VIEW / ストアド / トリガなど、DB の機能を広く触る
- 後半  
  実行計画 / インデックス / クエリ改善 / 権限 / バックアップ / VACUUM / ANALYZE など、性能と運用の入口を学ぶ

---

## 学習範囲

このリポジトリでは、以下の内容を一通り学習対象として扱った。

| Phase    | 内容                                                              |
| -------- | ----------------------------------------------------------------- |
| Phase 0  | 環境・基本操作                                                    |
| Phase 1  | SELECT 基礎 / CASE                                                |
| Phase 2  | JOIN                                                              |
| Phase 3  | 集約 / レポート系                                                 |
| Phase 4  | サブクエリ / EXISTS / 集合演算                                    |
| Phase 5  | CTE（WITH）/ 再帰                                                 |
| Phase 6  | ウィンドウ関数                                                    |
| Phase 7  | DDL / テーブル設計 / 制約                                         |
| Phase 8  | DML / トランザクション                                            |
| Phase 9  | VIEW / MATERIALIZED VIEW                                          |
| Phase 10 | 関数 / プロシージャ（ストアド）                                   |
| Phase 11 | トリガ                                                            |
| Phase 12 | 性能（EXPLAIN / INDEX / クエリ改善）                              |
| Phase 13 | 運用寄りの最低限（バックアップ / 権限 / VACUUM / ANALYZE / 調査） |

基礎から順に進めつつ、後半では PostgreSQL の実務寄り機能や、性能改善・運用の入口にも触れている。

---

## 使用技術・環境

- PostgreSQL
- Docker / Docker Compose
- psql
- DBeaver
- Git Bash

---

## セットアップ

### 1. `.env.example` を `.env` にコピー

```bash
cp .env.example .env
```

### 2. `.env` を必要に応じて編集

例:

```env
POSTGRES_USER=study
POSTGRES_PASSWORD=study_change_me
POSTGRES_DB=studydb
PG_PORT=5432
PG_CONTAINER_NAME=pg-study
DBSET=ec-v1
```

### 3. PostgreSQL を起動

```bash
docker compose up -d
docker compose ps
```

### 4. Git Bash で `.env` を読み込む

```bash
set -a
source .env
set +a
```

### 5. psql で接続

```bash
psql -h localhost -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

### 6. DBeaver で接続

接続情報の例:

- Host: `localhost`
- Port: `.env` の `PG_PORT`
- Database: `.env` の `POSTGRES_DB`
- User: `.env` の `POSTGRES_USER`
- Password: `.env` の `POSTGRES_PASSWORD`

---

## データセットの切り替え方

学習内容に応じて複数のデータセットを切り替えながら進める。

### 主なデータセット

- `ec-v0`
  - 初期学習用の最小構成
  - SELECT / JOIN / 基礎理解向け

- `ec-v1`
  - 実務寄りにボリュームを増やした学習用データセット
  - 集約 / レポート / CTE / ウィンドウ関数などに使用

- `ec-perf-v1`
  - 性能学習専用データセット
  - EXPLAIN / EXPLAIN ANALYZE / INDEX / クエリ改善向け

### 切り替え手順

`.env` の `DBSET` を変更してから、ボリュームごと作り直す。

```bash
docker compose down -v
docker compose up -d
```

例:

```env
DBSET=ec-v1
```

または

```env
DBSET=ec-perf-v1
```

補足:

- `down -v` を使うため、既存のデータ領域は削除される。
- 学習用データは `datasets/` 配下の schema / seed から再構築する前提。

---

## ディレクトリ構成

主要な構成は以下の通り。

```text
.
├─ datasets/
│  ├─ ec-v0/
│  ├─ ec-v1/
│  └─ ec-perf-v1/
│
├─ docs/
│  ├─ 00_phase0_environment.md
│  ├─ 01_phase1_select_case.md
│  ├─ ...
│  └─ 13_phase13_ops_minimum.md
│
├─ sql/
│  ├─ 000_phase0_sanity.sql
│  ├─ 001_...
│  ├─ 010_...
│  ├─ 020_...
│  ├─ ...
│  └─ 135_...
│
├─ docker-compose.yml
├─ .env.example
└─ README.md
```

### 各ディレクトリの役割

- `datasets/`
  - 学習用データセットの schema / seed
  - データセットごとに初期化 SQL を管理

- `docs/`
  - 各 Phase の学習手順、実行順、ポイントなどのメモ
  - 学習ログ兼、再開用のガイド

- `sql/`
  - 実際に実行した SQL
  - フェーズごとに採番して管理

- `docker-compose.yml`
  - PostgreSQL ローカル環境起動用

- `.env.example`
  - ローカル環境設定のテンプレート

---

## 学習の進め方・ファイルの見方

基本的には、`docs/` と `sql/` を対応させて順番に進める構成。

### 進め方

1. `docs/` の対象 Phase の md を読む
2. 記載されている順番で `sql/` のファイルを実行する
3. 結果を確認しながら学習する
4. 必要に応じて DBeaver でも同じ SQL を試す

### SQL ファイルの採番ルール

- フェーズの開始番号は 3 桁 + 10 刻み
  - 例: `010`, `020`, `030`, ...
- 同じフェーズ内で複数ファイルがある場合は連番
  - 例: `020`, `021`, `022`

### SQL の記述方針

- 基本は PostgreSQL を前提に実行可能な SQL
- 可能な範囲では標準 SQL / 汎用的な書き方も意識
- PostgreSQL 特有の書き方を使う場合は、必要に応じて標準寄りの書き方も併記

---

## 学習用スキーマ・専用領域について

後半の学習では、既存データセットを壊さずに学習するため、専用スキーマも使う。

### `lab`

DDL / 制約 / DML / トランザクション / 関数 / プロシージャ / トリガ などの学習用スキーマ。

### `view_lab`

VIEW / MATERIALIZED VIEW の学習用スキーマ。

### `ops_lab`

権限（ROLE / GRANT）や運用寄り学習の練習用スキーマ。

これらは「本体データセットを温存しつつ、安全に壊して学ぶ」ための領域。

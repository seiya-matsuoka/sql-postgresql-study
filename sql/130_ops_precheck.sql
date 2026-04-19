-- phase: 13
-- topic: 運用のための事前確認（サイズ/統計/基本状態）
-- dataset: 現在接続中のDB（ec-perf-v1想定だが、他でも可）
-- 0) 接続情報
SELECT
    current_database() AS db,
    current_user AS usr,
    CURRENT_TIMESTAMP AS now;

-- 1) テーブルサイズ（public主要テーブルがある場合）
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relname IN (
        'app_user',
        'user_address',
        'product',
        'customer_order',
        'order_item'
    )
ORDER BY
    pg_total_relation_size(c.oid) DESC;

-- 2) 統計（Seq Scan / Index Scan / dead tuple など）
SELECT
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    seq_scan,
    idx_scan,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM
    pg_stat_user_tables
WHERE
    schemaname = 'public'
ORDER BY
    relname;

-- 3) autovacuum 設定（確認だけ）
SHOW autovacuum;

SHOW track_counts;

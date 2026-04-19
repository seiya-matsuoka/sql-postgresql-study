-- phase: 12
-- topic: 統計・サイズ・索引利用状況の確認（見える化）
-- dataset: ec-perf-v1
-- 目的:
--   - どのテーブルが大きいか
--   - Seq Scan / Index Scan がどれくらい起きたか
--   - 実行計画の読み方を補強する
SET
    jit = off;

-- 1) テーブルサイズ（データ + 索引含む）
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

-- 2) テーブル統計（Seq Scan / Index Scan）
SELECT
    relname AS table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_live_tup,
    n_dead_tup,
    last_analyze,
    last_autoanalyze
FROM
    pg_stat_user_tables
WHERE
    schemaname = 'public'
    AND relname IN (
        'app_user',
        'user_address',
        'product',
        'customer_order',
        'order_item'
    )
ORDER BY
    relname;

-- 3) 索引利用統計（Phase 12で作った索引含む）
SELECT
    s.relname AS table_name,
    s.indexrelname AS index_name,
    s.idx_scan,
    s.idx_tup_read,
    s.idx_tup_fetch,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size
FROM
    pg_stat_user_indexes s
WHERE
    s.schemaname = 'public'
    AND s.relname IN ('customer_order', 'order_item')
ORDER BY
    s.relname,
    s.idx_scan DESC,
    s.indexrelname;

-- 4) 実行計画の読解練習（もう一度）
--    直近30日、都道府県別売上
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    ua.prefecture,
    COUNT(*) AS order_count,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    public.customer_order o
    JOIN public.order_item oi ON oi.order_id = o.id
    JOIN public.user_address ua ON ua.user_id = o.user_id
    AND ua.is_default = TRUE
WHERE
    o.order_status IN ('paid', 'shipped', 'delivered')
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    ua.prefecture
ORDER BY
    revenue_yen DESC,
    ua.prefecture;

-- 5) 観察ポイント（コメント）
--   - どのテーブルが一番大きいか（だいたい order_item）
--   - idx_scan が増えている索引は何か
--   - 実行計画で一番時間がかかっているノードはどこか
--   - rows 見積と actual rows が大きくズレていないか

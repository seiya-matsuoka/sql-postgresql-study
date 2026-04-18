-- dataset: ec-perf-v1
-- purpose: 初期統計情報の更新 + 最低限の件数確認
-- 方針:
--   - Phase 12でEXPLAIN ANALYZEを見る前に統計情報を整える
--   - まずは ANALYZE を実行
ANALYZE;

-- 最低限の件数確認
SELECT
    'app_user' AS table_name,
    COUNT(*) AS row_count
FROM
    public.app_user
UNION ALL
SELECT
    'user_address',
    COUNT(*)
FROM
    public.user_address
UNION ALL
SELECT
    'product',
    COUNT(*)
FROM
    public.product
UNION ALL
SELECT
    'customer_order',
    COUNT(*)
FROM
    public.customer_order
UNION ALL
SELECT
    'order_item',
    COUNT(*)
FROM
    public.order_item
ORDER BY
    table_name;

-- 日付範囲確認
SELECT
    MIN(ordered_at) AS min_ordered_at,
    MAX(ordered_at) AS max_ordered_at
FROM
    public.customer_order;

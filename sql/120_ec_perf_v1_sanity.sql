-- phase: 12
-- topic: ec-perf-v1 の件数・分布確認（sanity）
-- dataset: ec-perf-v1
-- 目的:
--   - 想定どおりのデータ量が入っているか確認
--   - 偏り（ヘビーユーザー、商品偏り）を確認
--   - 性能学習前の前提確認
-- 1) テーブル件数
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

-- 2) 注文ステータス分布
SELECT
    order_status,
    COUNT(*) AS cnt
FROM
    public.customer_order
GROUP BY
    order_status
ORDER BY
    cnt DESC,
    order_status;

-- 3) 注文日付の範囲
SELECT
    MIN(ordered_at) AS min_ordered_at,
    MAX(ordered_at) AS max_ordered_at
FROM
    public.customer_order;

-- 4) 1注文あたりの明細数
SELECT
    ROUND(AVG(item_count), 2) AS avg_items_per_order,
    MIN(item_count) AS min_items_per_order,
    MAX(item_count) AS max_items_per_order
FROM
    (
        SELECT
            order_id,
            COUNT(*) AS item_count
        FROM
            public.order_item
        GROUP BY
            order_id
    ) t;

-- 5) ヘビーユーザー上位（偏り確認）
SELECT
    o.user_id,
    COUNT(*) AS order_count
FROM
    public.customer_order o
GROUP BY
    o.user_id
ORDER BY
    order_count DESC,
    o.user_id
LIMIT
    20;

-- 6) 人気商品上位（偏り確認）
SELECT
    oi.product_id,
    COUNT(*) AS line_count,
    SUM(oi.quantity) AS qty_sum
FROM
    public.order_item oi
GROUP BY
    oi.product_id
ORDER BY
    qty_sum DESC,
    oi.product_id
LIMIT
    20;

-- 7) 直近90日対象の注文件数（以降のクエリでよく使う条件）
SELECT
    COUNT(*) AS recent_paid_like_orders
FROM
    public.customer_order o
WHERE
    o.order_status IN ('paid', 'shipped', 'delivered')
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '90 days';

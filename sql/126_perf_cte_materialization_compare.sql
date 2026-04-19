-- phase: 12
-- topic: CTEの比較（通常 / MATERIALIZED / NOT MATERIALIZED）
-- dataset: ec-perf-v1
-- 目的:
--   - CTEの書き方で実行計画が変わることを体験する
--   - PostgreSQL特有の MATERIALIZED / NOT MATERIALIZED を知る
-- 題材:
--   - 直近60日・paid系注文を先に絞ってから商品カテゴリ別売上集計
SET
    jit = off;

-- 0) 比較対象クエリ（通常CTE）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
WITH
    recent_orders AS (
        SELECT
            o.id,
            o.user_id
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '60 days'
    )
SELECT
    p.category,
    COUNT(*) AS line_count,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    recent_orders ro
    JOIN public.order_item oi ON oi.order_id = ro.id
    JOIN public.product p ON p.id = oi.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC,
    p.category;

-- 1) PostgreSQL特有: MATERIALIZED（CTEを明示的に実体化）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
WITH
    recent_orders AS MATERIALIZED (
        SELECT
            o.id,
            o.user_id
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '60 days'
    )
SELECT
    p.category,
    COUNT(*) AS line_count,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    recent_orders ro
    JOIN public.order_item oi ON oi.order_id = ro.id
    JOIN public.product p ON p.id = oi.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC,
    p.category;

-- 2) PostgreSQL特有: NOT MATERIALIZED（インライン化寄り）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
WITH
    recent_orders AS NOT MATERIALIZED (
        SELECT
            o.id,
            o.user_id
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '60 days'
    )
SELECT
    p.category,
    COUNT(*) AS line_count,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    recent_orders ro
    JOIN public.order_item oi ON oi.order_id = ro.id
    JOIN public.product p ON p.id = oi.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC,
    p.category;

-- 3) 結果確認（値は同じ）
WITH
    recent_orders AS (
        SELECT
            o.id,
            o.user_id
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '60 days'
    )
SELECT
    p.category,
    COUNT(*) AS line_count,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    recent_orders ro
    JOIN public.order_item oi ON oi.order_id = ro.id
    JOIN public.product p ON p.id = oi.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC,
    p.category;

-- 4) 補足
--   - CTE自体（WITH）は広く使われる
--   - MATERIALIZED / NOT MATERIALIZED は PostgreSQL特有の制御
--   - 実務では「読みやすさ」と「性能」のバランスで選ぶ

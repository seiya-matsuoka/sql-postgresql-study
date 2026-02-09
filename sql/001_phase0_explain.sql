-- phase: 0
-- purpose: EXPLAIN の入口（実行計画を「出せる」状態にする）
-- dataset: ec-v0
-- note:
--   - EXPLAIN は実行計画の表示
--   - EXPLAIN (ANALYZE, BUFFERS) は実際にSQLを実行して計測も行う（副作用のあるSQLでは注意）
-- まずは EXPLAIN（実行はしない）
EXPLAIN
SELECT
    *
FROM
    product
WHERE
    category = 'pc';

-- 計測付き（実行する）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    *
FROM
    product
WHERE
    category = 'pc';

-- JOIN の EXPLAIN（出せることが目的）
EXPLAIN
SELECT
    o.id AS order_id,
    o.order_status,
    i.line_no,
    p.name AS product_name,
    i.quantity,
    i.unit_price_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
    JOIN product p ON p.id = i.product_id
WHERE
    o.user_id = 1
ORDER BY
    o.ordered_at DESC;

-- 計測付き（データが少ないので速いはず）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    o.id AS order_id,
    o.order_status,
    i.line_no,
    p.name AS product_name,
    i.quantity,
    i.unit_price_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
    JOIN product p ON p.id = i.product_id
WHERE
    o.user_id = 1
ORDER BY
    o.ordered_at DESC;

-- phase: 4
-- topic: NOT EXISTS（アンチJOIN：存在しないものを探す）
-- dataset: ec-v1
-- 目的:
--   - 「〜が存在しない」を安全に書く（NOT IN の罠を回避）
--   - LEFT JOIN ... IS NULL と同じ発想で使い分けできるようにする
-- 0) 注文が1件もないユーザー（NOT EXISTS）
SELECT
    u.id AS user_id,
    u.display_name
FROM
    app_user u
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            customer_order o
        WHERE
            o.user_id = u.id
    )
ORDER BY
    u.id
LIMIT
    30;

-- 1) 一度も売れていない商品（注文明細に存在しない商品）
SELECT
    p.id AS product_id,
    p.sku,
    p.name,
    p.category,
    p.price_yen
FROM
    product p
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            order_item oi
        WHERE
            oi.product_id = p.id
    )
ORDER BY
    p.id
LIMIT
    30;

-- 2) 支払いが存在しない注文（例：draft を含むので存在しないものが混ざり得る）
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    customer_order o
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            payment p
        WHERE
            p.order_id = o.id
    )
ORDER BY
    o.ordered_at DESC,
    o.id
LIMIT
    30;

-- 3) paid なのに配送がない注文（EXCEPTでも書けるが、まずはNOT EXISTSで）
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    customer_order o
WHERE
    o.order_status = 'paid'
    AND NOT EXISTS (
        SELECT
            1
        FROM
            shipment s
        WHERE
            s.order_id = o.id
    )
ORDER BY
    o.ordered_at DESC,
    o.id
LIMIT
    30;

-- 4) 参考：LEFT JOIN + IS NULL でも同じ発想で書ける（どちらが読みやすいかは場面次第）
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    customer_order o
    LEFT JOIN shipment s ON s.order_id = o.id
WHERE
    o.order_status = 'paid'
    AND s.order_id IS NULL
ORDER BY
    o.ordered_at DESC,
    o.id
LIMIT
    30;

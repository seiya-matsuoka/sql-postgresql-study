-- phase: 2
-- topic: Multi-table join（注文 → 明細 → 商品：実務の定番形）
-- dataset: ec-v0
-- 0) 注文ヘッダ + 明細 + 商品名（最もよくある多段JOIN）
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at,
    i.line_no,
    i.quantity,
    i.unit_price_yen,
    p.sku,
    p.name AS product_name,
    p.category
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
    JOIN product p ON p.id = i.product_id
ORDER BY
    o.id,
    i.line_no;

-- 1) あるユーザーの注文だけ（WHEREで絞る）
SELECT
    o.id AS order_id,
    o.order_status,
    o.ordered_at,
    i.line_no,
    p.name AS product_name,
    i.quantity,
    i.unit_price_yen,
    (i.quantity * i.unit_price_yen) AS line_total_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
    JOIN product p ON p.id = i.product_id
WHERE
    o.user_id = 1
ORDER BY
    o.ordered_at DESC,
    o.id,
    i.line_no;

-- 2) 合計金額の再計算（明細合計）
SELECT
    o.id AS order_id,
    SUM(i.quantity * i.unit_price_yen) AS items_total_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
GROUP BY
    o.id
ORDER BY
    o.id;

-- 3) 左を注文にしてLEFT JOIN（「明細がない注文」も理屈としては出せる）
-- ※現データでは明細がある想定だが、LEFTの型を覚えるために載せる
SELECT
    o.id AS order_id,
    o.order_status,
    i.line_no,
    i.product_id
FROM
    customer_order o
    LEFT JOIN order_item i ON i.order_id = o.id
ORDER BY
    o.id,
    i.line_no NULLS LAST;

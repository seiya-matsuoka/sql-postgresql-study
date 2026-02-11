-- phase: 3
-- topic: Reporting with JOIN + GROUP BY（注文・明細からレポートを作る）
-- dataset: ec-v0
-- 0) 注文ごとの明細行数・明細合計（レポートの定番）
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    COUNT(*) AS item_lines,
    SUM(i.quantity * i.unit_price_yen) AS items_total_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
GROUP BY
    o.id,
    o.user_id,
    o.order_status
ORDER BY
    o.id;

-- 1) ユーザーごとの「注文数」「明細合計」（JOINして集約）
SELECT
    u.id AS user_id,
    u.display_name,
    COUNT(DISTINCT o.id) AS order_count,
    SUM(i.quantity * i.unit_price_yen) AS total_spend_yen
FROM
    app_user u
    JOIN customer_order o ON o.user_id = u.id
    JOIN order_item i ON i.order_id = o.id
GROUP BY
    u.id,
    u.display_name
ORDER BY
    total_spend_yen DESC NULLS LAST,
    u.id;

-- 2) 商品カテゴリ別 売上（カテゴリ別レポート）
SELECT
    p.category,
    SUM(i.quantity * i.unit_price_yen) AS revenue_yen,
    SUM(i.quantity) AS total_qty
FROM
    order_item i
    JOIN product p ON p.id = i.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC,
    p.category;

-- 3) TOP N（標準SQL寄りとPostgreSQLの両方）
-- PostgreSQL（一般的）：LIMIT
SELECT
    p.category,
    SUM(i.quantity * i.unit_price_yen) AS revenue_yen
FROM
    order_item i
    JOIN product p ON p.id = i.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC
LIMIT
    2;

-- 標準SQL（DBにより対応差あり）：FETCH FIRST
SELECT
    p.category,
    SUM(i.quantity * i.unit_price_yen) AS revenue_yen
FROM
    order_item i
    JOIN product p ON p.id = i.product_id
GROUP BY
    p.category
ORDER BY
    revenue_yen DESC
FETCH FIRST
    2 ROWS ONLY;

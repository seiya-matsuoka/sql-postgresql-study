-- phase: 3 (ec-v1 add-on)
-- topic: revenue by tag (many-to-many)
-- dataset: ec-v1
-- note: 多対多JOINで行数が増えやすいので、集約の単位を意識する。
SELECT
    t.name AS tag_name,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS total_qty
FROM
    order_item oi
    JOIN product_tag pt ON pt.product_id = oi.product_id
    JOIN tag t ON t.id = pt.tag_id
GROUP BY
    t.name
ORDER BY
    revenue_yen DESC
LIMIT
    10;

-- 標準SQL寄り（DBにより対応差あり）：FETCH FIRST
SELECT
    t.name AS tag_name,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen,
    COUNT(DISTINCT oi.order_id) AS order_count
FROM
    order_item oi
    JOIN product_tag pt ON pt.product_id = oi.product_id
    JOIN tag t ON t.id = pt.tag_id
GROUP BY
    t.name
ORDER BY
    revenue_yen DESC
FETCH FIRST
    10 ROWS ONLY;

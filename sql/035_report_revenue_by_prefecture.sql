-- phase: 3 (ec-v1 add-on)
-- topic: revenue by prefecture (default address)
-- dataset: ec-v1
SELECT
    COALESCE(a.prefecture, 'UNKNOWN') AS prefecture,
    COUNT(DISTINCT o.id) AS order_count,
    SUM(i.quantity * i.unit_price_yen) AS revenue_yen,
    AVG(i.quantity * i.unit_price_yen) AS avg_line_revenue_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
    JOIN app_user u ON u.id = o.user_id
    LEFT JOIN user_address a ON a.user_id = u.id
    AND a.is_default = TRUE
WHERE
    o.order_status IN ('paid', 'shipped', 'delivered')
GROUP BY
    COALESCE(a.prefecture, 'UNKNOWN')
ORDER BY
    revenue_yen DESC NULLS LAST,
    prefecture;

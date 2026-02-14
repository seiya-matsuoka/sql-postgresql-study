-- phase: 5
-- topic: CTEで分解する（基本：派生表→WITHに置き換えて読みやすくする）
-- dataset: ec-v1
-- 目的:
--   - FROM内派生表（サブクエリ）を、WITHで名前付けして読みやすくする感覚を掴む
-- 0) CTEなし版（比較用：派生表）
SELECT
    t.order_id,
    t.user_id,
    t.order_status,
    t.items_total_yen
FROM
    (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.order_status,
            SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        GROUP BY
            o.id,
            o.user_id,
            o.order_status
    ) t
WHERE
    t.order_status IN ('paid', 'shipped', 'delivered')
ORDER BY
    t.items_total_yen DESC
LIMIT
    20;

-- 1) CTE版（同じことをWITHで書く）
WITH
    order_totals AS (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.order_status,
            SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        GROUP BY
            o.id,
            o.user_id,
            o.order_status
    )
SELECT
    ot.order_id,
    ot.user_id,
    ot.order_status,
    ot.items_total_yen
FROM
    order_totals ot
WHERE
    ot.order_status IN ('paid', 'shipped', 'delivered')
ORDER BY
    ot.items_total_yen DESC
LIMIT
    20;

-- 2) CTEを1つ増やして「フィルタ済み」を分離する（読みやすさの型）
WITH
    order_totals AS (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.order_status,
            SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        GROUP BY
            o.id,
            o.user_id,
            o.order_status
    ),
    paid_like_orders AS (
        SELECT
            *
        FROM
            order_totals
        WHERE
            order_status IN ('paid', 'shipped', 'delivered')
    )
SELECT
    order_id,
    user_id,
    order_status,
    items_total_yen
FROM
    paid_like_orders
ORDER BY
    items_total_yen DESC
LIMIT
    20;

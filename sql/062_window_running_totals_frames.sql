-- phase: 6
-- topic: 累積（running total）とフレーム（ROWS/RANGE）
-- dataset: ec-v1
-- 目的:
--   - 日別売上を作り、累積売上や移動平均を作る
--   - “フレーム”の指定で、どの範囲を平均するのかを制御できることを体験する
-- 0) 日別売上（まずは材料を作る）
WITH
    daily_revenue AS (
        SELECT
            o.ordered_at::date AS d,
            SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.ordered_at::date
    )
SELECT
    *
FROM
    daily_revenue
ORDER BY
    d DESC
LIMIT
    20;

-- 1) 日別売上 + 累積売上（running total）
WITH
    daily_revenue AS (
        SELECT
            o.ordered_at::date AS d,
            SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.ordered_at::date
    )
SELECT
    d,
    revenue_yen,
    SUM(revenue_yen) OVER (
        ORDER BY
            d
    ) AS cumulative_revenue_yen
FROM
    daily_revenue
ORDER BY
    d;

-- 2) 7日移動平均（直近7行の平均：ROWSフレーム）
WITH
    daily_revenue AS (
        SELECT
            o.ordered_at::date AS d,
            SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.ordered_at::date
    )
SELECT
    d,
    revenue_yen,
    ROUND(
        AVG(revenue_yen) OVER (
            ORDER BY
                d ROWS BETWEEN 6 PRECEDING
                AND CURRENT ROW
        ),
        2
    ) AS ma_7d
FROM
    daily_revenue
ORDER BY
    d;

-- 3) 注意：ROWS と RANGE は別物（ここでは概念だけ）
-- - ROWS：行数ベース（直近7行など）
-- - RANGE：値の範囲ベース（同一日付が複数行あるなどで結果が変わり得る）
-- 今回は日別で1日1行なので、ROWSを主に使えばOK。

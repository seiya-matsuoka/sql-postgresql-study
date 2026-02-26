-- phase: 6
-- topic: LAG/LEAD（前後行参照）で差分・増減を見る
-- dataset: ec-v1
-- 目的:
--   - 「前日比」「前回注文比」など、実務でよくある差分分析を体験する
-- 0) 日別売上の前日比（LAG）
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
    ),
    with_prev AS (
        SELECT
            d,
            revenue_yen,
            LAG(revenue_yen) OVER (
                ORDER BY
                    d
            ) AS prev_revenue_yen
        FROM
            daily_revenue
    )
SELECT
    d,
    revenue_yen,
    prev_revenue_yen,
    (revenue_yen - prev_revenue_yen) AS diff_yen,
    CASE
        WHEN prev_revenue_yen IS NULL THEN NULL
        WHEN prev_revenue_yen = 0 THEN NULL
        ELSE ROUND(
            (revenue_yen - prev_revenue_yen) * 100.0 / prev_revenue_yen,
            2
        )
    END AS diff_pct
FROM
    with_prev
ORDER BY
    d;

-- 1) ユーザーごとの「前回注文との差」（注文合計を作ってLAG）
WITH
    order_totals AS (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.ordered_at,
            SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.id,
            o.user_id,
            o.ordered_at
    ),
    with_prev AS (
        SELECT
            user_id,
            order_id,
            ordered_at,
            items_total_yen,
            LAG(items_total_yen) OVER (
                PARTITION BY
                    user_id
                ORDER BY
                    ordered_at,
                    order_id
            ) AS prev_items_total_yen
        FROM
            order_totals
    )
SELECT
    user_id,
    order_id,
    ordered_at,
    items_total_yen,
    prev_items_total_yen,
    (items_total_yen - prev_items_total_yen) AS diff_from_prev_yen
FROM
    with_prev
ORDER BY
    user_id,
    ordered_at,
    order_id
LIMIT
    100;

-- 2) LEAD：次の行も参照できる（例：次回注文までの間隔）
WITH
    order_base AS (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.ordered_at
        FROM
            customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
    ),
    with_next AS (
        SELECT
            user_id,
            order_id,
            ordered_at,
            LEAD(ordered_at) OVER (
                PARTITION BY
                    user_id
                ORDER BY
                    ordered_at,
                    order_id
            ) AS next_ordered_at
        FROM
            order_base
    )
SELECT
    user_id,
    order_id,
    ordered_at,
    next_ordered_at,
    (next_ordered_at - ordered_at) AS gap_to_next_order
FROM
    with_next
ORDER BY
    user_id,
    ordered_at,
    order_id
LIMIT
    100;

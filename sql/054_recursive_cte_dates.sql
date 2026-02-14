-- phase: 5
-- topic: 再帰CTE（系列：日付の連番を作る）
-- dataset: ec-v1
-- 目的:
--   - 再帰CTEで「系列（カレンダー）」を作る基本形を体験する
--   - その系列に対して売上をLEFT JOINして「日別レポート」を作る
-- 0) 直近14日の日付系列を作る（date型）
WITH RECURSIVE
    dates AS (
        SELECT
            (CURRENT_DATE - INTERVAL '13 day')::date AS d
        UNION ALL
        SELECT
            (d + INTERVAL '1 day')::date
        FROM
            dates
        WHERE
            d < CURRENT_DATE
    )
SELECT
    d
FROM
    dates
ORDER BY
    d;

-- 1) 日付系列 × 売上（0の日も出す：LEFT JOIN）
WITH RECURSIVE
    dates AS (
        SELECT
            (CURRENT_DATE - INTERVAL '13 day')::date AS d
        UNION ALL
        SELECT
            (d + INTERVAL '1 day')::date
        FROM
            dates
        WHERE
            d < CURRENT_DATE
    ),
    daily_revenue AS (
        SELECT
            o.ordered_at::date AS d,
            SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at::date >= (CURRENT_DATE - INTERVAL '13 day')::date
        GROUP BY
            o.ordered_at::date
    )
SELECT
    dt.d,
    COALESCE(dr.revenue_yen, 0) AS revenue_yen
FROM
    dates dt
    LEFT JOIN daily_revenue dr ON dr.d = dt.d
ORDER BY
    dt.d;

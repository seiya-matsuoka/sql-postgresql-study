-- phase: 4
-- topic: WITH（CTE）で読みやすく分解する（サブクエリの整理）
-- dataset: ec-v1
-- 目的:
--   - サブクエリを “WITH句で名前を付けて” 分解し、レポートSQLを読みやすくする
--   - 実務で「長いSQL」を扱うときの基本形を体験する
-- 0) 注文合計（明細合計）をまず作る → paid系だけに絞る → 住所（都道府県）を付ける
WITH
    order_totals AS (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.order_status,
            o.ordered_at,
            SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        GROUP BY
            o.id,
            o.user_id,
            o.order_status,
            o.ordered_at
    ),
    paid_like_orders AS (
        SELECT
            *
        FROM
            order_totals
        WHERE
            order_status IN ('paid', 'shipped', 'delivered')
    ),
    user_default_address AS (
        SELECT
            ua.user_id,
            ua.prefecture
        FROM
            user_address ua
        WHERE
            ua.is_default = TRUE
    )
SELECT
    COALESCE(a.prefecture, 'UNKNOWN') AS prefecture,
    COUNT(*) AS orders,
    SUM(p.items_total_yen) AS revenue_yen,
    AVG(p.items_total_yen) AS avg_order_yen
FROM
    paid_like_orders p
    LEFT JOIN user_default_address a ON a.user_id = p.user_id
GROUP BY
    COALESCE(a.prefecture, 'UNKNOWN')
ORDER BY
    revenue_yen DESC NULLS LAST,
    prefecture;

-- 1) 支払いが paid の注文だけ（payment をCTE化して見通し良く）
WITH
    paid_payments AS (
        SELECT
            order_id,
            method,
            amount_yen,
            paid_at
        FROM
            payment
        WHERE
            status = 'paid'
    )
SELECT
    pp.method,
    COUNT(*) AS paid_orders,
    SUM(pp.amount_yen) AS sum_paid_yen
FROM
    paid_payments pp
GROUP BY
    pp.method
ORDER BY
    sum_paid_yen DESC,
    pp.method;

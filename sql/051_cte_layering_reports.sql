-- phase: 5
-- topic: CTEを層で積む（レポートSQLの組み立て）
-- dataset: ec-v1
-- 目的:
--   - 「中間結果 → 次の中間結果 → 最終出力」という組み立てを体験する
--   - レポートを読みやすく保つための分解の型を作る
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
    paid_like AS (
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
    ),
    enriched AS (
        SELECT
            p.order_id,
            p.user_id,
            p.ordered_at,
            p.items_total_yen,
            COALESCE(a.prefecture, 'UNKNOWN') AS prefecture
        FROM
            paid_like p
            LEFT JOIN user_default_address a ON a.user_id = p.user_id
    )
SELECT
    prefecture,
    COUNT(*) AS orders,
    SUM(items_total_yen) AS revenue_yen,
    AVG(items_total_yen) AS avg_order_yen
FROM
    enriched
GROUP BY
    prefecture
ORDER BY
    revenue_yen DESC NULLS LAST,
    prefecture;

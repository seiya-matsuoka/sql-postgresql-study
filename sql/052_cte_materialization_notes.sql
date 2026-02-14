-- phase: 5
-- topic: CTEの扱い（読みやすさと性能の関係：まずは“見た目”を理解する）
-- dataset: ec-v1
-- 注意:
--   - このファイルでは「CTEを同じクエリ内で複数回参照」する例を出し、
--     CTEが“部品化”として使えることを体験する。
--   - 実際の最適化は EXPLAIN と合わせて深掘りする。
-- 0) order_totals を2回参照して、ランキングと全体統計を1回で出す例
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
    paid_like AS (
        SELECT
            *
        FROM
            order_totals
        WHERE
            order_status IN ('paid', 'shipped', 'delivered')
    ),
    stats AS (
        SELECT
            COUNT(*) AS orders,
            AVG(items_total_yen) AS avg_order_yen,
            MAX(items_total_yen) AS max_order_yen
        FROM
            paid_like
    )
SELECT
    p.order_id,
    p.user_id,
    p.items_total_yen,
    s.orders AS total_orders,
    s.avg_order_yen,
    s.max_order_yen
FROM
    paid_like p
    CROSS JOIN stats s
ORDER BY
    p.items_total_yen DESC
LIMIT
    20;

-- 1) 参考：同じロジックはサブクエリでネストしても書ける
--    ただ、見通しはCTEのほうが良くなりやすい。

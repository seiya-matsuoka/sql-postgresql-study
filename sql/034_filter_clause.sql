-- phase: 3
-- topic: FILTER clause（条件付き集計をより簡潔に：PostgreSQLで実行可）
-- dataset: ec-v0
-- note:
--   FILTER はSQL標準（SQL:2003）として定義されているが、DBによっては未対応の場合がある。
--   対応が怪しい場合は「CASE版（032）」が最も汎用。
-- 0) CASE版（復習）
SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'paid' THEN 1
            ELSE 0
        END
    ) AS paid_count,
    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_count
FROM
    customer_order;

-- 1) FILTER版（PostgreSQLで実行可）：より短く書ける
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE
            order_status = 'paid'
    ) AS paid_count,
    COUNT(*) FILTER (
        WHERE
            order_status = 'delivered'
    ) AS delivered_count
FROM
    customer_order;

-- 2) JOIN + FILTER：カテゴリ別に“PCだけの売上”などを同時に出す
SELECT
    p.category,
    SUM(i.quantity * i.unit_price_yen) AS revenue_yen,
    SUM(i.quantity * i.unit_price_yen) FILTER (
        WHERE
            p.category = 'pc'
    ) AS revenue_pc_only_yen
FROM
    order_item i
    JOIN product p ON p.id = i.product_id
GROUP BY
    p.category
ORDER BY
    p.category;

-- 3) 同じことをCASEで書く（汎用）
SELECT
    p.category,
    SUM(i.quantity * i.unit_price_yen) AS revenue_yen,
    SUM(
        CASE
            WHEN p.category = 'pc' THEN i.quantity * i.unit_price_yen
            ELSE 0
        END
    ) AS revenue_pc_only_yen
FROM
    order_item i
    JOIN product p ON p.id = i.product_id
GROUP BY
    p.category
ORDER BY
    p.category;

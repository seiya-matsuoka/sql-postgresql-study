-- phase: 6
-- topic: グループごとの最新1件（最新注文、最新支払いなど）
-- dataset: ec-v1
-- 目的:
--   - 実務頻出の「各ユーザーの最新注文」「各注文の最新状態」をウィンドウ関数で取れるようにする
-- 0) 各ユーザーの最新注文（paid系のみ）
WITH
    base AS (
        SELECT
            o.id AS order_id,
            o.user_id,
            o.order_status,
            o.ordered_at
        FROM
            customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
    ),
    ranked AS (
        SELECT
            b.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    b.user_id
                ORDER BY
                    b.ordered_at DESC,
                    b.order_id DESC
            ) AS rn
        FROM
            base b
    )
SELECT
    r.user_id,
    r.order_id,
    r.order_status,
    r.ordered_at
FROM
    ranked r
WHERE
    r.rn = 1
ORDER BY
    r.user_id
LIMIT
    50;

-- 1) 最新注文に「注文合計」も付けたい（CTEを分けて読みやすくする）
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
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.id,
            o.user_id,
            o.order_status,
            o.ordered_at
    ),
    ranked AS (
        SELECT
            ot.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    ot.user_id
                ORDER BY
                    ot.ordered_at DESC,
                    ot.order_id DESC
            ) AS rn
        FROM
            order_totals ot
    )
SELECT
    user_id,
    order_id,
    ordered_at,
    order_status,
    items_total_yen
FROM
    ranked
WHERE
    rn = 1
ORDER BY
    items_total_yen DESC
LIMIT
    30;

-- 2) 「最新行だけ」ではなく、最新行とその前の行も見たい（rn <= 2 など）
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
    ranked AS (
        SELECT
            ot.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    ot.user_id
                ORDER BY
                    ot.ordered_at DESC,
                    ot.order_id DESC
            ) AS rn
        FROM
            order_totals ot
    )
SELECT
    user_id,
    order_id,
    ordered_at,
    items_total_yen,
    rn
FROM
    ranked
WHERE
    rn <= 2
ORDER BY
    user_id,
    rn;

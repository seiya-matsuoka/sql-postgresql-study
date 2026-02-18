-- phase: 6
-- topic: ウィンドウ関数の基礎（ROW_NUMBER / RANK / DENSE_RANK）
-- dataset: ec-v1
-- 目的:
--   - 「グループ内順位」「同率の扱い」の基本を体験する
--   - 実務のランキング系レポートの土台を作る
-- 0) まずは売上（注文合計）を作る：paid系だけを対象にする
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
    )
SELECT
    *
FROM
    order_totals
ORDER BY
    items_total_yen DESC
LIMIT
    10;

-- 1) ユーザーごとの注文金額ランキング（同じuser_id内で順位付け）
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
    )
SELECT
    ot.user_id,
    ot.order_id,
    ot.ordered_at,
    ot.items_total_yen,
    ROW_NUMBER() OVER (
        PARTITION BY
            ot.user_id
        ORDER BY
            ot.items_total_yen DESC,
            ot.order_id DESC
    ) AS rn,
    RANK() OVER (
        PARTITION BY
            ot.user_id
        ORDER BY
            ot.items_total_yen DESC,
            ot.order_id DESC
    ) AS rnk,
    DENSE_RANK() OVER (
        PARTITION BY
            ot.user_id
        ORDER BY
            ot.items_total_yen DESC,
            ot.order_id DESC
    ) AS dense_rnk
FROM
    order_totals ot
ORDER BY
    ot.user_id,
    rn
LIMIT
    50;

-- 2) カテゴリ別：商品を価格で並べて順位（ランキングの感覚）
SELECT
    p.category,
    p.id AS product_id,
    p.name,
    p.price_yen,
    ROW_NUMBER() OVER (
        PARTITION BY
            p.category
        ORDER BY
            p.price_yen DESC,
            p.id
    ) AS rn_in_category,
    RANK() OVER (
        PARTITION BY
            p.category
        ORDER BY
            p.price_yen DESC,
            p.id
    ) AS rank_in_category
FROM
    product p
ORDER BY
    p.category,
    rn_in_category
LIMIT
    100;

-- 3) 「カテゴリ別TOP3」を取りたい場合（ウィンドウ→外側で絞るのが定番）
WITH
    ranked AS (
        SELECT
            p.category,
            p.id AS product_id,
            p.name,
            p.price_yen,
            ROW_NUMBER() OVER (
                PARTITION BY
                    p.category
                ORDER BY
                    p.price_yen DESC,
                    p.id
            ) AS rn
        FROM
            product p
    )
SELECT
    category,
    product_id,
    name,
    price_yen,
    rn
FROM
    ranked
WHERE
    rn <= 3
ORDER BY
    category,
    rn;

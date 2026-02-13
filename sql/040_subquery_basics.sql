-- phase: 4
-- topic: サブクエリ基礎（スカラー / IN / FROM内派生表）
-- dataset: ec-v1
-- 目的:
--   - サブクエリの代表的な3パターンを体験する
--   - 「JOIN以外の書き方の引き出し」を増やす
-- 0) スカラーサブクエリ：全体平均を“各行に付与”する
-- 例：商品価格と全体平均の差
SELECT
    p.id,
    p.name,
    p.category,
    p.price_yen,
    (
        SELECT
            AVG(price_yen)
        FROM
            product
    ) AS avg_price_yen,
    p.price_yen - (
        SELECT
            AVG(price_yen)
        FROM
            product
    ) AS diff_from_avg
FROM
    product p
ORDER BY
    diff_from_avg DESC
LIMIT
    10;

-- 1) INサブクエリ：条件に一致するID集合を使って絞り込む
-- 例：PCカテゴリの商品を含む注文
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    customer_order o
WHERE
    o.id IN (
        SELECT
            oi.order_id
        FROM
            order_item oi
            JOIN product p ON p.id = oi.product_id
        WHERE
            p.category = 'pc'
    )
ORDER BY
    o.ordered_at DESC,
    o.id
LIMIT
    20;

-- 2) FROM内派生表（サブクエリを一時的な“表”として扱う）
-- 例：注文合計を作ってから、一定金額以上の注文だけ抽出
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
    t.items_total_yen >= 200000
ORDER BY
    t.items_total_yen DESC,
    t.order_id
LIMIT
    20;

-- 3) 注意：NOT IN はNULLが混ざると“全部落ちる”ことがある
-- この例は「わざとNULLを混ぜる」ことで、NOT IN が危険になり得ることを体験する（概念の確認）。
-- 実務では「NOT EXISTS」を優先するのが安全。
SELECT
    o.id AS order_id
FROM
    customer_order o
WHERE
    o.id NOT IN (
        SELECT
            order_id
        FROM
            payment
        UNION ALL
        SELECT
            NULL
    )
ORDER BY
    o.id
LIMIT
    10;

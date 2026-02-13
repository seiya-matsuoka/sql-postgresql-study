-- phase: 4
-- topic: EXISTS と相関サブクエリ（存在判定 / 1行ごとの集計をサブクエリで付与）
-- dataset: ec-v1
-- 目的:
--   - 「存在するか？」を EXISTS で書く感覚を掴む
--   - 相関サブクエリ（外側の行に依存するサブクエリ）を体験する
-- 0) EXISTS：支払いが「paid」の注文が存在するユーザー
SELECT
    u.id AS user_id,
    u.display_name
FROM
    app_user u
WHERE
    EXISTS (
        SELECT
            1
        FROM
            customer_order o
            JOIN payment p ON p.order_id = o.id
        WHERE
            o.user_id = u.id
            AND p.status = 'paid'
    )
ORDER BY
    u.id
LIMIT
    30;

-- 1) 同じことを IN で書く（書けるが、意図は EXISTS のほうが読みやすい場合が多い）
SELECT
    u.id AS user_id,
    u.display_name
FROM
    app_user u
WHERE
    u.id IN (
        SELECT
            o.user_id
        FROM
            customer_order o
            JOIN payment p ON p.order_id = o.id
        WHERE
            p.status = 'paid'
    )
ORDER BY
    u.id
LIMIT
    30;

-- 2) 相関サブクエリ：ユーザーごとに「注文数」「支払済み金額（概算）」を付与
-- JOIN + GROUP BY でも書けるが、ここでは “外側の1行に対してサブクエリで値を付ける” 形を体験する。
SELECT
    u.id AS user_id,
    u.display_name,
    (
        SELECT
            COUNT(*)
        FROM
            customer_order o
        WHERE
            o.user_id = u.id
    ) AS order_count,
    COALESCE(
        (
            SELECT
                SUM(oi.quantity * oi.unit_price_yen)
            FROM
                customer_order o
                JOIN order_item oi ON oi.order_id = o.id
            WHERE
                o.user_id = u.id
                AND o.order_status IN ('paid', 'shipped', 'delivered')
        ),
        0
    ) AS spend_yen_like
FROM
    app_user u
ORDER BY
    spend_yen_like DESC,
    u.id
LIMIT
    20;

-- 3) EXISTS：配送が存在する注文（「配送レコードがあるか？」の存在判定）
SELECT
    o.id AS order_id,
    o.order_status,
    o.ordered_at
FROM
    customer_order o
WHERE
    EXISTS (
        SELECT
            1
        FROM
            shipment s
        WHERE
            s.order_id = o.id
    )
ORDER BY
    o.ordered_at DESC
LIMIT
    20;

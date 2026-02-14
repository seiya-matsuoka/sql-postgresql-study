-- phase: 4
-- topic: 集合演算（UNION / UNION ALL / INTERSECT / EXCEPT）
-- dataset: ec-v1
-- 目的:
--   - 集合として「足す/重複を残す/共通部分/差集合」を体験する
-- 注意:
--   - 列数と型を揃える必要がある
--   - ORDER BY は “全体の最後” にだけ書く（途中には基本書けない）
-- 0) UNION：重複を消して集合を足す
-- 例：支払済み（paid/refunded含む）に関与したユーザー と 配送に関与したユーザー の集合
SELECT
    o.user_id AS user_id
FROM
    customer_order o
    JOIN payment p ON p.order_id = o.id
WHERE
    p.status IN ('paid', 'refunded')
UNION
SELECT
    o.user_id AS user_id
FROM
    customer_order o
    JOIN shipment s ON s.order_id = o.id
ORDER BY
    user_id
LIMIT
    50;

-- 1) UNION ALL：重複を残して足す（件数が増える）
SELECT
    o.user_id AS user_id
FROM
    customer_order o
    JOIN payment p ON p.order_id = o.id
WHERE
    p.status IN ('paid', 'refunded')
UNION ALL
SELECT
    o.user_id AS user_id
FROM
    customer_order o
    JOIN shipment s ON s.order_id = o.id
ORDER BY
    user_id
LIMIT
    50;

-- 2) INTERSECT：共通部分（両方に存在する）
-- 例：支払いが paid の注文 かつ 配送が存在する注文
SELECT
    p.order_id
FROM
    payment p
WHERE
    p.status = 'paid'
INTERSECT
SELECT
    s.order_id
FROM
    shipment s
ORDER BY
    order_id
LIMIT
    50;

-- 3) EXCEPT：差集合（左にあって右にない）
-- 例：paid の注文 から 配送がある注文 を引く（＝paidだが配送なし）
SELECT
    o.id AS order_id
FROM
    customer_order o
WHERE
    o.order_status = 'paid'
EXCEPT
SELECT
    s.order_id
FROM
    shipment s
ORDER BY
    order_id
LIMIT
    50;

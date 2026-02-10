-- phase: 2
-- topic: Join multiplication（1対多で行が増える）/ DISTINCT の扱い
-- dataset: ec-v0
-- 0) 注文（1）対 明細（多） なので、JOINすると注文が明細の数だけ増える
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    i.line_no,
    i.product_id,
    i.quantity
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
ORDER BY
    o.id,
    i.line_no;

-- 1) 「注文一覧」が欲しいのに、JOINして明細を付けたら行が増える典型
-- これはバグではなく、データ構造（1対多）による自然な結果。
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
ORDER BY
    o.id;

-- 2) DISTINCT で “見た目だけ” 注文一覧に戻す（便利だが、意味が変わりうる）
SELECT DISTINCT
    o.id AS order_id,
    o.user_id,
    o.order_status
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
ORDER BY
    o.id;

-- 3) 注文ごとに「明細数」を出したい場合は、DISTINCTではなく集約
SELECT
    o.id AS order_id,
    COUNT(*) AS item_lines
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
GROUP BY
    o.id
ORDER BY
    o.id;

-- 4) 「何を一意にしたいのか？」を先に決めると迷いにくい
-- - 注文が一意：order_id 単位
-- - 明細が一意：order_id + line_no 単位
-- - 商品が一意：product_id 単位

-- phase: 0
-- topic: ec-v1 の投入確認（件数一覧 + 最小の内容確認）
-- dataset: ec-v1
-- 目的:
--   - ec-v1 に切り替え後、テーブルが作成され、シードが想定通り入っているかを素早く確認する
-- 0) 環境確認
SELECT
    current_database() AS db,
    current_user AS usr,
    CURRENT_TIMESTAMP AS now;

-- 1) テーブル存在確認
-- psqlで実行する場合は \dt でも可
-- 2) コア4表（互換テーブル）の件数
SELECT
    COUNT(*) AS app_user_count
FROM
    app_user;

SELECT
    COUNT(*) AS product_count
FROM
    product;

SELECT
    COUNT(*) AS customer_order_count
FROM
    customer_order;

SELECT
    COUNT(*) AS order_item_count
FROM
    order_item;

-- 3) 追加テーブルの件数
SELECT
    COUNT(*) AS user_address_count
FROM
    user_address;

SELECT
    COUNT(*) AS payment_count
FROM
    payment;

SELECT
    COUNT(*) AS shipment_count
FROM
    shipment;

SELECT
    COUNT(*) AS tag_count
FROM
    tag;

SELECT
    COUNT(*) AS product_tag_count
FROM
    product_tag;

-- 4) 注文ステータスの分布（偏りがあるか確認）
SELECT
    order_status,
    COUNT(*) AS cnt
FROM
    customer_order
GROUP BY
    order_status
ORDER BY
    order_status;

-- 5) 支払いステータス/方法の分布（存在確認）
SELECT
    status,
    COUNT(*) AS cnt
FROM
    payment
GROUP BY
    status
ORDER BY
    status;

SELECT
    method,
    COUNT(*) AS cnt
FROM
    payment
GROUP BY
    method
ORDER BY
    method;

-- 6) 配送ステータスの分布（存在確認）
SELECT
    status,
    COUNT(*) AS cnt
FROM
    shipment
GROUP BY
    status
ORDER BY
    status;

-- 7) 代表データの軽い中身確認（数件だけ）
-- ユーザー
SELECT
    id,
    email,
    display_name,
    created_at
FROM
    app_user
ORDER BY
    id
LIMIT
    5;

-- 商品
SELECT
    id,
    sku,
    name,
    category,
    price_yen
FROM
    product
ORDER BY
    id
LIMIT
    10;

-- 注文 + 明細（JOINで見えるか）
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at,
    i.line_no,
    i.product_id,
    i.quantity,
    i.unit_price_yen
FROM
    customer_order o
    JOIN order_item i ON i.order_id = o.id
ORDER BY
    o.id,
    i.line_no
LIMIT
    20;

-- 8) 住所（デフォルト住所が入っているか）
SELECT
    user_id,
    prefecture,
    city,
    is_default
FROM
    user_address
WHERE
    is_default = TRUE
ORDER BY
    user_id
LIMIT
    20;

-- 9) タグ付け（多対多が入っているか）
SELECT
    pt.product_id,
    t.name AS tag_name
FROM
    product_tag pt
    JOIN tag t ON t.id = pt.tag_id
ORDER BY
    pt.product_id,
    t.name
LIMIT
    30;

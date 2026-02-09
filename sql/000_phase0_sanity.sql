-- phase: 0
-- purpose: sanity check（DB初期化・接続確認用の純SQL）
-- dataset: ec-v0
-- note:
--   - psql / DBeaver どちらでも実行できるように純SQLのみで構成する
SELECT
    version();

SELECT
    current_database() AS db,
    current_user AS usr,
    now() AS now;

-- init SQL が実行され、テーブルが存在することの確認
SELECT
    count(*) AS users
FROM
    app_user;

SELECT
    count(*) AS products
FROM
    product;

SELECT
    count(*) AS orders
FROM
    customer_order;

SELECT
    count(*) AS items
FROM
    order_item;

-- サンプル表示（結果が返ることの確認）
SELECT
    id,
    sku,
    name,
    category,
    price_yen
FROM
    product
ORDER BY
    id;

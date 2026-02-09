-- phase: 1
-- topic: SELECT basics（列指定、別名、式、並び替え、件数制限）
-- dataset: ec-v0
-- note: SELECTの型を体に入れる。
-- 0) 現在時刻とDB情報（環境の確認にもなる）
SELECT
    current_database() AS db,
    current_user AS usr,
    now() AS now;

-- 1) 最小のSELECT（列を明示して取る）
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

-- 2) 別名（AS）と計算式（消費税っぽい計算）
SELECT
    id,
    name AS product_name,
    price_yen,
    round(price_yen * 1.1) AS price_with_tax_yen
FROM
    product
ORDER BY
    price_with_tax_yen DESC,
    id;

-- 3) DISTINCT（重複を消して一覧を作る）
SELECT DISTINCT
    category
FROM
    product
ORDER BY
    category;

-- 4) LIMIT / OFFSET（件数制限とページングの入口）
SELECT
    id,
    sku,
    name,
    category,
    price_yen
FROM
    product
ORDER BY
    price_yen DESC,
    id
LIMIT
    3;

SELECT
    id,
    sku,
    name,
    category,
    price_yen
FROM
    product
ORDER BY
    price_yen DESC,
    id
LIMIT
    3
OFFSET
    1;

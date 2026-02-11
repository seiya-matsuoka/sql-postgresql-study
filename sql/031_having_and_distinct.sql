-- phase: 3
-- topic: HAVING / DISTINCT（集約後の絞り込み、重複の考え方）
-- dataset: ec-v0
-- 0) DISTINCT：カテゴリ一覧（見た目を一意にする）
SELECT DISTINCT
    category
FROM
    product
ORDER BY
    category;

-- 1) COUNT(DISTINCT ...)：一意な数を数える（標準SQL寄り）
SELECT
    COUNT(DISTINCT category) AS distinct_category_count
FROM
    product;

-- 2) WHERE（集約前）で絞ってから集約する
SELECT
    category,
    COUNT(*) AS product_count
FROM
    product
WHERE
    price_yen >= 1000
GROUP BY
    category
ORDER BY
    category;

-- 3) HAVING（集約後）で絞る：カテゴリ内の件数が2以上のものだけ
SELECT
    category,
    COUNT(*) AS product_count
FROM
    product
GROUP BY
    category
HAVING
    COUNT(*) >= 2
ORDER BY
    category;

-- 4) WHERE と HAVING の役割の違い
-- - WHERE: 行を絞ってから集約（材料を減らす）
-- - HAVING: 集約結果を絞る（集約しないと判断できない条件）

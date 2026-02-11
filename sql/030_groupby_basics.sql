-- phase: 3
-- topic: GROUP BY basics（COUNT/SUM/AVG、NULL、基本の集約）
-- dataset: ec-v0
-- 0) 全体の件数（COUNTの基本）
SELECT
    COUNT(*) AS total_products
FROM
    product;

-- 1) カテゴリ別 件数（GROUP BY）
SELECT
    category,
    COUNT(*) AS product_count
FROM
    product
GROUP BY
    category
ORDER BY
    category;

-- 2) カテゴリ別 価格の統計（SUM/AVG/MIN/MAX）
SELECT
    category,
    COUNT(*) AS product_count,
    SUM(price_yen) AS sum_price_yen,
    AVG(price_yen) AS avg_price_yen,
    MIN(price_yen) AS min_price_yen,
    MAX(price_yen) AS max_price_yen
FROM
    product
GROUP BY
    category
ORDER BY
    category;

-- 3) COUNT(*) と COUNT(column) の違い（NULLがあると差が出る）
-- NULLの例を作る：pc以外はNULLになる列
SELECT
    COUNT(*) AS total_rows,
    COUNT(
        CASE
            WHEN category = 'pc' THEN 1
        END
    ) AS count_nonnull_only_pc
FROM
    product;

-- 4) 集約は「非集約列は必ずGROUP BYに入れる」が基本ルール
--    例：以下は一般にエラー（非集約列 name がGROUP BYにない）
--    SELECT category, name, COUNT(*) FROM product GROUP BY category;

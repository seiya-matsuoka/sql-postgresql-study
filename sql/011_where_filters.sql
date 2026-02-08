-- phase: 1
-- topic: WHERE filters（比較、AND/OR、IN、BETWEEN、LIKE、NULLの入口）
-- dataset: ec-v0
-- note: 条件の書き方で結果が変わるのを確認する。
-- 1) 等価 / 不等価
SELECT
    id,
    sku,
    name,
    category,
    price_yen
FROM
    product
WHERE
    category = 'pc'
ORDER BY
    id;

SELECT
    id,
    sku,
    name,
    category,
    price_yen
FROM
    product
WHERE
    category <> 'pc'
ORDER BY
    id;

-- 2) 数値比較（>=, <=）
SELECT
    id,
    name,
    price_yen
FROM
    product
WHERE
    price_yen >= 1000
ORDER BY
    price_yen DESC,
    id;

-- 3) AND / OR（括弧の有無で意味が変わるので注意）
SELECT
    id,
    name,
    category,
    price_yen
FROM
    product
WHERE
    category = 'pc'
    AND price_yen >= 3000
ORDER BY
    id;

SELECT
    id,
    name,
    category,
    price_yen
FROM
    product
WHERE
    category = 'pc'
    OR price_yen >= 3000
ORDER BY
    id;

-- 4) IN（候補の中に含まれる）
SELECT
    id,
    name,
    category,
    price_yen
FROM
    product
WHERE
    category IN ('pc', 'food')
ORDER BY
    category,
    id;

-- 5) BETWEEN（範囲）
SELECT
    id,
    name,
    price_yen
FROM
    product
WHERE
    price_yen BETWEEN 300 AND 3000
ORDER BY
    price_yen,
    id;

-- 6) LIKE / ILIKE（前方一致・部分一致）
-- LIKE: 大文字小文字を区別する
SELECT
    id,
    name
FROM
    product
WHERE
    name LIKE 'K%'
ORDER BY
    id;

-- ILIKE: 大文字小文字を区別しない（PostgreSQL）
SELECT
    id,
    name
FROM
    product
WHERE
    name ILIKE '%note%'
ORDER BY
    id;

-- 7) NULLの扱い
-- 今のデータセットでは NOT NULL が多いので、NULLを“作る”例を少しだけ。
-- CASEにELSEを付けないと、条件に当たらない行はNULLになる。
SELECT
    id,
    name,
    category,
    CASE
        WHEN category = 'pc' THEN 'PC'
    END AS maybe_label
FROM
    product
ORDER BY
    id;

-- NULLを埋める（COALESCE：NULLなら右側を採用）
SELECT
    id,
    name,
    category,
    COALESCE(
        CASE
            WHEN category = 'pc' THEN 'PC'
        END,
        'OTHER'
    ) AS label_filled
FROM
    product
ORDER BY
    id;

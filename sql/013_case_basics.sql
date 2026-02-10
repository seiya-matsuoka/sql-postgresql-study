-- phase: 1
-- topic: CASE basics（searched CASE / simple CASE / 実務っぽいラベル付け）
-- dataset: ec-v0
-- note: CASEは「分類」「表示用ラベル」「優先順位の付与」で超頻出。条件順序が重要。
-- 1) searched CASE（条件で分岐）
-- 価格帯ラベル（例：low/mid/high）
SELECT
    id,
    name,
    price_yen,
    CASE
        WHEN price_yen < 1000 THEN 'low'
        WHEN price_yen < 5000 THEN 'mid'
        ELSE 'high'
    END AS price_tier
FROM
    product
ORDER BY
    price_yen,
    id;

-- 2) simple CASE（値に応じて分岐）
SELECT
    id,
    name,
    category,
    CASE category
        WHEN 'pc' THEN 'PC'
        WHEN 'food' THEN 'FOOD'
        WHEN 'stationery' THEN 'STATIONERY'
        ELSE 'OTHER'
    END AS category_label
FROM
    product
ORDER BY
    id;

-- 3) CASEで「優先度（ソートキー）」を作る（表示順の制御に使う）
SELECT
    id,
    name,
    category,
    CASE category
        WHEN 'pc' THEN 1
        WHEN 'stationery' THEN 2
        WHEN 'food' THEN 3
        ELSE 9
    END AS category_sort_key
FROM
    product
ORDER BY
    category_sort_key,
    id;

-- 4) ELSEを省略するとNULLになる（NULLの発生源になりやすい）
SELECT
    id,
    name,
    category,
    CASE
        WHEN category = 'pc' THEN 'PC'
    END AS label_maybe_null
FROM
    product
ORDER BY
    id;

-- 5) COALESCEでNULLを埋める（表示崩れ防止）
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

-- 6) CASEを使った条件付きカウントの形
-- 集約はPhase 3でやるが、「CASEで数を数える形」は頻出なので型だけ触る。
SELECT
    COUNT(*) AS total_products,
    SUM(
        CASE
            WHEN category = 'pc' THEN 1
            ELSE 0
        END
    ) AS pc_count,
    SUM(
        CASE
            WHEN price_yen >= 3000 THEN 1
            ELSE 0
        END
    ) AS price_ge_3000_count
FROM
    product;

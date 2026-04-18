-- dataset: ec-perf-v1
-- purpose: マスタ系データ投入（ユーザー/住所/商品）
-- 方針:
--   - 再現性重視（乱数は使わない）
--   - ユーザー/商品はそこそこ多め
--   - 住所は都道府県分布に偏りを少し持たせる
-- 1) ユーザー（4,000件）
INSERT INTO
    public.app_user (email, full_name, user_tier, created_at)
SELECT
    'user' || lpad(gs::text, 5, '0') || '@example.com' AS email,
    'User ' || gs AS full_name,
    CASE
        WHEN gs % 100 < 70 THEN 'free'
        WHEN gs % 100 < 95 THEN 'standard'
        ELSE 'premium'
    END AS user_tier,
    CURRENT_TIMESTAMP - ((gs % 730) || ' days')::INTERVAL
FROM
    generate_series(1, 4000) AS gs;

-- 2) 住所（デフォルト住所を全ユーザー1件）
INSERT INTO
    public.user_address (user_id, prefecture, city, is_default, created_at)
SELECT
    u.id AS user_id,
    CASE (u.id % 12)
        WHEN 0 THEN 'Tokyo'
        WHEN 1 THEN 'Kanagawa'
        WHEN 2 THEN 'Osaka'
        WHEN 3 THEN 'Aichi'
        WHEN 4 THEN 'Saitama'
        WHEN 5 THEN 'Chiba'
        WHEN 6 THEN 'Fukuoka'
        WHEN 7 THEN 'Hokkaido'
        WHEN 8 THEN 'Hyogo'
        WHEN 9 THEN 'Shizuoka'
        WHEN 10 THEN 'Kyoto'
        ELSE 'Miyagi'
    END AS prefecture,
    'City-' || ((u.id % 50) + 1) AS city,
    TRUE AS is_default,
    CURRENT_TIMESTAMP - ((u.id % 365) || ' days')::INTERVAL
FROM
    public.app_user u;

-- 3) 一部ユーザーにサブ住所（25%）
INSERT INTO
    public.user_address (user_id, prefecture, city, is_default, created_at)
SELECT
    u.id AS user_id,
    CASE ((u.id + 3) % 12)
        WHEN 0 THEN 'Tokyo'
        WHEN 1 THEN 'Kanagawa'
        WHEN 2 THEN 'Osaka'
        WHEN 3 THEN 'Aichi'
        WHEN 4 THEN 'Saitama'
        WHEN 5 THEN 'Chiba'
        WHEN 6 THEN 'Fukuoka'
        WHEN 7 THEN 'Hokkaido'
        WHEN 8 THEN 'Hyogo'
        WHEN 9 THEN 'Shizuoka'
        WHEN 10 THEN 'Kyoto'
        ELSE 'Miyagi'
    END AS prefecture,
    'SubCity-' || ((u.id % 30) + 1) AS city,
    FALSE AS is_default,
    CURRENT_TIMESTAMP - ((u.id % 200) || ' days')::INTERVAL
FROM
    public.app_user u
WHERE
    u.id % 4 = 0;

-- 4) 商品（500件）
INSERT INTO
    public.product (
        sku,
        name,
        category,
        price_yen,
        is_active,
        created_at
    )
SELECT
    'SKU-' || lpad(gs::text, 4, '0') AS sku,
    CASE
        WHEN gs <= 100 THEN 'Electronics Item ' || gs
        WHEN gs <= 200 THEN 'Books Item ' || gs
        WHEN gs <= 300 THEN 'Home Item ' || gs
        WHEN gs <= 400 THEN 'Beauty Item ' || gs
        ELSE 'Food Item ' || gs
    END AS name,
    CASE
        WHEN gs <= 100 THEN 'electronics'
        WHEN gs <= 200 THEN 'books'
        WHEN gs <= 300 THEN 'home'
        WHEN gs <= 400 THEN 'beauty'
        ELSE 'food'
    END AS category,
    CASE
        WHEN gs <= 100 THEN 1000 + ((gs * 137) % 12000)
        WHEN gs <= 200 THEN 500 + ((gs * 97) % 4000)
        WHEN gs <= 300 THEN 800 + ((gs * 53) % 8000)
        WHEN gs <= 400 THEN 600 + ((gs * 71) % 6000)
        ELSE 200 + ((gs * 29) % 3000)
    END AS price_yen,
    CASE
        WHEN gs % 25 = 0 THEN FALSE
        ELSE TRUE
    END AS is_active,
    CURRENT_TIMESTAMP - ((gs % 500) || ' days')::INTERVAL
FROM
    generate_series(1, 500) AS gs;

-- 5) 確認
SELECT
    COUNT(*) AS user_count
FROM
    public.app_user;

SELECT
    COUNT(*) AS user_address_count
FROM
    public.user_address;

SELECT
    COUNT(*) AS product_count
FROM
    public.product;

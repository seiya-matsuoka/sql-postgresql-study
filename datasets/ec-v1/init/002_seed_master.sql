-- purpose: seed (master-like data) for ec-v1
-- volumes (approx):
--   app_user:     200
--   product:      500
--   user_address: 300
--   tag:          30
--   product_tag:  1200 (unique pairs)
-- random reproducibility hint (session-scoped):
SELECT
    setseed(0.42);

-- ======
-- app_user (200)
-- ======
INSERT INTO
    app_user (id, email, display_name, created_at)
SELECT
    gs AS id,
    format('user%03s@example.com', gs) AS email,
    format('User %03s', gs) AS display_name,
    (CURRENT_TIMESTAMP - (gs % 365) * INTERVAL '1 day') AS created_at
FROM
    generate_series(1, 200) gs;

SELECT
    setval(
        pg_get_serial_sequence('app_user', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                app_user
        )
    );

-- ======
-- product (500)
-- ======
INSERT INTO
    product (id, sku, name, category, price_yen, created_at)
SELECT
    gs AS id,
    'SKU-' || lpad(CAST(gs AS TEXT), 6, '0') AS sku,
    CASE
        WHEN (gs % 10) < 3 THEN 'PC Item ' || gs
        WHEN (gs % 10) < 6 THEN 'Food Item ' || gs
        WHEN (gs % 10) < 8 THEN 'Stationery Item ' || gs
        WHEN (gs % 10) = 8 THEN 'Book Item ' || gs
        ELSE 'Home Item ' || gs
    END AS name,
    CASE
        WHEN (gs % 10) < 3 THEN 'pc'
        WHEN (gs % 10) < 6 THEN 'food'
        WHEN (gs % 10) < 8 THEN 'stationery'
        WHEN (gs % 10) = 8 THEN 'book'
        ELSE 'home'
    END AS category,
    CASE
        WHEN (gs % 10) < 3 THEN 50000 + ((gs * 97) % 150000) -- pc: 50,000..199,999
        WHEN (gs % 10) < 6 THEN 200 + ((gs * 37) % 2800) -- food: 200..2,999
        WHEN (gs % 10) < 8 THEN 100 + ((gs * 19) % 1400) -- stationery: 100..1,499
        WHEN (gs % 10) = 8 THEN 800 + ((gs * 29) % 3200) -- book: 800..3,999
        ELSE 1000 + ((gs * 41) % 9000) -- home: 1,000..9,999
    END AS price_yen,
    (CURRENT_TIMESTAMP - (gs % 180) * INTERVAL '1 day') AS created_at
FROM
    generate_series(1, 500) gs;

SELECT
    setval(
        pg_get_serial_sequence('product', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                product
        )
    );

-- ======
-- tag (30)
-- ======
INSERT INTO
    tag (id, name)
VALUES
    (1, 'sale'),
    (2, 'new'),
    (3, 'gift'),
    (4, 'eco'),
    (5, 'popular'),
    (6, 'limited'),
    (7, 'premium'),
    (8, 'budget'),
    (9, 'bulk'),
    (10, 'daily'),
    (11, 'office'),
    (12, 'home'),
    (13, 'travel'),
    (14, 'kids'),
    (15, 'gadget'),
    (16, 'healthy'),
    (17, 'snack'),
    (18, 'stationery'),
    (19, 'pc'),
    (20, 'book'),
    (21, 'kitchen'),
    (22, 'cleaning'),
    (23, 'outdoor'),
    (24, 'sports'),
    (25, 'fashion'),
    (26, 'seasonal'),
    (27, 'import'),
    (28, 'local'),
    (29, 'bundle'),
    (30, 'recommended');

SELECT
    setval(
        pg_get_serial_sequence('tag', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                tag
        )
    );

-- ======
-- product_tag (unique pairs; take first 1200 from ordered cartesian subset)
-- ======
INSERT INTO
    product_tag (product_id, tag_id)
SELECT
    p.id AS product_id,
    t.id AS tag_id
FROM
    product p
    JOIN tag t ON ((p.id + t.id) % 7 = 0)
ORDER BY
    p.id,
    t.id
LIMIT
    1200;

-- ======
-- user_address (300)
-- ======
WITH
    base AS (
        SELECT
            gs AS id,
            ((gs * 19) % 200) + 1 AS user_id,
            CASE
                WHEN (gs % 3) = 0 THEN 'home'
                WHEN (gs % 3) = 1 THEN 'work'
                ELSE 'other'
            END AS label,
            CASE (gs % 10)
                WHEN 0 THEN 'Tokyo'
                WHEN 1 THEN 'Kanagawa'
                WHEN 2 THEN 'Chiba'
                WHEN 3 THEN 'Saitama'
                WHEN 4 THEN 'Osaka'
                WHEN 5 THEN 'Aichi'
                WHEN 6 THEN 'Fukuoka'
                WHEN 7 THEN 'Hokkaido'
                WHEN 8 THEN 'Hyogo'
                ELSE 'Kyoto'
            END AS prefecture,
            format('City%02s', (gs % 50) + 1) AS city,
            format('Street %03s', gs) AS address1,
            lpad(
                CAST(((1000000 + gs * 37) % 10000000) AS TEXT),
                7,
                '0'
            ) AS postal_code
        FROM
            generate_series(1, 300) gs
    ),
    ranked AS (
        SELECT
            b.*,
            row_number() OVER (
                PARTITION BY
                    b.user_id
                ORDER BY
                    b.id
            ) AS rn
        FROM
            base b
    )
INSERT INTO
    user_address (
        id,
        user_id,
        label,
        prefecture,
        city,
        address1,
        postal_code,
        is_default,
        created_at
    )
SELECT
    id,
    user_id,
    label,
    prefecture,
    city,
    address1,
    postal_code,
    (rn = 1) AS is_default,
    (CURRENT_TIMESTAMP - (id % 365) * INTERVAL '1 day')
FROM
    ranked;

SELECT
    setval(
        pg_get_serial_sequence('user_address', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                user_address
        )
    );

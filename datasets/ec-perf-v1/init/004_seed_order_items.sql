-- dataset: ec-perf-v1
-- purpose: 注文明細データ投入（約18万行想定）
-- 方針:
--   - 1注文あたり 2〜4 明細
--   - 上位ユーザーの注文は人気商品帯（ID 1〜80）に偏らせる
--   - quantity は 1〜3 を中心
--   - unit_price_yen は商品価格を採用（注文時価格として固定）
INSERT INTO
    public.order_item (order_id, product_id, quantity, unit_price_yen)
SELECT
    o.id AS order_id,
    x.product_id,
    x.quantity,
    p.price_yen AS unit_price_yen
FROM
    public.customer_order o
    JOIN LATERAL generate_series(
        1,
        CASE
            WHEN o.id % 10 < 4 THEN 2
            WHEN o.id % 10 < 8 THEN 3
            ELSE 4
        END
    ) AS s (n) ON TRUE
    JOIN LATERAL (
        SELECT
            CASE
            -- ヘビーユーザーの注文は人気商品帯に寄せる
                WHEN o.user_id <= 200 THEN ((o.id * (s.n * 11) + s.n * 17) % 80) + 1
                -- 一部注文は人気商品帯
                WHEN o.id % 10 = 0 THEN ((o.id * (s.n * 19) + s.n * 23) % 120) + 1
                -- それ以外は全体に分散
                ELSE ((o.id * (s.n * 29) + s.n * 31) % 500) + 1
            END AS product_id,
            CASE
                WHEN (o.id + s.n) % 10 < 7 THEN 1
                WHEN (o.id + s.n) % 10 < 9 THEN 2
                ELSE 3
            END AS quantity
    ) AS x ON TRUE
    JOIN public.product p ON p.id = x.product_id;

-- 確認
SELECT
    COUNT(*) AS order_item_count
FROM
    public.order_item;

SELECT
    ROUND(AVG(item_count), 2) AS avg_items_per_order,
    MIN(item_count) AS min_items_per_order,
    MAX(item_count) AS max_items_per_order
FROM
    (
        SELECT
            order_id,
            COUNT(*) AS item_count
        FROM
            public.order_item
        GROUP BY
            order_id
    ) t;

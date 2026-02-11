-- phase: 3
-- topic: Conditional aggregation by CASE（条件付き集計：汎用パターン）
-- dataset: ec-v0
-- note: 実務で最頻出級。「1本のSELECTで複数の指標」を作る型。
-- 0) 商品カテゴリ別：PC件数、食品件数などを1行で出す
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
            WHEN category = 'food' THEN 1
            ELSE 0
        END
    ) AS food_count,
    SUM(
        CASE
            WHEN category = 'stationery' THEN 1
            ELSE 0
        END
    ) AS stationery_count
FROM
    product;

-- 1) 価格帯別 件数（CASEでラベル分けしてから集約）
SELECT
    price_tier,
    COUNT(*) AS product_count,
    AVG(price_yen) AS avg_price_yen
FROM
    (
        SELECT
            id,
            price_yen,
            CASE
                WHEN price_yen < 1000 THEN 'low'
                WHEN price_yen < 5000 THEN 'mid'
                ELSE 'high'
            END AS price_tier
        FROM
            product
    ) t
GROUP BY
    price_tier
ORDER BY
    price_tier;

-- 2) 注文ステータス別 件数（注文データ）
SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'draft' THEN 1
            ELSE 0
        END
    ) AS draft_count,
    SUM(
        CASE
            WHEN order_status = 'paid' THEN 1
            ELSE 0
        END
    ) AS paid_count,
    SUM(
        CASE
            WHEN order_status = 'cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_count,
    SUM(
        CASE
            WHEN order_status = 'shipped' THEN 1
            ELSE 0
        END
    ) AS shipped_count,
    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_count
FROM
    customer_order;

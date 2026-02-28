-- phase: 6
-- topic: NTILE / PERCENT_RANK（分位・相対位置）
-- dataset: ec-v1
-- 目的:
--   - “上位何%” や “4分位” といった、実務の区分けを作る
--   - 絶対値のランキングだけでなく、相対的な位置を扱う
-- 0) ユーザーごとの総購入額（paid系の概算）を作る
WITH
    user_spend AS (
        SELECT
            o.user_id,
            SUM(oi.quantity * oi.unit_price_yen) AS spend_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.user_id
    )
SELECT
    *
FROM
    user_spend
ORDER BY
    spend_yen DESC
LIMIT
    20;

-- 1) 4分位に分ける（NTILE）
WITH
    user_spend AS (
        SELECT
            o.user_id,
            SUM(oi.quantity * oi.unit_price_yen) AS spend_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.user_id
    )
SELECT
    user_id,
    spend_yen,
    NTILE(4) OVER (
        ORDER BY
            spend_yen DESC
    ) AS spend_quartile
FROM
    user_spend
ORDER BY
    spend_yen DESC,
    user_id
LIMIT
    100;

-- 2) 相対順位（PERCENT_RANK：0〜1）
WITH
    user_spend AS (
        SELECT
            o.user_id,
            SUM(oi.quantity * oi.unit_price_yen) AS spend_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.user_id
    )
SELECT
    user_id,
    spend_yen,
    ROUND(
        (
            PERCENT_RANK() OVER (
                ORDER BY
                    spend_yen
            )
        )::numeric,
        4
    ) AS percent_rank_low_to_high,
    ROUND(
        (
            PERCENT_RANK() OVER (
                ORDER BY
                    spend_yen DESC
            )
        )::numeric,
        4
    ) AS percent_rank_high_to_low
FROM
    user_spend
ORDER BY
    spend_yen DESC,
    user_id
LIMIT
    100;

-- 3) 参考：PERCENTILE_CONT（中央値など）も実務で便利（ウィンドウ or 集約で使える）
-- ここでは「全体の中央値」をウィンドウ関数として各行に付与する例（見た目の確認用）。
WITH
    user_spend AS (
        SELECT
            o.user_id,
            SUM(oi.quantity * oi.unit_price_yen) AS spend_yen
        FROM
            customer_order o
            JOIN order_item oi ON oi.order_id = o.id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY
            o.user_id
    ),
    median AS (
        SELECT
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY
                    spend_yen
            ) AS median_spend_yen
        FROM
            user_spend
    )
SELECT
    us.user_id,
    us.spend_yen,
    m.median_spend_yen
FROM
    user_spend us
    CROSS JOIN median m
ORDER BY
    us.spend_yen DESC,
    us.user_id
LIMIT
    50;

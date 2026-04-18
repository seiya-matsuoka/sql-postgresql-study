-- dataset: ec-perf-v1
-- purpose: 注文データ投入（多め + 偏りあり）
-- 方針:
--   - 60,000件の注文
--   - 一部ユーザー（上位200）に注文を偏らせる
--   - ステータス分布も偏らせる（delivered多め）
--   - ordered_at は直近365日中心に分散
INSERT INTO
    public.customer_order (
        user_id,
        order_status,
        ordered_at,
        payment_method,
        channel,
        coupon_code
    )
SELECT
    CASE
    -- 60%: 上位200ユーザーに集中（偏り）
        WHEN gs % 100 < 60 THEN ((gs * 17) % 200) + 1
        -- 25%: 中位1,000ユーザー
        WHEN gs % 100 < 85 THEN ((gs * 31) % 1000) + 201
        -- 15%: 残りユーザー
        ELSE ((gs * 43) % 2800) + 1201
    END AS user_id,
    CASE
        WHEN gs % 100 < 58 THEN 'delivered'
        WHEN gs % 100 < 70 THEN 'shipped'
        WHEN gs % 100 < 82 THEN 'paid'
        WHEN gs % 100 < 90 THEN 'placed'
        ELSE 'cancelled'
    END AS order_status,
    CURRENT_TIMESTAMP - ((gs % 365) || ' days')::INTERVAL - (((gs * 7) % 24) || ' hours')::INTERVAL - (((gs * 13) % 60) || ' minutes')::INTERVAL AS ordered_at,
    CASE
        WHEN gs % 100 < 65 THEN 'card'
        WHEN gs % 100 < 80 THEN 'wallet'
        WHEN gs % 100 < 92 THEN 'bank'
        ELSE 'cod'
    END AS payment_method,
    CASE
        WHEN gs % 10 < 6 THEN 'web'
        WHEN gs % 10 < 8 THEN 'ios'
        ELSE 'android'
    END AS channel,
    CASE
        WHEN gs % 11 = 0 THEN 'CPN10'
        WHEN gs % 17 = 0 THEN 'CPN20'
        ELSE NULL
    END AS coupon_code
FROM
    generate_series(1, 60000) AS gs;

-- 確認
SELECT
    COUNT(*) AS customer_order_count
FROM
    public.customer_order;

SELECT
    order_status,
    COUNT(*) AS cnt
FROM
    public.customer_order
GROUP BY
    order_status
ORDER BY
    cnt DESC,
    order_status;

-- phase: 1
-- topic: Functions / CAST / DateTime（実務頻出の関数・型変換・日時）
-- dataset: ec-v0
-- note: 「値の加工」をまず体験する。深い最適化は後回し。
-- 1) 文字列関数（upper/lower/length/replace）
SELECT
    id,
    email,
    upper(email) AS email_upper,
    length(email) AS email_len,
    replace(email, '@example.com', '@masked.local') AS email_masked
FROM
    app_user
ORDER BY
    id;

-- 2) 連結（||）と concat_ws（区切り付き）
SELECT
    id,
    display_name,
    email,
    display_name || ' <' || email || '>' AS label_concat,
    concat_ws(' / ', display_name, email) AS label_concat_ws
FROM
    app_user
ORDER BY
    id;

-- 3) 数値関数（round, ceil, floor）
SELECT
    id,
    name,
    price_yen,
    round(price_yen * 1.1) AS tax_included_round,
    ceil(price_yen / 1000.0) AS kilo_ceil,
    floor(price_yen / 1000.0) AS kilo_floor
FROM
    product
ORDER BY
    id;

-- 4) CAST（型変換）
SELECT
    id,
    name,
    price_yen,
    (price_yen::numeric / 1000) AS price_k_yen_numeric,
    (price_yen::text || ' JPY') AS price_text
FROM
    product
ORDER BY
    id;

-- 5) 日時（current_date, current_timestamp, interval）
SELECT
    current_date AS today,
    current_timestamp AS now_ts,
    (current_timestamp - interval '1 day') AS yesterday_ts;

-- 6) 注文日時の加工（date_trunc, extract）
SELECT
    id AS order_id,
    user_id,
    order_status,
    ordered_at,
    ordered_at::date AS ordered_date,
    date_trunc('day', ordered_at) AS ordered_day_ts,
    extract(
        dow
        from
            ordered_at
    ) AS dow_0_sun
FROM
    customer_order
ORDER BY
    ordered_at DESC,
    id;

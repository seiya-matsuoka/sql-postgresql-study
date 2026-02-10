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

-- 標準SQL（PostgreSQLでも実行可）：CONCAT で連結する
SELECT
    id,
    display_name,
    email,
    CONCAT(display_name, ' <', email, '>') AS label_concat_standard
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
-- PostgreSQL 方言（::）でのキャスト（省略記法）
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

-- 標準SQL（PostgreSQLでも実行可）：CAST(... AS ...) を使う
SELECT
    id,
    name,
    price_yen,
    (CAST(price_yen AS numeric) / 1000) AS price_k_yen_numeric,
    (CAST(price_yen AS text) || ' JPY') AS price_text
FROM
    product
ORDER BY
    id;

-- 5) 日時（current_date, current_timestamp, interval）
SELECT
    current_date AS today,
    current_timestamp AS now_ts,
    (current_timestamp - interval '1 day') AS yesterday_ts;

-- 標準寄り（PostgreSQLでも実行可）：now() ではなく CURRENT_TIMESTAMP を使う例
SELECT
    CURRENT_DATE AS today_standard,
    CURRENT_TIMESTAMP AS now_standard;

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

-- 標準SQL（PostgreSQLでも実行可）：日付へ落とす（timestamp丸めではなく「日付」の用途ならこれが移植性高い）
-- ※曜日番号（dow）はDB差が大きいので、ここでは日付変換にフォーカスする
SELECT
    id AS order_id,
    user_id,
    order_status,
    ordered_at,
    CAST(ordered_at AS date) AS ordered_date_standard
FROM
    customer_order
ORDER BY
    ordered_at DESC,
    id;

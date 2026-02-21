-- phase: 9
-- topic: ビュー利用（SELECT再利用・絞り込み・ネスト）
-- dataset: ec-v1（view_labのVIEWを利用）
-- 目的:
--   - 「元SQLを毎回書かずに済む」感覚を掴む
--   - VIEWの上にさらにSELECTを重ねる使い方に慣れる
-- 0) v_order_totals をそのまま使う
SELECT
    order_id,
    user_id,
    order_status,
    ordered_at,
    items_total_yen
FROM
    view_lab.v_order_totals
ORDER BY
    items_total_yen DESC,
    order_id DESC
LIMIT
    20;

-- 1) 日別売上ビューを使って、直近の日を確認
SELECT
    sales_date,
    order_count,
    revenue_yen,
    ROUND(avg_order_yen, 2) AS avg_order_yen
FROM
    view_lab.v_daily_revenue
ORDER BY
    sales_date DESC
LIMIT
    14;

-- 2) 都道府県別売上ビューに対してさらに絞る（上位10都道府県）
SELECT
    prefecture,
    order_count,
    revenue_yen,
    ROUND(avg_order_yen, 2) AS avg_order_yen
FROM
    view_lab.v_prefecture_revenue
ORDER BY
    revenue_yen DESC,
    prefecture
LIMIT
    10;

-- 3) 最新注文ビュー × 住所情報（VIEWの再利用）
SELECT
    l.user_id,
    l.order_id,
    l.ordered_at,
    l.items_total_yen,
    COALESCE(ua.prefecture, 'UNKNOWN') AS prefecture
FROM
    view_lab.v_latest_order_per_user l
    LEFT JOIN public.user_address ua ON ua.user_id = l.user_id
    AND ua.is_default = TRUE
ORDER BY
    l.items_total_yen DESC,
    l.user_id
LIMIT
    20;

-- 4) カテゴリ別Top3商品（VIEWの上にさらに条件）
SELECT
    category,
    product_id,
    name,
    price_yen,
    row_num_in_category
FROM
    view_lab.v_product_price_rank
WHERE
    row_num_in_category <= 3
ORDER BY
    category,
    row_num_in_category,
    product_id;

-- 5) ビュー定義は参照元テーブルの変更に影響される（概念）
--   - VIEWはデータを持たない（定義だけ）
--   - 参照元が変わると、VIEWのSELECT結果も変わる
--   - ただし、複雑なVIEWは更新不可（UPDATE/INSERTできない）なことが多い
-- phase: 9
-- topic: ビュー作成（ec-v1のレポートSQLを固定化）
-- dataset: ec-v1（publicを参照、view_labにVIEWを作成）
-- 方針:
--   - Phase 3〜6で扱った内容を「再利用しやすい形」にする
--   - CREATE OR REPLACE VIEW を使って、再実行しやすくする
CREATE SCHEMA IF NOT EXISTS view_lab;

-- 1) 注文合計（paid系のみ）
CREATE OR REPLACE VIEW view_lab.v_order_totals AS
SELECT
    o.id AS order_id,
    o.user_id,
    o.order_status,
    o.ordered_at,
    SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
FROM
    public.customer_order o
    JOIN public.order_item oi ON oi.order_id = o.id
WHERE
    o.order_status IN ('paid', 'shipped', 'delivered')
GROUP BY
    o.id,
    o.user_id,
    o.order_status,
    o.ordered_at;

COMMENT ON VIEW view_lab.v_order_totals IS 'ec-v1: paid系注文の注文合計（明細合算）';

-- 2) 日別売上（レポートの定番）
CREATE OR REPLACE VIEW view_lab.v_daily_revenue AS
SELECT
    CAST(v.ordered_at AS DATE) AS sales_date,
    COUNT(*) AS order_count,
    SUM(v.items_total_yen) AS revenue_yen,
    AVG(v.items_total_yen) AS avg_order_yen
FROM
    view_lab.v_order_totals v
GROUP BY
    CAST(v.ordered_at AS DATE);

COMMENT ON VIEW view_lab.v_daily_revenue IS 'ec-v1: 日別売上（件数・売上・平均注文額）';

-- 3) 都道府県別売上（住所のデフォルト住所を使用）
CREATE OR REPLACE VIEW view_lab.v_prefecture_revenue AS
WITH
    user_default_address AS (
        SELECT
            ua.user_id,
            ua.prefecture
        FROM
            public.user_address ua
        WHERE
            ua.is_default = TRUE
    )
SELECT
    COALESCE(a.prefecture, 'UNKNOWN') AS prefecture,
    COUNT(*) AS order_count,
    SUM(v.items_total_yen) AS revenue_yen,
    AVG(v.items_total_yen) AS avg_order_yen
FROM
    view_lab.v_order_totals v
    LEFT JOIN user_default_address a ON a.user_id = v.user_id
GROUP BY
    COALESCE(a.prefecture, 'UNKNOWN');

COMMENT ON VIEW view_lab.v_prefecture_revenue IS 'ec-v1: 都道府県別売上（デフォルト住所ベース）';

-- 4) 各ユーザーの最新注文（ウィンドウ関数の再利用）
CREATE OR REPLACE VIEW view_lab.v_latest_order_per_user AS
WITH
    ranked AS (
        SELECT
            v.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    v.user_id
                ORDER BY
                    v.ordered_at DESC,
                    v.order_id DESC
            ) AS rn
        FROM
            view_lab.v_order_totals v
    )
SELECT
    user_id,
    order_id,
    order_status,
    ordered_at,
    items_total_yen
FROM
    ranked
WHERE
    rn = 1;

COMMENT ON VIEW view_lab.v_latest_order_per_user IS 'ec-v1: ユーザーごとの最新注文（paid系）';

-- 5) カテゴリ内価格ランキング（ウィンドウ関数）
CREATE OR REPLACE VIEW view_lab.v_product_price_rank AS
SELECT
    p.category,
    p.id AS product_id,
    p.name,
    p.price_yen,
    ROW_NUMBER() OVER (
        PARTITION BY
            p.category
        ORDER BY
            p.price_yen DESC,
            p.id
    ) AS row_num_in_category,
    RANK() OVER (
        PARTITION BY
            p.category
        ORDER BY
            p.price_yen DESC,
            p.id
    ) AS rank_in_category
FROM
    public.product p;

COMMENT ON VIEW view_lab.v_product_price_rank IS 'ec-v1: 商品のカテゴリ内価格ランキング';

-- 軽い確認
SELECT
    schemaname,
    viewname
FROM
    pg_views
WHERE
    schemaname = 'view_lab'
ORDER BY
    viewname;
-- phase: 9
-- topic: マテビュー作成（ec-v1レポート + labデモ）
-- dataset: ec-v1 + lab（結果はview_labに作成）
-- 補足:
--   - マテビューは PostgreSQL の機能（DBごとに差あり）
--   - VIEWと違って「結果を保存」する
--   - REFRESHで更新する
CREATE SCHEMA IF NOT EXISTS view_lab;

-- 0) 再実行できるように既存を削除
DROP MATERIALIZED VIEW IF EXISTS view_lab.mv_ec_daily_revenue;

DROP MATERIALIZED VIEW IF EXISTS view_lab.mv_lab_transfer_status_counts;

-- 1) ec-v1の日別売上マテビュー（Phase 3の定番）
CREATE MATERIALIZED VIEW view_lab.mv_ec_daily_revenue AS
SELECT
    CAST(v.ordered_at AS DATE) AS sales_date,
    COUNT(*) AS order_count,
    SUM(v.items_total_yen) AS revenue_yen,
    AVG(v.items_total_yen) AS avg_order_yen
FROM
    view_lab.v_order_totals v
GROUP BY
    CAST(v.ordered_at AS DATE)
ORDER BY
    sales_date
WITH
    DATA;

COMMENT ON MATERIALIZED VIEW view_lab.mv_ec_daily_revenue IS 'ec-v1: 日別売上マテビュー（REFRESHで更新）';

-- CONCURRENTLY用にユニークインデックスが必要（sales_dateは1日1行の想定）
CREATE UNIQUE INDEX uq_mv_ec_daily_revenue_sales_date ON view_lab.mv_ec_daily_revenue (sales_date);

-- 2) lab.transfer の状態別件数マテビュー（REFRESH差分を体験しやすい題材）
CREATE MATERIALIZED VIEW view_lab.mv_lab_transfer_status_counts AS
SELECT
    t.status,
    COUNT(*) AS transfer_count,
    SUM(t.amount_yen) AS total_amount_yen
FROM
    lab.transfer t
GROUP BY
    t.status
ORDER BY
    t.status
WITH
    DATA;

COMMENT ON MATERIALIZED VIEW view_lab.mv_lab_transfer_status_counts IS 'lab: transfer状態別集計（REFRESHデモ用）';

CREATE UNIQUE INDEX uq_mv_lab_transfer_status_counts_status ON view_lab.mv_lab_transfer_status_counts (status);

-- 3) 初回確認
SELECT
    sales_date,
    order_count,
    revenue_yen,
    ROUND(avg_order_yen, 2) AS avg_order_yen
FROM
    view_lab.mv_ec_daily_revenue
ORDER BY
    sales_date DESC
LIMIT
    10;

SELECT
    status,
    transfer_count,
    total_amount_yen
FROM
    view_lab.mv_lab_transfer_status_counts
ORDER BY
    status;
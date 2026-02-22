-- phase: 9
-- topic: マテビューREFRESH体験（stale → refresh）
-- dataset: lab（差分体験用） + view_lab
-- 目的:
--   - マテビューは元テーブル更新後も自動反映されないことを確認
--   - REFRESH MATERIALIZED VIEW で反映されることを体験
--   - CONCURRENTLY の実行形も確認（ユニークインデックス前提）
-- 注意:
--   - このデモは lab.transfer に1件だけ追加する（ec-v1は更新しない）
-- 0) まず現在のマテビュー状態を確認（REFRESH前）
SELECT
    status,
    transfer_count,
    total_amount_yen
FROM
    view_lab.mv_lab_transfer_status_counts
ORDER BY
    status;

-- 1) デモ用transferを一旦削除（再実行対応）
DELETE FROM lab.transfer
WHERE
    idempotency_key = 'phase9-mv-refresh-demo-001';

-- 2) 元テーブル（lab.transfer）に新しい行を追加
--   - account_id=1,2 は Phase 7 seedの想定（labを再作成していれば存在）
INSERT INTO
    lab.transfer (
        from_account_id,
        to_account_id,
        amount_yen,
        status,
        idempotency_key,
        requested_at
    )
VALUES
    (
        1,
        2,
        111,
        'requested',
        'phase9-mv-refresh-demo-001',
        CURRENT_TIMESTAMP
    );

-- 3) 元テーブルの状態確認（増えている）
SELECT
    status,
    COUNT(*) AS transfer_count,
    SUM(amount_yen) AS total_amount_yen
FROM
    lab.transfer
GROUP BY
    status
ORDER BY
    status;

-- 4) マテビューの状態確認（まだ古い＝増えていない）
SELECT
    status,
    transfer_count,
    total_amount_yen
FROM
    view_lab.mv_lab_transfer_status_counts
ORDER BY
    status;

-- 5) REFRESH（通常）
REFRESH MATERIALIZED VIEW view_lab.mv_lab_transfer_status_counts;

-- 6) REFRESH後の確認（反映された）
SELECT
    status,
    transfer_count,
    total_amount_yen
FROM
    view_lab.mv_lab_transfer_status_counts
ORDER BY
    status;

-- 7) CONCURRENTLY の形も実行（PostgreSQL特有）
--    前提：マテビューにユニークインデックスがあること（sql/093で作成済み）
REFRESH MATERIALIZED VIEW CONCURRENTLY view_lab.mv_lab_transfer_status_counts;

-- 8) 参考として ec-v1側のマテビューもREFRESHしてみる
--    （今回はec-v1を更新していないので結果は通常変わらない）
REFRESH MATERIALIZED VIEW view_lab.mv_ec_daily_revenue;

SELECT
    sales_date,
    order_count,
    revenue_yen
FROM
    view_lab.mv_ec_daily_revenue
ORDER BY
    sales_date DESC
LIMIT
    5;
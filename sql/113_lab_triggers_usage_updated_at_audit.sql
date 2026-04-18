-- phase: 11
-- topic: updated_at 自動更新 + 監査ログ（audit）を体験
-- dataset: lab（trg_* テーブル）
-- 前提:
--   - sql/110, 111, 112 実行済み
-- 目的:
--   - BEFORE UPDATE で updated_at が更新されることを確認
--   - AFTER UPDATE/DELETE で監査ログが残ることを確認
-- 0) 初期状態確認
SELECT
    product_id,
    sku,
    product_name,
    stock_qty,
    price_yen,
    created_at,
    updated_at
FROM
    lab.trg_product
WHERE
    product_id IN (2, 9)
ORDER BY
    product_id;

SELECT
    audit_id,
    table_name,
    operation,
    pk_value,
    changed_at
FROM
    lab.trg_audit_log
ORDER BY
    audit_id;

-- 1) UPDATE（updated_at + audit対象）
SELECT
    pg_sleep(1);

-- 時刻差を見やすくする
UPDATE lab.trg_product
SET
    product_name = 'Pen (updated)',
    price_yen = 120
WHERE
    product_id = 2;

-- 2) DELETE（audit対象）
DELETE FROM lab.trg_product
WHERE
    product_id = 9;

-- 3) 結果確認（updated_atが変わっている）
SELECT
    product_id,
    sku,
    product_name,
    stock_qty,
    price_yen,
    created_at,
    updated_at
FROM
    lab.trg_product
WHERE
    product_id = 2;

-- 4) 監査ログ確認（UPDATEとDELETEの2件が増える）
SELECT
    audit_id,
    table_name,
    operation,
    pk_value,
    changed_at,
    changed_by
FROM
    lab.trg_audit_log
ORDER BY
    audit_id DESC
LIMIT
    10;

-- 5) old/new の中身確認（JSONB）
SELECT
    audit_id,
    operation,
    pk_value,
    old_row,
    new_row
FROM
    lab.trg_audit_log
WHERE
    table_name = 'lab.trg_product'
ORDER BY
    audit_id DESC
LIMIT
    5;

-- 6) JSONBから項目を抜いて見る（例）
SELECT
    audit_id,
    operation,
    old_row ->> 'product_name' AS old_product_name,
    new_row ->> 'product_name' AS new_product_name,
    old_row ->> 'price_yen' AS old_price_yen,
    new_row ->> 'price_yen' AS new_price_yen
FROM
    lab.trg_audit_log
WHERE
    table_name = 'lab.trg_product'
    AND operation = 'UPDATE'
ORDER BY
    audit_id DESC
LIMIT
    3;

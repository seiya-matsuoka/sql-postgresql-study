-- phase: 11
-- topic: トリガの無効化 / 有効化を体験（危険性の理解）
-- dataset: lab（trg_* テーブル）
-- 前提:
--   - sql/110, 111, 112 実行済み
-- 目的:
--   - ALTER TABLE ... DISABLE/ENABLE TRIGGER を体験する
--   - トリガが無効だと副作用（在庫減算）が起きないことを確認する
-- 注意:
--   - 実務での無効化は影響が大きいので慎重に扱う
--   - このファイルは学習用（lab専用）
-- 0) デモ用の状態を揃える（何度でも再実行しやすくする）
-- order 1103 を draft に戻し、Mouse在庫を2に戻す
UPDATE lab.trg_order
SET
    order_status = 'draft'
WHERE
    order_id = 1103;

UPDATE lab.trg_product
SET
    stock_qty = 2
WHERE
    product_id = 4;

SELECT
    order_id,
    order_status,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id = 1103;

SELECT
    product_id,
    sku,
    stock_qty,
    updated_at
FROM
    lab.trg_product
WHERE
    product_id = 4;

-- ============================================
-- 1) 在庫連動トリガを無効化
-- ============================================
ALTER TABLE lab.trg_order DISABLE TRIGGER trg_trg_order_apply_inventory_on_paid;

-- 無効化確認（tgenabled が D になる）
SELECT
    c.relname AS table_name,
    t.tgname AS trigger_name,
    t.tgenabled
FROM
    pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'lab'
    AND c.relname = 'trg_order'
    AND t.tgname = 'trg_trg_order_apply_inventory_on_paid';

-- 2) order_status を paid に更新（在庫は減らない）
UPDATE lab.trg_order
SET
    order_status = 'paid'
WHERE
    order_id = 1103;

SELECT
    order_id,
    order_status,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id = 1103;

SELECT
    product_id,
    sku,
    stock_qty
FROM
    lab.trg_product
WHERE
    product_id = 4;

-- ============================================
-- 3) トリガを再有効化
-- ============================================
ALTER TABLE lab.trg_order ENABLE TRIGGER trg_trg_order_apply_inventory_on_paid;

-- 有効化確認（tgenabled が O になる）
SELECT
    c.relname AS table_name,
    t.tgname AS trigger_name,
    t.tgenabled
FROM
    pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'lab'
    AND c.relname = 'trg_order'
    AND t.tgname = 'trg_trg_order_apply_inventory_on_paid';

-- ============================================
-- 4) 再度デモ状態を揃えて、有効化後の挙動を確認
--    （トリガ無効時の更新では在庫が減らなかったので、手動で戻して再実験）
-- ============================================
UPDATE lab.trg_order
SET
    order_status = 'draft'
WHERE
    order_id = 1103;

UPDATE lab.trg_product
SET
    stock_qty = 2
WHERE
    product_id = 4;

-- 今度はトリガ有効なので在庫が減る
UPDATE lab.trg_order
SET
    order_status = 'paid'
WHERE
    order_id = 1103;

SELECT
    order_id,
    order_status,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id = 1103;

SELECT
    product_id,
    sku,
    stock_qty
FROM
    lab.trg_product
WHERE
    product_id = 4;

-- ============================================
-- 5) 補足メモ
-- ============================================
SELECT
    'トリガ無効化中は整合性を守る処理が動かない可能性がある。実務では影響範囲を把握して慎重に行う。' AS note;

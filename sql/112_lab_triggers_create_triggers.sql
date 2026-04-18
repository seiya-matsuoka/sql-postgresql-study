-- phase: 11
-- topic: トリガ本体の作成（テーブルへ紐付け）
-- dataset: lab（trg_* テーブル）
-- 目的:
--   - BEFORE/AFTERトリガを貼る
--   - WHEN句で条件を絞る
-- 既存トリガがあれば削除（再実行対応）
DROP TRIGGER IF EXISTS trg_trg_product_set_updated_at ON lab.trg_product;

DROP TRIGGER IF EXISTS trg_trg_order_set_updated_at ON lab.trg_order;

DROP TRIGGER IF EXISTS trg_trg_product_audit_ud ON lab.trg_product;

DROP TRIGGER IF EXISTS trg_trg_order_audit_ud ON lab.trg_order;

DROP TRIGGER IF EXISTS trg_trg_order_apply_inventory_on_paid ON lab.trg_order;

-- ============================================
-- 1) updated_at 自動更新（BEFORE UPDATE）
-- ============================================
CREATE TRIGGER trg_trg_product_set_updated_at BEFORE
UPDATE ON lab.trg_product FOR EACH ROW
EXECUTE FUNCTION lab.fn_trg_set_updated_at ();

CREATE TRIGGER trg_trg_order_set_updated_at BEFORE
UPDATE ON lab.trg_order FOR EACH ROW
EXECUTE FUNCTION lab.fn_trg_set_updated_at ();

-- ============================================
-- 2) 監査ログ（AFTER UPDATE OR DELETE）
--    主キー列名を引数で渡す
-- ============================================
CREATE TRIGGER trg_trg_product_audit_ud
AFTER
UPDATE
OR DELETE ON lab.trg_product FOR EACH ROW
EXECUTE FUNCTION lab.fn_trg_audit_ud ('product_id');

CREATE TRIGGER trg_trg_order_audit_ud
AFTER
UPDATE
OR DELETE ON lab.trg_order FOR EACH ROW
EXECUTE FUNCTION lab.fn_trg_audit_ud ('order_id');

-- ============================================
-- 3) 在庫連動（AFTER UPDATE OF order_status）
--    draft -> paid のときだけ在庫減算
-- ============================================
CREATE TRIGGER trg_trg_order_apply_inventory_on_paid
AFTER
UPDATE OF order_status ON lab.trg_order FOR EACH ROW WHEN (
    OLD.order_status IS DISTINCT FROM NEW.order_status
    AND NEW.order_status = 'paid'
)
EXECUTE FUNCTION lab.fn_trg_apply_inventory_on_order_paid ();

-- 作成確認（簡易）
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    t.tgname AS trigger_name,
    CASE
        WHEN (t.tgtype & 2) = 2 THEN 'BEFORE'
        ELSE 'AFTER'
    END AS timing,
    CASE
        WHEN (t.tgtype & 4) = 4 THEN 'INSERT'
        WHEN (t.tgtype & 8) = 8 THEN 'DELETE'
        WHEN (t.tgtype & 16) = 16 THEN 'UPDATE'
        ELSE 'OTHER'
    END AS primary_event,
    t.tgenabled
FROM
    pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'lab'
    AND c.relname IN ('trg_product', 'trg_order')
    AND NOT t.tgisinternal
ORDER BY
    c.relname,
    t.tgname;

-- phase: 11
-- topic: トリガ関数の作成（updated_at / audit / 在庫連動）
-- dataset: lab（trg_* テーブル）
-- 目的:
--   - RETURNS trigger の関数を作る
--   - OLD/NEW/TG_OP/TG_TABLE_NAME を使う
-- 再実行しやすいように先に削除
DROP FUNCTION IF EXISTS lab.fn_trg_set_updated_at ();

DROP FUNCTION IF EXISTS lab.fn_trg_audit_ud ();

DROP FUNCTION IF EXISTS lab.fn_trg_apply_inventory_on_order_paid ();

-- ============================================
-- 1) updated_at 自動更新（BEFORE UPDATE用）
-- ============================================
CREATE OR REPLACE FUNCTION lab.fn_trg_set_updated_at () RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION lab.fn_trg_set_updated_at () IS 'BEFORE UPDATE で NEW.updated_at を現在時刻に更新するトリガ関数';

-- ============================================
-- 2) 監査ログ（UPDATE / DELETE）
--    - TG_ARGV[0] に主キー列名を渡す想定（例: product_id, order_id）
-- ============================================
CREATE OR REPLACE FUNCTION lab.fn_trg_audit_ud () RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_pk_col  TEXT := COALESCE(TG_ARGV[0], 'id');
  v_pk_val  TEXT;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    v_pk_val := COALESCE(to_jsonb(NEW) ->> v_pk_col, to_jsonb(OLD) ->> v_pk_col);

    INSERT INTO lab.trg_audit_log (
      table_name,
      operation,
      pk_value,
      old_row,
      new_row
    ) VALUES (
      TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
      TG_OP,
      v_pk_val,
      to_jsonb(OLD),
      to_jsonb(NEW)
    );

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    v_pk_val := to_jsonb(OLD) ->> v_pk_col;

    INSERT INTO lab.trg_audit_log (
      table_name,
      operation,
      pk_value,
      old_row,
      new_row
    ) VALUES (
      TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
      TG_OP,
      v_pk_val,
      to_jsonb(OLD),
      NULL
    );

    RETURN OLD;

  ELSE
    RAISE EXCEPTION 'fn_trg_audit_ud は UPDATE/DELETE専用です（TG_OP=%）', TG_OP;
  END IF;
END;
$$;

COMMENT ON FUNCTION lab.fn_trg_audit_ud () IS 'UPDATE/DELETE時に old/new をJSONBで監査ログへ書くトリガ関数';

-- ============================================
-- 3) 在庫連動（AFTER UPDATE OF order_status用）
--    - draft -> paid のときだけ在庫を減らす
--    - 在庫不足なら例外（更新全体を失敗させる）
-- ============================================
CREATE OR REPLACE FUNCTION lab.fn_trg_apply_inventory_on_order_paid () RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_item RECORD;
  v_rowcount INTEGER;
  v_current_stock INTEGER;
BEGIN
  -- 念のため（トリガ定義のWHEN句でも絞る想定）
  IF NOT (OLD.order_status IS DISTINCT FROM NEW.order_status AND NEW.order_status = 'paid') THEN
    RETURN NEW;
  END IF;

  -- 明細が0件ならエラー
  IF NOT EXISTS (
    SELECT 1
    FROM lab.trg_order_item oi
    WHERE oi.order_id = NEW.order_id
  ) THEN
    RAISE EXCEPTION '明細が0件のため在庫連動できません（order_id=%）', NEW.order_id;
  END IF;

  -- 明細ごとに在庫を減算
  FOR v_item IN
    SELECT
      oi.product_id,
      oi.quantity
    FROM lab.trg_order_item oi
    WHERE oi.order_id = NEW.order_id
    ORDER BY oi.line_no
  LOOP
    UPDATE lab.trg_product p
    SET stock_qty = p.stock_qty - v_item.quantity
    WHERE p.product_id = v_item.product_id
      AND p.stock_qty >= v_item.quantity;

    GET DIAGNOSTICS v_rowcount = ROW_COUNT;

    IF v_rowcount = 0 THEN
      -- 失敗理由の見える化（存在しない or 在庫不足）
      SELECT p.stock_qty
      INTO v_current_stock
      FROM lab.trg_product p
      WHERE p.product_id = v_item.product_id;

      IF NOT FOUND THEN
        RAISE EXCEPTION '商品が存在しません（product_id=%、order_id=%）', v_item.product_id, NEW.order_id;
      ELSE
        RAISE EXCEPTION '在庫不足です（product_id=%、stock=%、required=%、order_id=%）',
          v_item.product_id, v_current_stock, v_item.quantity, NEW.order_id;
      END IF;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION lab.fn_trg_apply_inventory_on_order_paid () IS '注文ステータスが paid になったときに明細分の在庫を減らすトリガ関数';

-- 作成確認
SELECT
  routine_schema,
  routine_name,
  routine_type
FROM
  information_schema.routines
WHERE
  routine_schema = 'lab'
  AND routine_name LIKE 'fn_trg_%'
ORDER BY
  routine_name;

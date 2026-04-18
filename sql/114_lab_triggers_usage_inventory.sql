-- phase: 11
-- topic: 在庫連動トリガを体験（成功 / 在庫不足）
-- dataset: lab（trg_* テーブル）
-- 前提:
--   - sql/110, 111, 112 実行済み
-- 目的:
--   - 注文ステータス更新だけで在庫が減る副作用を体験
--   - トリガ例外で更新全体が失敗することを確認
-- 注意:
--   - トリガは「見えにくい副作用」が本質
--   - UPDATEしたのは注文なのに、商品在庫が変わる
-- 0) 初期状態確認
SELECT
    order_id,
    order_status,
    note,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id IN (1101, 1102)
ORDER BY
    order_id;

SELECT
    product_id,
    sku,
    stock_qty
FROM
    lab.trg_product
WHERE
    product_id IN (1, 2, 3)
ORDER BY
    product_id;

SELECT
    order_id,
    line_no,
    product_id,
    quantity
FROM
    lab.trg_order_item
WHERE
    order_id IN (1101, 1102)
ORDER BY
    order_id,
    line_no;

-- ============================================
-- 1) 成功例：1101 を draft -> paid
--    トリガで在庫が減る
-- ============================================
UPDATE lab.trg_order
SET
    order_status = 'paid'
WHERE
    order_id = 1101;

-- 結果確認（注文ステータス + 在庫）
SELECT
    order_id,
    order_status,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id = 1101;

SELECT
    product_id,
    sku,
    stock_qty
FROM
    lab.trg_product
WHERE
    product_id IN (1, 2)
ORDER BY
    product_id;

-- 参考: 監査ログにも注文UPDATE / 商品UPDATE が記録されている
SELECT
    audit_id,
    table_name,
    operation,
    pk_value,
    changed_at
FROM
    lab.trg_audit_log
WHERE
    table_name IN ('lab.trg_order', 'lab.trg_product')
ORDER BY
    audit_id DESC
LIMIT
    20;

-- ============================================
-- 2) 同じ値へのUPDATE（paid -> paid）
--    order_status は同じなので在庫減算トリガは動かない（WHEN句）
--    ただし UPDATE文なので updated_at は更新される（BEFORE UPDATE）
-- ============================================
SELECT
    pg_sleep(1);

UPDATE lab.trg_order
SET
    order_status = 'paid'
WHERE
    order_id = 1101;

SELECT
    order_id,
    order_status,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id = 1101;

SELECT
    product_id,
    sku,
    stock_qty
FROM
    lab.trg_product
WHERE
    product_id IN (1, 2)
ORDER BY
    product_id;

-- ============================================
-- 3) 失敗例：1102 は在庫不足（Cable x5, 在庫3）
--    トリガ関数の例外で UPDATE 自体が失敗する
--    DOブロックで例外を捕まえてスクリプト継続
-- ============================================
DO $$
BEGIN
  BEGIN
    UPDATE lab.trg_order
    SET order_status = 'paid'
    WHERE order_id = 1102;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[トリガ例外] 想定どおり失敗: %', SQLERRM;
  END;
END $$;

-- 失敗後確認（注文はdraftのまま / 在庫も変化なし）
SELECT
    order_id,
    order_status,
    updated_at
FROM
    lab.trg_order
WHERE
    order_id = 1102;

SELECT
    product_id,
    sku,
    stock_qty
FROM
    lab.trg_product
WHERE
    product_id = 3;

-- 監査ログ確認（失敗したUPDATEはロールバックされるので、order/productのauditは増えない）
SELECT
    audit_id,
    table_name,
    operation,
    pk_value,
    changed_at
FROM
    lab.trg_audit_log
ORDER BY
    audit_id DESC
LIMIT
    20;

-- ============================================
-- 4) 補足（重要）
-- ============================================
SELECT
    '在庫連動のような業務ロジックをトリガで実装すると便利だが、どこで在庫が変わったか追いづらくなる。' AS note;

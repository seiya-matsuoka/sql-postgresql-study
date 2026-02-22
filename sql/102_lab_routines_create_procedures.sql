-- phase: 10
-- topic: 更新系プロシージャの作成（CALLで実行）
-- dataset: lab
-- 目的:
--   - 更新手順をDB側でまとめる
--   - 入力チェック / 例外 / idempotency を体験する
-- 備考:
--   - PostgreSQLの PROCEDURE / PLpgSQL を使用
--   - COMMIT/ROLLBACK はプロシージャ内で行わず、呼び出し側に任せる（学習しやすさ重視）
DROP PROCEDURE IF EXISTS lab.sp_apply_transfer (INTEGER, INTEGER, BIGINT, TEXT);

DROP PROCEDURE IF EXISTS lab.sp_finalize_simple_order (INTEGER);

-- =========
-- 1) 送金プロシージャ
--    - 2口座間で残高移動
--    - transfer履歴を1件追加
--    - idempotency_key 重複はUNIQUE制約で防止
-- =========
CREATE OR REPLACE PROCEDURE lab.sp_apply_transfer (
    p_from_account_id INTEGER,
    p_to_account_id INTEGER,
    p_amount_yen BIGINT,
    p_idempotency_key TEXT
) LANGUAGE plpgsql AS $$
DECLARE
  v_from_balance BIGINT;
  v_to_balance   BIGINT;
  v_from_currency CHAR(3);
  v_to_currency   CHAR(3);
BEGIN
  -- 入力チェック
  IF p_from_account_id IS NULL OR p_to_account_id IS NULL THEN
    RAISE EXCEPTION '口座IDは必須です';
  END IF;

  IF p_from_account_id = p_to_account_id THEN
    RAISE EXCEPTION '同一口座間の送金はできません（account_id=%）', p_from_account_id;
  END IF;

  IF p_amount_yen IS NULL OR p_amount_yen <= 0 THEN
    RAISE EXCEPTION '金額は1以上で指定してください（amount_yen=%）', p_amount_yen;
  END IF;

  IF p_idempotency_key IS NULL OR btrim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'idempotency_key は必須です';
  END IF;

  -- デッドロックを起こしにくくするため、口座行をID昇順で先にロック
  PERFORM 1
  FROM lab.account a
  WHERE a.account_id IN (p_from_account_id, p_to_account_id)
  ORDER BY a.account_id
  FOR UPDATE;

  -- 送金元口座取得
  SELECT a.balance_yen, a.currency
  INTO v_from_balance, v_from_currency
  FROM lab.account a
  WHERE a.account_id = p_from_account_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION '送金元口座が存在しません（account_id=%）', p_from_account_id;
  END IF;

  -- 送金先口座取得
  SELECT a.balance_yen, a.currency
  INTO v_to_balance, v_to_currency
  FROM lab.account a
  WHERE a.account_id = p_to_account_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION '送金先口座が存在しません（account_id=%）', p_to_account_id;
  END IF;

  -- ここでは学習のため JPY口座同士に限定
  IF v_from_currency <> 'JPY' OR v_to_currency <> 'JPY' THEN
    RAISE EXCEPTION 'このプロシージャはJPY口座同士のみ対応です（from=%、to=%）', v_from_currency, v_to_currency;
  END IF;

  -- 残高チェック
  IF v_from_balance < p_amount_yen THEN
    RAISE EXCEPTION '残高不足です（from_balance=%、amount=%）', v_from_balance, p_amount_yen;
  END IF;

  -- 残高更新
  UPDATE lab.account
  SET balance_yen = balance_yen - p_amount_yen
  WHERE account_id = p_from_account_id;

  UPDATE lab.account
  SET balance_yen = balance_yen + p_amount_yen
  WHERE account_id = p_to_account_id;

  -- 履歴追加（idempotency_key 重複時はUNIQUE制約違反）
  INSERT INTO lab.transfer (
    from_account_id,
    to_account_id,
    amount_yen,
    status,
    idempotency_key
  ) VALUES (
    p_from_account_id,
    p_to_account_id,
    p_amount_yen,
    'completed',
    p_idempotency_key
  );
END;
$$;

COMMENT ON PROCEDURE lab.sp_apply_transfer (INTEGER, INTEGER, BIGINT, TEXT) IS 'lab.account間で送金し、lab.transferに履歴を記録するプロシージャ（JPY限定）';

-- =========
-- 2) 注文確定プロシージャ
--    - draft注文を paid に変更
--    - 明細が1件以上あることをチェック
-- =========
CREATE OR REPLACE PROCEDURE lab.sp_finalize_simple_order (p_order_id INTEGER) LANGUAGE plpgsql AS $$
DECLARE
  v_status TEXT;
  v_line_count INTEGER;
BEGIN
  IF p_order_id IS NULL THEN
    RAISE EXCEPTION 'p_order_id は必須です';
  END IF;

  SELECT o.order_status
  INTO v_status
  FROM lab.simple_order o
  WHERE o.order_id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION '注文が存在しません（order_id=%）', p_order_id;
  END IF;

  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'draft 以外は確定できません（order_id=%、status=%）', p_order_id, v_status;
  END IF;

  SELECT COUNT(*)
  INTO v_line_count
  FROM lab.simple_order_line ol
  WHERE ol.order_id = p_order_id;

  IF v_line_count = 0 THEN
    RAISE EXCEPTION '明細が0件の注文は確定できません（order_id=%）', p_order_id;
  END IF;

  UPDATE lab.simple_order
  SET order_status = 'paid'
  WHERE order_id = p_order_id;
END;
$$;

COMMENT ON PROCEDURE lab.sp_finalize_simple_order (INTEGER) IS 'draft注文を確定（paid）するプロシージャ。明細0件はエラー';

-- 作成確認
SELECT
    routine_schema,
    routine_name,
    routine_type
FROM
    information_schema.routines
WHERE
    routine_schema = 'lab'
    AND routine_name IN ('sp_apply_transfer', 'sp_finalize_simple_order')
ORDER BY
    routine_name;
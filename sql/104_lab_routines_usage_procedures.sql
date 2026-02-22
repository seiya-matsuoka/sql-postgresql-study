-- phase: 10
-- topic: プロシージャの使い方（CALL / 例外 / トランザクション）
-- dataset: lab
-- 前提:
--   - sql/100, 102 実行済み
-- 目的:
--   - CALLで更新処理を実行する
--   - 失敗時の例外、ROLLBACK時の挙動を確認する
-- =========
-- 0) 対象データ確認（Phase10デモ口座・注文）
-- =========
SELECT
    a.account_id,
    c.email,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email IN (
        'phase10.demo@example.com',
        'phase10.system@example.com'
    )
ORDER BY
    a.account_id;

SELECT
    order_id,
    order_status
FROM
    lab.simple_order
WHERE
    order_id IN (9901, 9902)
ORDER BY
    order_id;

-- =========
-- 1) プロシージャ成功例：送金（CALL）
-- =========
CALL lab.sp_apply_transfer (
    (
        SELECT
            a.account_id
        FROM
            lab.account a
            JOIN lab.customer c ON c.customer_id = a.customer_id
        WHERE
            c.email = 'phase10.demo@example.com'
            AND a.currency = 'JPY'
        LIMIT
            1
    ),
    (
        SELECT
            a.account_id
        FROM
            lab.account a
            JOIN lab.customer c ON c.customer_id = a.customer_id
        WHERE
            c.email = 'phase10.system@example.com'
            AND a.currency = 'JPY'
        LIMIT
            1
    ),
    1200,
    'phase10-proc-success-001'
);

-- 送金後確認
SELECT
    a.account_id,
    c.email,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email IN (
        'phase10.demo@example.com',
        'phase10.system@example.com'
    )
ORDER BY
    a.account_id;

SELECT
    transfer_id,
    from_account_id,
    to_account_id,
    amount_yen,
    status,
    idempotency_key
FROM
    lab.transfer
WHERE
    idempotency_key = 'phase10-proc-success-001';

-- =========
-- 2) プロシージャ失敗例：同じidempotency_keyで再実行（UNIQUE違反）
--    DOブロックで例外を捕まえて、スクリプト継続
-- =========
DO $$
DECLARE
  v_from_account_id INTEGER;
  v_to_account_id   INTEGER;
BEGIN
  SELECT a.account_id
  INTO v_from_account_id
  FROM lab.account a
  JOIN lab.customer c ON c.customer_id = a.customer_id
  WHERE c.email = 'phase10.demo@example.com'
    AND a.currency = 'JPY'
  LIMIT 1;

  SELECT a.account_id
  INTO v_to_account_id
  FROM lab.account a
  JOIN lab.customer c ON c.customer_id = a.customer_id
  WHERE c.email = 'phase10.system@example.com'
    AND a.currency = 'JPY'
  LIMIT 1;

  BEGIN
    CALL lab.sp_apply_transfer(
      v_from_account_id,
      v_to_account_id,
      500,
      'phase10-proc-success-001' -- 既に使ったキー
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[プロシージャ例外] 想定どおり失敗: %', SQLERRM;
  END;
END $$;

-- =========
-- 3) プロシージャ失敗例：残高不足
-- =========
DO $$
DECLARE
  v_from_account_id INTEGER;
  v_to_account_id   INTEGER;
BEGIN
  SELECT a.account_id
  INTO v_from_account_id
  FROM lab.account a
  JOIN lab.customer c ON c.customer_id = a.customer_id
  WHERE c.email = 'phase10.demo@example.com'
    AND a.currency = 'JPY'
  LIMIT 1;

  SELECT a.account_id
  INTO v_to_account_id
  FROM lab.account a
  JOIN lab.customer c ON c.customer_id = a.customer_id
  WHERE c.email = 'phase10.system@example.com'
    AND a.currency = 'JPY'
  LIMIT 1;

  BEGIN
    CALL lab.sp_apply_transfer(
      v_from_account_id,
      v_to_account_id,
      999999999,
      'phase10-proc-insufficient-001'
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[プロシージャ例外] 残高不足エラー: %', SQLERRM;
  END;
END $$;

-- =========
-- 4) 呼び出し側トランザクションに乗ることを確認（CALL→ROLLBACK）
-- =========
BEGIN;

CALL lab.sp_apply_transfer (
    (
        SELECT
            a.account_id
        FROM
            lab.account a
            JOIN lab.customer c ON c.customer_id = a.customer_id
        WHERE
            c.email = 'phase10.demo@example.com'
            AND a.currency = 'JPY'
        LIMIT
            1
    ),
    (
        SELECT
            a.account_id
        FROM
            lab.account a
            JOIN lab.customer c ON c.customer_id = a.customer_id
        WHERE
            c.email = 'phase10.system@example.com'
            AND a.currency = 'JPY'
        LIMIT
            1
    ),
    700,
    'phase10-proc-rollback-001'
);

-- トランザクション中の見え方（まだ未確定）
SELECT
    'in_tx' AS scope,
    a.account_id,
    c.email,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email IN (
        'phase10.demo@example.com',
        'phase10.system@example.com'
    )
ORDER BY
    a.account_id;

ROLLBACK;

-- ROLLBACK後確認（履歴も残高も戻る）
SELECT
    'after_rollback' AS scope,
    a.account_id,
    c.email,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email IN (
        'phase10.demo@example.com',
        'phase10.system@example.com'
    )
ORDER BY
    a.account_id;

SELECT
    COUNT(*) AS rollback_transfer_count
FROM
    lab.transfer
WHERE
    idempotency_key = 'phase10-proc-rollback-001';

-- =========
-- 5) 注文確定プロシージャ（draft -> paid）
-- =========
SELECT
    order_id,
    order_status
FROM
    lab.simple_order
WHERE
    order_id = 9901;

CALL lab.sp_finalize_simple_order (9901);

SELECT
    o.order_id,
    o.order_status,
    lab.fn_simple_order_total_yen (o.order_id) AS order_total_yen
FROM
    lab.simple_order o
WHERE
    o.order_id = 9901;

-- =========
-- 6) 注文確定の失敗例：すでにpaidを再実行
-- =========
DO $$
BEGIN
  BEGIN
    CALL lab.sp_finalize_simple_order(9901);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[プロシージャ例外] 再確定は失敗: %', SQLERRM;
  END;
END $$;

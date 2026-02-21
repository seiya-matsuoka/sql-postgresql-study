-- phase: 8
-- topic: トランザクション基礎（BEGIN / COMMIT / ROLLBACK / SAVEPOINT）
-- dataset: ec-v1（labスキーマ）
-- 前提:
--   - sql/080_lab_phase8_fixture_prepare.sql 実行済み
-- 目的:
--   - 更新を「ひとかたまり」として扱う感覚を掴む
--   - SAVEPOINTで途中だけ戻す操作を体験する
-- 0) デモ状態を初期化（何度でも同じ挙動になりやすくする）
DELETE FROM lab.transfer
WHERE
    idempotency_key LIKE 'phase8-tx-%';

UPDATE lab.account a
SET
    balance_yen = CASE
        WHEN a.currency = 'JPY' THEN 20000
        WHEN a.currency = 'USD' THEN 300
        ELSE a.balance_yen
    END
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency IN ('JPY', 'USD');

-- 1) 現在の口座残高確認
SELECT
    a.account_id,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
ORDER BY
    a.account_id;

-- 2) 現在のトランザクション分離レベル（確認）
SHOW transaction_isolation;

-- 3) COMMIT例：送金を確定する
BEGIN;

-- JPY口座から1000減らす
UPDATE lab.account a
SET
    balance_yen = a.balance_yen - 1000
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';

-- USD口座に1000加える
UPDATE lab.account a
SET
    balance_yen = a.balance_yen + 1000
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'USD';

-- transfer履歴を追加
INSERT INTO
    lab.transfer (
        from_account_id,
        to_account_id,
        amount_yen,
        status,
        idempotency_key
    )
SELECT
    a_jpy.account_id,
    a_usd.account_id,
    1000,
    'completed',
    'phase8-tx-commit-001'
FROM
    lab.account a_jpy
    JOIN lab.account a_usd ON a_usd.customer_id = a_jpy.customer_id
    JOIN lab.customer c ON c.customer_id = a_jpy.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a_jpy.currency = 'JPY'
    AND a_usd.currency = 'USD';

COMMIT;

-- COMMIT後の確認（残高もtransferも反映される）
SELECT
    a.account_id,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
ORDER BY
    a.account_id;

SELECT
    transfer_id,
    idempotency_key,
    amount_yen,
    status
FROM
    lab.transfer
WHERE
    idempotency_key = 'phase8-tx-commit-001';

-- 4) ROLLBACK例：途中で取り消す（結果は残らない）
BEGIN;

UPDATE lab.account a
SET
    balance_yen = a.balance_yen - 500
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';

UPDATE lab.account a
SET
    balance_yen = a.balance_yen + 500
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'USD';

INSERT INTO
    lab.transfer (
        from_account_id,
        to_account_id,
        amount_yen,
        status,
        idempotency_key
    )
SELECT
    a_jpy.account_id,
    a_usd.account_id,
    500,
    'completed',
    'phase8-tx-rollback-001'
FROM
    lab.account a_jpy
    JOIN lab.account a_usd ON a_usd.customer_id = a_jpy.customer_id
    JOIN lab.customer c ON c.customer_id = a_jpy.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a_jpy.currency = 'JPY'
    AND a_usd.currency = 'USD';

-- トランザクション中の見え方（まだ未確定）
SELECT
    'in_tx' AS scope,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
ORDER BY
    a.currency;

ROLLBACK;

-- ROLLBACK後の確認（変更は残らない）
SELECT
    'after_rollback' AS scope,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
ORDER BY
    a.currency;

SELECT
    COUNT(*) AS rollback_transfer_count
FROM
    lab.transfer
WHERE
    idempotency_key = 'phase8-tx-rollback-001';

-- 5) SAVEPOINT例：途中の処理だけ戻す
BEGIN;

-- まず「受付」だけ作る（これは残したい）
INSERT INTO
    lab.transfer (
        from_account_id,
        to_account_id,
        amount_yen,
        status,
        idempotency_key
    )
SELECT
    a_jpy.account_id,
    a_usd.account_id,
    700,
    'requested',
    'phase8-tx-savepoint-001'
FROM
    lab.account a_jpy
    JOIN lab.account a_usd ON a_usd.customer_id = a_jpy.customer_id
    JOIN lab.customer c ON c.customer_id = a_jpy.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a_jpy.currency = 'JPY'
    AND a_usd.currency = 'USD';

SAVEPOINT sp_apply_transfer;

-- この先の残高更新は「やっぱり取り消す」想定
UPDATE lab.account a
SET
    balance_yen = a.balance_yen - 700
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';

UPDATE lab.account a
SET
    balance_yen = a.balance_yen + 700
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'USD';

-- トランザクション中の確認（更新後の一時状態）
SELECT
    'before_rollback_to_savepoint' AS scope,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
ORDER BY
    a.currency;

-- 途中だけ戻す
ROLLBACK TO SAVEPOINT sp_apply_transfer;

-- transfer受付は残しつつ、残高更新は取り消された状態で status を cancelled にする
UPDATE lab.transfer
SET
    status = 'cancelled'
WHERE
    idempotency_key = 'phase8-tx-savepoint-001';

COMMIT;

-- SAVEPOINT例の最終確認
SELECT
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
ORDER BY
    a.currency;

SELECT
    transfer_id,
    idempotency_key,
    amount_yen,
    status
FROM
    lab.transfer
WHERE
    idempotency_key = 'phase8-tx-savepoint-001';

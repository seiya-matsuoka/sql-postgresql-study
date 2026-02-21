-- phase: 8
-- topic: ロック体験（セッションB）
-- dataset: ec-v1（labスキーマ）
-- 使い方:
--   - セッションA（sql/084）が pg_sleep 中に実行する
--   - UPDATE がロック待ちでブロックされるのを観察する
--   - 最後に ROLLBACK して変更は残さない

\timing on

-- 0) 事前確認
SELECT
    a.account_id,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';

BEGIN;

-- 1) 同じ行を更新しようとする（セッションAがロック中なら待たされる）
UPDATE lab.account a
SET
    balance_yen = a.balance_yen + 123
FROM
    lab.customer c
WHERE
    c.customer_id = a.customer_id
    AND c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';

-- 2) 更新後の見え方（ただしこの後ROLLBACK）
SELECT
    a.account_id,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';

ROLLBACK;

-- 3) 最終確認（元に戻っている）
SELECT
    a.account_id,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY';
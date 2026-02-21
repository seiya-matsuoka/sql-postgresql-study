-- phase: 8
-- topic: ロック体験（セッションA）
-- dataset: ec-v1（labスキーマ）
-- 使い方:
--   - このSQLをセッションAで先に実行
--   - SELECT ... FOR UPDATE で行ロックを取得
--   - pg_sleep(20) でロック保持
--   - その間にセッションB（sql/085）を実行して待ちを観察する

\timing on

-- 0) 対象口座を確認
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

-- 1) 行ロック取得（値は変えない）
SELECT
    a.account_id,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a.currency = 'JPY'
FOR UPDATE;

-- 2) ロックを保持したまま待機（この間にセッションBを実行）
SELECT
    'session A sleeping (20s) with row lock' AS msg;

SELECT
    pg_sleep(20);

COMMIT;

SELECT
    'session A committed' AS msg;

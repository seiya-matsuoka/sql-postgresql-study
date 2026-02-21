-- phase: 8
-- topic: DML基本（INSERT / UPDATE / DELETE）
-- dataset: ec-v1（labスキーマ）
-- 前提:
--   - sql/080_lab_phase8_fixture_prepare.sql 実行済み
-- 目的:
--   - 基本DMLと、少し実務寄りの書き方（INSERT ... SELECT / UPDATE ... FROM / DELETE ... USING）を体験する
--   - PostgreSQL寄りの書き方には、標準寄りの代替も併記する
-- 0) 現在のデモ状態（確認）
SELECT
    c.customer_id,
    c.email,
    c.full_name,
    c.status
FROM
    lab.customer c
WHERE
    c.email = 'phase8.demo@example.com';

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

-- 1) INSERT（単発）：デモtransferを1件追加
-- idempotency_keyは一意制約があるので、毎回違う値にするか、事前に削除しておく
DELETE FROM lab.transfer
WHERE
    idempotency_key = 'phase8-insert-001';

INSERT INTO
    lab.transfer (
        from_account_id,
        to_account_id,
        amount_yen,
        status,
        idempotency_key,
        requested_at
    )
SELECT
    a_jpy.account_id AS from_account_id,
    a_usd.account_id AS to_account_id,
    1000 AS amount_yen,
    'requested' AS status,
    'phase8-insert-001' AS idempotency_key,
    CURRENT_TIMESTAMP
FROM
    lab.account a_jpy
    JOIN lab.account a_usd ON a_usd.customer_id = a_jpy.customer_id
    JOIN lab.customer c ON c.customer_id = a_jpy.customer_id
WHERE
    c.email = 'phase8.demo@example.com'
    AND a_jpy.currency = 'JPY'
    AND a_usd.currency = 'USD';

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
    idempotency_key = 'phase8-insert-001';

-- 2) INSERT ... SELECT：既存注文（9801）を元に明細を複製して別注文へコピー
-- まずコピー先注文を作る（9803）
DELETE FROM lab.simple_order
WHERE
    order_id = 9803;

INSERT INTO
    lab.simple_order (order_id, customer_id, order_status, ordered_at)
SELECT
    9803,
    o.customer_id,
    'draft',
    CURRENT_TIMESTAMP
FROM
    lab.simple_order o
WHERE
    o.order_id = 9801;

-- 明細をコピー（line_no / item / qty / price をそのまま）
INSERT INTO
    lab.simple_order_line (
        order_id,
        line_no,
        item_name,
        quantity,
        unit_price_yen
    )
SELECT
    9803 AS order_id,
    ol.line_no,
    ol.item_name || ' (copied)' AS item_name,
    ol.quantity,
    ol.unit_price_yen
FROM
    lab.simple_order_line ol
WHERE
    ol.order_id = 9801;

SELECT
    *
FROM
    lab.simple_order_line
WHERE
    order_id IN (9801, 9803)
ORDER BY
    order_id,
    line_no;

-- 3) UPDATE（基本）：draft注文をpaidに変更
UPDATE lab.simple_order
SET
    order_status = 'paid'
WHERE
    order_id = 9803;

SELECT
    order_id,
    order_status
FROM
    lab.simple_order
WHERE
    order_id = 9803;

-- 4) UPDATE ... FROM（PostgreSQLでよく使う）
-- 例：注文の合計金額を計算して、注文ステータスを条件付きで更新する（デモ）
-- 今回は “明細合計 >= 1000 なら shipped にする” というルールで更新
WITH
    order_sums AS (
        SELECT
            ol.order_id,
            SUM(ol.quantity * ol.unit_price_yen) AS order_total_yen
        FROM
            lab.simple_order_line ol
        GROUP BY
            ol.order_id
    )
UPDATE lab.simple_order o
SET
    order_status = CASE
        WHEN s.order_total_yen >= 1000 THEN 'shipped'
        ELSE o.order_status
    END
FROM
    order_sums s
WHERE
    o.order_id = s.order_id
    AND o.order_id = 9803;

SELECT
    o.order_id,
    o.order_status
FROM
    lab.simple_order o
WHERE
    o.order_id = 9803;

-- 標準寄りの代替（相関サブクエリで書くイメージ）：
-- UPDATE lab.simple_order o
-- SET order_status = CASE
--   WHEN (
--     SELECT SUM(ol.quantity * ol.unit_price_yen)
--     FROM lab.simple_order_line ol
--     WHERE ol.order_id = o.order_id
--   ) >= 1000 THEN 'shipped'
--   ELSE o.order_status
-- END
-- WHERE o.order_id = 9803;
-- 5) DELETE ... USING（PostgreSQLでよく使う）
-- 例：draft注文の明細を、親注文条件を使って削除する
-- まずデモ用に9801をdraftに戻す（明細削除を観察しやすくする）
UPDATE lab.simple_order
SET
    order_status = 'draft'
WHERE
    order_id = 9801;

SELECT
    order_id,
    line_no,
    item_name
FROM
    lab.simple_order_line
WHERE
    order_id = 9801
ORDER BY
    line_no;

DELETE FROM lab.simple_order_line ol USING lab.simple_order o
WHERE
    o.order_id = ol.order_id
    AND o.order_status = 'draft'
    AND o.order_id = 9801;

SELECT
    order_id,
    line_no,
    item_name
FROM
    lab.simple_order_line
WHERE
    order_id = 9801
ORDER BY
    line_no;

-- 標準寄りの代替（EXISTS）：
-- DELETE FROM lab.simple_order_line ol
-- WHERE EXISTS (
--   SELECT 1
--   FROM lab.simple_order o
--   WHERE o.order_id = ol.order_id
--     AND o.order_status = 'draft'
--     AND o.order_id = 9801
-- );
-- 6) DELETE（基本）：不要になったコピー注文 9803 を削除（lineはON DELETE CASCADE）
DELETE FROM lab.simple_order
WHERE
    order_id = 9803;

SELECT
    order_id,
    order_status
FROM
    lab.simple_order
WHERE
    order_id BETWEEN 9800 AND 9899
ORDER BY
    order_id;

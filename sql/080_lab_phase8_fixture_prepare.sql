-- phase: 8
-- topic: Phase 8用のデモデータ準備（何度でも再実行OK）
-- dataset: ec-v1（labスキーマ）
-- 目的:
--   - DML/トランザクション学習用の固定データをlab内に用意する
--   - 再実行時に同じ状態に戻せるようにする
-- 0) まず、Phase 8用のデモデータを掃除（存在すれば削除）
-- transfer は idempotency_key で消す
DELETE FROM lab.transfer
WHERE
    idempotency_key LIKE 'phase8-%';

-- simple_order は高いID帯をPhase 8専用として使う（lineはON DELETE CASCADEで消える）
DELETE FROM lab.simple_order
WHERE
    order_id BETWEEN 9800 AND 9899;

-- account / customer はデモ顧客email経由で掃除
DELETE FROM lab.account
WHERE
    customer_id IN (
        SELECT
            customer_id
        FROM
            lab.customer
        WHERE
            email = 'phase8.demo@example.com'
    );

DELETE FROM lab.customer
WHERE
    email = 'phase8.demo@example.com';

-- 1) デモ顧客を作成
INSERT INTO
    lab.customer (email, full_name, status)
VALUES
    (
        'phase8.demo@example.com',
        'Phase8 Demo User',
        'active'
    );

-- 2) デモ口座を作成（JPY / USD）
INSERT INTO
    lab.account (customer_id, currency, balance_yen)
SELECT
    c.customer_id,
    'JPY',
    20000
FROM
    lab.customer c
WHERE
    c.email = 'phase8.demo@example.com';

INSERT INTO
    lab.account (customer_id, currency, balance_yen)
SELECT
    c.customer_id,
    'USD',
    300
FROM
    lab.customer c
WHERE
    c.email = 'phase8.demo@example.com';

-- 3) DML練習用の注文データ（固定ID帯）
INSERT INTO
    lab.simple_order (order_id, customer_id, order_status, ordered_at)
SELECT
    9801,
    c.customer_id,
    'draft',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
FROM
    lab.customer c
WHERE
    c.email = 'phase8.demo@example.com';

INSERT INTO
    lab.simple_order (order_id, customer_id, order_status, ordered_at)
SELECT
    9802,
    c.customer_id,
    'paid',
    CURRENT_TIMESTAMP - INTERVAL '12 hour'
FROM
    lab.customer c
WHERE
    c.email = 'phase8.demo@example.com';

INSERT INTO
    lab.simple_order_line (
        order_id,
        line_no,
        item_name,
        quantity,
        unit_price_yen
    )
VALUES
    (9801, 1, 'Phase8 Notebook', 1, 500),
    (9801, 2, 'Phase8 Pen', 2, 120),
    (9802, 1, 'Phase8 Cable', 1, 1500);

-- 4) 確認表示
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
    a.customer_id,
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
    o.order_id,
    o.order_status,
    o.ordered_at
FROM
    lab.simple_order o
WHERE
    o.order_id BETWEEN 9800 AND 9899
ORDER BY
    o.order_id;

SELECT
    ol.order_id,
    ol.line_no,
    ol.item_name,
    ol.quantity,
    ol.unit_price_yen
FROM
    lab.simple_order_line ol
WHERE
    ol.order_id BETWEEN 9800 AND 9899
ORDER BY
    ol.order_id,
    ol.line_no;

-- phase: 7
-- topic: labの正しいデータ投入（制約が通る例）
-- dataset: ec-v1（labスキーマ）
-- =========
-- customer
-- =========
INSERT INTO
    lab.customer (customer_id, email, full_name, status, created_at)
VALUES
    (
        1,
        'alice@example.com',
        'Alice',
        'active',
        CURRENT_TIMESTAMP - INTERVAL '10 day'
    ),
    (
        2,
        'bob@example.com',
        'Bob',
        'active',
        CURRENT_TIMESTAMP - INTERVAL '8 day'
    ),
    (
        3,
        'carol@example.com',
        'Carol',
        'active',
        CURRENT_TIMESTAMP - INTERVAL '6 day'
    ),
    (
        4,
        'dave@example.com',
        'Dave',
        'suspended',
        CURRENT_TIMESTAMP - INTERVAL '3 day'
    );

SELECT
    setval(
        pg_get_serial_sequence('lab.customer', 'customer_id'),
        (
            SELECT
                MAX(customer_id)
            FROM
                lab.customer
        )
    );

-- =========
-- account
-- =========
INSERT INTO
    lab.account (
        account_id,
        customer_id,
        currency,
        balance_yen,
        opened_at
    )
VALUES
    (
        1,
        1,
        'JPY',
        100000,
        CURRENT_TIMESTAMP - INTERVAL '9 day'
    ),
    (
        2,
        2,
        'JPY',
        50000,
        CURRENT_TIMESTAMP - INTERVAL '7 day'
    ),
    (
        3,
        3,
        'JPY',
        0,
        CURRENT_TIMESTAMP - INTERVAL '5 day'
    ),
    (
        4,
        1,
        'USD',
        1000,
        CURRENT_TIMESTAMP - INTERVAL '4 day'
    );

SELECT
    setval(
        pg_get_serial_sequence('lab.account', 'account_id'),
        (
            SELECT
                MAX(account_id)
            FROM
                lab.account
        )
    );

-- =========
-- transfer
-- =========
INSERT INTO
    lab.transfer (
        transfer_id,
        from_account_id,
        to_account_id,
        amount_yen,
        status,
        idempotency_key,
        requested_at
    )
VALUES
    (
        1,
        1,
        2,
        10000,
        'completed',
        'tr-0001',
        CURRENT_TIMESTAMP - INTERVAL '2 day'
    ),
    (
        2,
        2,
        1,
        5000,
        'requested',
        'tr-0002',
        CURRENT_TIMESTAMP - INTERVAL '1 day'
    ),
    (
        3,
        1,
        3,
        2000,
        'cancelled',
        'tr-0003',
        CURRENT_TIMESTAMP - INTERVAL '12 hour'
    );

SELECT
    setval(
        pg_get_serial_sequence('lab.transfer', 'transfer_id'),
        (
            SELECT
                MAX(transfer_id)
            FROM
                lab.transfer
        )
    );

-- =========
-- simple_order / line
-- =========
INSERT INTO
    lab.simple_order (order_id, customer_id, order_status, ordered_at)
VALUES
    (
        1,
        1,
        'paid',
        CURRENT_TIMESTAMP - INTERVAL '3 day'
    ),
    (
        2,
        1,
        'shipped',
        CURRENT_TIMESTAMP - INTERVAL '2 day'
    ),
    (
        3,
        2,
        'draft',
        CURRENT_TIMESTAMP - INTERVAL '1 day'
    ),
    (
        4,
        3,
        'delivered',
        CURRENT_TIMESTAMP - INTERVAL '5 day'
    );

SELECT
    setval(
        pg_get_serial_sequence('lab.simple_order', 'order_id'),
        (
            SELECT
                MAX(order_id)
            FROM
                lab.simple_order
        )
    );

INSERT INTO
    lab.simple_order_line (
        order_id,
        line_no,
        item_name,
        quantity,
        unit_price_yen
    )
VALUES
    (1, 1, 'Notebook', 2, 300),
    (1, 2, 'Pen', 1, 100),
    (2, 1, 'Cable', 1, 1200),
    (4, 1, 'Snack', 5, 200);

-- 簡易確認
SELECT
    COUNT(*) AS customer_count
FROM
    lab.customer;

SELECT
    COUNT(*) AS account_count
FROM
    lab.account;

SELECT
    COUNT(*) AS transfer_count
FROM
    lab.transfer;

SELECT
    COUNT(*) AS order_count
FROM
    lab.simple_order;

SELECT
    COUNT(*) AS order_line_count
FROM
    lab.simple_order_line;

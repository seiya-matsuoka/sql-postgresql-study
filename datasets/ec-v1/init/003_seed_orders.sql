-- purpose: seed (transaction-like data) for ec-v1
-- volumes (approx):
--   customer_order:  4000
--   order_item:      ~12000 (avg 3 lines/order)
--   payment:         ~80% of non-draft orders
--   shipment:        shipped/delivered + part of paid
-- random reproducibility hint (session-scoped):
SELECT
    setseed(0.42);

-- ======
-- customer_order (4000)
-- ======
INSERT INTO
    customer_order (id, user_id, order_status, ordered_at, created_at)
SELECT
    gs AS id,
    ((gs * 37) % 200) + 1 AS user_id,
    CASE
        WHEN (gs % 20) IN (0, 1) THEN 'draft' -- 10%
        WHEN (gs % 20) = 2 THEN 'cancelled' -- 5%
        WHEN (gs % 20) IN (3, 4, 5, 6) THEN 'paid' -- 20%
        WHEN (gs % 20) IN (7, 8, 9, 10, 11, 12) THEN 'shipped' -- 30%
        ELSE 'delivered' -- 35%
    END AS order_status,
    (
        CURRENT_TIMESTAMP - (gs % 180) * INTERVAL '1 day' - ((gs * 97) % 86400) * INTERVAL '1 second'
    ) AS ordered_at,
    CURRENT_TIMESTAMP AS created_at
FROM
    generate_series(1, 4000) gs;

SELECT
    setval(
        pg_get_serial_sequence('customer_order', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                customer_order
        )
    );

-- ======
-- order_item (1..4 lines per order; deterministic mapping)
-- ======
INSERT INTO
    order_item (
        order_id,
        line_no,
        product_id,
        quantity,
        unit_price_yen,
        created_at
    )
SELECT
    o.id AS order_id,
    ln AS line_no,
    pid AS product_id,
    qty AS quantity,
    p.price_yen AS unit_price_yen,
    o.ordered_at AS created_at
FROM
    customer_order o
    JOIN generate_series(1, 4) ln ON ln <= ((o.id % 4) + 1)
    CROSS JOIN LATERAL (
        SELECT
            ((o.id * 13 + ln * 7) % 500) + 1 AS pid,
            ((o.id + ln) % 5) + 1 AS qty
    ) v
    JOIN product p ON p.id = v.pid;

-- ======
-- payment (about 80% of non-draft orders)
-- ======
WITH
    order_sum AS (
        SELECT
            oi.order_id,
            SUM(oi.quantity * oi.unit_price_yen) AS items_total_yen
        FROM
            order_item oi
        GROUP BY
            oi.order_id
    )
INSERT INTO
    payment (
        id,
        order_id,
        method,
        amount_yen,
        status,
        paid_at,
        created_at
    )
SELECT
    o.id AS id,
    o.id AS order_id,
    CASE (o.id % 4)
        WHEN 0 THEN 'card'
        WHEN 1 THEN 'bank_transfer'
        WHEN 2 THEN 'cash_on_delivery'
        ELSE 'wallet'
    END AS method,
    s.items_total_yen AS amount_yen,
    CASE
        WHEN o.order_status = 'cancelled' THEN 'refunded'
        WHEN o.order_status IN ('paid', 'shipped', 'delivered') THEN 'paid'
        ELSE 'pending'
    END AS status,
    CASE
        WHEN o.order_status IN ('paid', 'shipped', 'delivered') THEN o.ordered_at + INTERVAL '1 hour'
        WHEN o.order_status = 'cancelled' THEN o.ordered_at + INTERVAL '2 hour'
        ELSE NULL
    END AS paid_at,
    CURRENT_TIMESTAMP AS created_at
FROM
    customer_order o
    JOIN order_sum s ON s.order_id = o.id
WHERE
    o.order_status <> 'draft'
    AND (o.id % 5) <> 0;

-- 80%程度
SELECT
    setval(
        pg_get_serial_sequence('payment', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                payment
        )
    );

-- ======
-- shipment
-- - shipped/delivered は基本配送あり
-- - paid の一部も pending として配送テーブルを作っておく（学習用）
-- ======
INSERT INTO
    shipment (
        id,
        order_id,
        carrier,
        tracking_no,
        status,
        shipped_at,
        delivered_at,
        created_at
    )
SELECT
    o.id AS id,
    o.id AS order_id,
    CASE (o.id % 3)
        WHEN 0 THEN 'Sagawa'
        WHEN 1 THEN 'Yamato'
        ELSE 'JapanPost'
    END AS carrier,
    'TRK' || lpad(CAST(o.id AS TEXT), 10, '0') AS tracking_no,
    CASE
        WHEN o.order_status = 'delivered' THEN 'delivered'
        WHEN o.order_status = 'shipped' THEN 'shipped'
        WHEN o.order_status = 'paid'
        AND (o.id % 2) = 0 THEN 'pending'
        ELSE NULL
    END AS status,
    CASE
        WHEN o.order_status IN ('shipped', 'delivered') THEN o.ordered_at + ((o.id % 5) + 1) * INTERVAL '1 day'
        ELSE NULL
    END AS shipped_at,
    CASE
        WHEN o.order_status = 'delivered' THEN (
            o.ordered_at + ((o.id % 5) + 1) * INTERVAL '1 day'
        ) + ((o.id % 4) + 1) * INTERVAL '1 day'
        ELSE NULL
    END AS delivered_at,
    CURRENT_TIMESTAMP AS created_at
FROM
    customer_order o
WHERE
    o.order_status IN ('shipped', 'delivered')
    OR (
        o.order_status = 'paid'
        AND (o.id % 2) = 0
    );

-- status が NULL の行は入れない（念のため）
DELETE FROM shipment
WHERE
    status IS NULL;

SELECT
    setval(
        pg_get_serial_sequence('shipment', 'id'),
        (
            SELECT
                MAX(id)
            FROM
                shipment
        )
    );

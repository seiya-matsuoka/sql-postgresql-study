BEGIN;

INSERT INTO
    app_user (email, display_name)
VALUES
    ('a@example.com', 'Aki'),
    ('b@example.com', 'Beni'),
    ('c@example.com', 'Chika');

INSERT INTO
    product (sku, name, category, price_yen)
VALUES
    ('SKU-001', 'Keyboard', 'pc', 4980),
    ('SKU-002', 'Mouse', 'pc', 2980),
    ('SKU-003', 'Coffee', 'food', 800),
    ('SKU-004', 'Notebook', 'stationery', 350);

INSERT INTO
    customer_order (user_id, order_status, ordered_at, total_yen)
VALUES
    (1, 'paid', now () - interval '10 days', 7960),
    (1, 'delivered', now () - interval '3 days', 800);

INSERT INTO
    order_item (
        order_id,
        line_no,
        product_id,
        quantity,
        unit_price_yen
    )
VALUES
    (1, 1, 1, 1, 4980),
    (1, 2, 2, 1, 2980),
    (2, 1, 3, 1, 800);

COMMIT;

-- phase: 10
-- topic: Phase 10用のデモデータ準備（関数/プロシージャ用）
-- dataset: lab + view_lab（参照）
-- 目的:
--   - Phase 10の実行例で使う固定データを用意する
--   - 再実行しても同じ状態に戻しやすくする
-- =========
-- 0) Phase 10デモ用データの掃除（再実行対応）
-- =========
-- transfer（プロシージャ実行で作る履歴）
DELETE FROM lab.transfer
WHERE
    idempotency_key LIKE 'phase10-%';

-- 注文（高いID帯をPhase 10専用に使う）
DELETE FROM lab.simple_order
WHERE
    order_id BETWEEN 9900 AND 9999;

-- simple_order_line は ON DELETE CASCADE で消える
-- 顧客/口座（phase10専用email）
DELETE FROM lab.account
WHERE
    customer_id IN (
        SELECT
            customer_id
        FROM
            lab.customer
        WHERE
            email IN (
                'phase10.demo@example.com',
                'phase10.system@example.com'
            )
    );

DELETE FROM lab.customer
WHERE
    email IN (
        'phase10.demo@example.com',
        'phase10.system@example.com'
    );

-- =========
-- 1) 顧客作成（送金元ユーザー + システム受け口）
-- =========
INSERT INTO
    lab.customer (email, full_name, status)
VALUES
    (
        'phase10.demo@example.com',
        'Phase10 Demo User',
        'active'
    ),
    (
        'phase10.system@example.com',
        'Phase10 System Account',
        'active'
    );

-- =========
-- 2) 口座作成（両者ともJPY口座）
-- =========
INSERT INTO
    lab.account (customer_id, currency, balance_yen)
SELECT
    c.customer_id,
    'JPY',
    30000
FROM
    lab.customer c
WHERE
    c.email = 'phase10.demo@example.com';

INSERT INTO
    lab.account (customer_id, currency, balance_yen)
SELECT
    c.customer_id,
    'JPY',
    0
FROM
    lab.customer c
WHERE
    c.email = 'phase10.system@example.com';

-- =========
-- 3) 注文データ作成（注文確定プロシージャ用）
-- =========
INSERT INTO
    lab.simple_order (order_id, customer_id, order_status, ordered_at)
SELECT
    9901,
    c.customer_id,
    'draft',
    CURRENT_TIMESTAMP - INTERVAL '1 hour'
FROM
    lab.customer c
WHERE
    c.email = 'phase10.demo@example.com';

INSERT INTO
    lab.simple_order (order_id, customer_id, order_status, ordered_at)
SELECT
    9902,
    c.customer_id,
    'draft',
    CURRENT_TIMESTAMP - INTERVAL '30 minute'
FROM
    lab.customer c
WHERE
    c.email = 'phase10.demo@example.com';

INSERT INTO
    lab.simple_order_line (
        order_id,
        line_no,
        item_name,
        quantity,
        unit_price_yen
    )
VALUES
    (9901, 1, 'Phase10 Book', 2, 1200),
    (9901, 2, 'Phase10 Pencil', 3, 100),
    (9902, 1, 'Phase10 Cable', 1, 1500);

-- =========
-- 4) 確認表示
-- =========
SELECT
    customer_id,
    email,
    full_name,
    status
FROM
    lab.customer
WHERE
    email IN (
        'phase10.demo@example.com',
        'phase10.system@example.com'
    )
ORDER BY
    email;

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
    customer_id,
    order_status,
    ordered_at
FROM
    lab.simple_order
WHERE
    order_id BETWEEN 9900 AND 9999
ORDER BY
    order_id;

SELECT
    order_id,
    line_no,
    item_name,
    quantity,
    unit_price_yen
FROM
    lab.simple_order_line
WHERE
    order_id BETWEEN 9900 AND 9999
ORDER BY
    order_id,
    line_no;

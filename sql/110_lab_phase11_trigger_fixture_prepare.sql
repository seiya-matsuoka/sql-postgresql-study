-- phase: 11
-- topic: トリガ学習用の専用題材テーブル作成 + seed
-- dataset: lab（trg_* テーブル）
-- 目的:
--   - トリガの学習を既存テーブルから切り離して安全に行う
--   - 何度でも再実行できるように DROP ... CASCADE で作り直す
-- =========================
-- 0) リセット（再実行対応）
-- =========================
DROP TABLE IF EXISTS lab.trg_audit_log CASCADE;

DROP TABLE IF EXISTS lab.trg_order_item CASCADE;

DROP TABLE IF EXISTS lab.trg_order CASCADE;

DROP TABLE IF EXISTS lab.trg_product CASCADE;

-- =========================
-- 1) 商品テーブル（在庫・価格）
-- =========================
CREATE TABLE lab.trg_product (
    product_id INTEGER PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    product_name TEXT NOT NULL,
    stock_qty INTEGER NOT NULL CHECK (stock_qty >= 0),
    price_yen BIGINT NOT NULL CHECK (price_yen > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE lab.trg_product IS 'Phase 11 トリガ学習用の商品テーブル（在庫あり）';

-- =========================
-- 2) 注文テーブル（ステータス変更で在庫連動）
-- =========================
CREATE TABLE lab.trg_order (
    order_id INTEGER PRIMARY KEY,
    order_status TEXT NOT NULL CHECK (order_status IN ('draft', 'paid', 'cancelled')),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE lab.trg_order IS 'Phase 11 トリガ学習用の注文テーブル';

CREATE TABLE lab.trg_order_item (
    order_id INTEGER NOT NULL REFERENCES lab.trg_order (order_id) ON DELETE CASCADE,
    line_no INTEGER NOT NULL CHECK (line_no > 0),
    product_id INTEGER NOT NULL REFERENCES lab.trg_product (product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_yen BIGINT NOT NULL CHECK (unit_price_yen > 0),
    PRIMARY KEY (order_id, line_no)
);

COMMENT ON TABLE lab.trg_order_item IS 'Phase 11 トリガ学習用の注文明細';

-- =========================
-- 3) 監査ログテーブル
-- =========================
CREATE TABLE lab.trg_audit_log (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('UPDATE', 'DELETE')),
    pk_value TEXT,
    old_row JSONB,
    new_row JSONB,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL DEFAULT CURRENT_USER
);

COMMENT ON TABLE lab.trg_audit_log IS 'Phase 11 トリガ学習用の監査ログ（UPDATE/DELETE）';

-- =========================
-- 4) seed データ投入
-- =========================
INSERT INTO
    lab.trg_product (
        product_id,
        sku,
        product_name,
        stock_qty,
        price_yen
    )
VALUES
    (1, 'P-BOOK', 'Book', 10, 1200),
    (2, 'P-PEN', 'Pen', 20, 100),
    (3, 'P-CABLE', 'Cable', 3, 1500),
    (4, 'P-MOUSE', 'Mouse', 2, 3000),
    (9, 'P-TMP', 'Temp Product (delete demo)', 1, 999);

INSERT INTO
    lab.trg_order (order_id, order_status, note)
VALUES
    (1101, 'draft', '在庫連動トリガの成功例用'),
    (1102, 'draft', '在庫不足エラー用'),
    (1103, 'draft', 'トリガ無効化/有効化デモ用');

INSERT INTO
    lab.trg_order_item (
        order_id,
        line_no,
        product_id,
        quantity,
        unit_price_yen
    )
VALUES
    (1101, 1, 1, 2, 1200), -- Book x2（在庫10 -> 8予定）
    (1101, 2, 2, 3, 100), -- Pen x3（在庫20 -> 17予定）
    (1102, 1, 3, 5, 1500), -- Cable x5（在庫3しかないので失敗デモ）
    (1103, 1, 4, 1, 3000);

-- Mouse x1（無効化デモ）
-- =========================
-- 5) 初期確認
-- =========================
SELECT
    product_id,
    sku,
    product_name,
    stock_qty,
    price_yen,
    created_at,
    updated_at
FROM
    lab.trg_product
ORDER BY
    product_id;

SELECT
    order_id,
    order_status,
    note,
    created_at,
    updated_at
FROM
    lab.trg_order
ORDER BY
    order_id;

SELECT
    order_id,
    line_no,
    product_id,
    quantity,
    unit_price_yen
FROM
    lab.trg_order_item
ORDER BY
    order_id,
    line_no;

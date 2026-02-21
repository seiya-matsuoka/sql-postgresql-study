-- phase: 7
-- topic: ALTER TABLE 練習（後から列/制約/インデックスを足す）
-- dataset: ec-v1（labスキーマ）
-- 注意:
--   - 何度もやり直す前提なので、困ったら sql/070 → 071 → 072 でリセットする
--   - 本ファイルは「成功する流れ」を中心にしている（必要なら自分で壊して試す）
-- =========
-- 0) まず現状確認
-- =========
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM
    information_schema.columns
WHERE
    table_schema = 'lab'
    AND table_name = 'customer'
ORDER BY
    ordinal_position;

-- =========
-- 1) 列追加（DEFAULT付き）
-- =========
ALTER TABLE lab.customer
ADD COLUMN phone TEXT NULL;

-- 2) 既存データを埋める（NOT NULLにする前段階）
UPDATE lab.customer
SET
    phone = CASE customer_id
        WHEN 1 THEN '090-1111-1111'
        WHEN 2 THEN '090-2222-2222'
        WHEN 3 THEN '090-3333-3333'
        WHEN 4 THEN '090-4444-4444'
        ELSE NULL
    END
WHERE
    phone IS NULL;

-- 3) CHECK制約を後から追加（簡易：数字とハイフンのみ、長さも軽く）
ALTER TABLE lab.customer
ADD CONSTRAINT chk_lab_customer_phone_format CHECK (phone ~ '^[0-9-]{10,15}$');

-- 4) NOT NULLにする（データが埋まっているので成功する）
ALTER TABLE lab.customer
ALTER COLUMN phone
SET NOT NULL;

-- =========
-- 5) transfer に “上限” のCHECKを追加（例：極端な金額を禁止）
-- =========
ALTER TABLE lab.transfer
ADD CONSTRAINT chk_lab_transfer_amount_upper CHECK (amount_yen <= 1000000);

-- =========
-- 6) インデックス追加の例（検索しそうな列：status）
-- =========
CREATE INDEX idx_lab_transfer_status ON lab.transfer (status);

-- =========
-- 7) 確認：制約が増えたことを見える化
-- =========
SELECT
    conname,
    contype,
    conrelid::regclass AS table_name
FROM
    pg_constraint
    JOIN pg_namespace ns ON ns.oid = pg_constraint.connamespace
WHERE
    ns.nspname = 'lab'
ORDER BY
    (conrelid::regclass)::text,
    contype,
    conname;

SELECT
    schemaname,
    tablename,
    indexname
FROM
    pg_indexes
WHERE
    schemaname = 'lab'
ORDER BY
    tablename,
    indexname;

-- =========
-- 8) 追加したphone列の確認
-- =========
SELECT
    customer_id,
    email,
    full_name,
    phone
FROM
    lab.customer
ORDER BY
    customer_id;

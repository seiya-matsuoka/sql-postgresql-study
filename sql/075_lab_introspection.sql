-- phase: 7
-- topic: 見える化（カラム/制約/インデックスをメタ情報から確認）
-- dataset: ec-v1（lab + 一部publicも確認）
-- =========
-- 1) lab のテーブル一覧
-- =========
SELECT
    table_schema,
    table_name
FROM
    information_schema.tables
WHERE
    table_schema = 'lab'
    AND table_type = 'BASE TABLE'
ORDER BY
    table_name;

-- =========
-- 2) lab.customer のカラム定義（nullable / default含む）
-- =========
SELECT
    ordinal_position,
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
-- 3) lab の制約一覧（pg_constraint）
-- contype: p=PK, f=FK, u=UNIQUE, c=CHECK
-- =========
SELECT
    c.conrelid::regclass AS table_name,
    c.conname,
    c.contype
FROM
    pg_constraint c
    JOIN pg_namespace ns ON ns.oid = c.connamespace
WHERE
    ns.nspname = 'lab'
ORDER BY
    (conrelid::regclass)::text,
    contype,
    conname;

-- =========
-- 4) FKの関係を見たい（どのテーブルがどこを参照しているか）
-- =========
SELECT
    c.conname AS fk_name,
    c.conrelid::regclass AS child_table,
    c.confrelid::regclass AS parent_table
FROM
    pg_constraint c
    JOIN pg_namespace ns ON ns.oid = c.connamespace
WHERE
    ns.nspname = 'lab'
    AND c.contype = 'f'
ORDER BY
    (c.conrelid::regclass)::text,
    fk_name;

-- =========
-- 5) lab のインデックス一覧（pg_indexes）
-- =========
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'lab'
ORDER BY
    tablename,
    indexname;

-- =========
-- 6) ec-v1（public）のテーブルも “読む” 練習（例：customer_order）
-- =========
SELECT
    c.conrelid::regclass AS table_name,
    c.conname,
    c.contype
FROM
    pg_constraint c
WHERE
    c.conrelid = 'public.customer_order'::regclass
ORDER BY
    contype,
    conname;

SELECT
    schemaname,
    tablename,
    indexname
FROM
    pg_indexes
WHERE
    schemaname = 'public'
    AND tablename IN ('customer_order', 'order_item')
ORDER BY
    tablename,
    indexname;

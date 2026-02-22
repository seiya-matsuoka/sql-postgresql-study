-- phase: 10
-- topic: 関数・プロシージャの見える化（information_schema / pg_proc）
-- dataset: PostgreSQLシステムカタログ
-- 目的:
--   - 作成したルーチンを一覧・定義・引数で確認する
--   - FUNCTION と PROCEDURE を見分ける
-- 1) information_schema.routines（一覧）
SELECT
    routine_schema,
    routine_name,
    routine_type,
    data_type AS return_type
FROM
    information_schema.routines
WHERE
    routine_schema = 'lab'
    AND routine_name LIKE 'fn_%'
    OR (
        routine_schema = 'lab'
        AND routine_name LIKE 'sp_%'
    )
ORDER BY
    routine_type,
    routine_name;

-- 2) information_schema.parameters（引数）
SELECT
    specific_schema,
    specific_name,
    ordinal_position,
    parameter_mode,
    parameter_name,
    data_type
FROM
    information_schema.parameters
WHERE
    specific_schema = 'lab'
    AND (
        specific_name LIKE 'fn_%'
        OR specific_name LIKE 'sp_%'
    )
ORDER BY
    specific_name,
    ordinal_position;

-- 3) pg_proc / pg_namespace（PostgreSQL）
-- prokind: f=function, p=procedure
SELECT
    n.nspname AS schema_name,
    p.proname AS routine_name,
    p.prokind,
    pg_get_function_identity_arguments(p.oid) AS identity_args,
    pg_get_function_result(p.oid) AS result_type,
    l.lanname AS language_name
FROM
    pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_language l ON l.oid = p.prolang
WHERE
    n.nspname = 'lab'
    AND (
        p.proname LIKE 'fn_%'
        OR p.proname LIKE 'sp_%'
    )
ORDER BY
    p.prokind,
    p.proname;

-- 4) 定義確認（PostgreSQL）
SELECT
    n.nspname AS schema_name,
    p.proname AS routine_name,
    p.prokind,
    pg_get_functiondef(p.oid) AS routine_definition
FROM
    pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE
    n.nspname = 'lab'
    AND (
        p.proname LIKE 'fn_%'
        OR p.proname LIKE 'sp_%'
    )
ORDER BY
    p.prokind,
    p.proname;

-- 5) 補足メモ
SELECT
    'prokind=f が関数、prokind=p がプロシージャ。pg_get_functiondef で定義を確認できる（PostgreSQL固有）' AS note;
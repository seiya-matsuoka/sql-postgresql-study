-- phase: 11
-- topic: トリガ / トリガ関数の見える化（pg_trigger / pg_proc）
-- dataset: PostgreSQLシステムカタログ
-- 目的:
--   - どのテーブルにどのトリガがあるか把握する
--   - トリガ定義や関数定義を確認する
-- 1) トリガ一覧（lab.trg_*）
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    t.tgname AS trigger_name,
    t.tgenabled AS enabled_flag,
    pg_get_triggerdef(t.oid, true) AS trigger_def
FROM
    pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'lab'
    AND c.relname LIKE 'trg_%'
    AND NOT t.tgisinternal
ORDER BY
    c.relname,
    t.tgname;

-- 2) トリガ関数一覧（fn_trg_*）
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    p.prokind,
    pg_get_function_identity_arguments(p.oid) AS identity_args,
    l.lanname AS language_name
FROM
    pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_language l ON l.oid = p.prolang
WHERE
    n.nspname = 'lab'
    AND p.proname LIKE 'fn_trg_%'
ORDER BY
    p.proname;

-- 3) トリガ関数の定義確認
SELECT
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_def
FROM
    pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE
    n.nspname = 'lab'
    AND p.proname LIKE 'fn_trg_%'
ORDER BY
    p.proname;

-- 4) 監査ログ件数（テーブル別）
SELECT
    table_name,
    operation,
    COUNT(*) AS log_count
FROM
    lab.trg_audit_log
GROUP BY
    table_name,
    operation
ORDER BY
    table_name,
    operation;

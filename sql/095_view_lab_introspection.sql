-- phase: 9
-- topic: ビュー / マテビューの見える化（メタ情報確認）
-- dataset: ec-v1 + view_lab
-- 目的:
--   - information_schema / pg_catalog から構造を確認する
--   - 「何がVIEWで何がMATERIALIZED VIEWか」を見分ける
-- 1) view_lab の VIEW 一覧（information_schema）
SELECT
    table_schema,
    table_name
FROM
    information_schema.views
WHERE
    table_schema = 'view_lab'
ORDER BY
    table_name;

-- 2) view_lab の VIEW 定義（pg_views）
SELECT
    schemaname,
    viewname,
    definition
FROM
    pg_views
WHERE
    schemaname = 'view_lab'
ORDER BY
    viewname;

-- 3) view_lab の マテビュー一覧（PostgreSQLカタログ）
SELECT
    schemaname,
    matviewname,
    hasindexes,
    ispopulated,
    definition
FROM
    pg_matviews
WHERE
    schemaname = 'view_lab'
ORDER BY
    matviewname;

-- 4) view_lab のインデックス一覧（マテビュー用インデックス含む）
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'view_lab'
ORDER BY
    tablename,
    indexname;

-- 5) pg_get_viewdef（PostgreSQL）で定義を確認
SELECT
    c.relname AS relation_name,
    c.relkind AS relation_kind, -- v=view, m=materialized view
    pg_get_viewdef(c.oid, true) AS view_definition
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'view_lab'
    AND c.relkind IN ('v', 'm')
ORDER BY
    c.relkind,
    c.relname;

-- 6) 依存の確認（簡易）
--    view_lab.v_order_totals が public.customer_order / order_item を参照していることを確認しやすくするため、
--    実際の利用例として説明用に1件だけ表示
SELECT
    'view_lab.v_order_totals を使うと public.customer_order / public.order_item のJOINを毎回書かなくてよい' AS note;
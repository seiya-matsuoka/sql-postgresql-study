-- phase: 12
-- topic: Phase 12で追加した索引の掃除（任意）
-- dataset: ec-perf-v1
-- 目的:
--   - 比較をもう一度やりたいときにベースに戻す
--   - 「索引あり/なし」を再実験しやすくする
-- 注意:
--   - 任意ファイル。残しておきたいなら実行しなくてOK
DROP INDEX IF EXISTS public.idx_customer_order_user_status_orderedat;

DROP INDEX IF EXISTS public.idx_customer_order_status_orderedat_id;

DROP INDEX IF EXISTS public.idx_order_item_order_id;

DROP INDEX IF EXISTS public.idx_order_item_product_id;

DROP INDEX IF EXISTS public.idx_customer_order_user_orderedat_id;

ANALYZE public.customer_order;

ANALYZE public.order_item;

-- 確認
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

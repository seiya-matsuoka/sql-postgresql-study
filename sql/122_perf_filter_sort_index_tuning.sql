-- phase: 12
-- topic: 単一テーブルの絞り込み + 並び替え（索引改善）
-- dataset: ec-perf-v1
-- 目的:
--   - 同じクエリを索引追加前/後で比較する
--   - 複合索引の効き方を体験する
-- 備考:
--   - まずは標準的な複合索引（比較的汎用的）を採用
--   - PostgreSQL特有の部分索引はコメントで補足
SET
    jit = off;

-- 0) 比較対象クエリ（121と同じ）
--    user_id + order_status + ordered_at の絞り込み、ordered_at DESC の並び
--    → 複合索引が効きやすい形
-- 1) 念のため、対象索引を削除（再実行対応）
DROP INDEX IF EXISTS public.idx_customer_order_user_status_orderedat;

-- 2) 追加前の実行計画
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    o.id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    public.customer_order o
WHERE
    o.user_id = 1
    AND o.order_status = 'delivered'
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '180 days'
ORDER BY
    o.ordered_at DESC
LIMIT
    50;

-- 3) 複合索引を作成（比較的汎用的な形）
CREATE INDEX idx_customer_order_user_status_orderedat ON public.customer_order (user_id, order_status, ordered_at DESC);

ANALYZE public.customer_order;

-- 4) 追加後の実行計画
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    o.id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    public.customer_order o
WHERE
    o.user_id = 1
    AND o.order_status = 'delivered'
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '180 days'
ORDER BY
    o.ordered_at DESC
LIMIT
    50;

-- 5) 実データ確認（結果は同じ）
SELECT
    o.id,
    o.user_id,
    o.order_status,
    o.ordered_at
FROM
    public.customer_order o
WHERE
    o.user_id = 1
    AND o.order_status = 'delivered'
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '180 days'
ORDER BY
    o.ordered_at DESC
LIMIT
    10;

-- 6) 補足（PostgreSQL特有の改善案）
--    部分索引（partial index）は PostgreSQL の強み。
--    例:
--    CREATE INDEX ... ON customer_order (user_id, ordered_at DESC)
--    WHERE order_status IN ('paid','shipped','delivered');
--    ただし今回はまず、DB方言に寄りすぎない複合索引で体験する。

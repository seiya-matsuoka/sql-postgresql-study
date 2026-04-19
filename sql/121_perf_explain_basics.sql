-- phase: 12
-- topic: EXPLAIN / EXPLAIN ANALYZE の基本
-- dataset: ec-perf-v1
-- 目的:
--   - 実行計画の見方に慣れる
--   - EXPLAIN（見積）と EXPLAIN ANALYZE（実測）の違いを体験する
-- 使い方:
--   - まずはノード名（Seq Scan / Sort）だけ読めればOK
--   - rows と actual time の差を観察する
SET
    jit = off;

-- 0) 対象クエリ（単純な絞り込み + 並び替え）
--    ※ user_id=1 はデータ生成時に注文が偏るようにしてある
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

-- 1) EXPLAIN（実行しない・見積）
EXPLAIN
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

-- 2) EXPLAIN ANALYZE（実際に実行）
EXPLAIN (
    ANALYZE
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

-- 3) EXPLAIN ANALYZE + BUFFERS（PostgreSQL特有）
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

-- 4) まず見るポイント（コメント）
--   - Seq Scan が出ているか（全件寄りに読んでいる）
--   - Sort が出ているか（並び替えコスト）
--   - rows 見積と actual rows の差が大きいか
--   - 次の 122 で索引を追加して、同じクエリの差を見る

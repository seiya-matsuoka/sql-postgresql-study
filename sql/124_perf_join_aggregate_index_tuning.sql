-- phase: 12
-- topic: JOIN + 集約の索引改善（同じクエリを比較）
-- dataset: ec-perf-v1
-- 目的:
--   - JOIN用/FILTER用の索引を追加して差を見る
--   - 「どの列に索引を作ると効くか」を体験する
-- 方針:
--   - customer_order: ステータス + 日付 + id
--   - order_item: JOINキー（order_id）
--   - order_item: 集約・商品軸の補助（product_id）
SET
    jit = off;

-- 0) 再実行対応（先に削除）
DROP INDEX IF EXISTS public.idx_customer_order_status_orderedat_id;

DROP INDEX IF EXISTS public.idx_order_item_order_id;

DROP INDEX IF EXISTS public.idx_order_item_product_id;

-- 1) 追加前（比較用、同じクエリ）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    oi.product_id,
    p.name AS product_name,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    public.customer_order o
    JOIN public.order_item oi ON oi.order_id = o.id
    JOIN public.product p ON p.id = oi.product_id
WHERE
    o.order_status IN ('paid', 'shipped', 'delivered')
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY
    oi.product_id,
    p.name
ORDER BY
    revenue_yen DESC,
    oi.product_id
LIMIT
    20;

-- 2) 索引作成
-- 2-1) 注文側の絞り込み用（比較的汎用的）
CREATE INDEX idx_customer_order_status_orderedat_id ON public.customer_order (order_status, ordered_at DESC, id);

-- 2-2) 明細側のJOINキー（重要）
CREATE INDEX idx_order_item_order_id ON public.order_item (order_id);

-- 2-3) 商品軸の集約補助（ケースによって効き方は変わる）
CREATE INDEX idx_order_item_product_id ON public.order_item (product_id);

ANALYZE public.customer_order;

ANALYZE public.order_item;

-- 3) 追加後（同じクエリ）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    oi.product_id,
    p.name AS product_name,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    public.customer_order o
    JOIN public.order_item oi ON oi.order_id = o.id
    JOIN public.product p ON p.id = oi.product_id
WHERE
    o.order_status IN ('paid', 'shipped', 'delivered')
    AND o.ordered_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY
    oi.product_id,
    p.name
ORDER BY
    revenue_yen DESC,
    oi.product_id
LIMIT
    20;

-- 4) 「先に絞ってからJOIN」の書き方（同じ意味、比較用）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
WITH
    filtered_orders AS (
        SELECT
            o.id
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '90 days'
    )
SELECT
    oi.product_id,
    p.name AS product_name,
    SUM(oi.quantity) AS qty_sum,
    SUM(oi.quantity * oi.unit_price_yen) AS revenue_yen
FROM
    filtered_orders fo
    JOIN public.order_item oi ON oi.order_id = fo.id
    JOIN public.product p ON p.id = oi.product_id
GROUP BY
    oi.product_id,
    p.name
ORDER BY
    revenue_yen DESC,
    oi.product_id
LIMIT
    20;

-- 5) 補足
--   - どの索引が効くかは、データ分布・件数・条件の選択性で変わる
--   - まずは「JOINキー」「よく絞る列」から考えるのが基本

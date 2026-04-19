-- phase: 12
-- topic: ウィンドウ関数（標準寄り） vs DISTINCT ON（PostgreSQL特有）
-- dataset: ec-perf-v1
-- 目的:
--   - 「ユーザーごとの最新注文」を2パターンで比較する
--   - 標準寄り（ROW_NUMBER）と PostgreSQL特有（DISTINCT ON）の違いを体験する
--   - 複合索引が効く例を体験する
SET
    jit = off;

-- 0) 比較用索引（再実行対応）
DROP INDEX IF EXISTS public.idx_customer_order_user_orderedat_id;

-- 1) 索引追加（ユーザーごとの最新注文に効きやすい）
CREATE INDEX idx_customer_order_user_orderedat_id ON public.customer_order (user_id, ordered_at DESC, id DESC);

ANALYZE public.customer_order;

-- 2) 標準寄り: ROW_NUMBER() で最新注文1件/ユーザー
EXPLAIN (
    ANALYZE,
    BUFFERS
)
WITH
    ranked AS (
        SELECT
            o.id,
            o.user_id,
            o.order_status,
            o.ordered_at,
            ROW_NUMBER() OVER (
                PARTITION BY
                    o.user_id
                ORDER BY
                    o.ordered_at DESC,
                    o.id DESC
            ) AS rn
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
    )
SELECT
    r.user_id,
    r.id AS latest_order_id,
    r.order_status,
    r.ordered_at
FROM
    ranked r
WHERE
    r.rn = 1
ORDER BY
    r.user_id
LIMIT
    200;

-- 3) PostgreSQL特有: DISTINCT ON で最新注文1件/ユーザー
--    ※ DISTINCT ON は PostgreSQL方言。標準SQLでは 2) のウィンドウ関数を使う。
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    x.user_id,
    x.id AS latest_order_id,
    x.order_status,
    x.ordered_at
FROM
    (
        SELECT DISTINCT
            ON (o.user_id) o.user_id,
            o.id,
            o.order_status,
            o.ordered_at
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        ORDER BY
            o.user_id,
            o.ordered_at DESC,
            o.id DESC
    ) x
ORDER BY
    x.user_id
LIMIT
    200;

-- 4) 結果比較（先頭20件だけ目視用）
WITH
    ranked AS (
        SELECT
            o.id,
            o.user_id,
            o.order_status,
            o.ordered_at,
            ROW_NUMBER() OVER (
                PARTITION BY
                    o.user_id
                ORDER BY
                    o.ordered_at DESC,
                    o.id DESC
            ) AS rn
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
    ),
    win_res AS (
        SELECT
            r.user_id,
            r.id AS latest_order_id
        FROM
            ranked r
        WHERE
            r.rn = 1
    ),
    pg_res AS (
        SELECT DISTINCT
            ON (o.user_id) o.user_id,
            o.id AS latest_order_id
        FROM
            public.customer_order o
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
        ORDER BY
            o.user_id,
            o.ordered_at DESC,
            o.id DESC
    )
SELECT
    w.user_id,
    w.latest_order_id AS window_latest_order_id,
    p.latest_order_id AS distinct_on_latest_order_id
FROM
    win_res w
    JOIN pg_res p ON p.user_id = w.user_id
ORDER BY
    w.user_id
LIMIT
    20;

-- 5) 補足
--   - 標準SQLとして覚える本線は ROW_NUMBER()
--   - PostgreSQL実務では DISTINCT ON が非常に便利な場面がある

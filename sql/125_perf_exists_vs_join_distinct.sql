-- phase: 12
-- topic: EXISTS と JOIN DISTINCT の比較（性能 + 意味）
-- dataset: ec-perf-v1
-- 目的:
--   - 「存在チェック」は EXISTS が素直なことを体験する
--   - JOIN DISTINCT は重複を作ってから消す形になりやすい
-- 題材:
--   - 直近30日で electronics 商品を1回以上買ったユーザー数
SET
    jit = off;

-- 0) 比較A: JOIN + DISTINCT
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    COUNT(*) AS user_count
FROM
    (
        SELECT DISTINCT
            o.user_id
        FROM
            public.customer_order o
            JOIN public.order_item oi ON oi.order_id = o.id
            JOIN public.product p ON p.id = oi.product_id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '30 days'
            AND p.category = 'electronics'
    ) t;

-- 1) 比較B: EXISTS（存在チェックの意図に近い）
EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    COUNT(*) AS user_count
FROM
    public.app_user u
WHERE
    EXISTS (
        SELECT
            1
        FROM
            public.customer_order o
            JOIN public.order_item oi ON oi.order_id = o.id
            JOIN public.product p ON p.id = oi.product_id
        WHERE
            o.user_id = u.id
            AND o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '30 days'
            AND p.category = 'electronics'
    );

-- 2) 結果確認（件数は同じになる想定）
SELECT
    'join_distinct' AS pattern,
    COUNT(*) AS user_count
FROM
    (
        SELECT DISTINCT
            o.user_id
        FROM
            public.customer_order o
            JOIN public.order_item oi ON oi.order_id = o.id
            JOIN public.product p ON p.id = oi.product_id
        WHERE
            o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '30 days'
            AND p.category = 'electronics'
    ) t
UNION ALL
SELECT
    'exists' AS pattern,
    COUNT(*) AS user_count
FROM
    public.app_user u
WHERE
    EXISTS (
        SELECT
            1
        FROM
            public.customer_order o
            JOIN public.order_item oi ON oi.order_id = o.id
            JOIN public.product p ON p.id = oi.product_id
        WHERE
            o.user_id = u.id
            AND o.order_status IN ('paid', 'shipped', 'delivered')
            AND o.ordered_at >= CURRENT_DATE - INTERVAL '30 days'
            AND p.category = 'electronics'
    );

-- 3) 補足
--   - JOIN DISTINCT が悪い、ではなく「目的が存在確認なら EXISTS が自然」
--   - 実行計画では Semi Join 相当の形になることがある（PostgreSQLが最適化）

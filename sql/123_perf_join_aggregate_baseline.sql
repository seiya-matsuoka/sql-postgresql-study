-- phase: 12
-- topic: JOIN + 集約のベースライン（索引追加前）
-- dataset: ec-perf-v1
-- 目的:
--   - 性能学習で重要な「JOIN + GROUP BY + ORDER BY」の重さを体験する
--   - 次ファイル（124）で同じクエリに索引を足して比較する
SET
    jit = off;

-- 0) 比較対象クエリ（直近90日の商品売上ランキング）
--    よくある実務レポート系
--    - 注文を期間・ステータスで絞る
--    - 明細とJOIN
--    - 商品名とJOIN
--    - GROUP BYして売上順
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

-- 1) 実結果（上位20）
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

-- 2) 観察ポイント
--   - customer_order の絞り込みがどう読まれているか（Seq Scanか）
--   - order_item へのJOINがどう読まれているか
--   - Hash Join / HashAggregate / Sort のどこが重いか
--   - 次の124で索引を足して、同じクエリで比較する

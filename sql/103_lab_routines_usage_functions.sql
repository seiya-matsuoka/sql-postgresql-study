-- phase: 10
-- topic: 関数の使い方（SELECTで呼ぶ）
-- dataset: lab + view_lab + ec-v1
-- 前提:
--   - sql/100, 101 実行済み
-- 目的:
--   - スカラー関数 / テーブル関数を実際にSELECTで使う
--   - VIEWの部品化として関数が使える感覚を掴む
-- 0) Phase 10用注文の確認
SELECT
    order_id,
    order_status
FROM
    lab.simple_order
WHERE
    order_id BETWEEN 9900 AND 9999
ORDER BY
    order_id;

-- 1) スカラー関数：注文合計
SELECT
    o.order_id,
    o.order_status,
    lab.fn_simple_order_total_yen (o.order_id) AS order_total_yen
FROM
    lab.simple_order o
WHERE
    o.order_id IN (9901, 9902)
ORDER BY
    o.order_id;

-- 2) テーブル関数（SQL）：ec-v1日別売上を期間指定で取得
--    まず利用可能な日付範囲を軽く確認
SELECT
    MIN(sales_date) AS min_date,
    MAX(sales_date) AS max_date
FROM
    view_lab.v_daily_revenue;

-- 直近14日を関数経由で取得（PostgreSQL）
SELECT
    *
FROM
    lab.fn_ec_daily_revenue_between (CURRENT_DATE - 14, CURRENT_DATE)
ORDER BY
    sales_date;

-- 3) テーブル関数（PL/pgSQL）：transfer履歴（現時点では少ない/0件でもOK）
SELECT
    a.account_id,
    c.email,
    a.currency,
    a.balance_yen
FROM
    lab.account a
    JOIN lab.customer c ON c.customer_id = a.customer_id
WHERE
    c.email = 'phase10.demo@example.com';

SELECT
    *
FROM
    lab.fn_lab_transfer_history (
        (
            SELECT
                a.account_id
            FROM
                lab.account a
                JOIN lab.customer c ON c.customer_id = a.customer_id
            WHERE
                c.email = 'phase10.demo@example.com'
                AND a.currency = 'JPY'
            LIMIT
                1
        ),
        10
    );

-- 4) 不正引数（関数の例外）を安全に観察する
DO $$
BEGIN
  BEGIN
    PERFORM *
    FROM lab.fn_lab_transfer_history(999999, 10);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[関数例外] 想定どおりエラー: %', SQLERRM;
  END;
END $$;

DO $$
DECLARE
  v_account_id INTEGER;
BEGIN
  SELECT a.account_id
  INTO v_account_id
  FROM lab.account a
  JOIN lab.customer c ON c.customer_id = a.customer_id
  WHERE c.email = 'phase10.demo@example.com'
    AND a.currency = 'JPY'
  LIMIT 1;

  BEGIN
    PERFORM *
    FROM lab.fn_lab_transfer_history(v_account_id, 0);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[関数例外] p_limit不正のエラー: %', SQLERRM;
  END;
END $$;

-- 5) 関数をJOINの部品として使う例（LATERAL）
SELECT
    o.order_id,
    x.order_total_yen
FROM
    lab.simple_order o
    CROSS JOIN LATERAL (
        SELECT
            lab.fn_simple_order_total_yen (o.order_id) AS order_total_yen
    ) x
WHERE
    o.order_id IN (9901, 9902)
ORDER BY
    o.order_id;
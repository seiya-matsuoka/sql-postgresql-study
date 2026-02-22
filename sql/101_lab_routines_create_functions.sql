-- phase: 10
-- topic: 参照系関数の作成（SQL関数 / PLpgSQL関数）
-- dataset: lab + view_lab + ec-v1
-- 目的:
--   - SELECTで使える関数を作る
--   - スカラー関数 / テーブル関数 を体験する
-- 備考:
--   - ここで作るのは PostgreSQL（PL/pgSQL）寄りの実装
-- 既存があれば削除（再実行しやすくする）
DROP FUNCTION IF EXISTS lab.fn_simple_order_total_yen (INTEGER);

DROP FUNCTION IF EXISTS lab.fn_ec_daily_revenue_between (DATE, DATE);

DROP FUNCTION IF EXISTS lab.fn_lab_transfer_history (INTEGER, INTEGER);

-- =========
-- 1) スカラー関数（SQL）
--    指定した simple_order の明細合計を返す
-- =========
CREATE OR REPLACE FUNCTION lab.fn_simple_order_total_yen (p_order_id INTEGER) RETURNS BIGINT LANGUAGE sql AS $$
  SELECT COALESCE(SUM(ol.quantity * ol.unit_price_yen), 0)::BIGINT
  FROM lab.simple_order_line ol
  WHERE ol.order_id = p_order_id;
$$;

COMMENT ON FUNCTION lab.fn_simple_order_total_yen (INTEGER) IS 'lab.simple_order の明細合計を返すスカラー関数';

-- =========
-- 2) テーブル関数（SQL）
--    ec-v1の日別売上（Phase 9で作ったVIEW）を期間指定で返す
-- =========
CREATE OR REPLACE FUNCTION lab.fn_ec_daily_revenue_between (p_date_from DATE, p_date_to DATE) RETURNS TABLE (
    sales_date DATE,
    order_count BIGINT,
    revenue_yen NUMERIC,
    avg_order_yen NUMERIC
) LANGUAGE sql AS $$
  SELECT
    v.sales_date,
    v.order_count::BIGINT,
    v.revenue_yen::NUMERIC,
    v.avg_order_yen::NUMERIC
  FROM view_lab.v_daily_revenue v
  WHERE v.sales_date BETWEEN p_date_from AND p_date_to
  ORDER BY v.sales_date;
$$;

COMMENT ON FUNCTION lab.fn_ec_daily_revenue_between (DATE, DATE) IS 'ec-v1の日別売上VIEWを期間指定で返すテーブル関数';

-- =========
-- 3) テーブル関数（PL/pgSQL）
--    口座のtransfer履歴（出金/入金）を見やすく返す
--    - p_limit で件数制限
--    - 不正引数は例外
-- =========
CREATE OR REPLACE FUNCTION lab.fn_lab_transfer_history (p_account_id INTEGER, p_limit INTEGER DEFAULT 20) RETURNS TABLE (
    transfer_id INTEGER,
    direction TEXT,
    counterparty_id INTEGER,
    amount_yen BIGINT,
    status TEXT,
    requested_at TIMESTAMPTZ
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_limit IS NULL OR p_limit <= 0 THEN
    RAISE EXCEPTION 'p_limit は 1以上で指定してください（p_limit=%）', p_limit;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM lab.account a
    WHERE a.account_id = p_account_id
  ) THEN
    RAISE EXCEPTION '指定account_idが存在しません（account_id=%）', p_account_id;
  END IF;

  RETURN QUERY
  SELECT
    t.transfer_id,
    CASE
      WHEN t.from_account_id = p_account_id THEN 'out'
      WHEN t.to_account_id = p_account_id THEN 'in'
      ELSE 'unknown'
    END AS direction,
    CASE
      WHEN t.from_account_id = p_account_id THEN t.to_account_id
      ELSE t.from_account_id
    END AS counterparty_id,
    t.amount_yen,
    t.status,
    t.requested_at
  FROM lab.transfer t
  WHERE t.from_account_id = p_account_id
     OR t.to_account_id = p_account_id
  ORDER BY t.requested_at DESC, t.transfer_id DESC
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION lab.fn_lab_transfer_history (INTEGER, INTEGER) IS '指定口座のtransfer履歴（入出金方向付き）を返すテーブル関数（PL/pgSQL）';

-- 作成確認
SELECT
    routine_schema,
    routine_name,
    routine_type
FROM
    information_schema.routines
WHERE
    routine_schema = 'lab'
    AND routine_name IN (
        'fn_simple_order_total_yen',
        'fn_ec_daily_revenue_between',
        'fn_lab_transfer_history'
    )
ORDER BY
    routine_name;

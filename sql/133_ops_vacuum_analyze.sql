-- phase: 13
-- topic: VACUUM / ANALYZE の体験（ops_lab の小さな表で観察）
-- dataset: ops_lab
-- 前提:
--   - sql/131 を実行済み
-- 0) 事前状態（dead tuple の観察）
SELECT
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM
    pg_stat_user_tables
WHERE
    schemaname = 'ops_lab'
ORDER BY
    relname;

-- 1) 更新・削除をたくさん発生させる（dead tuple を作る）
-- （小さい表なので大きくは増えないが、概念体験用）
DO $$
DECLARE
  i INTEGER;
BEGIN
  FOR i IN 1..200 LOOP
    UPDATE ops_lab.sample_order
    SET amount_yen = amount_yen + 1
    WHERE order_id = 2;

    INSERT INTO ops_lab.sample_order_audit (order_id, action)
    VALUES (2, 'touch');

    DELETE FROM ops_lab.sample_order_audit
    WHERE audit_id IN (
      SELECT audit_id
      FROM ops_lab.sample_order_audit
      ORDER BY audit_id
      LIMIT 1
    );
  END LOOP;
END $$;

-- 2) ANALYZE（統計更新）
ANALYZE ops_lab.sample_order;

ANALYZE ops_lab.sample_order_audit;

-- 3) VACUUM（通常）
VACUUM ops_lab.sample_order;

VACUUM ops_lab.sample_order_audit;

-- 4) 状態確認（統計が更新される）
SELECT
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM
    pg_stat_user_tables
WHERE
    schemaname = 'ops_lab'
ORDER BY
    relname;

-- 5) 参考：VACUUM (VERBOSE, ANALYZE)（情報量が多い）
-- 実行すると出力が増えるので、必要なら手で実行して見てください。
-- VACUUM (VERBOSE, ANALYZE) ops_lab.sample_order;

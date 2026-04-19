-- phase: 13
-- topic: 権限検証（SET ROLE で “できる/できない” を体験）
-- dataset: ops_lab
-- 前提:
--   - sql/131 を実行済み
-- 0) まず普通に見えること（管理ユーザー）
SELECT
    *
FROM
    ops_lab.sample_order
ORDER BY
    order_id;

-- 1) 読み取り専用ロールを仮適用して試す
SET ROLE r_ops_readonly;

-- SELECTはできる
SELECT
    *
FROM
    ops_lab.sample_order
ORDER BY
    order_id;

-- INSERTはできない（エラーになるのが正常）
DO $$
BEGIN
  BEGIN
    INSERT INTO ops_lab.sample_order (user_id, status, amount_yen) VALUES (9, 'paid', 999);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[権限制約] read-only なので INSERT は失敗: %', SQLERRM;
  END;
END $$;

RESET ROLE;

-- 2) 読み書きロールを仮適用して試す
SET ROLE r_ops_rw;

-- INSERT/UPDATE/DELETE ができる
INSERT INTO
    ops_lab.sample_order (user_id, status, amount_yen)
VALUES
    (9, 'paid', 999);

UPDATE ops_lab.sample_order
SET
    amount_yen = amount_yen + 1
WHERE
    user_id = 9;

DELETE FROM ops_lab.sample_order
WHERE
    user_id = 9;

RESET ROLE;

-- 3) 最後に状態確認（元に戻っている）
SELECT
    *
FROM
    ops_lab.sample_order
ORDER BY
    order_id;

-- 4) 権限確認（table grants）
SELECT
    table_name,
    grantee,
    privilege_type
FROM
    information_schema.role_table_grants
WHERE
    table_schema = 'ops_lab'
ORDER BY
    table_name,
    grantee,
    privilege_type;

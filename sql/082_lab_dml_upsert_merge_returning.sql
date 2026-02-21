-- phase: 8
-- topic: UPSERT / MERGE / RETURNING
-- dataset: ec-v1（labスキーマ）
-- 前提:
--   - sql/080_lab_phase8_fixture_prepare.sql 実行済み
-- 目的:
--   - PostgreSQLの ON CONFLICT（UPSERT）を体験する
--   - 標準SQL寄りの MERGE も触る
--   - RETURNING（PostgreSQL）で更新結果を受け取る便利さを知る
-- 0) 現在のデモ顧客を確認
SELECT
    customer_id,
    email,
    full_name,
    status
FROM
    lab.customer
WHERE
    email = 'phase8.demo@example.com';

-- 1) UPSERT（PostgreSQL方言）：email重複時は更新
INSERT INTO
    lab.customer (email, full_name, status)
VALUES
    (
        'phase8.demo@example.com',
        'Phase8 Demo User Updated by ON CONFLICT',
        'active'
    )
ON CONFLICT (email) DO UPDATE
SET
    full_name = EXCLUDED.full_name,
    status = EXCLUDED.status
RETURNING
    customer_id,
    email,
    full_name,
    status,
    created_at;

-- 2) MERGE（標準SQL系・PostgreSQLでも使用可）
-- 「存在すればUPDATE、なければINSERT」を標準寄りの形で表現できる
MERGE INTO lab.customer AS c USING (
    VALUES
        (
            'phase8.merge@example.com',
            'Phase8 Merge User',
            'active'
        )
) AS src (email, full_name, status) ON c.email = src.email WHEN MATCHED THEN
UPDATE
SET
    full_name = src.full_name,
    status = src.status WHEN NOT MATCHED THEN INSERT (email, full_name, status)
VALUES
    (src.email, src.full_name, src.status);

SELECT
    customer_id,
    email,
    full_name,
    status
FROM
    lab.customer
WHERE
    email IN (
        'phase8.demo@example.com',
        'phase8.merge@example.com'
    )
ORDER BY
    email;

-- 3) RETURNING（PostgreSQL方言）：UPDATE結果をその場で確認
-- 例：デモ顧客のstatusを一時的にsuspendedにして、戻す
UPDATE lab.customer
SET
    status = 'suspended'
WHERE
    email = 'phase8.demo@example.com'
RETURNING
    customer_id,
    email,
    full_name,
    status;

UPDATE lab.customer
SET
    status = 'active'
WHERE
    email = 'phase8.demo@example.com'
RETURNING
    customer_id,
    email,
    full_name,
    status;

-- 4) RETURNING（PostgreSQL方言）：DELETEした行を確認
-- 例：MERGEで作った顧客を削除して、削除内容を表示
DELETE FROM lab.customer
WHERE
    email = 'phase8.merge@example.com'
RETURNING
    customer_id,
    email,
    full_name,
    status;

-- 5) 参考：標準SQL寄りに考えるなら
-- - UPSERT相当は MERGE を使う（DBによって対応差あり）
-- - RETURNING はDB差が大きい（PostgreSQLは非常に便利）
--   他RDBMSではOUTPUT句や別の書き方になることがある

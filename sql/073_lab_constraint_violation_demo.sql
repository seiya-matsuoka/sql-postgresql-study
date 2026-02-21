-- phase: 7
-- topic: 制約違反デモ（エラーを安全に観察する）
-- dataset: ec-v1（labスキーマ）
-- 方針:
--   - あえて制約違反を起こす
--   - DOブロック内で例外を捕まえ、NOTICEにして続行する
--   - 実務では「なぜ弾かれたか」を読む力が重要
-- 0) UNIQUE違反（email重複）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.customer (email, full_name) VALUES ('alice@example.com', 'Alice Duplicate');
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '[UNIQUE違反] emailが重複しました: %', SQLERRM;
  END;
END $$;

-- 1) CHECK違反（email形式）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.customer (email, full_name) VALUES ('no-at-mark', 'Bad Email');
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '[CHECK違反] email形式チェックに失敗: %', SQLERRM;
  END;
END $$;

-- 2) CHECK違反（statusの許容値）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.customer (email, full_name, status) VALUES ('eve@example.com', 'Eve', 'deleted');
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '[CHECK違反] statusの許容値に違反: %', SQLERRM;
  END;
END $$;

-- 3) FK違反（存在しないcustomer_id）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.account (customer_id, currency, balance_yen) VALUES (9999, 'JPY', 0);
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '[FK違反] 親(customer)が存在しません: %', SQLERRM;
  END;
END $$;

-- 4) 複合UNIQUE違反（同一customer_id + currency）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.account (customer_id, currency, balance_yen) VALUES (1, 'JPY', 123);
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '[複合UNIQUE違反] 同一顧客に同じ通貨口座を重複作成: %', SQLERRM;
  END;
END $$;

-- 5) CHECK違反（transfer: amount_yen > 0）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.transfer (from_account_id, to_account_id, amount_yen, idempotency_key)
    VALUES (1, 2, 0, 'tr-bad-amount');
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '[CHECK違反] 振込金額が不正: %', SQLERRM;
  END;
END $$;

-- 6) CHECK違反（transfer: from_account_id <> to_account_id）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.transfer (from_account_id, to_account_id, amount_yen, idempotency_key)
    VALUES (1, 1, 100, 'tr-same-account');
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '[CHECK違反] 同一口座への振込は禁止: %', SQLERRM;
  END;
END $$;

-- 7) FK違反（transfer: 存在しないaccount_id）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.transfer (from_account_id, to_account_id, amount_yen, idempotency_key)
    VALUES (9999, 1, 100, 'tr-bad-fk');
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '[FK違反] 参照先accountが存在しません: %', SQLERRM;
  END;
END $$;

-- 8) NOT NULL違反（idempotency_key）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.transfer (from_account_id, to_account_id, amount_yen, idempotency_key)
    VALUES (1, 2, 100, NULL);
  EXCEPTION WHEN not_null_violation THEN
    RAISE NOTICE '[NOT NULL違反] 必須列がNULL: %', SQLERRM;
  END;
END $$;

-- 9) 複合PK違反（order_id, line_noが重複）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.simple_order_line (order_id, line_no, item_name, quantity, unit_price_yen)
    VALUES (1, 1, 'Duplicate Line', 1, 999);
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '[複合PK違反] (order_id, line_no)が重複: %', SQLERRM;
  END;
END $$;

-- 10) CHECK違反（quantity > 0）
DO $$
BEGIN
  BEGIN
    INSERT INTO lab.simple_order_line (order_id, line_no, item_name, quantity, unit_price_yen)
    VALUES (1, 99, 'Bad Qty', 0, 100);
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '[CHECK違反] quantityが不正: %', SQLERRM;
  END;
END $$;

-- 最後に 正しいデータは残っている ことを確認
SELECT
    COUNT(*) AS customer_count
FROM
    lab.customer;

SELECT
    COUNT(*) AS transfer_count
FROM
    lab.transfer;

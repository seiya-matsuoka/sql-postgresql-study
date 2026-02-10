-- phase: 2
-- topic: ON vs WHERE（LEFT JOINの罠：WHERE条件でINNERになりがち）
-- dataset: ec-v0
-- note: 実務で事故りやすいポイントなので、結果行数を見て体で覚える。
-- 0) ベース：ユーザーを全件出したいので LEFT JOIN
SELECT
    u.id AS user_id,
    u.display_name,
    o.id AS order_id,
    o.order_status
FROM
    app_user u
    LEFT JOIN customer_order o ON o.user_id = u.id
ORDER BY
    u.id,
    o.id NULLS LAST;

-- 1) 罠パターン：WHEREで右テーブル条件を付ける（NULL行が落ちる）
-- 「paidの注文があるユーザーだけ」が欲しいならこれでもOKだが、
-- 「ユーザー全件＋paidの注文があれば出したい」場合にはダメ。
SELECT
    u.id AS user_id,
    u.display_name,
    o.id AS order_id,
    o.order_status
FROM
    app_user u
    LEFT JOIN customer_order o ON o.user_id = u.id
WHERE
    o.order_status = 'paid'
ORDER BY
    u.id,
    o.id;

-- 2) 正しい置き方（ユーザー全件は残しつつ、paidの注文だけ結合する）
-- 条件を ON に移すと、LEFT JOIN の “NULL行” が残る
SELECT
    u.id AS user_id,
    u.display_name,
    o.id AS order_id,
    o.order_status
FROM
    app_user u
    LEFT JOIN customer_order o ON o.user_id = u.id
    AND o.order_status = 'paid'
ORDER BY
    u.id,
    o.id NULLS LAST;

-- 3) さらに：paid注文があるユーザーだけ欲しい場合（LEFTの意味を消してOK）
-- これは INNER JOIN で書くのが自然（“意図”が明確）
SELECT
    u.id AS user_id,
    u.display_name,
    o.id AS order_id,
    o.order_status
FROM
    app_user u
    JOIN customer_order o ON o.user_id = u.id
    AND o.order_status = 'paid'
ORDER BY
    u.id,
    o.id;

-- 4) まとめ（判断の型）
-- - 「左を必ず残す」＋「右は条件付きで付ける」→ 条件は ON に置く
-- - 「条件を満たす行だけ欲しい」→ INNER JOIN か WHERE で絞る

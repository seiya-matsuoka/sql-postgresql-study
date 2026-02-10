-- phase: 2
-- topic: INNER / LEFT JOIN basics（結合の基本形と結果の違い）
-- dataset: ec-v0
-- 0) まずは「注文」が存在するユーザーを確認（JOIN対象の雰囲気）
SELECT
    u.id AS user_id,
    u.display_name,
    o.id AS order_id,
    o.order_status,
    o.ordered_at
FROM
    app_user u
    JOIN customer_order o ON o.user_id = u.id
ORDER BY
    u.id,
    o.ordered_at;

-- 1) INNER JOIN：両方に存在するものだけ
-- 注文がないユーザーは出ない
SELECT
    u.id AS user_id,
    u.display_name,
    o.id AS order_id,
    o.order_status
FROM
    app_user u
    INNER JOIN customer_order o ON o.user_id = u.id
ORDER BY
    u.id,
    o.id;

-- 2) LEFT JOIN：左（ユーザー）は全部出す。注文がないユーザーはNULLになる
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

-- 3) LEFT JOIN + 「注文がないユーザーだけ」抽出（IS NULL）
SELECT
    u.id AS user_id,
    u.display_name
FROM
    app_user u
    LEFT JOIN customer_order o ON o.user_id = u.id
WHERE
    o.id IS NULL
ORDER BY
    u.id;

-- 4) 右を必須にしたいならINNER、右が無い場合も見たいならLEFT、という判断の型
-- “ユーザー一覧”が主で、注文はオプション → LEFT JOIN が自然
-- “注文一覧”が主で、必ずユーザー情報が欲しい → INNER JOIN が自然（FKがあるので実質必ずある）

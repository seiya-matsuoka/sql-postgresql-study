-- phase: 5
-- topic: 再帰CTE（階層：親子関係の展開）
-- dataset: ec-v1（ただし、階層用の一時テーブルをこのSQL内で用意）
-- 目的:
--   - 再帰CTEの基本形（アンカー + 再帰部）を体験する
--   - 実務の「階層（組織/カテゴリ/メニュー）」で出る形に慣れる
-- 0) 学習用に一時テーブルを作る（セッション中だけ）
DROP TABLE IF EXISTS temp_category;

CREATE TEMP TABLE temp_category (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL,
    parent_category_id INTEGER NULL
);

INSERT INTO
    temp_category (category_id, category_name, parent_category_id)
VALUES
    (1, 'Root', NULL),
    (2, 'Electronics', 1),
    (3, 'PC', 2),
    (4, 'Accessories', 2),
    (5, 'Food', 1),
    (6, 'Snacks', 5),
    (7, 'Health', 5),
    (8, 'Stationery', 1),
    (9, 'Writing', 8),
    (10, 'Paper', 8);

-- 1) 再帰CTE：ルートから全階層を展開（深さとパスも付与）
WITH RECURSIVE
    cat_tree AS (
        -- アンカー（最初の行）
        SELECT
            c.category_id,
            c.category_name,
            c.parent_category_id,
            0 AS depth,
            CAST(c.category_name AS TEXT) AS path
        FROM
            temp_category c
        WHERE
            c.parent_category_id IS NULL
        UNION ALL
        -- 再帰部（直前の結果にぶら下がる子を取る）
        SELECT
            c.category_id,
            c.category_name,
            c.parent_category_id,
            t.depth + 1 AS depth,
            (t.path || ' > ' || c.category_name) AS path
        FROM
            temp_category c
            JOIN cat_tree t ON t.category_id = c.parent_category_id
    )
SELECT
    category_id,
    category_name,
    parent_category_id,
    depth,
    path
FROM
    cat_tree
ORDER BY
    path;

-- 2) 特定ノード配下だけ（例：Electronics配下）
WITH RECURSIVE
    cat_tree AS (
        SELECT
            c.category_id,
            c.category_name,
            c.parent_category_id,
            0 AS depth,
            CAST(c.category_name AS TEXT) AS path
        FROM
            temp_category c
        WHERE
            c.category_name = 'Electronics'
        UNION ALL
        SELECT
            c.category_id,
            c.category_name,
            c.parent_category_id,
            t.depth + 1 AS depth,
            (t.path || ' > ' || c.category_name) AS path
        FROM
            temp_category c
            JOIN cat_tree t ON t.category_id = c.parent_category_id
    )
SELECT
    category_id,
    category_name,
    parent_category_id,
    depth,
    path
FROM
    cat_tree
ORDER BY
    path;

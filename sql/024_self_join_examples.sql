-- phase: 2
-- topic: Self join（自己JOINの入口）
-- dataset: ec-v0
-- note: いまのEC題材では「親子関係」が薄いので、ここでは“自己JOINの形”を体験するために
--       その場で一時テーブル（TEMP TABLE）を作って試す。
--       学習後に不要なら、セッションが終われば消える。
-- 0) 一時テーブル（セッション中だけ存在）
DROP TABLE IF EXISTS temp_employee;

CREATE TEMP TABLE temp_employee (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    manager_emp_id INTEGER NULL
);

INSERT INTO
    temp_employee (emp_id, emp_name, manager_emp_id)
VALUES
    (1, 'CEO', NULL),
    (2, 'Dev Manager', 1),
    (3, 'QA Manager', 1),
    (4, 'Dev A', 2),
    (5, 'Dev B', 2),
    (6, 'QA A', 3);

-- 1) 自己JOIN：部下と上司を並べる
SELECT
    e.emp_id,
    e.emp_name,
    m.emp_id AS manager_id,
    m.emp_name AS manager_name
FROM
    temp_employee e
    LEFT JOIN temp_employee m ON m.emp_id = e.manager_emp_id
ORDER BY
    e.emp_id;

-- 2) 上司がいない人（トップ）だけ
SELECT
    e.emp_id,
    e.emp_name
FROM
    temp_employee e
WHERE
    e.manager_emp_id IS NULL
ORDER BY
    e.emp_id;

-- 3) 「同じ上司の同僚」を出す（自己JOINを2回使う感じ）
-- 例：Dev A（emp_id=4）の同僚
SELECT
    me.emp_id AS me_id,
    me.emp_name AS me_name,
    colleague.emp_id AS colleague_id,
    colleague.emp_name AS colleague_name
FROM
    temp_employee me
    JOIN temp_employee colleague ON colleague.manager_emp_id = me.manager_emp_id
    AND colleague.emp_id <> me.emp_id
WHERE
    me.emp_id = 4
ORDER BY
    colleague.emp_id;

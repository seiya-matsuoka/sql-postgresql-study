-- phase: 13
-- topic: pg_stat_activity / ロックの見える化（最低限）
-- dataset: 任意
-- 目的:
--   - 今動いているSQL、待ち状態、ロックを確認する型を作る
-- 補足:
--   - ロック待ちを再現したい場合は Phase 8 の2セッションロックデモを同時に動かしてからこのSQLを実行すると分かりやすい
-- 1) 現在の接続一覧（自分以外も含む）
SELECT
    pid,
    usename,
    datname,
    state,
    wait_event_type,
    wait_event,
    backend_start,
    xact_start,
    query_start,
    LEFT(query, 120) AS query_head
FROM
    pg_stat_activity
WHERE
    datname = current_database()
ORDER BY
    query_start NULLS LAST;

-- 2) ロック一覧（どのpidが何をロックしているか）
SELECT
    l.pid,
    a.usename,
    a.state,
    l.locktype,
    l.mode,
    l.granted,
    l.relation::regclass AS relation,
    LEFT(a.query, 120) AS query_head
FROM
    pg_locks l
    JOIN pg_stat_activity a ON a.pid = l.pid
WHERE
    a.datname = current_database()
ORDER BY
    l.granted,
    l.pid;

-- 3) ブロック関係（誰が誰を待たせているか）
SELECT
    blocked.pid AS blocked_pid,
    blocked_a.usename AS blocked_user,
    blocking.pid AS blocking_pid,
    blocking_a.usename AS blocking_user,
    blocked.mode AS blocked_mode,
    blocking.mode AS blocking_mode,
    blocked.relation::regclass AS relation,
    LEFT(blocked_a.query, 100) AS blocked_query_head,
    LEFT(blocking_a.query, 100) AS blocking_query_head
FROM
    pg_locks blocked
    JOIN pg_stat_activity blocked_a ON blocked_a.pid = blocked.pid
    JOIN pg_locks blocking ON blocking.locktype = blocked.locktype
    AND blocking.database IS NOT DISTINCT FROM blocked.database
    AND blocking.relation IS NOT DISTINCT FROM blocked.relation
    AND blocking.page IS NOT DISTINCT FROM blocked.page
    AND blocking.tuple IS NOT DISTINCT FROM blocked.tuple
    AND blocking.transactionid IS NOT DISTINCT FROM blocked.transactionid
    AND blocking.classid IS NOT DISTINCT FROM blocked.classid
    AND blocking.objid IS NOT DISTINCT FROM blocked.objid
    AND blocking.objsubid IS NOT DISTINCT FROM blocked.objsubid
    AND blocking.pid <> blocked.pid
    JOIN pg_stat_activity blocking_a ON blocking_a.pid = blocking.pid
WHERE
    NOT blocked.granted
    AND blocking.granted
ORDER BY
    blocked_pid;

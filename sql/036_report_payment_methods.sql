-- phase: 3 (ec-v1 add-on)
-- topic: payment method / status report
-- dataset: ec-v1
-- CASE版（汎用パターン）
SELECT
    method,
    COUNT(*) AS payment_rows,
    SUM(amount_yen) AS sum_amount_yen,
    SUM(
        CASE
            WHEN status = 'paid' THEN 1
            ELSE 0
        END
    ) AS paid_count,
    SUM(
        CASE
            WHEN status = 'refunded' THEN 1
            ELSE 0
        END
    ) AS refunded_count,
    SUM(
        CASE
            WHEN status = 'pending' THEN 1
            ELSE 0
        END
    ) AS pending_count
FROM
    payment
GROUP BY
    method
ORDER BY
    sum_amount_yen DESC,
    method;

-- FILTER版（短く書ける：PostgreSQLで実行可）
SELECT
    method,
    COUNT(*) AS payment_rows,
    SUM(amount_yen) AS sum_amount_yen,
    COUNT(*) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_count,
    COUNT(*) FILTER (
        WHERE
            status = 'refunded'
    ) AS refunded_count,
    COUNT(*) FILTER (
        WHERE
            status = 'pending'
    ) AS pending_count
FROM
    payment
GROUP BY
    method
ORDER BY
    sum_amount_yen DESC,
    method;

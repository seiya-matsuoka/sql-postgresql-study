-- phase: 3 (ec-v1 add-on)
-- topic: shipment lead time (ordered -> shipped/delivered)
-- dataset: ec-v1
-- note: intervalの扱いはDB差が出るので、ここでは「時間(時間/日)に落として集約」する。
SELECT
    s.status,
    COUNT(*) AS shipment_count,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH
                FROM
                    (s.shipped_at - o.ordered_at)
            ) / 3600.0
        )
    ) AS avg_hours_to_ship
FROM
    shipment s
    JOIN customer_order o ON o.id = s.order_id
WHERE
    s.shipped_at IS NOT NULL
GROUP BY
    s.status
ORDER BY
    s.status;

SELECT
    s.status,
    COUNT(*) AS shipment_count,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH
                FROM
                    (s.delivered_at - o.ordered_at)
            ) / 86400.0
        ),
        2
    ) AS avg_days_to_deliver
FROM
    shipment s
    JOIN customer_order o ON o.id = s.order_id
WHERE
    s.delivered_at IS NOT NULL
GROUP BY
    s.status
ORDER BY
    s.status;

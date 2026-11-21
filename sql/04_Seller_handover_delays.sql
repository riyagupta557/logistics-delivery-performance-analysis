------------------------------------------------------------------------------------------------------------------
-------------------------------------- SELLER HANDOVER AND DELIVERY ANALYSIS---------------------------------------------
------------------------------------------------------------------------------------------------------------------


--3.1 Are orders handed to the carrier after the deadline late more often?


WITH order_handover AS (
    SELECT
        o.order_id,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        MAX(oi.shipping_limit_date) AS shipping_deadline
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_carrier_date <= o.order_delivered_customer_date
    GROUP BY o.order_id, o.order_delivered_carrier_date,
             o.order_delivered_customer_date, o.order_estimated_delivery_date
)
SELECT
    CASE WHEN order_delivered_carrier_date > shipping_deadline
         THEN 'Missed Deadline' ELSE 'Met Deadline' END AS handover_status,
    COUNT(*) AS delivered_orders,
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) AS late_orders,
    ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END)
          / COUNT(*), 2) AS late_rate_pct
FROM order_handover
GROUP BY 1
ORDER BY 1;

--3.2 Does the late rate rise as the handover delay gets longer?

WITH order_handover AS (
    SELECT
        o.order_id,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        MAX(oi.shipping_limit_date) AS shipping_deadline
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_carrier_date <= o.order_delivered_customer_date
    GROUP BY o.order_id, o.order_delivered_carrier_date,
             o.order_delivered_customer_date, o.order_estimated_delivery_date
),
handover_gap AS (
    SELECT *,
        EXTRACT(EPOCH FROM (order_delivered_carrier_date - shipping_deadline)) / 86400.0 AS days_over_deadline
    FROM order_handover
)
SELECT
    CASE
        WHEN days_over_deadline <= 0 THEN '1. Met Deadline'
        WHEN days_over_deadline <= 1 THEN '2. Up to 1 Day Over'
        WHEN days_over_deadline <= 3 THEN '3. 1-3 Days Over'
        ELSE '4. More Than 3 Days Over'
    END AS handover_delay_group,
    COUNT(*) AS delivered_orders,
    ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END)
          / COUNT(*), 2) AS late_rate_pct
FROM handover_gap
GROUP BY 1
ORDER BY 1;

--3.3 What share of all late customer deliveries involved a missed handover deadline?

WITH order_handover AS (
    SELECT
        o.order_id,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        MAX(oi.shipping_limit_date) AS shipping_deadline
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_carrier_date <= o.order_delivered_customer_date
    GROUP BY o.order_id, o.order_delivered_carrier_date,
             o.order_delivered_customer_date, o.order_estimated_delivery_date
)
SELECT
    COUNT(*) AS total_late_orders,
    COUNT(CASE WHEN order_delivered_carrier_date > shipping_deadline THEN 1 END) AS late_with_missed_handover,
    ROUND(100.0 * COUNT(CASE WHEN order_delivered_carrier_date > shipping_deadline THEN 1 END)
          / COUNT(*), 2) AS pct_of_late_orders_with_missed_handover
FROM order_handover
WHERE order_delivered_customer_date > order_estimated_delivery_date;


--3.4 Which seller states miss handover deadlines most often, and are they also the late-delivery hotspots?

SELECT
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_delivered_carrier_date > oi.shipping_limit_date
                                      THEN o.order_id END)
          / COUNT(DISTINCT o.order_id), 2) AS missed_handover_rate_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                                      THEN o.order_id END)
          / COUNT(DISTINCT o.order_id), 2) AS late_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'Delivered'
  AND o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_carrier_date <= o.order_delivered_customer_date
GROUP BY s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY missed_handover_rate_pct DESC;

--3.5 How many delivered orders is each seller associated with?

SELECT
    oi.seller_id,
	COUNT(DISTINCT o.order_id) AS delivered_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY oi.seller_id
ORDER BY delivered_orders DESC;


--3.6 What is the late-delivery rate for each seller state?

SELECT
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                                      THEN o.order_id END)
          / COUNT(DISTINCT o.order_id), 2) AS late_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'Delivered'
GROUP BY s.seller_state
ORDER BY late_rate_pct DESC;

--3.7 Which seller cities have the highest late-delivery rates?

SELECT
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                                      THEN o.order_id END)
          / COUNT(DISTINCT o.order_id), 2) AS late_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'Delivered'
GROUP BY s.seller_city, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY late_rate_pct DESC
LIMIT 10;


--3.8 Which seller locations handle a high volume of delivered orders but have a poor on-time delivery record?

WITH location_stats AS (
    SELECT
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                            THEN o.order_id END) AS late_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'Delivered'
    GROUP BY s.seller_city, s.seller_state
)
SELECT
    seller_city,
    seller_state,
    delivered_orders,
    late_orders,
    ROUND(100.0 * late_orders / delivered_orders, 2) AS late_rate_pct
FROM location_stats
WHERE delivered_orders >= (SELECT AVG(delivered_orders) FROM location_stats)
  AND 100.0 * late_orders / delivered_orders >
  (SELECT 100.0 * SUM(late_orders) / SUM(delivered_orders) FROM location_stats)
ORDER BY late_orders DESC
LIMIT 10;





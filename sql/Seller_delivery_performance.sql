------------------------------------------------------------------------------------------------------------------
------------------------------------------- SELLER DELIVERY PERFORMANCE-------------------------------------------
------------------------------------------------------------------------------------------------------------------

--3.1 How many delivered orders is each seller associated with?

SELECT
    oi.seller_id,
	COUNT(DISTINCT o.order_id) AS delivered_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY oi.seller_id
ORDER BY delivered_orders DESC;


--3.2 What is the late-delivery rate for each seller state?

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

--3.3 Which seller cities have the highest late-delivery rates?

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


--3.4 Which seller locations handle a high volume of delivered orders but have a poor on-time delivery record?

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
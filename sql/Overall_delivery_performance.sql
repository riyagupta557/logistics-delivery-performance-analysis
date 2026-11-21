-----------------------------------------------------------------------------------------------------------------
-------------------------------------- OVERALL DELIVERY PERFORMANCE----------------------------------------------
-----------------------------------------------------------------------------------------------------------------


-- 1.1 How many total orders were received, and how many were successfully delivered, late, and on time?

SELECT
    COUNT(*) AS total_orders,

    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS delivered_orders,

    COUNT(CASE WHEN order_status = 'Delivered'
               AND order_delivered_customer_date > order_estimated_delivery_date
               THEN 1 END) AS late_orders,

    COUNT(CASE WHEN order_status = 'Delivered'
               AND order_delivered_customer_date <= order_estimated_delivery_date
               THEN 1 END) AS on_time_orders

FROM orders;

-- 1.2 What percentage of delivered orders were delivered late versus on time?

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                             THEN 1 END) / COUNT(*), 2) AS late_pct,

    ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
                             THEN 1 END) / COUNT(*), 2) AS on_time_pct

FROM orders
WHERE order_status = 'Delivered';


-- 1.3 What is the average time taken to deliver an order from purchase to customer receipt?

SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))
	/ 86400.0), 2) AS avg_delivery_days
FROM orders
WHERE order_status = 'Delivered';

-- 1.4 On average, how many days late are orders delivered compared with their estimated delivery dates?

SELECT
    COUNT(*) AS late_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date))
	/ 86400.0), 2) AS avg_days_late
FROM orders
WHERE order_status = 'Delivered'
  AND order_delivered_customer_date > order_estimated_delivery_date;


-- 1.5 How does monthly order volume and delivery performance change over time?

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::DATE AS order_month,

    COUNT(*) AS total_orders,

    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS delivered_orders,

    COUNT(CASE WHEN order_status = 'Delivered'
               AND order_delivered_customer_date > order_estimated_delivery_date
               THEN 1 END) AS late_orders,

    ROUND(100.0 * COUNT(CASE WHEN order_status = 'Delivered'
                             AND order_delivered_customer_date > order_estimated_delivery_date
                             THEN 1 END)
          / NULLIF(COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END), 0), 2) AS late_pct

FROM orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY order_month;

-- 1.6 How has the annual late-delivery rate changed compared with the previous year?

SET search_path TO logistics_delivery_analysis;

WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp)::INT AS order_year,
        COUNT(*) AS delivered_orders,
        COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                   THEN 1 END) AS late_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY EXTRACT(YEAR FROM order_purchase_timestamp)
)
SELECT
    order_year,
    delivered_orders,
    late_orders,
    ROUND(100.0 * late_orders / delivered_orders, 2) AS late_rate_pct,
    ROUND(100.0 * LAG(late_orders) OVER (ORDER BY order_year)
          / LAG(delivered_orders) OVER (ORDER BY order_year), 2) AS prev_year_late_rate_pct,
    ROUND(100.0 * late_orders / delivered_orders
          - 100.0 * LAG(late_orders) OVER (ORDER BY order_year)
          / LAG(delivered_orders) OVER (ORDER BY order_year), 2) AS change_in_pct_points
FROM yearly
ORDER BY order_year;
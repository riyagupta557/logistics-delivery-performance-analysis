-------------------------------------------------------------------------------------------------------------------
-------------------------------------- PRODUCT CATEGORY ANALYSIS---------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

--4.1 How many total orders are associated with each product category?

SELECT
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY total_orders DESC;

--4.2 What is the average delivery time (from purchase to customer receipt) for each product category?  

SELECT
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
	/ 86400.0), 2) AS avg_delivery_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_category_name_english
ORDER BY avg_delivery_days DESC;

--4.3 What is the late-delivery rate for each product category?

SELECT
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                                      THEN o.order_id END)
          / COUNT(DISTINCT o.order_id), 2) AS late_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_category_name_english
ORDER BY late_rate_pct DESC;


--4.4 Do heavier products have higher late-delivery rates and longer delivery times?

WITH order_weight AS (
    SELECT
        o.order_id,
        SUM(p.product_weight_g) AS total_weight_g,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        o.order_purchase_timestamp
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
      AND p.product_weight_g > 0
    GROUP BY o.order_id, o.order_delivered_customer_date,
             o.order_estimated_delivery_date, o.order_purchase_timestamp
)
SELECT
    CASE
        WHEN total_weight_g <= 500 THEN '1. Up to 500 g'
        WHEN total_weight_g <= 2000 THEN '2. 501 g - 2 kg'
        WHEN total_weight_g <= 5000 THEN '3. 2 - 5 kg'
        ELSE '4. Over 5 kg'
    END AS weight_group,
    COUNT(*) AS delivered_orders,
    ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END)
          / COUNT(*), 2) AS late_rate_pct,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))
	/ 86400.0), 2) AS avg_delivery_days
FROM order_weight
GROUP BY 1
ORDER BY 1;




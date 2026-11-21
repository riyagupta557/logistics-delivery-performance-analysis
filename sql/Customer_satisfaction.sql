----------------------------------------------------------------------------------------------------------------------
----------------------------------------------- CUSTOMER SATISFACTION ------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

--5.1 What is the average review score for late orders compared with on-time orders?

SELECT
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Late'
         ELSE 'On Time'
    END AS delivery_status,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Late'
         ELSE 'On Time'
    END
ORDER BY delivery_status;


--5.2 How do average review scores compare across different delay-duration groups?

WITH delay_data AS (
    SELECT
        o.order_id,
        r.review_score,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))
		/ 86400.0 AS days_diff
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'Delivered'
)
SELECT
    CASE
        WHEN days_diff <= 0 THEN '1. On Time / Early'
        WHEN days_diff <= 3 THEN '2. 1-3 Days Late'
        WHEN days_diff <= 7 THEN '3. 4-7 Days Late'
        WHEN days_diff <= 14 THEN '4. 8-14 Days Late'
        ELSE '5. 15+ Days Late'
    END AS delay_group,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM delay_data
GROUP BY
    CASE
        WHEN days_diff <= 0 THEN '1. On Time / Early'
        WHEN days_diff <= 3 THEN '2. 1-3 Days Late'
        WHEN days_diff <= 7 THEN '3. 4-7 Days Late'
        WHEN days_diff <= 14 THEN '4. 8-14 Days Late'
        ELSE '5. 15+ Days Late'
    END
ORDER BY delay_group;


--5.7 Do orders shipped within the same state get better reviews than cross-state orders?

WITH order_route AS (
    SELECT DISTINCT
        o.order_id,
        CASE WHEN s.seller_state = c.customer_state THEN 'Same State' ELSE 'Different State' END AS route_type,
        r.review_score,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'Delivered'
)
SELECT
    route_type,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * SUM(is_late) / COUNT(*), 2) AS late_rate_pct
FROM order_route
GROUP BY route_type;

--5.11 Within each route type (same state vs different state), how do late and on-time orders 
--compare on average review score?

WITH order_route AS (
    SELECT DISTINCT
        o.order_id,
        CASE WHEN s.seller_state = c.customer_state THEN 'Same State' ELSE 'Different State' END AS route_type,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late' 
		ELSE 'On Time' END AS delivery_status,
        r.review_score
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'Delivered'
)
SELECT
    route_type,
    delivery_status,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_route
GROUP BY route_type, delivery_status
ORDER BY route_type, delivery_status;
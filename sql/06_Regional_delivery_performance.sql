-----------------------------------------------------------------------------------------------------------------
-------------------------------------- GEOGRAPHIC ANALYSIS ----------------------------------------------
-----------------------------------------------------------------------------------------------------------------


--2.1 Which Brazilian states have the highest late-delivery rates and contribute the most late deliveries?

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
	
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
               THEN 1 END) AS late_orders,
			   
    ROUND(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                             THEN 1 END) / COUNT(*), 2) AS late_rate_pct,
							 
    ROUND(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                             THEN 1 END)
          / SUM(COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                           THEN 1 END)) OVER (), 2) AS share_of_all_late_pct
						   
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_state
ORDER BY late_rate_pct DESC;


--2.2 Which customer cities have the highest late-delivery rates?

SELECT
    c.customer_city,
    c.customer_state,
	
    COUNT(*) AS delivered_orders,
	
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
               THEN 1 END) AS late_orders,
			   
    ROUND(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                             THEN 1 END) / COUNT(*), 2) AS late_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_city, c.customer_state
HAVING COUNT(*) >= 100
ORDER BY late_rate_pct DESC
LIMIT 10;



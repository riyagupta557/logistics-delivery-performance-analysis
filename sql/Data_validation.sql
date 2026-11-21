SET search_path TO logistics_delivery_analysis;

--Verifying table row count

SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM logistics_delivery_analysis.customers

UNION ALL

SELECT 'sellers', COUNT(*)
FROM logistics_delivery_analysis.sellers

UNION ALL

SELECT 'products', COUNT(*)
FROM logistics_delivery_analysis.products

UNION ALL

SELECT 'orders', COUNT(*)
FROM logistics_delivery_analysis.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM logistics_delivery_analysis.order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM logistics_delivery_analysis.order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM logistics_delivery_analysis.order_reviews

ORDER BY table_name;

-- Validating primary key uniqueness

SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_ids
FROM logistics_delivery_analysis.customers

UNION ALL

SELECT
    'sellers',
    COUNT(*),
    COUNT(DISTINCT seller_id)
FROM logistics_delivery_analysis.sellers

UNION ALL

SELECT
    'products',
    COUNT(*),
    COUNT(DISTINCT product_id)
FROM logistics_delivery_analysis.products

UNION ALL

SELECT
    'orders',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM logistics_delivery_analysis.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*),
    COUNT(DISTINCT (order_id, order_item_id))
FROM logistics_delivery_analysis.order_items

UNION ALL

SELECT
    'order_payments',
    COUNT(*),
    COUNT(DISTINCT (order_id, payment_sequential))
FROM logistics_delivery_analysis.order_payments

UNION ALL

SELECT
    'order_reviews',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM logistics_delivery_analysis.order_reviews;

-- Validating foreign key relationships

--1.Orders without matching customers
SELECT COUNT(*) AS unmatched_orders
FROM logistics_delivery_analysis.orders o
LEFT JOIN logistics_delivery_analysis.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--2.Order Items without matching orders
SELECT COUNT(*) AS unmatched_order_items
FROM logistics_delivery_analysis.order_items oi
LEFT JOIN logistics_delivery_analysis.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--3.Order Items without matching products
SELECT COUNT(*) AS unmatched_products
FROM logistics_delivery_analysis.order_items oi
LEFT JOIN logistics_delivery_analysis.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

--4.Order Items without matching sellers
SELECT COUNT(*) AS unmatched_sellers
FROM logistics_delivery_analysis.order_items oi
LEFT JOIN logistics_delivery_analysis.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

--5.Payments without matching orders
SELECT COUNT(*) AS unmatched_payments
FROM logistics_delivery_analysis.order_payments p
LEFT JOIN logistics_delivery_analysis.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

--6.Reviews without matching orders
SELECT COUNT(*) AS unmatched_reviews
FROM logistics_delivery_analysis.order_reviews r
LEFT JOIN logistics_delivery_analysis.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

--- Distinct order statuses 
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

--- Delivered orders missing a delivery date
SELECT COUNT(*) AS delivered_without_date
FROM orders
WHERE order_status = 'Delivered'
  AND order_delivered_customer_date IS NULL;

--- Illogical date sequences (each should be 0 or a small, explained number)
SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase,
    COUNT(*) FILTER (WHERE order_approved_at < order_purchase_timestamp) AS approved_before_purchase,
	COUNT(*) FILTER (WHERE order_delivered_carrier_date < order_approved_at) AS carrier_before_approval,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date > order_delivered_customer_date) AS carrier_after_delivery
FROM orders;







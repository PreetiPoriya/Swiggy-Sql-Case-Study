-- =====================================================
-- Q1. Find customers who have never placed an order

-- Business Objective:
-- Identify registered users who have not yet converted into customers. This information can be used for targeted marketing campaigns and promotional offers.
-- =====================================================
SELECT name
FROM users
WHERE user_id NOT IN (
    SELECT DISTINCT user_id
    FROM orders
);

-- =====================================================
-- Q2. Calculate average price per dish

-- Business Objective:
-- Will help identify premium, budget-friendly, and competitively priced dishes.
-- =====================================================
SELECT
    f.f_id,
    f.f_name,
    AVG(price) AS avg_price
FROM food f
JOIN menu m
    ON f.f_id = m.f_id
GROUP BY
    f.f_id,
    f.f_name;


-- =====================================================
-- Q3. Identify the top-performing restaurant based on order volume for a given month.

-- Business Objective:
-- This helps evaluate restaurant popularity and seasonal performance.
-- =====================================================
SELECT
    r_name,
    COUNT(*) AS total_orders
FROM orders
JOIN restaurants r
    ON r.r_id = orders.r_id
WHERE MONTHNAME(date) = 'June'
GROUP BY r_name
ORDER BY total_orders DESC
LIMIT 1;


-- =====================================================
-- Q4. Find restaurants with monthly sales above a specified threshold.

-- Business Objective:
-- This can help in recognizing top revenue-generating restaurants and designing targeted business strategies.

-- =====================================================
SELECT
    r_name,
    SUM(amount) AS total_sales
FROM orders
JOIN restaurants r
    ON orders.r_id = r.r_id
WHERE MONTHNAME(date) = 'June'
GROUP BY r_name
HAVING total_sales > 500;


-- =====================================================
-- Q5. Retrieve complete order details for a customer within a given date range.

-- Business Objective:
-- To understand purchasing behavior, preferred restaurants, and food choices for targeted recommendations and customer retention strategies.
-- =====================================================

SELECT
    o.order_id,
    r_name,
    f_name
FROM orders o
JOIN restaurants r
    ON o.r_id = r.r_id
JOIN order_details od
    ON o.order_id = od.order_id
JOIN food f
    ON od.f_id = f.f_id
WHERE o.user_id = (
    SELECT user_id
    FROM users
    WHERE name = 'Ankit'
)
AND date BETWEEN '2022-06-10' AND '2022-07-10';


-- =====================================================
-- Q6. Identify restaurants with the highest number of repeat customers.

-- Business Objective:
-- A high number of repeat customers indicates strong customer satisfaction, loyalty, and retention.
-- =====================================================

SELECT
    r_name,
    COUNT(user_id) AS repeat_customers
FROM (
    SELECT
        r.r_name,
        user_id,
        COUNT(*) AS order_count
    FROM restaurants r
    JOIN orders o
        ON r.r_id = o.r_id
    GROUP BY
        r.r_name,
        user_id
    HAVING COUNT(*) > 1
) t
GROUP BY r_name
ORDER BY repeat_customers DESC
LIMIT 1;


-- =====================================================
-- Q7. Month-over-month revenue growth

-- Business Objective:
-- This helps evaluate business performance and identify periods of growth or decline.
-- =====================================================

WITH sales AS (
    SELECT
        MONTHNAME(date) AS month,
        SUM(amount) AS revenue,
        LAG(SUM(amount)) OVER (
            ORDER BY MONTH(date)
        ) AS previous_revenue
    FROM orders
    GROUP BY
        MONTHNAME(date),
        MONTH(date)
)

SELECT
    month,
    ROUND(
        ((revenue - previous_revenue) / previous_revenue) * 100,
        2
    ) AS growth_percentage
FROM sales;


-- =====================================================
-- Q8. Determine each customer's favorite food item.

-- Business Objective:
-- This insight can be used to understand customer preferences and support personalized recommendations and marketing campaigns.
-- =====================================================

WITH customer_food_orders AS (
    SELECT
        o.user_id,
        od.f_id,
        COUNT(*) AS order_count
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY
        o.user_id,
        od.f_id
)

SELECT
    u.name AS customer_name,
    f.f_name AS favorite_food
FROM customer_food_orders cfo
JOIN users u
    ON cfo.user_id = u.user_id
JOIN food f
    ON cfo.f_id = f.f_id
WHERE order_count = (
    SELECT MAX(order_count)
    FROM customer_food_orders cfo2
    WHERE cfo.user_id = cfo2.user_id
);

-- =====================================================
-- Q9. Identify the most loyal customers for each restaurant.

-- Business Objective:
-- Determine the customer who has placed the highest number of orders at each restaurant. This information can be used identify highly engaged customers and supports loyalty and retention initiatives.
-- =====================================================

WITH customer_orders AS (
    SELECT
        r_id,
        user_id,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY
        r_id,
        user_id
)

SELECT
    r_name,
    name AS customer_name,
    total_orders
FROM customer_orders c1
JOIN restaurants r
    ON c1.r_id = r.r_id
JOIN users u
    ON c1.user_id = u.user_id
WHERE total_orders = (
    SELECT MAX(total_orders)
    FROM customer_orders c2
    WHERE c2.r_id = c1.r_id
);

-- =====================================================
-- Q10. Analyze Month-over-Month Revenue Growth for a Specific Restaurant

-- Business Objective:
-- Useful in identify growth trends, seasonal patterns, and periods of declining performance.
-- =====================================================

SELECT
    month,
    ROUND(
        ((revenue - previous_revenue) / previous_revenue) * 100,
        2
    ) AS growth_percentage
FROM (
    SELECT
        MONTHNAME(date) AS month,
        SUM(amount) AS revenue,
        LAG(SUM(amount)) OVER (
            ORDER BY MONTH(date)
        ) AS previous_revenue
    FROM orders
    WHERE r_id = (
        SELECT r_id
        FROM restaurants
        WHERE r_name = 'KFC'
    )
    GROUP BY
        MONTHNAME(date),
        MONTH(date)
) monthly_sales;


-- =====================================================
-- Q11. Discover the most frequently paired products.

-- Business Objective:
-- These insights can be used to create combo offers, and personalized product recommendations.
-- =====================================================

SELECT
    f1.f_name AS food_item_1,
    f2.f_name AS food_item_2,
    COUNT(*) AS frequency
FROM order_details od1
JOIN order_details od2
    ON od1.order_id = od2.order_id
    AND od1.f_id < od2.f_id
JOIN food f1
    ON od1.f_id = f1.f_id
JOIN food f2
    ON od2.f_id = f2.f_id
GROUP BY
    f1.f_name,
    f2.f_name
ORDER BY frequency DESC;

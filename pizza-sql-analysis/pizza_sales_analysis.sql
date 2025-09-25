-- ===========================================================
-- Database & Table Creation
-- ===========================================================

CREATE DATABASE pizzahut;

CREATE TABLE orders (
    order_id   INT  NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

-- ===========================================================
-- Basic Queries
-- ===========================================================

-- 1. Retrieve the total number of orders placed.
USE pizzahut;

SELECT COUNT(order_id) AS total_orders
FROM orders;


-- 2. Calculate the total revenue generated from pizza sales.
SELECT ROUND(SUM(order_details.quantity * pizzas.price), 2) AS total_revenue
FROM order_details
JOIN pizzas
    ON pizzas.pizza_id = order_details.pizza_id;


-- 3. Identify the highest-priced pizza.
-- (With name)
SELECT pizza_types.name, pizzas.price
FROM pizza_types
JOIN pizzas
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;

-- (Without name)
SELECT MAX(pizzas.price) AS highest_price
FROM pizzas;


-- 4. Identify the most common pizza size ordered.
SELECT pizzas.size,
       COUNT(order_details.order_details_id) AS order_count
FROM pizzas
JOIN order_details
    ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC
LIMIT 1;


-- 5. List the top 5 most ordered pizza types along with their quantities.
SELECT pizza_types.name,
       SUM(order_details.quantity) AS quantity
FROM pizza_types
JOIN pizzas
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
    ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;

-- ===========================================================
-- Intermediate Queries
-- ===========================================================

-- 6. Join necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_types.category,
       SUM(order_details.quantity) AS quantity
FROM pizza_types
JOIN pizzas
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
    ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY quantity ASC;


-- 7. Determine the distribution of orders by hour of the day.
SELECT HOUR(orders.time) AS order_hour,
       COUNT(orders.order_id) AS total_orders
FROM orders
GROUP BY HOUR(orders.time)
ORDER BY order_hour;


-- 8. Find category-wise distribution of pizzas.
SELECT category,
       COUNT(name) AS pizza_count
FROM pizza_types
GROUP BY category;


-- 9. Group orders by date and calculate the average number of pizzas ordered per day.
SELECT orders.date,
       SUM(order_details.quantity) / COUNT(DISTINCT orders.order_id) AS average
FROM orders
JOIN order_details
    ON orders.order_id = order_details.order_id
GROUP BY orders.date
ORDER BY average;

-- (Alternative approach – commented out)
-- SELECT ROUND(AVG(quantity),0)
-- FROM (
--     SELECT orders.date,
--            SUM(order_details.quantity) AS quantity
--     FROM orders
--     JOIN order_details
--         ON orders.order_id = order_details.order_id
--     GROUP BY orders.date
-- ) AS order_quantity;

-- ===========================================================
-- Advanced Queries
-- ===========================================================

-- 10. Determine the top 3 most ordered pizza types based on revenue.
SELECT pizza_types.name,
       SUM(order_details.quantity * pizzas.price) AS revenue
FROM pizza_types
JOIN pizzas
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
    ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;


-- 11. Calculate the percentage contribution of each pizza type to total revenue.
SELECT pizza_types.name,
       SUM(order_details.quantity * pizzas.price) AS revenue,
       ROUND(
            (SUM(order_details.quantity * pizzas.price) * 100.0) /
            (SELECT SUM(order_details.quantity * pizzas.price)
             FROM order_details
             JOIN pizzas
                ON order_details.pizza_id = pizzas.pizza_id),
            2
       ) AS revenue_percentage
FROM pizza_types
JOIN pizzas
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
    ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;

-- (Alternative – commented out)
-- SELECT pizza_types.name,
--        SUM(pizzas.price * order_details.quantity) AS rev,
--        ROUND(
--            (SUM(pizzas.price * order_details.quantity) * 100.0) /
--            (SELECT SUM(pizzas.price * order_details.quantity)
--             FROM order_details
--             JOIN pizzas
--                ON order_details.pizza_id = pizzas.pizza_id),
--            2
--        ) AS rev_perct
-- FROM pizza_types
-- JOIN pizzas
--     ON pizza_types.pizza_type_id = pizzas.pizza_type_id
-- JOIN order_details
--     ON order_details.pizza_id = pizzas.pizza_id
-- GROUP BY pizza_types.name
-- ORDER BY rev DESC
-- LIMIT 4;


-- 12. Analyze the cumulative revenue generated over time.
SELECT date AS order_date,
       SUM(revenue) OVER (ORDER BY date) AS cum_revenue
FROM (
    SELECT orders.date,
           SUM(order_details.quantity * pizzas.price) AS revenue
    FROM order_details
    JOIN pizzas
        ON order_details.pizza_id = pizzas.pizza_id
    JOIN orders
        ON orders.order_id = order_details.order_id
    GROUP BY orders.date
) AS sales;


-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT name,
       revenue
FROM (
    SELECT category,
           name,
           revenue,
           RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM (
        SELECT pizza_types.category,
               pizza_types.name,
               SUM(order_details.quantity * pizzas.price) AS revenue
        FROM pizza_types
        JOIN pizzas
            ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN order_details
            ON order_details.pizza_id = pizzas.pizza_id
        GROUP BY pizza_types.category, pizza_types.name
    ) AS a
) AS b
WHERE rn <= 3;

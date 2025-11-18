CREATE DATABASE pizzahut;

-- Import pizzas table and pizza_types table directly from SQL (small data)

CREATE TABLE orders
(
order_id int not null,
`date` date not null,
`time` time not null,
PRIMARY KEY (order_id)
);

CREATE TABLE orders_details
(
order_detail_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
PRIMARY KEY (order_detail_id)
);



-- 1. Retrieve the total number of orders placed.
SELECT COUNT(order_id) FROM orders;



-- 2. Calculate the total revenue generated from pizza sales.  quantity.orders_details*price.pizzas
SELECT ROUND(SUM(od.quantity * pz.price),0) as Total_Sales
FROM orders_details as od
	JOIN pizzas as pz
		ON od.pizza_id = pz.pizza_id;



-- 3. Identify the highest-priced pizza.
SELECT pizza_types.`name`, pizzas.price
FROM pizza_types
	JOIN pizzas
		ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC
LIMIT 1;



-- 4. Identify the most common pizza size ordered.
SELECT pizzas.size, COUNT(orders_details.order_detail_id) as Total_Order
FROM orders_details
	JOIN pizzas
		ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizzas.size
ORDER BY Total_Order DESC LIMIT 1 ;



-- 5. List the top 5 most ordered pizza types along with their quantities.
SELECT pizza_types.pizza_type_id, pizza_types.`name`,
SUM(orders_details.quantity) as Total_Quantity
FROM pizza_types
	JOIN pizzas
		ON pizza_types.pizza_type_id = pizzas.pizza_type_id
	JOIN orders_details
		ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizza_types.pizza_type_id, pizza_types.`name`
ORDER BY Total_Quantity DESC LIMIT 5 ;



-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_types.category, SUM(orders_details.quantity) as Total_Quantity
FROM pizza_types
	JOIN pizzas
		ON pizza_types.pizza_type_id = pizzas.pizza_type_id
	JOIN orders_details
		ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizza_types.category
ORDER BY Total_Quantity DESC ;



-- 7. Determine the distribution of orders by hour of the day.
SELECT HOUR(`time`), COUNT(order_id) Total_orders 
FROM orders 
GROUP BY HOUR(`time`)
ORDER BY Total_orders DESC;



-- 8. Join relevant tables to find the category-wise distribution of pizzas.
SELECT category, COUNT(`name`) 
FROM pizza_types
GROUP BY category;



-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT ROUND(avg(Total_orders),0) as Average_order 
FROM 
(
SELECT orders.`date`, SUM(orders_details.quantity) Total_orders 
FROM orders 
	JOIN orders_details
		ON orders.order_id = orders_details.order_id
GROUP BY orders.`date`
ORDER BY Total_orders DESC
) as daily_quantity;



-- 10. Determine the top 3 most ordered pizza types based on revenue.
SELECT pizza_types.name, ROUND(SUM(orders_details.quantity* pizzas.price),0) Revenue 
FROM orders_details
	JOIN pizzas
		ON orders_details.pizza_id = pizzas.pizza_id
	JOIN pizza_types
		ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.name
ORDER BY Revenue DESC LIMIT 3;



-- 11. Calculate the percentage contribution of each pizza type to total revenue.
SELECT pizza_types.category, ROUND((SUM(orders_details.quantity * pizzas.price))/ 
(
SELECT SUM(orders_details.quantity * pizzas.price)
FROM orders_details
	JOIN pizzas
		ON orders_details.pizza_id = pizzas.pizza_id
) * 100 ,2) AS percentage_contribution
FROM pizzas
	JOIN pizza_types
		ON pizzas.pizza_type_id = pizza_types.pizza_type_id
	JOIN orders_details
		ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizza_types.category;



-- 12. Analyze the cumulative revenue generated over time.
-- Cumulative means add previous day revenue to present and so on.. means Rolling Sum
-- Using CTE :
WITH Cumulative_revenue AS
(
SELECT orders.date as Dates, ROUND(SUM(orders_details.quantity * pizzas.price),0) Revenue
FROM orders
	JOIN orders_details
		ON orders.order_id = orders_details.order_id
	JOIN pizzas
		ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY orders.date
)
SELECT Dates, Revenue, SUM(Revenue) OVER (ORDER BY Dates ASC) as Roll_Sum
FROM Cumulative_revenue
;

-- Using Subquery :
SELECT date, ROUND(SUM(revenue) OVER(ORDER BY date),2) as cum_revenue
FROM
(
SELECT orders.date, SUM(orders_details.quantity * pizzas.price)  revenue
FROM orders
	JOIN orders_details
		ON orders.order_id = orders_details.order_id
	JOIN pizzas
		ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY orders.date
) as total_revenue;



-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category
SELECT category, name, revenue, Rank_wise
FROM
(
WITH Ranking AS
	(
	SELECT pizza_types.category , pizza_types.name, SUM(orders_details.quantity * pizzas.price) Revenue
	FROM pizza_types
		JOIN pizzas
			ON pizza_types.pizza_type_id = pizzas.pizza_type_id
		JOIN orders_details
			ON orders_details.pizza_id = pizzas.pizza_id
	GROUP BY pizza_types.category, pizza_types.name
	)
SELECT category, name, Revenue, dense_rank() OVER (partition by category Order By Revenue DESC) as Rank_wise
FROM Ranking
) AS a
WHERE Rank_wise <= 3






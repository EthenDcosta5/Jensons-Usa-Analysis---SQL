-- Find the total number of products sold by each store along with the store name.

SELECT 
    stores.store_name,
    SUM(order_items.quantity) AS total_products_sold
FROM
    order_items
        JOIN
    orders ON order_items.order_id = orders.order_id
        JOIN
    stores ON stores.store_id = orders.store_id
GROUP BY stores.store_name;


-- Calculate the cumulative sum of quantities sold for each product over time.

SELECT 
	product_id, product_name, order_date, quantity,
	sum(quantity) OVER(PARTITION BY product_id ORDER BY order_date) AS cumulative_sum
FROM (SELECT 
    products.product_id, products.product_name, orders.order_date,
    SUM(order_items.quantity) AS quantity
FROM
    orders
        JOIN
    order_items ON orders.order_id = order_items.order_id
        JOIN
    products ON products.product_id = order_items.product_id
GROUP BY products.product_id , orders.order_date) AS cum_sum;


-- Find the product with the highest total sales (quantity * price) for each category.

WITH a AS (SELECT 
    categories.category_id, categories.category_name,
    products.product_id, products.product_name,
    SUM(order_items.quantity * (order_items.list_price - order_items.discount)) AS total_sales
FROM
    order_items JOIN
    products ON order_items.product_id = products.product_id JOIN
    categories ON categories.category_id = products.category_id
GROUP BY categories.category_id , categories.category_name , products.product_id , products.product_name)
SELECT * FROM
    (SELECT
		*,
		RANK() OVER (PARTITION BY category_id ORDER BY total_sales DESC) AS "rank"
	FROM a) 
    AS b
WHERE 
	b.rank = 1;


-- Find the customer who spent the most money on orders.

SELECT * FROM
	(SELECT 
		customer_id, customer_name, sales,
		RANK() OVER (ORDER BY sales DESC) AS "rank"
	FROM
		(SELECT 
			customers.customer_id,
			CONCAT(customers.first_name," ", customers.last_name) AS customer_name,
			SUM(order_items.quantity * (order_items.list_price - order_items.discount)) AS sales
		FROM
			customers
				JOIN
			orders ON customers.customer_id = orders.customer_id
				JOIN
			order_items ON order_items.order_id = orders.order_id
		GROUP BY customers.customer_id) AS a)
	AS b
WHERE 
	b.rank = 1;


-- Find the highest-priced product for each category name.

SELECT 
	category_id, category_name, product_name, a.rank
FROM(SELECT  
		categories.category_id,
        categories.category_name,
        products.product_name,
		products.list_price,
		RANK() OVER (PARTITION BY categories.category_id ORDER BY products.list_price DESC) AS "rank"
	FROM 
		products 
	JOIN 
		categories
	ON products.category_id = categories.category_id) AS a
WHERE 
	a.rank = 1;


-- Find the total number of orders placed by each customer per store.

SELECT 
    store_id, customer_id, 
    COUNT(order_id) as total_orders
FROM
    orders
GROUP BY store_id , customer_id;


-- Find the names of staff members who have not made any sales.

SELECT 
	staffs.staff_id,
    CONCAT(first_name, " ", last_name) as staff_name
FROM
    staffs
WHERE
    NOT EXISTS( SELECT 
            1
        FROM
            orders
        WHERE
            orders.staff_id = staffs.staff_id);


-- Find the top 3 most sold products in terms of quantity.

SELECT
	product_id, product_name, total_quantities_sold
FROM
	(SELECT
		products.product_id, products.product_name,
		SUM(order_items.quantity) AS total_quantities_sold,
		RANK() OVER (ORDER BY SUM(order_items.quantity) DESC) AS "rank"
	FROM 
		products
	JOIN
		order_items
	ON
		products.product_id = order_items.product_id
	GROUP BY products.product_id, products.product_name) as a
WHERE
	a.rank <= 3;


-- Find the median value of the price list. 

WITH a AS (SELECT 
	list_price,
    ROW_NUMBER() OVER (ORDER BY list_price) AS rn,
    COUNT(list_price) OVER() AS "length"
	FROM order_items)
	SELECT 
		CASE WHEN a.length % 2 = 0 THEN
			(SELECT AVG(list_price) FROM a
			WHERE rn IN (a.length/2, (a.length/2)+1))
		ELSE
			(SELECT list_price FROM a
			WHERE rn = (a.length+1)/2)
		END AS median
FROM a
LIMIT 1;


-- List all products that have never been ordered.(use Exists)

SELECT 
	product_id,
    product_name
FROM
	products
WHERE 
	NOT EXISTS(
		SELECT
			1
		FROM
			order_items
		WHERE
			order_items.product_id = products.product_id);


-- List the names of staff members who have made more sales than the average number of sales by all staff members.

SELECT
	staffs.staff_id,
    CONCAT(staffs.first_name, " ", staffs.last_name) AS staff_name,
    COALESCE(SUM(order_items.quantity * (order_items.list_price - order_items.discount)),0) AS total_sales
FROM staffs LEFT JOIN orders
ON staffs.staff_id = orders.staff_id
LEFT JOIN order_items
ON orders.order_id = order_items.order_id
GROUP BY staffs.staff_id
HAVING SUM(order_items.quantity * (order_items.list_price - order_items.discount)) >

(SELECT AVG(total_sales) FROM
(SELECT
	staffs.staff_id,
    CONCAT(staffs.first_name, " ", staffs.last_name) AS staff_name,
    COALESCE(SUM(order_items.quantity * (order_items.list_price - order_items.discount)),0) AS total_sales
FROM staffs LEFT JOIN orders
ON staffs.staff_id = orders.staff_id
LEFT JOIN
	order_items
ON orders.order_id = order_items.order_id
GROUP BY staffs.staff_id) AS a);


-- Identify the customers who have ordered all types of products (i.e., from every category).

SELECT 
	customers.customer_id,
    concat(customers.first_name, " ", customers.last_name) as customers_name
FROM customers JOIN orders
ON customers.customer_id = orders.customer_id
JOIN order_items
ON orders.order_id = order_items.order_id
JOIN products
ON  order_items.product_id = products.product_id
GROUP BY customers.customer_id,
    customers_name
HAVING count(DISTINCT products.category_id) = 
	(SELECT
		count(category_id)
	FROM
		categories
	);

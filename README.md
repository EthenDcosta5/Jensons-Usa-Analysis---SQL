# Jensons-USA SQL Data Analysis

## Overview
This repository contains SQL queries designed to perform data analysis for Jensons USA, an online cycling store. The queries focus on optimizing store and staff performance, enhancing customer experience, and improving inventory management.

## Table of Contents
- [Project Goals](#project-goals)
- [SQL Queries](#sql-queries)
  - [Store and Product Sales Analysis](#store-and-product-sales-analysis)
  - [Customer Behavior Analysis](#customer-behavior-analysis)
  - [Staff Performance Analysis](#staff-performance-analysis)
  - [Inventory Management](#inventory-management)
- [Key Insights](#key-insights)
- [Recommendations](#recommendations)
- [Contact](#contact)

## Project Goals
1. **Optimize Store and Staff Performance**:
   - Identify the total number of products sold by each store.
   - Find staff members who have not made any sales.
   - List the names of staff members who have made more sales than the average.

2. **Enhance Customer Experience**:
   - Identify customers who spent the most money.
   - Find customers who have ordered all types of products.

3. **Improve Inventory Management**:
   - Track top-selling products.
   - Identify products that have never been ordered.
   - Calculate the median price of products.

## SQL Queries

### Store and Product Sales Analysis

- **Total Products Sold by Store**:
  ```sql
  SELECT 
      stores.store_name,
      SUM(order_items.quantity) AS total_products_sold
  FROM
      order_items
      JOIN orders ON order_items.order_id = orders.order_id
      JOIN stores ON stores.store_id = orders.store_id
  GROUP BY stores.store_name;


- **Cumulative Sum of Quantities Sold Over Time**:
  ```sql
  SELECT 
      product_id, product_name, order_date, quantity,
      SUM(quantity) OVER(PARTITION BY product_id ORDER BY order_date) AS cumulative_sum
  FROM 
      (SELECT 
          products.product_id, products.product_name, orders.order_date,
          SUM(order_items.quantity) AS quantity
      FROM
          orders
          JOIN order_items ON orders.order_id = order_items.order_id
          JOIN products ON products.product_id = order_items.product_id
      GROUP BY products.product_id , orders.order_date) AS cum_sum;
  ```

- **Product with Highest Total Sales for Each Category**:
  ```sql
  WITH a AS (
      SELECT 
          categories.category_id, categories.category_name,
          products.product_id, products.product_name,
          SUM(order_items.quantity * (order_items.list_price - order_items.discount)) AS total_sales
      FROM
          order_items
          JOIN products ON order_items.product_id = products.product_id
          JOIN categories ON categories.category_id = products.category_id
      GROUP BY categories.category_id , categories.category_name , products.product_id , products.product_name)
  SELECT * FROM (
      SELECT *, RANK() OVER (PARTITION BY category_id ORDER BY total_sales DESC) AS "rank"
      FROM a) AS b
  WHERE b.rank = 1;
  ```

### Customer Behavior Analysis

- **Customer Who Spent the Most Money**:
  ```sql
  SELECT * FROM (
      SELECT 
          customer_id, customer_name, sales,
          RANK() OVER (ORDER BY sales DESC) AS "rank"
      FROM (
          SELECT 
              customers.customer_id,
              CONCAT(customers.first_name," ", customers.last_name) AS customer_name,
              SUM(order_items.quantity * (order_items.list_price - order_items.discount)) AS sales
          FROM
              customers
              JOIN orders ON customers.customer_id = orders.customer_id
              JOIN order_items ON order_items.order_id = orders.order_id
          GROUP BY customers.customer_id) AS a) AS b
  WHERE b.rank = 1;
  ```

- **Customers Who Ordered All Types of Products**:
  ```sql
  SELECT 
      customers.customer_id,
      CONCAT(customers.first_name, " ", customers.last_name) AS customers_name
  FROM customers 
  JOIN orders ON customers.customer_id = orders.customer_id
  JOIN order_items ON orders.order_id = order_items.order_id
  JOIN products ON order_items.product_id = products.product_id
  GROUP BY customers.customer_id, customers_name
  HAVING COUNT(DISTINCT products.category_id) = 
      (SELECT COUNT(category_id) FROM categories);
  ```

### Staff Performance Analysis

- **Staff Members with No Sales**:
  ```sql
  SELECT 
      staffs.staff_id,
      CONCAT(first_name, " ", last_name) AS staff_name
  FROM
      staffs
  WHERE
      NOT EXISTS( SELECT 
                  1
                  FROM orders
                  WHERE orders.staff_id = staffs.staff_id);
  ```

- **Staff Members with Sales Above Average**:
  ```sql
  SELECT
      staffs.staff_id,
      CONCAT(staffs.first_name, " ", staffs.last_name) AS staff_name,
      COALESCE(SUM(order_items.quantity * (order_items.list_price - order_items.discount)),0) AS total_sales
  FROM staffs 
  LEFT JOIN orders ON staffs.staff_id = orders.staff_id
  LEFT JOIN order_items ON orders.order_id = order_items.order_id
  GROUP BY staffs.staff_id
  HAVING SUM(order_items.quantity * (order_items.list_price - order_items.discount)) > (
      SELECT AVG(total_sales) FROM (
          SELECT 
              staffs.staff_id,
              CONCAT(staffs.first_name, " ", staffs.last_name) AS staff_name,
              COALESCE(SUM(order_items.quantity * (order_items.list_price - order_items.discount)),0) AS total_sales
          FROM staffs 
          LEFT JOIN orders ON staffs.staff_id = orders.staff_id
          LEFT JOIN order_items ON orders.order_id = order_items.order_id
          GROUP BY staffs.staff_id) AS a);
  ```

### Inventory Management

- **Top 3 Most Sold Products by Quantity**:
  ```sql
  SELECT
      product_id, product_name, total_quantities_sold
  FROM (
      SELECT
          products.product_id, products.product_name,
          SUM(order_items.quantity) AS total_quantities_sold,
          RANK() OVER (ORDER BY SUM(order_items.quantity) DESC) AS "rank"
      FROM 
          products
      JOIN order_items ON products.product_id = order_items.product_id
      GROUP BY products.product_id, products.product_name) AS a
  WHERE a.rank <= 3;
  ```

- **Median Value of the Price List**:
  ```sql
  WITH a AS (
      SELECT 
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
  ```

- **Products Never Ordered**:
  ```sql
  SELECT 
      product_id,
      product_name
  FROM
      products
  WHERE 
      NOT EXISTS(
          SELECT 1 FROM order_items
          WHERE order_items.product_id = products.product_id);
  ```

## Key Insights
- Identifying products with the highest sales and customers who spend the most helps in targeting marketing efforts and optimizing inventory.
- Finding staff members who are underperforming can guide training and incentives to improve overall sales.
- Monitoring cumulative sales data and top products ensures inventory is aligned with demand.

## Recommendations
- **Training Programs**: Provide training for staff with no sales and reward high performers.
- **Targeted Marketing**: Create personalized offers for top customers and promote top-selling products.
- **Inventory Management**: Discontinue products that have never been ordered and ensure top products are always in stock.

## Contact
For further information, please contact:

- **Email**: [ethendcosta5@gmail.com](mailto:ethendcosta5@gmail.com)
- **LinkedIn**: [ethendcosta](http://www.linkedin.com/in/ethendcosta)
```

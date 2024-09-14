# Case Study #1: Danny's Dinner
![CaseStudy#1](https://8weeksqlchallenge.com/images/case-study-designs/1.png)

## Table of Contents
- [Problem Statement](#problem_statement)
- [Entity Relationship Diagram](#entity_relationship_diagram)
- [Question and Solution](#question_and_solution)

Please note that all the information about the case study was obtain from the following source: [Case Study #1: Danny's Dinner](https://8weeksqlchallenge.com/case-study-1/)

***
## Problem Statement
Danny wants to analyze his customer data to understand their visiting patterns, spending habits, and favorite menu items. He aims to use these insights to enhance customer satisfaction and decide whether to expand his loyalty program. 

Danny has shared 3 key datasets to help you write SQL queries that can answer his questions:
- `sales`
- `menu`
- `members`

***
## Entity Relationship Diagram
![Danny's Diner](https://github.com/user-attachments/assets/d27c0912-d125-4c29-9f78-0a74acffa6ff)

***
## Question and Solution
**1. What is the total amount each customer spent at the restaurant?**
```sql
SELECT 
  sales.customer_id
  , SUM(menu.price) AS total_sales
FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC; 
```
**Step:**
- Use **JOIN** to merge `sales` and `menu` tables to extract information about customer_id and price from both tables.
- Use **SUM** to calculate the total amount that each customer has spent at the restaurant.
- Group the aggregate results by `sales.customer_id`.

**Answer:**
|customer_id|total_sales|
|---|---|
|A|76|
|B|74|
|C|36|

**2. How many days has each customer visited the restaurant?**
```sql
SELECT
    customer_id
    , COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
```
**Step:**
- Use **COUNT DISTINCT** to determine the unique number of visits for each customer
- Group aggregate results by `customer_id`

**Answer:**


**3. What was the first item from the menu purchased by each customer?**
```sql
WITH sales_order AS (
    SELECT
        customer_id
        , product_name
        , order_date
        , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS item_rank
    FROM sales
        LEFT JOIN menu ON sales.product_id = menu.product_id
)
SELECT 
    customer_id
    , product_name
FROM sales_order
WHERE item_rank = 1
GROUP BY
    customer_id
    , product_name;
```

**Step:**
- Create a Common Expression Table (CTE) name `sales_order` to store the joined data and calculate rank for each product.
- Within the CTE table, join the `sales` and `menu` tables to get product names and use **DENSE_RANK()** to assign a sequential rank to each product for a given customer, based on `order_date`.
- The main query selects only the rows from the `sales_order` CTE where the `item_rank` is 1, indicating the first product purchased by each customer.

**Answer:**


**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```sql
SELECT TOP 1
    product_name
    , COUNT(sales.product_id) AS total_orders
FROM sales
    LEFT JOIN menu ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY total_orders DESC;
```

**Step:**
    - Perform **COUNT** on `product_id` column to calculate the total number of orders for each product and then sort the results in the descending order to ensure the most puchased item appears first.
    - Filter with **TOP 1** in **SELECT** clause to limit the result set to top row, which is the most purchased item.

**Answer:**


**5. Which item was the most popular for each customer?**
```sql
WITH sales_order AS (
    SELECT
        customer_id
        , product_id
        , COUNT(product_id) AS item_count
        , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS item_rank
    FROM sales
    GROUP BY
        customer_id
        , product_id
)
SELECT 
    customer_id
    , product_name
    , item_count
FROM sales_order
    INNER JOIN menu ON sales_order.product_id = menu.product_id
WHERE item_rank = 1;
```

**Steps:**
- Create CTE named `sales_order` to store information about customer_id, product_id, and their respective item counts.
- In outer query, appropriate columns are selected and then joined with `menu` table to get the product name.
- Finally, filter out the most frequently purchase item for each customer by selecting only the rows where `item_rank` equals 1.

**Answer:**


**6. Which item was purchased first by the customer after they became a member?**
```sql
WITH joined_as_member AS (
    SELECT
        sales.customer_id
        , product_id
        , order_date
        , join_date
        , DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date ASC) AS rank
    FROM sales
        INNER JOIN members
            ON sales.customer_id = members.customer_id AND order_date >= join_date
)
SELECT
    joined_as_member.customer_id
    , product_name
FROM joined_as_member
    INNER JOIN menu ON joined_as_member.product_id = menu.product_id
WHERE rank = 1
GROUP BY
    customer_id
    , product_name;
```

**Step:**
- Create a CTE to tempotarily store information about customers and their order history after they became a member, in this case is the information of customer A and customer B.
- Within the CTE, use window function **DENSE_RANK()** to assign ranking for the first item purchased by each customer.
- In the `WHERE` clause, filter to retrieve only the rows equals 1, indicating the first row within each customer partition.

**Answer:**


**7. Which item was purchased just before the customer became a member?**
```sql
WITH purchased_prior_member AS (
    SELECT
        sales.customer_id
        , sales.product_id
        , order_date
        , DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date DESC) AS rank
    FROM sales
        INNER JOIN members
            ON sales.customer_id = members.customer_id AND sales.order_date < members.join_date
)
SELECT 
    p.customer_id
    , menu.product_name
FROM purchased_prior_member AS p
    INNER JOIN menu ON p.product_id = menu.product_id
WHERE rank = 1
ORDER BY p.customer_id;
```

**Step:**
- Create a CTE called `purchased_prior_member`.
- In CTE, join `sales` with `members` table based on `customer_id` column, only including orders that occured *before* the date the customers join as a member (`sales.order_date < members.join_date`).
- Also, create a rank column within the CTE to determine the first items based on the descending order of `order_date` for each customer.
- Join `purchased_prior_member` with `menu` table to get the `product_name`.
- Filter the result where rank equals 1 to get the name of the product that each customer bought before they became a member.
- Sort the result by `customer_id` in ascending order.

**Answer:**

**8. What is the total items and amount spent for each member before they became a member?**
```sql
SELECT
    sales.customer_id
    , COUNT(sales.product_id) AS total_items
    , SUM(menu.price) AS total_sales
FROM sales
    INNER JOIN members 
        ON sales.customer_id = members.customer_id AND sales.order_date < members.join_date
    INNER JOIN menu
        ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;
```

**Steps:**
- Join three `sales`, `members`, and `menu` together to retrieve information about total product sold, and total amount of revenue for each customer *before* they became a member.
- Use **COUNT** on `sales.product_id` column and **SUM** on `menu.price` column to calculate the total items purchased and total amount spent by each customer.
- Group the results by `sales.customer_id`.
- Sort the results by `sales.customer_id` in ascending order.

**Answer:**

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
WITH points_cte AS (
    SELECT
        customer_id
        , sales.product_id
        , product_name
        , price
        , CASE
            WHEN sales.product_id = 1 THEN price * 2 * 10
            ELSE price * 10
        END AS points
    FROM sales
        INNER JOIN menu ON sales.product_id = menu.product_id
)
SELECT
    customer_id
    , SUM(points) AS total_points
FROM points_cte
GROUP BY customer_id;
```

**Step:**
- Create a temporary result set to calculate points.
- Use **CASE** expression to determine the points earned for each product:
    - If the `product_id` is 1 (sushi), the points are doubled and multiplied by 10.
    - Otherwise, the points are simply multiplied by 10.
- In the main query, the points are aggregated for each customer to get their total points.

**Answer:**

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```sql
WITH dates_cte AS (
    SELECT
        sales.customer_id
        , join_date
        , order_date
        , sales.product_id
        , product_name
        , price
        , DATEADD(DAY, 6, join_date) AS valid_date
        , EOMONTH('2021-01-01') AS last_date_of_jan
    FROM sales
        INNER JOIN members
            ON sales.customer_id = members.customer_id AND sales.order_date >= members.join_date
        INNER JOIN menu
            ON sales.product_id = menu.product_id
)
SELECT
    customer_id
    , SUM(
        CASE
            WHEN order_date BETWEEN join_date AND valid_date THEN price * 2 * 10
            WHEN order_date > valid_date AND product_id = 1 THEN price * 2 * 10
            ELSE price * 10
        END
    ) AS total_points
FROM dates_cte
WHERE order_date <= last_date_of_jan
GROUP BY customer_id;
```

**Step:**
- Create a CTE called `dates_cte`:
    - Join the `sales`, `members`, and `menu` tables to get the customer information, product details, and prices.
    - Calculate a `valid_date` (6 days after) for each customer to indicate the first week since their `join_date` and a `last_date_of_jan` constant for filtering later.
- In the main query:
    - Use **CASE** and **SUM** expression to calculate the total points for each customer.
    - Filter the results to include only orders before or on the `last_date_of_jan`.
    - Group the results by `customer_id` to get the total points for each individual customer.
- Point calculation logic:
    - If the order_date is between the join_date and valid_date, the points are doubled and multiplied by 10.
    - If the order_date is after the valid_date and the product_id is 1, the points are doubled and multiplied by 10.
    - Otherwise, the points are simply multiplied by 10.




**Answer:**



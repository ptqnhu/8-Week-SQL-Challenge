-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
  sales.customer_id
  , SUM(menu.price) AS total_sales
FROM dannys_dinner.sales
    INNER JOIN dannys_dinner.menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;


-- 2. How many days has each customer visited the restaurant?

SELECT
    customer_id
    , COUNT(DISTINCT order_date) AS visit_count
FROM dannys_dinner.sales
GROUP BY customer_id
ORDER BY customer_id ASC;


-- 3. What was the first item from the menu purchased by each customer?

WITH sales_order AS (
    SELECT
        customer_id
        , product_name
        , order_date
        , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS item_rank
    FROM dannys_dinner.sales
        INNER JOIN dannys_dinner.menu ON sales.product_id = menu.product_id
)
SELECT 
    customer_id
    , product_name
FROM sales_order
WHERE item_rank = 1
GROUP BY
    customer_id
    , product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1
    product_name
    , COUNT(sales.product_id) AS total_orders
FROM dannys_dinner.sales
    LEFT JOIN dannys_dinner.menu ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY total_orders DESC;


-- 5. Which item was the most popular for each customer?

WITH sales_order AS (
    SELECT
        customer_id
        , product_id
        , COUNT(product_id) AS item_count
        , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS item_rank
    FROM dannys_dinner.sales
    GROUP BY
        customer_id
        , product_id
)
SELECT 
    customer_id
    , product_name
    , item_count
FROM sales_order
    INNER JOIN dannys_dinner.menu ON sales_order.product_id = menu.product_id
WHERE item_rank = 1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH joined_as_member AS (
    SELECT
        sales.customer_id
        , product_id
        , order_date
        , join_date
        , DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date ASC) AS rank
    FROM dannys_dinner.sales
        INNER JOIN dannys_dinner.members
            ON sales.customer_id = members.customer_id AND order_date >= join_date
)
SELECT
    customer_id
    , product_name
FROM joined_as_member
    INNER JOIN dannys_dinner.menu ON joined_as_member.product_id = menu.product_id
WHERE rank = 1
GROUP BY
    customer_id
    , product_name;


-- 7. Which item was purchased just before the customer became a member?

WITH purchased_prior_member AS (
    SELECT
        sales.customer_id
        , sales.product_id
        , order_date
        , DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date DESC) AS rank
    FROM dannys_dinner.sales
        INNER JOIN dannys_dinner.members
            ON sales.customer_id = members.customer_id AND sales.order_date < members.join_date
)
SELECT 
    p.customer_id
    , menu.product_name
FROM purchased_prior_member AS p
    INNER JOIN dannys_dinner.menu ON p.product_id = menu.product_id
WHERE rank = 1
ORDER BY p.customer_id;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
    sales.customer_id
    , COUNT(sales.product_id) AS total_items
    , SUM(menu.price) AS total_sales
FROM dannys_dinner.sales
    INNER JOIN dannys_dinner.members 
        ON sales.customer_id = members.customer_id AND sales.order_date < members.join_date
    INNER JOIN dannys_dinner.menu
        ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

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
    FROM dannys_dinner.sales
        INNER JOIN dannys_dinner.menu ON sales.product_id = menu.product_id
)
SELECT
    customer_id
    , SUM(points) AS total_points
FROM points_cte
GROUP BY customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

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
    FROM dannys_dinner.sales
        INNER JOIN dannys_dinner.members
            ON sales.customer_id = members.customer_id AND sales.order_date >= members.join_date
        INNER JOIN dannys_dinner.menu
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


-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT 
    sales.customer_id
    , sales.order_date
    , menu.product_name
    , menu.price
    , CASE
        WHEN members.join_date > sales.order_date THEN 'N'
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END AS member_status
FROM dannys_dinner.sales
    LEFT JOIN dannys_dinner.members
        ON sales.customer_id = members.customer_id
    INNER JOIN dannys_dinner.menu
        ON sales.product_id = menu.product_id
ORDER BY sales.customer_id ASC;


-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

WITH customers_data AS (
    SELECT 
        sales.customer_id
        , sales.order_date
        , menu.product_name
        , menu.price
        , CASE
            WHEN members.join_date > sales.order_date THEN 'N'
            WHEN members.join_date <= sales.order_date THEN 'Y'
            ELSE 'N'
        END AS member_status
    FROM dannys_dinner.sales
        LEFT JOIN dannys_dinner.members
            ON sales.customer_id = members.customer_id
        INNER JOIN dannys_dinner.menu
            ON sales.product_id = menu.product_id
)
SELECT 
    *, 
    CASE
        WHEN member_status = 'N' then NULL
        ELSE RANK() OVER (PARTITION BY customer_id, member_status ORDER BY order_date)
    END AS ranking
FROM customers_data;

SELECT
    order_id
    , customer_id
    , pizza_id
    , CASE
        WHEN exclusions LIKE '' OR exclusions LIKE 'null' THEN NULL
        ELSE exclusions
    END AS exclusions
    , CASE
        WHEN extras LIKE '' OR extras LIKE 'null' THEN NULL
        ELSE extras
    END AS extras
    , order_time
INTO ##customer_orders
FROM pizza_runner.customer_orders
;


SELECT
    order_id
    , runner_id
    , CASE
        WHEN pickup_time LIKE 'null' THEN NULL
        ELSE pickup_time
    END AS pickup_time
    , CASE
        WHEN distance LIKE 'null' THEN NULL
        WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
        WHEN distance LIKE '% km' THEN TRIM(' km' FROM distance)
        ELSE distance
    END AS distance
    , CASE
        WHEN duration LIKE 'null' THEN NULL
        WHEN duration LIKE '% minute' THEN TRIM(' minute' FROM duration)
        WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
        WHEN duration LIKE '% minutes' THEN TRIM(' minutes' FROM duration)
        WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
        WHEN duration LIKE '% mins' THEN TRIM(' mins' FROM duration)
        ELSE duration
    END AS duration
    , CASE
        WHEN cancellation LIKE '' OR cancellation LIKE 'null' THEN NULL
        ELSE cancellation
    END AS cancelltion
INTO ##runner_orders
FROM pizza_runner.runner_orders
;

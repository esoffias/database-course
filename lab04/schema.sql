SELECT 
    category_id,
    title,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS row_num,
    RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS rank_num,
    DENSE_RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS dense_rank_num
FROM products
LIMIT 20;


WITH RankedProducts AS (
    SELECT 
        category_id,
        title,
        price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
)
SELECT * 
FROM RankedProducts
WHERE rn <= 3;


SELECT 
    created_at::date AS order_date,
    SUM(total_amount) AS daily_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY created_at::date) AS running_total
FROM orders
GROUP BY created_at::date
ORDER BY order_date;


SELECT 
    category_id,
    seller_id,
    SUM(price) AS seller_category_sum,
    SUM(SUM(price)) OVER (PARTITION BY category_id) AS total_category_sum,
    ROUND((SUM(price) * 100.0) / SUM(SUM(price)) OVER (PARTITION BY category_id), 2) AS percentage
FROM products
GROUP BY category_id, seller_id;




WITH DailyRevenue AS (
    SELECT 
        created_at::date AS order_date,
        SUM(total_amount) AS daily_sum
    FROM orders
    GROUP BY created_at::date
)
SELECT 
    order_date,
    daily_sum,
    LAG(daily_sum) OVER (ORDER BY order_date) AS prev_day_sum,
    daily_sum - LAG(daily_sum) OVER (ORDER BY order_date) AS growth
FROM DailyRevenue;




SELECT 
    title, 
    category_id, 
    price,
    AVG(price) OVER (PARTITION BY category_id) AS avg_category_price
FROM products
LIMIT 10;



SELECT 
    p.title, 
    p.category_id, 
    p.price,
    c.avg_price
FROM products p
JOIN (
    SELECT category_id, AVG(price) AS avg_price 
    FROM products 
    GROUP BY category_id
) c ON p.category_id = c.category_id
LIMIT 10;
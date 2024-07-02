/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-------------------------------------------------------------------------
-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) as total_amount
from sales as s
left join menu as m
on s.product_id = m.product_id
group by customer_id
order by customer_id

-- results
+──────────────+──────────────+
| customer_id  | total_spent  |
+──────────────+──────────────+
| A            | 76           |
| B            | 74           |
| C            | 36           |
+──────────────+──────────────+

-------------------------------------------------------------------------
-- 2. How many days has each customer visited the restaurant?

Select customer_id, COUNT(distinct order_date) as visited_Days
from sales
group by customer_id

-- results
+──────────────+───────────────+
| customer_id  | visited_days  |
+──────────────+───────────────+
| A            | 4             |
| B            | 6             |
| C            | 2             |
+──────────────+───────────────+

-------------------------------------------------------------------------
-- 3. What was the first item from the menu purchased by each customer?

with order_cte as (
	Select sales.customer_id, menu.product_name,
	ROW_NUMBER() over (
		partition by sales.customer_id
		order by sales.order_date, sales.product_id
		) as item_order
	from sales join menu on
	sales.product_id = menu.product_id
	)
select *
from order_cte
where item_order = 1

-- results
+──────────────+───────────────+─────────────+
| customer_id  | product_name  | item_order  |
+──────────────+───────────────+─────────────+
| A            | sushi         | 1           |
| B            | curry         | 1           |
| C            | ramen         | 1           |
+──────────────+───────────────+─────────────+

-------------------------------------------------------------------------
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select TOP 1 menu.product_name, count(sales.order_date) as freq
from menu 
join sales on menu.product_id = sales.product_id
group by product_name
order by freq desc

--results
+───────────────+──────────────+
| product_name  | order_count  |
+───────────────+──────────────+
| ramen         | 8            |
+───────────────+──────────────+

-------------------------------------------------------------------------
-- 5. Which item was the most popular for each customer?

with cte_order_count as (
	Select sales.customer_id, menu.product_name, COUNT(*) as order_count
	from sales 
	inner join menu on 
	menu.product_id = sales.product_id
	group by customer_id, menu.product_name
	),
cte_populer_Rank as (
	select *,
	RANK() over(partition by customer_id order by order_count desc) as rank
	from cte_order_count
	)
select * from cte_populer_Rank
where rank = 1

--results
+──────────────+───────────────+──────────────+───────+
| customer_id  | product_name  | order_count  | rank  |
+──────────────+───────────────+──────────────+───────+
| A            | ramen         | 3            | 1     |
| B            | ramen         | 2            | 1     |
| B            | curry         | 2            | 1     |
| B            | sushi         | 2            | 1     |
| C            | ramen         | 3            | 1     |
+──────────────+───────────────+──────────────+───────+


-------------------------------------------------------------------------
-- I created a membership_validation table to validate only those customers joining in the membership program
DROP table if exists #membership_validation
select
	sales.customer_id,
	sales.order_date,
	menu.product_name,
	menu.price,
	members.join_date,
CASE when sales.order_date >= members.join_date then 'x' else '' end as membership
into #membership_validation
from sales
inner join menu on menu.product_id = sales.product_id
left join members on members.customer_id = sales.customer_id
where members.join_date is not null
ORDER BY customer_id, order_date

/*
select * from #membership_validation
order by customer_id, order_date
*/

-------------------------------------------------------------------------
-- 6. Which item was purchased first by the customer after they became a member?

;with cte_firstby as (
	select
		customer_id,
		product_name,
		order_date,
		RANK() over(
		PARTITION by customer_id
		order by order_date
		) as purchase_order
		from #membership_validation
		where membership = 'X'
		)
select * from cte_firstby
where purchase_order = 1

-- results
+──────────────+───────────────+─────────────+─────────────────+
| customer_id  | product_name  | order_date  | purchase_order  |
+──────────────+───────────────+─────────────+─────────────────+
| A            | curry         | 2021-01-07  | 1               |
| B            | sushi         | 2021-01-11  | 1               |
+──────────────+───────────────+─────────────+─────────────────+

-------------------------------------------------------------------------
-- 7. Which item was purchased just before the customer became a member?

;with cte_beforeby as (
	select
		customer_id,
		product_name,
		order_date,
		RANK() over(
		PARTITION by customer_id
		order by order_date desc
		) as purchase_order
		from #membership_validation
		where membership = ''
		)
select * from cte_beforeby
where purchase_order = 1

--results
+──────────────+───────────────+─────────────+─────────────────+
| customer_id  | product_name  | order_date  | purchase_order  |
+──────────────+───────────────+─────────────+─────────────────+
| A            | sushi         | 2021-01-01  | 1               |
| A            | curry         | 2021-01-01  | 1               |
| B            | sushi         | 2021-01-04  | 1               |
+──────────────+───────────────+─────────────+─────────────────+

-------------------------------------------------------------------------
-- 8. What is the total items and amount spent for each member before they became a member?

;with cte_spent as (
	select
		customer_id,
		product_name,
		price
		from #membership_validation
		where membership = ''
		)

	select 
		customer_id,
		SUM(price) as total_price,
		COUNT(*) as total_item
		from cte_spent
		group by customer_id
		order by customer_id
-- results
+──────────────+──────────────+──────────────+
| customer_id  | total_spent  | total_items  |
+──────────────+──────────────+──────────────+
| A            | 25           | 2            |
| B            | 40           | 3            |
+──────────────+──────────────+──────────────+

-------------------------------------------------------------------------
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
	
select 
	customer_id,
	SUM(
		case when product_name = 'sushi'
		then (price * 20)
		else (price * 10)
		end
	) as total_points
from #membership_validation
group by customer_id
order by customer_id

--results
+──────────────+───────────────+
| customer_id  | total_points  |
+──────────────+───────────────+
| A            | 860           |
| B            | 940           |
+──────────────+───────────────+

-------------------------------------------------------------------------
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

DROP TABLE IF EXISTS #membership_first_week_validation;

;WITH cte_valid AS (
  SELECT
    customer_id,
    order_date,
    product_name,
    price,
    COUNT(*) AS order_count,
    CASE 
      WHEN order_date BETWEEN join_date AND DATEADD(day, 6, join_date)
      THEN 'X'
      ELSE ''
    END AS within_first_week
  FROM #membership_validation
  GROUP BY 
    customer_id,
    order_date,
    product_name,
    price,
    join_date
)
SELECT *
INTO #membership_first_week_validation
FROM cte_valid
WHERE order_date < '2021-02-01';

SELECT * 
FROM #membership_first_week_validation;



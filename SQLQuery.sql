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

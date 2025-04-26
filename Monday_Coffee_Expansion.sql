create database monday_coffee_expansion; 

use monday_coffee_expansion;

select * from city;
select * from customers;
select * from products;
select * from sales;

-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
	select city_name,population,(population/4) as people_consuming from city
	order by (population/4) desc;

-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
	select c.city_name,sum(total) as Total_Sales from sales s
	inner join customers ct
	on s.customer_id = ct.customer_id
	inner join city c
	on ct.city_id = c.city_id
	where datepart(quarter,s.sale_date) = 4
	and datepart(YEAR,s.sale_date) = 2023
	group by c.city_name;
	
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
	select s.product_id,p.product_name,count(s.product_id) as count_units from sales s
	inner join products p 
	on s.product_id = p.product_id
	group by s.product_id,p.product_name
	order by count_units desc;

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
	select ct.customer_name,c.city_name,avg(s.total) as Avg_Sales from customers ct
	inner join sales s
	on ct.customer_id = s.customer_id
	inner join city c
	on ct.city_id = c.city_id
	group by ct.customer_name,c.city_name;

-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
	select city_name,population,(population/4) as Estimated_Consumers from city;

-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
	with sale_volume_product as(
	select c.city_name,p.product_name,sum(total) as Total_sales,
	row_number() over(partition by city_name order by sum(total) desc) as rn from sales s
	inner join products p
	on s.product_id = p.product_id
	inner join customers ct
	on ct.customer_id = s.customer_id
	inner join city c
	on c.city_id = ct.city_id
	group by c.city_name,p.product_name)
	select city_name,product_name,Total_sales
	from sale_volume_product where rn <= 3;

-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
	select c.city_name,p.product_name,count(distinct ct.customer_name) as customer_count from customers ct
	inner join city c
	on c.city_id = ct.city_id
	inner join sales s
	on s.customer_id = ct.customer_id
	inner join products p
	on p.product_id = s.product_id
	group by c.city_name,p.product_name
	order by c.city_name,count(distinct ct.customer_name) desc;

-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
	select ct.customer_name,c.city_name,AVG(s.total) as avg_sale,avg(c.estimated_rent) as avg_rent from sales s
	inner join customers ct
	on ct.customer_id = s.customer_id
	inner join products p
	on p.product_id = s.product_id
	inner join city c
	on c.city_id = ct.city_id
	group by ct.customer_name,c.city_name
	order by avg(s.total) desc, avg(c.estimated_rent) desc;

-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

	with total_sales as(
	select format(sale_date,'yyyy-MM') as month,sum(total) as total_sales from sales
	group by format(sale_date,'yyyy-MM')),
	previous_month as(
	select month,total_sales,lag(total_sales,1) over(order by month) as previous_month from total_sales)
	select *,(case when previous_month = NUll then 0 else
	cast((total_sales - previous_month)/100 as decimal(10,2))  end) as percentage_growth
	from previous_month;

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with cust_sales as(
	select c.city_id,c.city_name as City_Name,
	sum(s.total) as Total_Sales,
	count(distinct ct.customer_id) as Total_Customers,
	sum(s.total)/count(distinct ct.customer_id) as Avg_Sale_Cust
	from customers ct
	inner join sales s
	on ct.customer_id = s.customer_id
	inner join city c
	on c.city_id = ct.city_id
	group by c.city_id,c.city_name),
city_rent as(
	select c.city_id,c.city_name as City_Name,
	sum(c.estimated_rent) as Estimated_Rent,
	sum(c.population)/4 as Estimated_Population
	from city c
	group by c.city_id,c.city_name)
select cs.City_Name,Total_Sales,Total_Customers,Avg_Sale_Cust,
Estimated_Rent, Estimated_Population from cust_sales cs
inner join city_rent cr
on cs.city_id = cr.city_id
order by Total_Sales desc;
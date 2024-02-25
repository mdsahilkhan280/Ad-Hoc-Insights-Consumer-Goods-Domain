#Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct(market) as list_of_market
from dim_customer
where customer= 'Atliq Exclusive';


#What is the percentage of unique product increase in 2021 vs. 2020?
with A as(
select count(distinct product_code) as unique_2020
from fact_sales_monthly
where fiscal_year=2020
),
B as (
select count(distinct product_code) as unique_2021
from fact_sales_monthly
where fiscal_year=2021)
select A.unique_2020 , B.unique_2021, ((B.unique_2021- A.unique_2020)*100/B.unique_2021) as pct_change
from A,B;

#Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
select segment, count(distinct product_code) as cnt
from dim_product
group by segment
order by cnt desc;

#Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
with A as
(select p.segment,count(distinct s.product_code) as unique2020
from dim_product p
join fact_sales_monthly s
using(product_code)
where fiscal_year=2020
group by p.segment),
B as
(select p.segment,count(distinct s.product_code) as unique2021
from dim_product p
join fact_sales_monthly s
using(product_code)
where fiscal_year=2021
group by p.segment)
select A.segment,unique2020,unique2021,abs(unique2021-unique2020) as difference
from A
join B 
using(segment)
order by difference desc;

#Get the products that have the highest and lowest manufacturing costs.
select product,manufacturing_cost
from fact_manufacturing_cost m
join dim_product p
using(product_code)
where m.manufacturing_cost =(select max(manufacturing_cost) from fact_manufacturing_cost) 
or m.manufacturing_cost =(select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;


#Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
select c.customer_code,customer,pre.pre_invoice_discount_pct
from fact_pre_invoice_deductions pre
join dim_customer c
using(customer_code)
where fiscal_year=2021 and market="India" and pre_invoice_discount_pct>(select avg(pre_invoice_discount_pct) from fact_pre_invoice_deductions)
order by pre.pre_invoice_discount_pct desc
limit 5;

#Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions
select monthname(s.date) as month, s.fiscal_year, 
sum(round(gr.gross_price*s.sold_quantity,2)) as gross_total
from fact_sales_monthly s
join fact_gross_price gr
using(fiscal_year,product_code)
join dim_customer c
using(customer_code)
where c.customer="Atliq Exclusive"
group by month, fiscal_year
order by fiscal_year;

#In which quarter of 2020, got the maximum total_sold_quantity
select 
case when month(date) in(9,10,11) then "Q1"
	when month(date) in(12,1,2) then "Q2"
    when month(date) in(3,4,5) then "Q3"
	when month(date) in(6,7,8) then "Q4"
    end as Qtr, sum(sold_quantity) as total_quantity_sold
from fact_sales_monthly
where fiscal_year=2020
group by Qtr 
order by total_quantity_sold desc;

#Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
with A as(
select c.channel,round(sum(gr.gross_price*s.sold_quantity)/1000000,2)as gross_total_mln
from fact_sales_monthly s
join fact_gross_price gr
using(fiscal_year,product_code)
join dim_customer c
using(customer_code)
where fiscal_year=2021
group by c.channel
order by gross_total_mln desc
)
select *, round(gross_total_mln*100/sum(gross_total_mln) over(),2) as pct
from A;

#Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021
with A as(
select p.division,s.product_code,p.product,sum(s.sold_quantity) as total_sold_quantity,
row_number() over (partition by division order by sum(sold_quantity) desc) as rnk
from fact_sales_monthly s
join dim_product p
using(product_code)
where fiscal_year=2021
group by p.division,s.product_code,p.product)
select * from A
where rnk<=3
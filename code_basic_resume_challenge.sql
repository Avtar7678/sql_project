/*1 Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/
select  market as unique_market_list
          from dim_customer
          where customer='Atliq Exclusive' and region="apac"
          group by market;

/*2 What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/

WITH count_of_unique AS (
        SELECT 
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN fact_sales_monthly.product_code END) AS unique_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN fact_sales_monthly.product_code END) AS unique_2021 
        FROM dim_product
        INNER JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
        )
       SELECT 
       unique_2020,
       unique_2021,
       ((unique_2021 / unique_2020)*100)-100 AS percentage_change
       FROM count_of_unique;
       
 /*3 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/
 
 select segment , count(distinct product_code) as product_count 
                      from dim_product group by segment 
                      order by count(distinct product_code) desc;
/*4  Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

with unique_product
        as(select count(distinct case when fiscal_year=2020 then fact_sales_monthly.product_code end) as product_count_2020,
        count(distinct case when fiscal_year=2021 then fact_sales_monthly.product_code end) as product_count_2021,
        segment
        from dim_product
        inner join fact_sales_monthly on dim_product.product_code=fact_sales_monthly.product_code
        group by segment)
        select segment,
       product_count_2020,
       product_count_2021,
       product_count_2021-product_count_2020 as difference
       from unique_product
       order by difference desc
       ;
 /*5 Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

 
 select fact_manufacturing_cost.product_code,dim_product.product,fact_manufacturing_cost.manufacturing_cost
                    from fact_manufacturing_cost
                    inner join dim_product on dim_product.product_code= fact_manufacturing_cost.product_code
                    where fact_manufacturing_cost.manufacturing_cost in((select max(fact_manufacturing_cost.manufacturing_cost) from fact_manufacturing_cost),
                    (select min(fact_manufacturing_cost.manufacturing_cost) from fact_manufacturing_cost))
                    order by manufacturing_cost desc;
                    
/*6 Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/
select fact_pre_invoice_deductions.customer_code ,
       dim_customer.customer,
       avg(fact_pre_invoice_deductions.pre_invoice_discount_pct)*100
       as avg_discount_percentage
       from fact_pre_invoice_deductions
       inner join dim_customer on fact_pre_invoice_deductions.customer_code=dim_customer.customer_code
       where fact_pre_invoice_deductions.fiscal_year=2021 and market="india"
       group by customer
       order by avg(fact_pre_invoice_deductions.pre_invoice_discount_pct) desc
        limit 5;
        
/*7 Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

SELECT MONTHNAME(FSM.date) month, YEAR(FSM.date) year,
                   SUM(FSM.sold_quantity*FGP.gross_price) gross_sales_amount
                   FROM fact_sales_monthly FSM
                   LEFT JOIN fact_gross_price FGP ON FGP.product_code = FSM.product_code
                   LEFT JOIN dim_customer DC ON DC.customer_code = FSM.customer_code
                   WHERE DC.customer = 'Atliq Exclusive'
                   GROUP BY month, year
                   ORDER BY year, MONTH(date);
                   
                   
 /*8 In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */
 select quarter(date) as quarter,sum(sold_quantity) as total_sold_quantity 
                    from fact_sales_monthly 
                    where year(date)=2020
                    group by quarter(date)
                    order by total_sold_quantity desc
                    ;
 /*9 Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/
   with highest_contributions as (
        select dim_customer.channel as channel,
        fact_sales_monthly.sold_quantity * fact_gross_price.gross_price as gross_sales
        from fact_sales_monthly
        inner join dim_customer on fact_sales_monthly.customer_code = dim_customer.customer_code
        inner join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
        where fact_sales_monthly.fiscal_year = 2021) 
        select channel,
       sum(gross_sales) as total_gross_sales,
       sum(gross_sales) / total_sales * 100 as percentage_contribution
       from highest_contributions
       cross join (select sum(gross_sales) as total_sales from highest_contributions) as t
       group by channel;

/*10 Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code */

 WITH rank_cte AS (
        SELECT DP.division,DP.product_code,DP.product,
        SUM(FSM.sold_quantity) total_sold_quantity,
        ROW_NUMBER() OVER(PARTITION BY DP.division ORDER BY SUM(FSM.sold_quantity) DESC) rank_order
        FROM fact_sales_monthly FSM
        LEFT JOIN dim_product DP ON DP.product_code = FSM.product_code
        WHERE FSM.fiscal_year = '2021'
        GROUP BY DP.division,DP.product_code,DP.product
        )
        SELECT division,product_code,product,total_sold_quantity,rank_order
        FROM rank_cte
        WHERE rank_order <= 3;      

          
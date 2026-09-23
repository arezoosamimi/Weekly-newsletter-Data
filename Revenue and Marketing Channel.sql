

select fiscal_year, fiscal_week, sum(revenue) as revenue, sum(orders) orders , sum(revenue)/sum(orders) as AOV, 
CAST(SUM(quantity) AS DECIMAL(10,2)) / NULLIF(SUM(orders), 0) as UPT, sum(loyalty_redemption_gross) loyalty_redemption_gross, sum(pre_order_products_available) pre_order_products_available,
sum(new_customers) new_customers,sum(omni_customers) omni_customers, sum(enrolled) enrolled, sum(digital_enrolled) digital_enrolled,
sum(retail_enrolled) retail_enrolled, max(total_enrolled) total_enrolled ,sum(international_digital_revenue) international_digital_revenue ,
sum(spend) spend, sum(sessions) sessions, sum(sends) sends,sum(target) target, sum(stretch_target) stretch_target, sum(support_cases_opened) support_cases_opened, 
sum(discounts) as discounts, sum(gross_sales) as gross_sales, sum(sfs_revenue) sfs_revenue, sum(a.bopis_revenue ) as bopis_revenue, 
sum(sdd_revenue) sdd_revenue,sum(a.sts_revenue) as sts_revenue, sum(international_digital_revenue)/sum(revenue) as int_perc
from silver.sil_post_alo_daily_metrics a join bronze.br_dates b on a.date = b.date_dt where fiscal_year >=2024 group by 1,2 order by 1,2;

select fiscal_year, fiscal_week, --app_vs_web, 
channel, sum(ga_revenue) as revenue, sum(total_orders) as orders, sum(sessions) as sessions, sum(cost) as cost,
sum(digital_customers_acquired) as acq, sum(daily_revenue_target_channel) as target_revenue
from silver.sil_post_bq_channel_performance a join bronze.br_dates b on a.date = b.date_dt where fiscal_year >=2025 
and brand_vs_ecomm = 'ecomm'
group by 1,2,3 order by 1,2;
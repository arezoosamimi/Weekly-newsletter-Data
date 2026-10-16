-- Aloversary Dashboard 2026 — SQL extracted from Hex notebook

-- ============================================================
-- Query 1 (notebook cell 11)
-- ============================================================
/*
  Customers acquired during Aloversary 2025 (4/26 - 5/2) who returned for Aloversary 2026 (5/2 - 5/8).

  This query identifies customers whose very first purchase (digital or retail) was during
  the 2025 Aloversary sale period, then checks how many of them came back and shopped
  during the 2026 Aloversary sale period.

  Returns the count of these returning customers and their total 2026 Aloversary revenue.
*/
with order_attribution as ( -- Sometimes a single order can have line items attributed to both digital and retail. Most commonly, this happens when a digital order is exchanged in store. 
							--Here, each such order is attributed to digital, as that was the original sale channel 
	select od.order_id, 
			min(od.customer_id) as customer_id,
			min(olid.digital_vs_retail) as order_source,
			min(olid.order_processed_at_pst) as order_processed_at_pst
	from analytics_silver.sil_shopify_order_line_items_dim olid 
	join analytics_silver.sil_shopify_order_dim od 
	on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
	and od.order_id is not null
	group by 1
	),
	ranking as ( -- Ranks each order based on when it was placed and by which channel it was placed through
	select order_id, 
			customer_id,
			order_source,
			order_processed_at_pst,
			dense_rank()
            	OVER (PARTITION BY customer_id ORDER BY order_processed_at_pst ASC)
        	AS order_rank,
        	dense_rank()
            	OVER (PARTITION BY customer_id, order_source ORDER BY order_processed_at_pst ASC)
        	AS source_rank
     from order_attribution
	),
	acquired_holiday_ly as (
	select customer_id
	from ranking 
	where order_rank = 1
	and order_processed_at_pst::date between '2025-04-26' and '2025-05-02'
	)
select count(distinct od.customer_id), sum(olif.subtotal_ordered_usd_less_duties)
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid 
on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od 
on olid.order_id = od.order_id
join acquired_holiday_ly ah
on ah.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 2 (notebook cell 12)
-- ============================================================
/*
  Returning 2025 sale shoppers during Aloversary 2026 (5/2/2026 - 5/8/2026).

  This query identifies customers who:
    1. Shopped during any 2025 sale event (Aloversary, Early Access, Singles Day, or BFCM)
    2. Then came back and shopped during the 2026 Aloversary sale period

  Returns the count of these customers and their total 2026 Aloversary revenue.
*/
with shopped_2025_sales as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst in (
		-- Aloversary 2025
		'2025-04-26','2025-04-27','2025-04-28','2025-04-29','2025-04-30','2025-05-01','2025-05-02',
		-- Early Access 2025
		'2025-10-27','2025-10-28','2025-10-29',
		-- Singles Day 2025
		'2025-11-11','2025-11-12','2025-11-13','2025-11-14','2025-11-15',
		-- BFCM 2025
		'2025-11-24','2025-11-25','2025-11-26','2025-11-27','2025-11-28','2025-11-29','2025-11-30','2025-12-01','2025-12-02'
	)
	and olid.digital_vs_retail in ('digital', 'retail')
	and od.customer_id is not null
)
select
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
join shopped_2025_sales s
	on s.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 3 (notebook cell 13)
-- ============================================================
/*
  Customers acquired during Aloversary 2025 (4/26 - 5/2) who returned for Aloversary 2026 (5/2 - 5/8).

  This query identifies customers whose very first purchase (digital or retail) was during
  the 2025 Aloversary sale period, then checks how many of them came back and shopped
  during the 2026 Aloversary sale period.

  Returns the count of these returning customers and their total 2026 Aloversary revenue.
*/
with order_attribution as (
	select od.order_id, 
			min(od.customer_id) as customer_id,
			min(olid.digital_vs_retail) as order_source,
			min(olid.order_processed_at_pst) as order_processed_at_pst
	from analytics_silver.sil_shopify_order_line_items_dim olid 
	join analytics_silver.sil_shopify_order_dim od 
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.order_id is not null
	group by 1
),
ranking as (
	select order_id, 
			customer_id,
			order_source,
			order_processed_at_pst,
			dense_rank()
				OVER (PARTITION BY customer_id ORDER BY order_processed_at_pst ASC)
			AS order_rank,
			dense_rank()
				OVER (PARTITION BY customer_id, order_source ORDER BY order_processed_at_pst ASC)
			AS source_rank
	from order_attribution
),
acquired_aloversary_2025 as (
	select customer_id
	from ranking
	where order_rank = 1
		and order_processed_at_pst::date between '2025-04-26' and '2025-05-02'
)
select
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid 
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od 
	on olid.order_id = od.order_id
join acquired_aloversary_2025 a
	on a.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 4 (notebook cell 14)
-- ============================================================
/*
  New customers acquired during any 2025 sale event who returned for Aloversary 2026 (5/2/2026 - 5/8/2026).

  This query identifies customers who:
    1. Made their very first Alo purchase during a 2025 sale event (Aloversary, Early Access, Singles Day, or BFCM)
    2. Then came back and shopped during the 2026 Aloversary sale period

  Returns the count of these customers and their total 2026 Aloversary revenue.
*/
with first_orders as (
	select od.customer_id,
			min(olid.order_processed_date_pst) as first_order_date
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
acquired_2025_sales as (
	select customer_id
	from first_orders
	where first_order_date in (
		-- Aloversary 2025
		'2025-04-26','2025-04-27','2025-04-28','2025-04-29','2025-04-30','2025-05-01','2025-05-02',
		-- Early Access 2025
		'2025-10-27','2025-10-28','2025-10-29',
		-- Singles Day 2025
		'2025-11-11','2025-11-12','2025-11-13','2025-11-14','2025-11-15',
		-- BFCM 2025
		'2025-11-24','2025-11-25','2025-11-26','2025-11-27','2025-11-28','2025-11-29','2025-11-30','2025-12-01','2025-12-02'
	)
)
select
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
join acquired_2025_sales a
	on a.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 5 (notebook cell 15)
-- ============================================================
/*
  Reactivated lapsed customers during Aloversary 2026 (5/2 - 5/8).

  This query identifies customers who had purchased at some point before 5/2/2025,
  made no purchases (digital or retail) in the 12 months leading up to the sale
  (5/2/2025 - 5/1/2026), and then came back and shopped during the Aloversary
  sale period.

  Returns the count of these reactivated customers and their total Aloversary revenue.
*/
with order_attribution as (
	select od.order_id,
			min(od.customer_id) as customer_id,
			min(olid.digital_vs_retail) as order_source,
			min(olid.order_processed_at_pst) as order_processed_at_pst
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.order_id is not null
	group by 1
),
customers_prior_to_l12m as (
	select distinct customer_id
	from order_attribution
	where order_processed_at_pst::date < '2025-05-02'
),
purchased_l12m as (
	select distinct customer_id
	from order_attribution
	where order_processed_at_pst::date >= '2025-05-02'
		and order_processed_at_pst::date < '2026-05-02'
),
lapsed_customers as (
	select cp.customer_id
	from customers_prior_to_l12m cp
	left join purchased_l12m pl
		on cp.customer_id = pl.customer_id
	where pl.customer_id is null
)
select
	olid.order_processed_date_pst as sale_date,
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
join lapsed_customers lc
	on lc.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail')
group by 1
order by 1;

-- ============================================================
-- Query 6 (notebook cell 16)
-- ============================================================
/*
  Reactivated lapsed customers during Aloversary 2026 (5/2 - 5/8).

  This query identifies customers who had purchased at some point before 5/2/2025,
  made no purchases (digital or retail) in the 12 months leading up to the sale
  (5/2/2025 - 5/1/2026), and then came back and shopped during the Aloversary
  sale period.

  Returns the count of these reactivated customers and their total Aloversary revenue.


  Same CTEs as before, then attribute each reactivated customer
  to their first Aloversary purchase day only.

*/
with order_attribution as (
	select od.order_id,
			min(od.customer_id) as customer_id,
			min(olid.digital_vs_retail) as order_source,
			min(olid.order_processed_at_pst) as order_processed_at_pst
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.order_id is not null
	group by 1
),
customers_prior_to_l12m as (
	select distinct customer_id
	from order_attribution
	where order_processed_at_pst::date < '2025-05-02'
),
purchased_l12m as (
	select distinct customer_id
	from order_attribution
	where order_processed_at_pst::date >= '2025-05-02'
		and order_processed_at_pst::date < '2026-05-02'
),
lapsed_customers as (
	select cp.customer_id
	from customers_prior_to_l12m cp
	left join purchased_l12m pl
		on cp.customer_id = pl.customer_id
	where pl.customer_id is null
), first_aloversary_purchase as (
	select
		od.customer_id,
		min(olid.order_processed_date_pst) as first_sale_date
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join lapsed_customers lc
		on lc.customer_id = od.customer_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
	group by 1
)
select
	first_sale_date,
	count(*) as new_reactivated_customers
from first_aloversary_purchase
group by 1
order by 1;

-- ============================================================
-- Query 7 (notebook cell 18)
-- ============================================================
/*
  Top 10% spenders in the last 12 months who shopped during Aloversary 2026 (5/2 - 5/8).

  This query ranks all customers by total spend (digital and retail) over the 12 months
  prior to the sale (5/2/2025 - 5/1/2026), identifies those in the top 10% by spend,
  and then checks how many of them shopped during the Aloversary sale period.

  Returns the count of these high-value customers and their total Aloversary revenue.
*/
with spend_per_customer as (
	select od.customer_id,
			sum(olif.subtotal_ordered_usd_less_duties) as spend,
			row_number() over (order by sum(olif.subtotal_ordered_usd_less_duties) desc) as customer_rank
	from analytics_silver.sil_shopify_order_line_item_facts olif
	join analytics_silver.sil_shopify_order_line_items_dim olid
		on olif.line_items_id = olid.line_items_id
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst >= '2025-05-02'
		and olid.order_processed_date_pst < '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
spend_cutoff as (
	select spend as cutoff
	from spend_per_customer
	where customer_rank = (select ceil(count(*) * 0.1) from spend_per_customer)
),
top_10_pct_customers as (
	select customer_id
	from spend_per_customer
	where spend >= (select cutoff from spend_cutoff)
)
select
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
join top_10_pct_customers t
	on t.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 8 (notebook cell 19)
-- ============================================================
/*
  Reactivated high-value lapsed customers during the sale period (5/2/2026 - 5/8/2026).

  This query identifies customers who:
    1. Were in the top 10% of all-time spend prior to 5/2/2025
    2. Made no purchases (digital or retail) in the 12 months leading up to the sale (5/2/2025 - 5/1/2026)
    3. Then came back and shopped during the sale period

  Returns the count of these customers and their total sale period revenue.
*/

with spend_per_customer as (
	select od.customer_id,
			sum(olif.subtotal_ordered_usd_less_duties) as spend,
			row_number() over (order by sum(olif.subtotal_ordered_usd_less_duties) desc) as customer_rank
	from analytics_silver.sil_shopify_order_line_item_facts olif
	join analytics_silver.sil_shopify_order_line_items_dim olid
		on olif.line_items_id = olid.line_items_id
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst < '2025-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
spend_cutoff as (
	select spend as cutoff
	from spend_per_customer
	where customer_rank = (select ceil(count(*) * 0.1) from spend_per_customer)
),
top_10_pct_customers as (
	select customer_id
	from spend_per_customer
	where spend >= (select cutoff from spend_cutoff)
),
purchased_l12m as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst >= '2025-05-02'
		and olid.order_processed_date_pst < '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
),
top_10_lapsed as (
	select t.customer_id
	from top_10_pct_customers t
	left join purchased_l12m p
		on t.customer_id = p.customer_id
	where p.customer_id is null
)
select
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
join top_10_lapsed t
	on t.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 9 (notebook cell 20)
-- ============================================================
/*
  Repeat purchasers during Aloversary 2026 (5/2 - 5/8).

  Counts the number of customers (digital and retail) who placed more than one
  distinct order during the Aloversary sale period.
*/
with sale_orders as (
	select od.customer_id,
			count(distinct od.order_id) as order_count
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
	having count(distinct od.order_id) > 1
)
select count(*) as customer_count
from sale_orders;

-- ============================================================
-- Query 10 (notebook cell 21)
-- ============================================================
/*
  Customers who shopped all three prior Aloversary events (2023, 2024, and 2025)
  and also shopped during Aloversary 2026 (5/2 - 5/8).

  Counts the number of customers (digital and retail) who made at least one purchase
  during each of the last three Aloversary sale periods and then returned for this year's:
    - 2023: 4/29 - 5/5
    - 2024: 4/27 - 5/3
    - 2025: 4/26 - 5/2
    - 2026: 5/2 - 5/8
*/
with aloversary_shoppers as (
	select od.customer_id,
			case
				when olid.order_processed_date_pst between '2023-04-29' and '2023-05-05' then 2023
				when olid.order_processed_date_pst between '2024-04-27' and '2024-05-03' then 2024
				when olid.order_processed_date_pst between '2025-04-26' and '2025-05-02' then 2025
			end as aloversary_year
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and (
			olid.order_processed_date_pst between '2023-04-29' and '2023-05-05' 
            or olid.order_processed_date_pst between '2024-04-27' and '2024-05-03'
			or olid.order_processed_date_pst between '2025-04-26' and '2025-05-02'
		)
),
all_three_years as (
	select customer_id
	from aloversary_shoppers
	group by 1
	having count(distinct aloversary_year) = 3
),
shopped_aloversary_2026 as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
)
select count(*) as customer_count
from all_three_years a
join shopped_aloversary_2026 s
	on a.customer_id = s.customer_id;

-- ============================================================
-- Query 11 (notebook cell 22)
-- ============================================================
/*
  Customers who shopped both prior Aloversary events (2024 and 2025)
  and also shopped during Aloversary 2026 (5/2 - 5/8).
*/
with aloversary_shoppers as (
	select od.customer_id,
			case
				when olid.order_processed_date_pst between '2024-04-27' and '2024-05-03' then 2024
				when olid.order_processed_date_pst between '2025-04-26' and '2025-05-02' then 2025
			end as aloversary_year
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and (
			olid.order_processed_date_pst between '2024-04-27' and '2024-05-03'
			or olid.order_processed_date_pst between '2025-04-26' and '2025-05-02'
		)
),
both_years as (
	select customer_id
	from aloversary_shoppers
	group by 1
	having count(distinct aloversary_year) = 2
),
shopped_aloversary_2026 as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
)
select count(*) as customer_count
from both_years a
join shopped_aloversary_2026 s
	on a.customer_id = s.customer_id;

-- ============================================================
-- Query 12 (notebook cell 23)
-- ============================================================
/*
  Customers who shopped during any sale event (Aloversary, Early Access, Singles Day, or BFCM)
  in all three years (2023, 2024, 2025), and then also shopped during Aloversary 2026 (5/2 - 5/8).
  Returns 5 examples.
*/
with sale_shoppers as (
	select od.customer_id,
			case
				-- 2023
				when olid.order_processed_date_pst in (
					'2023-04-29','2023-04-30','2023-05-01','2023-05-02','2023-05-03','2023-05-04','2023-05-05',
					'2023-10-30','2023-10-31','2023-11-01',
					'2023-11-07','2023-11-08','2023-11-09','2023-11-10','2023-11-11',
					'2023-11-20','2023-11-21','2023-11-22','2023-11-23','2023-11-24','2023-11-25','2023-11-26','2023-11-27','2023-11-28'
				) then 2023
				-- 2024
				when olid.order_processed_date_pst in (
					'2024-04-27','2024-04-28','2024-04-29','2024-04-30','2024-05-01','2024-05-02','2024-05-03',
					'2024-10-28','2024-10-29','2024-10-30',
					'2024-11-11','2024-11-12','2024-11-13','2024-11-14','2024-11-15',
					'2024-11-25','2024-11-26','2024-11-27','2024-11-28','2024-11-29','2024-11-30','2024-12-01','2024-12-02','2024-12-03'
				) then 2024
				-- 2025
				when olid.order_processed_date_pst in (
					'2025-04-26','2025-04-27','2025-04-28','2025-04-29','2025-04-30','2025-05-01','2025-05-02',
					'2025-10-27','2025-10-28','2025-10-29',
					'2025-11-11','2025-11-12','2025-11-13','2025-11-14','2025-11-15',
					'2025-11-24','2025-11-25','2025-11-26','2025-11-27','2025-11-28','2025-11-29','2025-11-30','2025-12-01','2025-12-02'
				) then 2025
			end as sale_year
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
),
all_three_years as (
	select customer_id
	from sale_shoppers
	where sale_year is not null
	group by 1
	having count(distinct sale_year) = 3
),
shopped_aloversary_2026 as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
)
select a.customer_id
from all_three_years a
join shopped_aloversary_2026 s
	on a.customer_id = s.customer_id
limit 5;

-- ============================================================
-- Query 13 (notebook cell 24)
-- ============================================================
/*
  Daily new-to-app customer breakdown during Aloversary 2026 (5/2 - 5/8).

  This query identifies customers whose first-ever app purchase (platform_adj = 'app')
  occurred during the Aloversary sale period, broken out by day. Each customer is also
  classified as "new" or "returning" based on whether this was their first Alo purchase
  overall (across any channel), not just their first app purchase.

  Excludes gift cards, lion discounts, GWP items, and cancelled orders.

  Returns a daily count of distinct first-time app customers, split by order date,
  new vs returning status, channel (digital/retail), and platform.
*/

with ranking AS (
                select
                    o.order_id,
                    d.customer_id,
                    dense_rank()
                        OVER (PARTITION BY d.customer_id ORDER BY d.order_processed_at_pst ASC)
                    AS order_rank
                from analytics_silver.sil_shopify_order_line_items_dim as d
                left join analytics_silver.sil_shopify_order_dim as o on d.order_id = o.order_id
                where gift_card is false
                and is_lion_discount_applied is false
                and d.is_item_gwp_adj is false
                and d.cancelled_at is null
                and d.customer_id is not null
                and digital_vs_retail in ('digital', 'retail')
                group by o.order_id, d.customer_id, d.order_processed_at_pst
), 
app as (
select distinct d.customer_id,order_processed_date_pst as order_date, bd.fiscal_year,bd.fiscal_month,digital_vs_retail as source, bd.fiscal_week ,
case when r.order_rank=1 then 'new' else 'returning' end as new_vs_returning,platform_adj,
dense_rank()
    OVER (PARTITION BY d.customer_id ORDER BY d.order_processed_at_pst ASC)
AS app_order_rank
from analytics_silver.sil_shopify_order_line_items_dim d
left join analytics_silver.sil_shopify_order_dim od
on d.order_id = od.order_id
left join analytics_silver.sil_shopify_order_line_item_facts f
on d.line_items_id = f.line_items_id
left join analytics_bronze.br_dates bd
on d.order_processed_date_pst=bd.date_dt
left join ranking r
on d.order_id=r.order_id
and d.customer_id=r.customer_id
where 
gift_card is false
                and d.is_lion_discount_applied is false
                and d.is_item_gwp_adj is false
                and d.cancelled_at is null
                and digital_vs_retail in ('digital', 'retail')
                and digital_vs_retail!='gift_card'
                and platform_adj='app'
and bd.fiscal_year >=2026
and d.order_processed_at_pst::date between '2026-05-02' and '2026-05-08'
group by d.customer_id , d.order_id,d.order_processed_at_pst, order_processed_date_pst,od.destination_country, bd.fiscal_year, bd.fiscal_month , bd.fiscal_week, digital_vs_retail, r.order_rank, platform_adj
)
select order_date, new_vs_returning,source,platform_adj, count(distinct customer_id) as customers
from app
where app_order_rank=1
group by order_date, new_vs_returning, source, platform_adj;

-- ============================================================
-- Query 14 (notebook cell 25)
-- ============================================================
/*
  Customers who had never purchased on the app before Aloversary 2026,
  and made their first app purchase during the sale period (5/2 - 5/8).
*/
with first_time_app_customers as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and od.platform_adj = 'app'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
),
prior_app_customers as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where od.platform_adj = 'app'
		and olid.order_processed_date_pst < '2026-05-02'
		and od.customer_id is not null
)
select count(*) as customer_count
from first_time_app_customers f
left join prior_app_customers p
	on f.customer_id = p.customer_id
where p.customer_id is null;

-- ============================================================
-- Query 15 (notebook cell 26)
-- ============================================================
/*
  Customers who shopped all 4 Aloversary sales (2023-2025 any channel),
  but whose Aloversary 2026 purchase was their FIRST EVER app purchase.
  Returns 5 examples.
*/
with aloversary_shoppers as (
	select od.customer_id,
			case
				when olid.order_processed_date_pst between '2023-04-29' and '2023-05-05' then 2023
				when olid.order_processed_date_pst between '2024-04-27' and '2024-05-03' then 2024
				when olid.order_processed_date_pst between '2025-04-26' and '2025-05-02' then 2025
				when olid.order_processed_date_pst between '2026-05-02' and '2026-05-08' then 2026
			end as aloversary_year
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and (
			olid.order_processed_date_pst between '2023-04-29' and '2023-05-05'
			or olid.order_processed_date_pst between '2024-04-27' and '2024-05-03'
			or olid.order_processed_date_pst between '2025-04-26' and '2025-05-02'
			or olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		)
),
all_four_years as (
	select customer_id
	from aloversary_shoppers
	group by 1
	having count(distinct aloversary_year) = 4
),
-- customers who purchased on app during aloversary 2026
app_purchasers_2026 as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_dim od
	join analytics_silver.sil_shopify_order_line_items_dim olid
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and od.platform_adj = 'app'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
),
-- customers who have EVER purchased on app before aloversary 2026
prior_app_purchasers as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_dim od
	join analytics_silver.sil_shopify_order_line_items_dim olid
		on olid.order_id = od.order_id
	where od.platform_adj = 'app'
		and olid.order_processed_date_pst < '2026-05-02'
		and od.customer_id is not null
)
select
	a.customer_id,
	gmc."first_name",
	gmc."last_name",
	gmc."city",
	gmc."state",
	gmc."country",
	gmc."loyalty_tier_name",
	gmc."shopify_total_sales",
	gmc."order_total_count",
	gmc."first_order_date",
	gmc."top_category"
from all_four_years a
join app_purchasers_2026 ap
	on a.customer_id = ap.customer_id
left join prior_app_purchasers pap
	on a.customer_id = pap.customer_id
left join dev.analytics_gold.gold_marketing_customers gmc
	on a.customer_id = gmc."shopify_customer_id"
where pap.customer_id is null
order by gmc."shopify_total_sales" desc
limit 6;

-- ============================================================
-- Query 16 (notebook cell 27)
-- ============================================================
/*
  New-to-app customers during Aloversary 2026 (5/2/2026 - 5/8/2026) who also purchased in store.

  This query identifies customers who:
    1. Made their first-ever app order (ga_platform = 'app') during the Aloversary sale period
    2. Also made at least one retail (in-store) purchase during that same sale period
    3. Includes total revenue for the sale period (both digital and retail)

  Returns the count of these customers and their total sale period revenue (across all channels).
*/
with first_app_order as (
	select od.customer_id,
			min(olid.order_processed_date_pst) as first_app_date
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where od.platform_adj = 'app'
		and od.customer_id is not null
	group by 1
),
new_to_app_during_sale as (
	select customer_id
	from first_app_order
	where first_app_date between '2026-05-02' and '2026-05-08'
),
also_shopped_retail as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail = 'retail'
		and od.customer_id is not null
),
new_app_and_retail as (
	select n.customer_id
	from new_to_app_during_sale n
	join also_shopped_retail r
		on n.customer_id = r.customer_id
)
select
	count(distinct od.customer_id) as customer_count,
	sum(olif.subtotal_ordered_usd_less_duties) as total_revenue
from analytics_silver.sil_shopify_order_line_item_facts olif
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olif.line_items_id = olid.line_items_id
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
join new_app_and_retail na
	on na.customer_id = od.customer_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 17 (notebook cell 28)
-- ============================================================
/*
  Customers who shopped during every Aloversary sale period
  (2023, 2024, 2025, and 2026). Full profile pull for trend analysis.
*/
with aloversary_shoppers as (
	select od.customer_id,
			case
				when olid.order_processed_date_pst between '2023-04-29' and '2023-05-05' then 2023
				when olid.order_processed_date_pst between '2024-04-27' and '2024-05-03' then 2024
				when olid.order_processed_date_pst between '2025-04-26' and '2025-05-02' then 2025
				when olid.order_processed_date_pst between '2026-05-02' and '2026-05-08' then 2026
			end as aloversary_year
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and (
			olid.order_processed_date_pst between '2023-04-29' and '2023-05-05'
			or olid.order_processed_date_pst between '2024-04-27' and '2024-05-03'
			or olid.order_processed_date_pst between '2025-04-26' and '2025-05-02'
			or olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		)
),
all_four_years as (
	select customer_id
	from aloversary_shoppers
	group by 1
	having count(distinct aloversary_year) = 4
)
select
	a.customer_id,
	gmc."first_name",
	gmc."last_name",
	gmc."country",
	gmc."state",
	gmc."city",
	gmc."loyalty_tier_name",
	gmc."loyalty_points_approved",
	gmc."loyalty_points_lifetime",
	gmc."shopify_total_sales",
	gmc."order_total_count",
	gmc."first_order_date",
	gmc."last_order_date",
	gmc."top_category",
	gmc."second_category",
	gmc."third_category",
	gmc."shopped_pos_only",
	gmc."shopped_web_only",
	gmc."shopped_in_store",
	gmc."last_purchase_source",
	gmc."order_item_count_women",
	gmc."order_item_count_men",
	gmc."order_item_count_beauty",
	gmc."order_item_count_other",
	gmc."order_item_percent_women",
	gmc."order_item_percent_men",
	gmc."order_item_percent_beauty",
	gmc."shopify_email_marketing_consent",
	gmc."sms_subscriber",
	gmc."has_app_downloaded",
	gmc."has_loyalty_tier"
from all_four_years a
left join dev.analytics_gold.gold_marketing_customers gmc
	on a.customer_id = gmc."shopify_customer_id"
order by gmc."shopify_total_sales" desc;

-- ============================================================
-- Query 18 (notebook cell 29)
-- ============================================================
/*
  Potential reseller flags among Aloversary 2026 shoppers.
  
  Flags customers who meet ANY of:
    - 100+ lifetime orders
    - $50K+ lifetime spend
    - Top category is an accessory (Socks, Caps, Visors, Hats, Headbands)
    - Kept 20+ of a single item in one order during Aloversary 2026
  
  The more flags a customer hits, the more likely they are reselling.
*/
with aloversary_2026_shoppers as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
),
bulk_buyers as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join analytics_silver.sil_shopify_order_line_item_facts f
		on olid.line_items_id = f.line_items_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and f.quantity_kept > 15
)
select
	a.customer_id,
	gmc."first_name",
	gmc."last_name",
	gmc."city",
	gmc."state",
	gmc."country",
	gmc."order_total_count",
	gmc."shopify_total_sales",
	gmc."top_category",
	gmc."loyalty_tier_name",
	gmc."first_order_date",
	gmc."last_order_date",
	gmc."shopped_in_store",
	gmc."last_purchase_source",
	case when gmc."order_total_count" >= 100 then 1 else 0 end as flag_high_order_count,
	case when gmc."shopify_total_sales" >= 50000 then 1 else 0 end as flag_high_spend,
	case when gmc."top_category" in ('Socks', 'Caps', 'Visors', 'Hats', 'Headbands') then 1 else 0 end as flag_accessory_heavy,
	case when bb.customer_id is not null then 1 else 0 end as flag_bulk_quantity,
	(
		case when gmc."order_total_count" >= 100 then 1 else 0 end
		+ case when gmc."shopify_total_sales" >= 50000 then 1 else 0 end
		+ case when gmc."top_category" in ('Socks', 'Caps', 'Visors', 'Hats', 'Headbands') then 1 else 0 end
		+ case when bb.customer_id is not null then 1 else 0 end
	) as total_flags
from aloversary_2026_shoppers a
left join dev.analytics_gold.gold_marketing_customers gmc
	on a.customer_id = gmc."shopify_customer_id"
left join bulk_buyers bb
	on a.customer_id = bb.customer_id
where gmc."order_total_count" >= 100
	or gmc."shopify_total_sales" >= 50000
	or gmc."top_category" in ('Socks', 'Caps', 'Visors', 'Hats', 'Headbands')
	or bb.customer_id is not null
order by total_flags desc, gmc."shopify_total_sales" desc;

-- ============================================================
-- Query 19 (notebook cell 30)
-- ============================================================
/*
  Aloversary 2026 spend for potential resellers (2+ flags).

*/
with aloversary_2026_spend as (
	select
		od.customer_id,
		sum(olid.product_price) as aloversary_2026_spend,
		count(distinct od.order_id) as aloversary_2026_orders
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
flagged_customers as (
	select
		a26.customer_id,
		gmc."order_total_count",
		gmc."shopify_total_sales",
		gmc."top_category",
		case when gmc."order_total_count" >= 100 then 1 else 0 end
			+ case when gmc."shopify_total_sales" >= 50000 then 1 else 0 end
			+ case when gmc."top_category" in ('Socks', 'Caps', 'Visors', 'Hats', 'Headbands') then 1 else 0 end as total_flags
	from aloversary_2026_spend a26
	left join dev.analytics_gold.gold_marketing_customers gmc
		on a26.customer_id = gmc."shopify_customer_id"
)
select
	f.customer_id,
	a.aloversary_2026_spend,
	a.aloversary_2026_orders
from flagged_customers f
join aloversary_2026_spend a
	on f.customer_id = a.customer_id
where f.total_flags >= 2
order by a.aloversary_2026_spend desc;

-- ============================================================
-- Query 20 (notebook cell 31)
-- ============================================================
/*
  First customer to transact online (digital) on  5/2/2026 and what they purchased.
*/
select od.customer_id,
		olid.order_processed_at_pst,
		od.order_id,
		olid.product_title,
		olid.variant_title,
		olid.color,
		olid.product_size,
		olid.sku
from analytics_silver.sil_shopify_order_line_items_dim olid
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
where olid.order_processed_date_pst = '2026-05-02'
	and olid.digital_vs_retail = 'digital'
	and od.customer_id is not null
order by olid.order_processed_at_pst asc
limit 20;

-- ============================================================
-- Query 21 (notebook cell 32)
-- ============================================================
/*
  Top 8 customers by total spend during Aloversary 2026 and their purchased items.
*/
with top_spenders as (
	select od.customer_id,
			sum(olif.subtotal_ordered_usd_less_duties) as total_spend
	from analytics_silver.sil_shopify_order_line_item_facts olif
	join analytics_silver.sil_shopify_order_line_items_dim olid
		on olif.line_items_id = olid.line_items_id
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
	order by 2 desc
	limit 8
)
select ts.customer_id,
		ts.total_spend,
		olid.order_processed_date_pst,
		olid.digital_vs_retail,
		olid.product_title,
		olid.variant_title,
		olid.color,
		olid.product_size,
		olid.sku,
		olif.subtotal_ordered_usd_less_duties as line_item_revenue
from top_spenders ts
join analytics_silver.sil_shopify_order_dim od
	on ts.customer_id = od.customer_id
join analytics_silver.sil_shopify_order_line_items_dim olid
	on od.order_id = olid.order_id
join analytics_silver.sil_shopify_order_line_item_facts olif
	on olid.line_items_id = olif.line_items_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail')
order by ts.total_spend desc, ts.customer_id, olid.order_processed_at_pst;

-- ============================================================
-- Query 22 (notebook cell 33)
-- ============================================================
/*
  Top 5 new customers (first-ever purchase during the sale) for Hong Kong and Australia,
  ranked by sale period spend.
*/
with first_orders as (
	select od.customer_id,
			min(olid.order_processed_date_pst) as first_order_date
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
new_during_sale as (
	select customer_id
	from first_orders
	where first_order_date between '2026-05-02' and '2026-05-08'
),
new_customer_spend as (
	select od.customer_id,
			od.attributed_country_code,
			sum(olif.subtotal_ordered_usd_less_duties) as total_spend
	from analytics_silver.sil_shopify_order_line_item_facts olif
	join analytics_silver.sil_shopify_order_line_items_dim olid
		on olif.line_items_id = olid.line_items_id
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join new_during_sale n
		on n.customer_id = od.customer_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.attributed_country_code in ('HK', 'AU')
	group by 1, 2
),
ranked as (
	select customer_id,
			attributed_country_code,
			total_spend,
			row_number() over (partition by attributed_country_code order by total_spend desc) as rn
	from new_customer_spend
)
select customer_id,
		attributed_country_code,
		total_spend
from ranked
where rn <= 5
order by attributed_country_code, total_spend desc;

-- ============================================================
-- Query 23 (notebook cell 34)
-- ============================================================
/*
  Customers who ONLY purchased Accolade products before Aloversary 2026,
  then purchased Suit Up or Match Point during the sale period (5/2 - 5/8).
  Returns 5 examples with profile details and sale period info.
*/
with pre_sale_customers as (
	select od.customer_id,
			count(distinct od.order_id) as historical_orders,
			sum(f.subtotal_ordered_usd_less_duties) as historical_revenue,
			max(case when olid.product_title ilike '%accolade%' then 1 else 0 end) as bought_accolade,
			max(case when olid.product_title not ilike '%accolade%' then 1 else 0 end) as bought_non_accolade
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join analytics_silver.sil_shopify_order_line_item_facts f
		on olid.line_items_id = f.line_items_id
	where olid.order_processed_date_pst < '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
accolade_only as (
	select customer_id, historical_orders, historical_revenue
	from pre_sale_customers
	where bought_accolade = 1
		and bought_non_accolade = 0
),
sale_stats as (
	select od.customer_id,
			count(distinct od.order_id) as sale_orders,
			sum(f.subtotal_ordered_usd_less_duties) as sale_revenue
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join analytics_silver.sil_shopify_order_line_item_facts f
		on olid.line_items_id = f.line_items_id
	where olid.order_processed_date_pst >= '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and (olid.product_title ilike '%suit up%' or olid.product_title ilike '%match point%')
	group by 1
),
sale_products as (
	select od.customer_id,
			listagg(distinct olid.product_title, ', ') within group (order by olid.product_title) as products_purchased
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst >= '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and (olid.product_title ilike '%suit up%' or olid.product_title ilike '%match point%')
	group by 1
)
select
	ao.customer_id,
	gmc."first_name",
	gmc."last_name",
	gmc."city",
	gmc."state",
	gmc."country",
	gmc."loyalty_tier_name",
	gmc."first_order_date",
	ao.historical_orders,
	ao.historical_revenue,
	ss.sale_orders,
	ss.sale_revenue,
	sp.products_purchased
from accolade_only ao
join sale_stats ss
	on ao.customer_id = ss.customer_id
join sale_products sp
	on ao.customer_id = sp.customer_id
left join dev.analytics_gold.gold_marketing_customers gmc
	on ao.customer_id = gmc."shopify_customer_id"
order by ao.historical_orders desc
limit 5;

-- ============================================================
-- Query 24 (notebook cell 35)
-- ============================================================
/*
  Fallback: Accolade-only customers who bought ANYTHING non-Accolade
  during Aloversary 2026.
*/
with pre_sale_customers as (
	select od.customer_id,
			count(distinct od.order_id) as historical_orders,
			sum(f.subtotal_ordered_usd_less_duties) as historical_revenue,
			max(case when olid.product_title ilike '%accolade%' then 1 else 0 end) as bought_accolade,
			max(case when olid.product_title not ilike '%accolade%' then 1 else 0 end) as bought_non_accolade
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join analytics_silver.sil_shopify_order_line_item_facts f
		on olid.line_items_id = f.line_items_id
	where olid.order_processed_date_pst < '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
accolade_only as (
	select customer_id, historical_orders, historical_revenue
	from pre_sale_customers
	where bought_accolade = 1
		and bought_non_accolade = 0
),
sale_stats as (
	select od.customer_id,
			count(distinct od.order_id) as sale_orders,
			sum(f.subtotal_ordered_usd_less_duties) as sale_revenue
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	join analytics_silver.sil_shopify_order_line_item_facts f
		on olid.line_items_id = f.line_items_id
	where olid.order_processed_date_pst >= '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and olid.product_title not ilike '%accolade%'
	group by 1
),
sale_products as (
	select od.customer_id,
			listagg(distinct olid.product_title, ', ') within group (order by olid.product_title) as products_purchased
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst >= '2026-05-02'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and olid.product_title not ilike '%accolade%'
	group by 1
)
select
	ao.customer_id,
	gmc."first_name",
	gmc."last_name",
	gmc."city",
	gmc."state",
	gmc."country",
	gmc."loyalty_tier_name",
	gmc."first_order_date",
	ao.historical_orders,
	ao.historical_revenue,
	ss.sale_orders,
	ss.sale_revenue,
	sp.products_purchased
from accolade_only ao
join sale_stats ss
	on ao.customer_id = ss.customer_id
join sale_products sp
	on ao.customer_id = sp.customer_id
left join dev.analytics_gold.gold_marketing_customers gmc
	on ao.customer_id = gmc."shopify_customer_id"
order by ao.historical_orders desc
limit 5;

-- ============================================================
-- Query 25 (notebook cell 36)
-- ============================================================
select
	od.customer_id,
	olid.order_id,
	olid.order_processed_date_pst,
	olid.product_title,
	olid.sku,
	olid.color,
	olid.product_size,
	olid.product_price,
	olid.digital_vs_retail,
	case
		when olid.order_processed_date_pst < '2026-05-02' then 'pre-aloversary'
		else 'aloversary-2026'
	end as period
from analytics_silver.sil_shopify_order_line_items_dim olid
join analytics_silver.sil_shopify_order_dim od
	on olid.order_id = od.order_id
where od.customer_id in (
	'6766071382196',
	'8583540539751',
	'8687289893223',
	'7558007226548',
	'6370715140276',
	'6773818589364',
	'8641165033831',
	'6803505873076',
	'6722992439476'
)
and olid.digital_vs_retail in ('digital', 'retail')
order by od.customer_id, olid.order_processed_date_pst;

-- ============================================================
-- Query 26 (notebook cell 37)
-- ============================================================
/*
  Channel crossover and omni-channel customers during Aloversary 2026 (5/2/2026 - 5/8/2026).

  Returns four metrics:
    1. Retail-only customers who made their first-ever digital purchase during the sale
    2. Digital-only customers who made their first-ever retail purchase during the sale
    3. Total new omni customers (sum of the two above)
    4. Total customers who shopped both digital and retail during the sale period (regardless of history)

*/
with customer_channel_history as (
    select od.customer_id,
            max(case when olid.digital_vs_retail = 'digital' then 1 else 0 end) as has_digital,
            max(case when olid.digital_vs_retail = 'retail' then 1 else 0 end) as has_retail
    from analytics_silver.sil_shopify_order_line_items_dim olid
    join analytics_silver.sil_shopify_order_dim od
        on olid.order_id = od.order_id
    where olid.digital_vs_retail in ('digital', 'retail')
        and od.customer_id is not null
        and olid.order_processed_date_pst < '2026-05-02'
    group by 1
),
sale_period_channels as (
    select od.customer_id,
            max(case when olid.digital_vs_retail = 'digital' then 1 else 0 end) as shopped_digital_sale,
            max(case when olid.digital_vs_retail = 'retail' then 1 else 0 end) as shopped_retail_sale
    from analytics_silver.sil_shopify_order_line_items_dim olid
    join analytics_silver.sil_shopify_order_dim od
        on olid.order_id = od.order_id
    where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
        and olid.digital_vs_retail in ('digital', 'retail')
        and od.customer_id is not null
    group by 1
)
select
    sum(case when ch.has_digital = 0 and ch.has_retail = 1 and sp.shopped_digital_sale = 1 then 1 else 0 end) as retail_only_first_digital,
    sum(case when ch.has_retail = 0 and ch.has_digital = 1 and sp.shopped_retail_sale = 1 then 1 else 0 end) as digital_only_first_retail,
    sum(case when ch.has_digital = 0 and ch.has_retail = 1 and sp.shopped_digital_sale = 1 then 1 else 0 end)
        + sum(case when ch.has_retail = 0 and ch.has_digital = 1 and sp.shopped_retail_sale = 1 then 1 else 0 end) as total_new_omni,
    sum(case when sp.shopped_digital_sale = 1 and sp.shopped_retail_sale = 1 then 1 else 0 end) as both_channels_during_sale
from sale_period_channels sp
left join customer_channel_history ch
    on sp.customer_id = ch.customer_id;

-- ============================================================
-- Query 27 (notebook cell 38)
-- ============================================================
/*
  Omni-channel customer count during Aloversary 2026 (5/2/2026 - 5/8/2026) and their Revenue breakdown.

  Returns four metrics:
    1. Total customers who shopped both digital and retail during the sale period (regardless of history)
    2. Digital revenue
    3. Retail revenue
    4. Total revenue

*/
with customer_channel_history as (
	select od.customer_id,
			max(case when olid.digital_vs_retail = 'digital' then 1 else 0 end) as has_digital,
			max(case when olid.digital_vs_retail = 'retail' then 1 else 0 end) as has_retail
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and olid.order_processed_date_pst < '2026-05-02'
	group by 1
),
sale_period_channels as (
	select od.customer_id,
			max(case when olid.digital_vs_retail = 'digital' then 1 else 0 end) as shopped_digital_sale,
			max(case when olid.digital_vs_retail = 'retail' then 1 else 0 end) as shopped_retail_sale
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
	group by 1
),
both_channel_customers as (
	select sp.customer_id
	from sale_period_channels sp
	where sp.shopped_digital_sale = 1
		and sp.shopped_retail_sale = 1
)
select
	count(distinct od.customer_id) as customer_count,
	sum(case when olid.digital_vs_retail = 'digital' then f.subtotal_ordered_usd_less_duties else 0 end) as digital_revenue,
	sum(case when olid.digital_vs_retail = 'retail' then f.subtotal_ordered_usd_less_duties else 0 end) as retail_revenue,
	sum(f.subtotal_ordered_usd_less_duties) as total_revenue
from both_channel_customers bc
join analytics_silver.sil_shopify_order_dim od
	on bc.customer_id = od.customer_id
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olid.order_id = od.order_id
join analytics_silver.sil_shopify_order_line_item_facts f
	on olid.line_items_id = f.line_items_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 28 (notebook cell 39)
-- ============================================================
/*
  Customers who had only ever shopped retail (POS) before Aloversary 2026,
  and made their first digital purchase during the sale period (5/2 - 5/8).
  Includes their total Aloversary 2026 revenue (digital only, since that's the new channel).
*/
with retail_only_customers as (
	select od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.digital_vs_retail in ('digital', 'retail')
		and od.customer_id is not null
		and olid.order_processed_date_pst < '2026-05-02'
	group by 1
	having count(distinct olid.digital_vs_retail) = 1
		and max(olid.digital_vs_retail) = 'retail'
),
shopped_digital_aloversary as (
	select distinct od.customer_id
	from analytics_silver.sil_shopify_order_line_items_dim olid
	join analytics_silver.sil_shopify_order_dim od
		on olid.order_id = od.order_id
	where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
		and olid.digital_vs_retail = 'digital'
		and od.customer_id is not null
),
crossover_customers as (
	select r.customer_id
	from retail_only_customers r
	join shopped_digital_aloversary d
		on r.customer_id = d.customer_id
)
select
	count(distinct od.customer_id) as customer_count,
	sum(f.subtotal_ordered_usd_less_duties) as total_revenue
from crossover_customers cc
join analytics_silver.sil_shopify_order_dim od
	on cc.customer_id = od.customer_id
join analytics_silver.sil_shopify_order_line_items_dim olid
	on olid.order_id = od.order_id
join analytics_silver.sil_shopify_order_line_item_facts f
	on olid.line_items_id = f.line_items_id
where olid.order_processed_date_pst between '2026-05-02' and '2026-05-08'
	and olid.digital_vs_retail in ('digital', 'retail');

-- ============================================================
-- Query 29 (notebook cell 40)
-- ============================================================
/*
  Loyalty enrollment sign-ups by country during Aloversary 2026 (5/2 - 5/8).
*/
select
	country,
	count(*) as enrollments
from analytics.silver.sil_customer_dim
where enrolled_at_date between '2026-05-02' and '2026-05-08'
	and enrolled = true
group by 1
order by 2 desc;

/*
   Query Name: Capsule 1st Week Product Performance
   Owner: Christian Labenberg
   Purpose: Look at top performing product titles in a capsule
   Cadence: Every other week, to review the 1st week of a capsule launch
   Source Tables: gold_omni_order_line_item_detail, and logic based on what products are in the capsule (reference content planning docs for capsule product list)
   Output: product title performance within capsule in specified date range
   Assumptions: Filtered to digital only; no redemptions or GWP
   Automation Notes: would require a file with list of capsule products for future drops
*/

SELECT
    product_title,
    SUM(gross_sales_usd - line_item_duties_usd - total_discounts_usd) AS revenue
FROM analytics_gold.gold_omni_order_line_item_detail
WHERE digital_vs_retail = 'digital'
  AND order_date BETWEEN '2026-08-30' AND '2026-09-05'
  AND is_item_gwp_adj = false
  AND is_lion_discount_applied = false
  AND product_title ILIKE '%Airbrush Lock In%'
GROUP BY 1
ORDER BY 2 DESC;

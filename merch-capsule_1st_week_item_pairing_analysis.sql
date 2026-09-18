/*
   Query Name: Capsule Within-Item Pairing Analysis
   Owner: Christian Labenberg
   Purpose: Identify which pairs of items within the same capsule are most often purchased together in the same order
   Cadence: Every other week, to review the 1st week of a capsule launch
   Source Tables: gold_omni_order_line_item_detail, and logic based on what products are in the capsule (reference content planning docs for capsule product list)
   Output: every pairwise combination of capsule product titles, with the count and percentage of capsule orders containing that pair
   Assumptions: Filtered to digital only; no redemptions or GWP
   Automation Notes: would require a file with list of capsule products for future drops
*/

WITH capsule_orders AS (
    SELECT DISTINCT order_id, product_title
    FROM analytics_gold.gold_omni_order_line_item_detail
    WHERE digital_vs_retail = 'digital'
      AND order_date BETWEEN '2026-08-30' AND '2026-09-05'
      AND product_title IN (
          'Airbrush Lock In Bra - California Blue',
          'Airbrush Lock In Bra - White',
          'Airbrush Lock In Bra - Black',
          'Airbrush Lock In Bra Tank - California Blue',
          'Airbrush Lock In Bra Tank - Black',
          'Airbrush Lock In Tennis Dress - California Blue',
          'Airbrush Lock In Tennis Dress - White',
          'Airbrush Lock In Tennis Dress - Black'
      )
),
total AS (
    SELECT COUNT(DISTINCT order_id) AS total_orders FROM capsule_orders
)
SELECT
    a.product_title AS item_a,
    b.product_title AS item_b,
    COUNT(DISTINCT a.order_id) AS order_count,
    t.total_orders,
    ROUND(100.0 * COUNT(DISTINCT a.order_id) / t.total_orders, 2) AS pct_of_capsule_orders
FROM capsule_orders a
JOIN capsule_orders b
    ON a.order_id = b.order_id
    AND a.product_title < b.product_title  -- avoids duplicate pairs and self-pairs
CROSS JOIN total t
GROUP BY 1, 2, t.total_orders
ORDER BY 3 DESC;

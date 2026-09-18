SELECT
    f.date,
    f.channel,
    SUM(f.session_last_clicked) AS sessions,
    SUM(f.view_item) AS view_item,
    SUM(f.page_view) AS page_view,
    SUM(f.add_to_cart) AS atc,
    SUM(f.begin_checkout) AS begin_checkout,
    SUM(f.purchase) AS purchase
FROM gold.gold_purchase_funnel AS f
LEFT JOIN (
    SELECT DISTINCT bq.campaign
    FROM silver.sil_post_bq_channel_performance AS bq
    WHERE bq.brand_vs_ecomm = 'brand'
      AND bq.date >= DATE '2026-01-04'
) AS brand_campaigns
    ON f.campaign = brand_campaigns.campaign
WHERE f.date >= DATE '2026-01-04'
  AND f.date <= DATEADD(
        day, -1,
        CONVERT_TIMEZONE('UTC', 'US/Pacific', GETDATE())::date
      )
  AND brand_campaigns.campaign IS NULL
GROUP BY
    f.date,
    f.channel;

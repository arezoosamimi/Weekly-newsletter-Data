# Weekly-newsletter-Data

This repository stores the SQL queries used to pull data for the weekly newsletter.

## Goal

Centralizing these queries helps the Data Analytics team:

- document the logic behind each newsletter metric
- make query ownership clear
- support future automation of the weekly newsletter process
- capture learnings that can be reused for deeper analysis

## Repository structure

```text
queries/
├── README.md
└── _template.sql
```

## How to add a query

1. Copy `queries/_template.sql`.
2. Rename the file to describe the newsletter section or metric, for example:
   - `queries/customer_growth.sql`
   - `queries/pipeline_summary.sql`
   - `queries/product_usage_weekly.sql`
3. Fill in the metadata fields at the top of the file.
4. Add the SQL used to produce the newsletter output.
5. Commit the file to this repository.

## Standard for every query

Each SQL file should capture:

- query name
- owner
- purpose
- schedule or reporting cadence
- source tables
- output definition
- assumptions or caveats
- downstream use in the newsletter

See `queries/README.md` for the full template guidance.

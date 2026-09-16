# Newsletter query guidelines

Use one `.sql` file per newsletter query.

## Required metadata

Before the SQL body, document:

- `Query name`: a short descriptive name
- `Owner`: primary analyst or team
- `Purpose`: what business question the query answers
- `Cadence`: weekly, monthly, ad hoc, etc.
- `Source tables`: upstream tables or views used
- `Output`: the table, chart, KPI, or section supported
- `Assumptions`: filters, business rules, or known limitations
- `Automation notes`: anything needed to schedule or productionize the query

## Naming guidance

- prefer descriptive snake_case file names
- keep one query per file when possible
- if a section needs multiple steps, keep them in the same file with clearly labeled sections

## Template

Start from `queries/_template.sql` when adding a new query.

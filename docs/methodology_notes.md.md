# Methodology Notes

This document covers the technical decisions behind the dataset sourcing, RFM segmentation logic, and marketing spend simulation used in this project. It supplements the [Business Requirements Document](docs/BRD_v1.2.docx), which defines the project's scope and requirements as agreed with the stakeholder.

## 1. Dataset Sourcing

The fictional client's transactional data is represented using **The Look E-Commerce** dataset (apparel/lifestyle retail data), sourced as a static CSV export (Kaggle mirror of the public BigQuery dataset). The CSV was loaded directly into SQL Server, replicating the manual CSV handoff workflow described in the BRD's constraints (no live database connection; weekly manual refresh), rather than establishing a live database connection.

Three tables were used: `users`, `orders`, and `order_items`. Product/category detail (`inventory_items`) and behavioral/session data (`events`) were deliberately excluded — the former wasn't needed for the stakeholder's budget-allocation question, and the latter was explicitly out of scope per the BRD.

## 2. RFM Segmentation Logic

RFM components were calculated per customer using `order_items` as the fact table, restricted to a 2-year window (2022-01-21 to 2024-01-21) and to order statuses `Complete`, `Shipped`, `Processing`, and `Returned` (`Cancelled` excluded entirely).

- **Recency**: days since each customer's most recent qualifying order, relative to the dataset's max date (2024-01-21).
- **Frequency**: count of distinct qualifying orders. `Returned` orders count toward Frequency (the customer did engage), but are excluded from Monetary (the business didn't retain that revenue).
- **Monetary**: sum of `sale_price` for non-returned orders.

**Scoring**: Recency and Monetary use `NTILE(5)` quintile scoring. Frequency uses a fixed `CASE`-based mapping instead of `NTILE`, since the customer base's order counts only range from 1–4 — too discrete a range for quintile scoring to produce meaningful, non-arbitrary buckets (heavy ties would otherwise split identical customers into different score buckets essentially at random).

**Segment assignment** uses business-rule thresholds developed with the stakeholder, rather than a fully automated clustering approach:

| Segment | Rule |
|---|---|
| **Loyal** | High recency (r_score ≥ 4) and high frequency (f_score ≥ 3) |
| **At-Risk** | Low recency (r_score ≤ 2) and moderate-to-high historical frequency or monetary |
| **New** | Exactly one order, but recent (r_score ≥ 4) — tracked separately since one order isn't enough to judge long-term behavior |
| **One-Time** | Exactly one order, not recent (r_score < 4) |
| **Others** | Catch-all for customers not cleanly matching the above |

Segment assignment updates naturally as new data arrives on each refresh — a "New" customer will shift into "One-Time," "Loyal," or "Others" as their subsequent behavior (or lack of it) accumulates.

**Known data-quality findings** (documented as BRD risks, not corrected in place):
- Accelerating month-over-month growth was found in the underlying data, with Q4 growth notably steeper than other quarters — a genuine business trend, not an anomaly requiring exclusion.
- An anomalous spike in new account creation was found in a narrow date range (~450 signups/day vs. a ~50-55/day baseline), consistent with a synthetic data generation artifact. Final-month figures affected by this are treated as directional rather than precise.

## 3. Marketing Spend Simulation

No public dataset tracks internal marketing/advertising spend, so this figure was simulated rather than sourced from real data — a deliberate, documented assumption, not an oversight.

- **Revenue per segment** is real, calculated directly from `order_items.sale_price`.
- **Spend per segment** was derived from researched email service provider (ESP) pricing for a contact list of this size. The monthly budget scales with the cumulative number of registered customers as of that month (based on `users.created_at` — confirmed with the stakeholder as the point at which customers begin receiving campaigns, not their first purchase date), since the emailed customer base grew over time.
- New customers' first month of email exposure is **prorated** based on how many days remained in their signup month, rather than assuming a full month of emails from day one.
- The per-email cost rate was set at a level that brings the blended revenue-per-dollar-spent ratio in line with real-world email marketing benchmarks (roughly $36–40 return per $1 spent), based on a second round of research into realistic full-campaign costs (platform + creative/design), not platform fees alone.

This reflects the stakeholder's description of current practice: every registered customer receives the same campaigns, regardless of segment or purchase history — which is the core inefficiency the dashboard is built to surface.

## 4. Known Limitations

- **Trend chart windowing**: the Revenue-per-Dollar-Spent trend chart on the executive summary page is trimmed to Apr 2022–Jul 2023. The excluded periods are not representative: the earliest months suffer from a small-denominator distortion (very few customers existed yet, producing an unstable ratio), and the final months are affected by the segment-definition artifact where remaining One-Time buyers get reclassified as "New" as the analysis window closes.
- **Row-level security**: dynamic RLS was implemented and is testable via Power BI Desktop's "View As Roles" feature. Full user-based enforcement (real login-based restriction) requires publishing to Power BI Service, which was outside the scope of this portfolio environment.

# E-Commerce Customer Segmentation: Budget Allocation Dashboard

**Loyal customers return $96 for every $1 spent on them. One-time buyers return just $20 — not because they're worth less, but because they get the exact same generic campaign as everyone else.**

📌 **Quick links:** [Project Background](#project-background) · [Data Structure](#data-structure--initial-checks) · [Executive Summary](#executive-summary) · [Insights Deep Dive](#insights-deep-dive) · [Recommendations](#recommendations) · [Assumptions & Caveats](#assumptions-and-caveats) · [Technical Resources](#technical-resources)

![Executive Summary Dashboard]([dashboard/Executive Summary view.png](dashboard/screenshots/page1_customer_segmentation.png.png))

---

# Project Background

A mid-sized e-commerce retailer specializing in apparel and lifestyle goods was sending identical email campaigns, at identical frequency, to its entire customer base — regardless of whether a customer had ordered once or ten times. There was no segmentation strategy, no visibility into which customers were driving returns on that spend, and no data-backed way to defend the marketing budget when leadership asked for justification at quarterly review.

This project was scoped and built the way a real BI engagement would be: starting with a full stakeholder requirements conversation (playing both analyst and Head of Marketing) to define the actual business decision at stake, before any data was touched. That conversation produced a signed-off [Business Requirements Document](docs/BRD_v1.2.docx.docx).

Insights and recommendations are provided on the following key areas:

- **Customer Segmentation:** how the customer base breaks down by purchase behavior (Recency & Frequency), and how large each segment is
- **Marketing Spend Allocation:** where the existing, undifferentiated email budget is actually going
- **Revenue Performance by Segment:** how much real revenue each segment generates
- **Return on Investment by Segment:** which segments generate the strongest return per dollar spent, and how that gap has moved over time

The SQL queries used to build and validate the RFM segmentation, calendar table, and marketing spend simulation can be found [here](sql/).

The full technical methodology — dataset sourcing, segmentation logic, spend model, and documented data-quality findings — can be found [here](docs/methodology_notes.md.md).

An interactive Power BI dashboard used to report and explore segment performance can be found [here](dashboard/Budget_Allocation_Dashboard.pbix.pbix).

# Data Structure & Initial Checks

The underlying dataset (The Look E-Commerce, apparel/lifestyle retail) consists of three core tables used in this analysis, spanning a 2-year window (Jan 2022–Jan 2024) with roughly 59,000 unique customers. A description of each table is as follows:

- **`users`:** one row per customer — customer ID and account creation date (used to determine when a customer entered the emailed customer base)
- **`orders`:** one row per order — order status and key dates, used to filter to genuinely completed activity
- **`order_items`:** one row per line item within an order — the core fact table, providing order date, sale price, and customer linkage used to calculate Recency, Frequency, and Monetary value

Two additional tables in the source dataset (`inventory_items`, `events`) were deliberately excluded — product-category detail wasn't relevant to the stakeholder's budget-allocation question, and behavioral/session data was explicitly out of scope per the BRD.

Three supporting objects were built to support the analysis: a `CalendarTable` (date dimension), a segment-monthly cumulative customer bridge view, and a simulated marketing spend table (see [Assumptions & Caveats](#assumptions-and-caveats)). Full detail on each is in the [methodology notes](docs/methodology_notes.md).

# Executive Summary

### Overview of Findings

If leadership were to take away three things from this project: **(1)** nearly 7 in 10 customers have ordered only once, and this segment absorbs the largest share of a budget that's currently spent the same way on everyone; **(2)** that same segment is also the single highest-revenue group in the business, so the answer was never to cut their spend; **(3)** the real gap is efficiency, not volume — loyal customers return roughly 5x more revenue per marketing dollar than one-time buyers, because they receive no differentiated engagement strategy.

![Customer Segmentation Dashboard](dashboard/Customer_Segmentation.png)

# Insights Deep Dive

### Customer Segmentation

- **Nearly 7 in 10 customers (≈68%) have ordered exactly once**, making One-Time the largest single segment in the customer base by a wide margin.
- Segments were built on **Recency and Frequency** specifically, per the stakeholder's own stated priority — not Monetary value, which the stakeholder identified as a weaker signal of "who's worth chasing."
- Five segments emerged from this logic: **Loyal**, **At-Risk**, **One-Time**, **New** (a single recent order, tracked separately from One-Time since it's too early to judge), and **Others**.
- Segment membership is not static — it recalculates on each data refresh, so a customer naturally moves between segments as their behavior develops (e.g., New → Loyal, or New → One-Time).

### Marketing Spend Allocation

- **One-Time buyers absorb more email spend than every other segment combined** — despite receiving no strategy differentiated from any other group.
- Spend was modeled from researched email service provider (ESP) pricing, scaled to the size of the customer base as it grew over the 2-year window — not an arbitrary flat figure. Full methodology [here](docs/methodology_notes.md).
- Because every customer has historically received identical treatment, spend allocation directly mirrors segment size, not segment value.

### Revenue Performance by Segment

- **One-Time buyers generate $2.1M in revenue — the highest of any segment**, narrowly ahead of Others ($1.6M).
- This was a critical check before recommending anything: an early draft recommendation to cut One-Time spend was reversed once this figure surfaced, since it would have meant cutting the business's single largest revenue driver.
- Loyal and At-Risk generate less total revenue in absolute terms, but with dramatically less spend behind them.

### Return on Investment by Segment

- **Loyal customers return $96 for every $1 spent; One-Time buyers return just $20** — roughly a 5x efficiency gap.
- **Others outperforms At-Risk on both revenue ($1.6M vs $0.6M) and ROI ($56 vs $41 per dollar)** — an assumption about which underperforming segment deserved the most attention was corrected once the actual numbers were checked.
- This gap has held consistently across the analysis window (Apr 2022–Jul 2023; see [Assumptions & Caveats](#assumptions-and-caveats) for why the full window isn't shown) — Loyal's return has grown over time, while One-Time's has stayed flat.

# Recommendations

Based on the insights and findings above, we would recommend the marketing team consider the following:

- **One-Time buyers generate the most total revenue of any segment, but return the least per dollar spent.** Do not cut their budget — instead, replace the generic weekly campaign they currently receive with a targeted, conversion-focused message (e.g., a second-purchase incentive), aimed at closing the efficiency gap rather than reducing investment.

- **Loyal and Others segments deliver the strongest return per dollar spent, yet receive a disproportionately small share of the budget.** Protect and, where possible, grow the budget already allocated to these segments rather than treating all segments as equal by default.

- **At-Risk customers should remain monitored but are not the top priority for reallocated budget** — Others currently outperforms At-Risk on both revenue and ROI, and the data should continue to guide this prioritization as it updates.

- **Segment-level reporting should become part of the regular budget review process**, replacing the current spreadsheet-based, single-number view of overall marketing spend that made this kind of comparison impossible to see before.

# Assumptions and Caveats

Throughout the analysis, several assumptions were made to manage real limitations in the data. These are noted below:

- **Marketing spend is a documented simulation, not real data.** No public e-commerce dataset tracks internal advertising/email budgets, so spend was modeled from researched ESP pricing and cross-checked against real-world industry ROI benchmarks (~$36–40 revenue per $1 spent) for plausibility, rather than picked arbitrarily.

- **The ROI trend chart is trimmed to Apr 2022–Jul 2023**, excluding the first and final months of the full analysis window. The earliest months suffer from a small-denominator distortion (very few customers existed yet, producing an unstable ratio); the final months are affected by a segment-definition artifact where remaining One-Time buyers get mechanically reclassified as "New" as the window closes. Both are documented rather than silently corrected.

- **A synthetic data generation artifact was identified** in the source dataset — an anomalous spike in new account creation over a narrow date range, inconsistent with any real business event. This is logged as a risk in the BRD; figures for the affected period are treated as directional rather than precise.

- **Row-level security is implemented and testable** via Power BI Desktop's "View As Roles" feature, restricting individual customer-level data to Marketing/Admin roles while Leadership sees segment-level summaries only. Full login-based enforcement would require publishing to Power BI Service, which was outside this project's environment — see the [RLS demo screenshot](dashboard/screenshots/rls_demo.png) for a before/after comparison.

---

# Technical Resources

| | |
|---|---|
| 📄 Business Requirements Document | [docs/BRD_v1.2.docx](docs/BRD_v1.2.docx) |
| 🧠 Methodology Notes | [docs/methodology_notes.md](docs/methodology_notes.md) |
| 🗄️ SQL Scripts | [sql/](sql/) |
| 📊 Dashboard File | [dashboard/Budget_Allocation_Dashboard.pbix](dashboard/Budget_Allocation_Dashboard.pbix) |
| 🔒 RLS Demo | [dashboard/screenshots/rls_demo.png](dashboard/screenshots/rls_demo.png) |

## Project Structure

```
├── README.md
├── docs/
│   ├── BRD_v1.2.docx
│   └── methodology_notes.md
├── sql/
│   ├── 01_rfm_segmentation.sql
│   ├── 02_calendar_table.sql
│   ├── 03_marketing_spend_simulation.sql
│   ├── 04_segment_monthly_bridge.sql
│   └── 05_final_views.sql
└── dashboard/
    ├── Budget_Allocation_Dashboard.pbix
    └── screenshots/
        ├── page1_customer_segmentation.png
        ├── page2_executive_summary.png
        └── rls_demo.png
```

---

*Part of a larger portfolio focused on explanatory analytics — building analyses that answer "what should you do about it," not just "what happened." More projects at [portfolio link].*

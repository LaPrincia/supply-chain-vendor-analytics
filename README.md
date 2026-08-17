# Healthcare Analytics Case Study 3
## Supply Chain Performance & Vendor Operations

### Palmetto Regional Health System (Fictional)

An end-to-end healthcare supply chain analytics project designed to evaluate supply spending, vendor performance, delivery reliability, critical-item availability, contract exposure, and operational risk.

This project uses Microsoft SQL Server and Tableau to transform healthcare supply chain data into executive-level insights that support procurement oversight, vendor management, critical supply continuity, and data-driven operational decision-making.

---

## Business Challenge

Palmetto Regional Health System (PRHS) sought greater visibility into supply chain performance and vendor reliability to better monitor supply spending, identify delivery delays, evaluate critical-item availability, assess vendor performance, and understand contract-related financial exposure.

Executive and operational leadership required a centralized analytics solution capable of transforming transactional supply chain data into actionable insights that support procurement strategy, vendor accountability, supply continuity, and operational risk management.

---

## Tools & Technologies

- **Microsoft SQL Server** — data preparation, validation, KPI calculations, and dashboard-ready datasets
- **Tableau Public** — interactive dashboard development and executive reporting
- **Excel** — source data development and validation
- **GitHub** — technical documentation and SQL repository

---

## Interactive Dashboards

### Dashboard 1 — Supply Chain Performance

Provides an executive overview of supply chain operations, including:

- Total supply spend
- On-time delivery performance
- Quantity fill rate
- Critical-item delivery performance
- Order cancellation rate
- Monthly supply spending trends
- Supply category spending
- Department-level critical-item performance

![Supply Chain Performance Dashboard](Images/Supply%20Chain%20Performance%20Dashboard.png)

### Dashboard 2 — Supply Chain Vendor Operations

Provides a deeper analysis of vendor reliability, critical supply risk, and contract exposure, including:

- Active vendor monitoring
- Vendor on-time delivery performance
- Critical-item fill rate
- Critical late orders
- Expiring contract exposure
- Vendor performance comparisons
- Critical-item performance by vendor and category
- Contract risk distribution

![Supply Chain Vendor Operations Dashboard](Images/Supply%20Chain%20Vendor%20Operations%20Dashboard.png)

---

## Key Findings

The analysis identified several operational and vendor-management opportunities:

- Vendor on-time delivery performance indicates meaningful reliability gaps requiring continued monitoring and vendor accountability.
- Critical-item fill performance remains strong overall, but late critical-supply orders create operational risk that should be monitored by vendor and department.
- Supply spending varies across categories and departments, creating opportunities for targeted procurement review and cost management.
- A portion of supply spending is associated with expiring vendor contracts, creating an opportunity for proactive contract review and negotiation.
- Vendor-level performance analysis enables leadership to identify suppliers requiring corrective action, closer monitoring, or procurement intervention.

---

## SQL Repository Structure

The SQL workflow was organized into six scripts supporting analysis, validation, and Tableau reporting.

| File | Purpose |
|---|---|
| `01_dashboard_1_supply_chain_performance_queries.sql` | Supply chain KPI calculations and operational analysis |
| `02_dashboard_1_supply_chain_performance_validation.sql` | Dashboard 1 data and KPI validation |
| `03_dashboard_1_tableau_dataset.sql` | Tableau-ready dataset for Dashboard 1 |
| `04_dashboard_2_vendor_operations_queries.sql` | Vendor, critical-supply, and contract-risk analysis |
| `05_dashboard_2_vendor_operations_validation.sql` | Dashboard 2 data and KPI validation |
| `06_dashboard_2_tableau_dataset.sql` | Tableau-ready dataset for Dashboard 2 |

The SQL scripts are available in the [`SQL`](SQL/) folder.

---

## Analytics Approach

This project followed an end-to-end healthcare analytics workflow:

1. **Define the Business Challenge** — Identify supply chain visibility, vendor reliability, critical-item availability, and contract-risk priorities.
2. **Prepare & Validate Data** — Use SQL Server to clean, transform, validate, and organize supply chain data for analysis.
3. **Develop KPI Logic** — Calculate supply spending, delivery performance, fill rates, critical-item risk, vendor performance, and contract exposure.
4. **Build Dashboard Datasets** — Create validated SQL datasets optimized for Tableau reporting.
5. **Develop Executive Dashboards** — Design interactive Tableau dashboards for operational monitoring and vendor-risk analysis.
6. **Evaluate Performance** — Identify trends, performance gaps, high-risk vendors, critical-supply concerns, and contract exposure.
7. **Translate Insights Into Action** — Develop recommendations, implementation priorities, and ongoing performance measures.

---

## Project Structure

```text
Healthcare-Analytics-Case-Study-3-Supply-Chain/
│
├── Images/
│   ├── Supply Chain Performance Dashboard.png
│   └── Supply Chain Vendor Operations Dashboard.png
│
├── SQL/
│   ├── 01_dashboard_1_supply_chain_performance_queries.sql
│   ├── 02_dashboard_1_supply_chain_performance_validation.sql
│   ├── 03_dashboard_1_tableau_dataset.sql
│   ├── 04_dashboard_2_vendor_operations_queries.sql
│   ├── 05_dashboard_2_vendor_operations_validation.sql
│   └── 06_dashboard_2_tableau_dataset.sql
│
└── README.md



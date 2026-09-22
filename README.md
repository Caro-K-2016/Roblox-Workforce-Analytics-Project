# Roblox HRMS Workforce Analytics — Capstone Project

**Group 6 · Generation Ghana & Kenya Data Analytics Programme**
Dennis · Daniel · Comfort · Henry · August 2026

A end-to-end HR data analytics project on a 30,000-employee synthetic HRMS dataset spanning 8 departments. Raw Excel exports are cleaned, loaded into a relational MySQL warehouse, queried for executive KPIs, and visualized in a Power BI dashboard — culminating in an analyst report with findings and recommendations for leadership.

**Pipeline:** Excel cleaning → MySQL data warehouse → SQL analytics → Power BI dashboards → Executive reporting

## Repository Contents

```
├── clean csv doc/                     Cleaned CSVs, ready for MySQL LOAD DATA
│   ├── Department.csv
│   ├── department_performance.csv
│   ├── education.csv
│   ├── employee.csv
│   ├── employee_performance.csv
│   ├── finance_dataset.csv
│   └── health_dataset.csv
├── excel files/                       Cleaned data in Excel format
├── sql results/                       CSV exports of each executive query's output
├── roblox_hrms_executive_analytics_final.sql   Full schema build + 7 executive queries
├── Roblox_HRMS_Data_Dictionary.(docx/pdf)       Table & field reference
├── Group 6 roblox hrms schema file.docx         Entity-relationship / schema notes
├── Group 6 Executive Dashboard for Capstone Project.pbix   Power BI dashboard (4 pages)
├── Roblox_Workforce_Analytics_Group_6_Report.(docx/pdf)     Full analyst report
├── Workforce_Analytics_Capstone_Analyst_Report.docx         Supporting analyst report
└── Workforce_Analytics_Capstone_Group6.pptx                 Presentation deck (10 slides)
```

## Data Model

A star schema centered on `employee`, built in MySQL (database `roblox_hrms`):

| Table | Grain | Description |
|---|---|---|
| `department` | 1 row per department | Department names and codes |
| `employee` | 1 row per employee | Core employee master (position, status, department, join date, etc.) |
| `employee_performance` | 1 row per employee per year | Annual performance score, projects completed, training hours, attendance, bonus |
| `education` | 1+ rows per employee | Education level, institution, field of study |
| `finance` | 1 row per employee | Basic salary, allowances, bank/payroll details |
| `health` | 1 row per employee | Insurance status, medical leave balance, wellbeing risk flags |
| `department_performance` | 1 row per department per year | Revenue, cost, average performance, training hours by department |

`employee` joins to `department` via `department_code`, and to `finance`/`health` 1:1 via `employee_id`. `employee_performance` and `education` are 1:many and are aggregated to employee-level before joining, to avoid inflating headcount or compensation at the join. Full field-level definitions are in `Roblox_HRMS_Data_Dictionary.docx`/`.pdf`.

## SQL Analytics

`roblox_hrms_executive_analytics_final.sql` builds the warehouse from scratch (drop/create tables, `LOAD DATA INFILE` from the cleaned CSVs, referential-integrity checks) and then runs 7 executive queries, each mapped to a business question:

1. **Executive Workforce, Cost & Wellbeing Overview** — headcount, compensation, and wellbeing risk by department
2. **Department Performance & Financial Efficiency** — revenue-to-cost ratio by department
3. **Education, Job Placement & Compensation** — how education relates to placement and pay
4. **Employee Cost vs Productivity** — top-performer profile (top 1,000 by performance score)
5. **Workforce Risk & Cost Exposure** — insurance/wellbeing risk concentration and cost exposure
6. **Executive Department Scorecard** — scale, cost, performance, productivity, and risk in one view
7. **Executive Outlier Analysis** — departments combining above-average cost with below-average performance

Query outputs are saved as CSVs under `sql results/`.

## Power BI Dashboard

`Group 6 Executive Dashboard for Capstone Project.pbix` contains four dashboard pages built from the same warehouse, covering: Workforce Composition, Education & Compensation, Employee Cost vs Productivity, and Workforce Risk & Wellbeing (including attrition).

## Key Findings

- Performance is remarkably stable across departments (3.58–3.61 average score), but **financial efficiency varies widely** — from 1.38× revenue-per-dollar-cost (Customer Support) to 1.75× (Human Resources).
- **Wellbeing/insurance risk is systemic**, touching 65–68% of employees in every department, representing $208.7M of at-risk compensation.
- **Training investment does not track efficiency**: HR gets the best revenue-cost ratio with the least training (401 hours); Finance gets the most training (2,788 hours) for the second-best ratio.
- **Education has little relationship to pay** — compensation is driven far more by role and department than by degree level.
- **Operations** is the department to watch: mid-pack performance combined with the highest attrition (35.1%) and the lowest share of high-productivity top performers.
- Cross-checking the SQL exports against the Power BI dashboard surfaced a **data-quality issue**: `employee_status = "Active"` (33.6%) and dashboard attrition (32.9%) measure different things and should not be used interchangeably.

Full findings, methodology, data-quality notes, and five prioritized recommendations are in `Roblox_Workforce_Analytics_Group_6_Report.pdf`.

## Reproducing the Analysis

1. Create a MySQL 8.0 instance and update the `LOAD DATA INFILE` paths in `roblox_hrms_executive_analytics_final.sql` to point at your local copy of `clean csv doc/`.
2. Run the script — it creates the `roblox_hrms` database, builds all 7 tables, loads the data, and runs the data-quality checks and 7 executive queries in sequence.
3. Open `Group 6 Executive Dashboard for Capstone Project.pbix` in Power BI Desktop and point its data source at the same MySQL instance (or the CSVs in `sql results/`) to refresh the dashboards.

## Reports & Deliverables

- `Roblox_Workforce_Analytics_Group_6_Report.pdf` — primary executive analyst report
- `Workforce_Analytics_Capstone_Analyst_Report.docx` — supporting analyst report
- `Workforce_Analytics_Capstone_Group6.pptx` — stakeholder presentation deck
- `Roblox_HRMS_Data_Dictionary.pdf` — data dictionary

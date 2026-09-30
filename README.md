# Foam Manufacturing Quality Analysis

## Project Overview
This project analyzes a fictional foam manufacturing dataset to discover insights, trends, and patterns to understand key metrics using PostgreSQL. The project follows an end-to-end workflow starting from obtaining the raw dataset, performing exploratory data analysis (EDA) with PostgreSQL, and finally gaining business insights.

Note that the dataset used is fictional and obtained for the purpose of building the portfolio project. 

## Business Problem

The manufacturing plant needs to understand where quality losses occur and which processes are in need of further investigation and optimization. This project aims to look into the production data and quality inspection data to isolate potential defect sources and recommend actionable quality insights.

## Objectives

- Measure overall production and quality performance
- Calculate defect rate and first-pass yield
- Compare quality performance by product, machine, line, and shift
- Identify the most frequent defect types
- Quantify repair/scrap quality cost
- Perform Pareto analysis on defects
- Investigate the effects of maintenance age to defect generation
- Investigate the effects of ambient temparature and humidity to defect generation
- Check cycle-time performance against product standards
- Build a Power BI report for visual analysis

## Tools Used

- **PostgreSQL** — database and SQL analysis
- **pgAdmin 4** — database management
- **GitHub** — portfolio documentation and version control

## Dataset

The project contains eight tables:

| Table | Purpose |
|---|---|
| `products` | Product specifications and standard cycle times |
| `machines` | Machine, line, and machine-type information |
| `operators` | Operator reference data |
| `production` | Production batch and process data |
| `inspection` | Inspection quantities, defects, and pass quantities |
| `defects` | Individual defect records, severity, disposition, and cost |
| `maintenance` | Machine maintenance events and downtime |
| `calendar` | Date dimension for time-based analysis |

## Database Structure

Core relationships:

```text
products ───────┐
                │
                ▼
    ─────── production ──────── inspection ──────── defects
    │           │
    │           ├──────── machines
    │           ├──────── operators
    │           │
    │           └──────── calendar
    │
machines ───────── maintenance
```

## SQL Analysis

The SQL scripts are organized by analytical stage:

### `sql/02_Dimension-Exploration.sql`

Exploration of the dimensions of the tables of the dataset:

- Products and product categories
- Machine type, line names, and machine names
- Defect severity and defect types
- Dispositions
- Maintenance types
- Production shifts and process status
- Operator names

### `sql/03_Date-Range-Exploration.sql`

Checking the date boundaries and working shifts of the manufacturing plant

- Production date range
- Work week arrangement
- Number of shifts per day

### `sql/04_Measures-Exploration.sql`

Quick insights exploration through key performance metrics

- Total production quantity
- Total defect quantity
- Total production orders
- Average production quantity
- Average cycle time
- Overall yield
- Overall defect rate
- Cost of quality

### `sql/05_Operations-Insights-and-Analysis.sql`

Business-oriented production quality analysis

- Overall Yield and Overall Defect Rate
- Monthly yield and defect rate
- Monthly defect rate + 3-month rolling average
- Product performance
- Machine performance
- Shift performance
- Operator performance
- Deep-dive into months with non-compliant yield and defect rate
  - Pareto analysis on defects using window functions
- Maintenance age analysis
- Process conditions analysis (ambient temperature and humidity)
  - Box plot analysis 
- Cycle time analysis

## Key Analytical Principle

The project calculates yield (%) and defect rate (DPPM) using aggregated defect quantities and production quantities rather than aggregating the yield and defect rates of row-level production batches. This prevents treating the data being clustered per batch with different volumes, but counts the data as individual units regardless of the quantity per production batch.

```sql
SUM(passed_qty) / SUM(production_qty) * 100 AS overall_yield

SUM(defect_qty) / SUM(production_qty) * 1000000 AS overall_defect_rate
```

## Limitations

The dataset used in the project is synthetic. The relationships uncovered in the dataset should not be interpreted as legitimate causations. Such relationships in real-world manufacturing systems require operational validation before business decisions are made.

## Project Takeaways

The project demonstrates an exploratory data analysis workflow combining domain knowledge in manufacturing and quality with SQL querying to gain quick insights about the operations of the foam manufacturing plant. It emphasizes not only the use of SQL code, but more on answering deep manufacturing questions and communicating the evidences clearly.





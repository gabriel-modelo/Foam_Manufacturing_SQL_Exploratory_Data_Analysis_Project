# Foam_Manufacturing_SQL_Exploratory_Data_Analysis_Project

## Project Overview
This project analyzes a fictional foam manufacturing dataset to discover insights, trends, and patterns to understand key metrics using PostgreSQL and Power BI.

The project follows an end-to-end workflow starting from obtaining the raw dataset, performing exploratory data analysis (EDA) with PosgreSQL, visualizing with Power BI, and finally gaining business insights.

*Note that the dataset used is fictional and obtained for the purpose of building the portfolio project. 

## Business Problem

The manufacturing plant needs to understand where quality losses occur and which processes deserve further investigation. This project aims to look into the production data and quality inspection data to isolate potential defect sources and recommend actionable quality insights.

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
- **Power BI** — interactive dashboarding
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




/* 
=====================================================================================================================

Foam Manufacturing Quality & Defect Analysis
PART 2: DATE RANGE EXPLORATION

=====================================================================================================================
Purpose:
	- To determine and understand the date boundaries of the data
	- To grasp the manufacturing plant's working schedule throughout the timeframe of the dataset

SQL Functions Used:
    - MIN(), MAX(), COUNT(), DISTINCT, GROUP BY, ORDER BY, CASE STATEMENT, JOIN, GENERATE_SERIES(), CAST(::)
=====================================================================================================================
*/


-- Determine the production date range.
SELECT 
	MIN(production_date) AS date_from,
    MAX(production_date) AS date_to
FROM production;


-- Determine the production's work week arrangement.
SELECT 
	generated_date, 
	production_date, 
	CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
FROM production
RIGHT JOIN 
(SELECT generate_series('2025-01-01'::date, '2025-12-31'::date, '1 day'::interval)::date 
AS generated_date) AS generated_dates
ON generated_date = production_date
GROUP BY generated_date, production_date
ORDER BY generated_date;


-- Determine the production shifts per day.
SELECT 
	production_date,
	shift,
	COUNT(DISTINCT shift)
FROM production
GROUP BY production_date, shift
ORDER BY production_date ASC;


/* 
=====================================================================================================================

Foam Manufacturing Quality & Defect Analysis
	PART 4: MEASURES EXPLORATION (KEY METRICS)

=====================================================================================================================
Purpose:
	- To calculate aggregated metrics for quick insights

SQL Functions Used:
    - SUM(), ROUND(), CAST/::, AVG(), COUNT(), UNION ALL
=====================================================================================================================
*/


-- Calculate the total production quantity
SELECT SUM(production_qty) AS total_production_qty
FROM production;

-- Calculate the total defect quantity
SELECT SUM(defect_qty) AS total_defect_qty
FROM inspection;

-- Calculate the total number of production orders
SELECT COUNT(production_id) AS total_production_orders
FROM production;

-- Calculate the average cycle time per production order
SELECT AVG(cycle_time_min) AS average_cycle_time
FROM production;

-- Check if all production quantities undergo 100% inspection
SELECT 
	CASE WHEN SUM(production_qty) = SUM(inspected_qty) THEN 100
	ELSE SUM(inspected_qty)/SUM(production_qty)::numeric*100
	END AS inspection_percentage
FROM inspection;

-- Calculate the overall yield 
SELECT SUM(pass_qty)/SUM(production_qty)::numeric*100 AS overall_yield
FROM inspection;

-- Calculate the overall defect rate in DPPM units
SELECT SUM(defect_qty)/SUM(production_qty)::numeric*1000000 AS overall_dppm
FROM inspection;

-- Calculate the overall cost of quality
SELECT SUM(repair_or_scrap_cost) AS cost_of_quality
FROM defects;

-- Display all key metrics of the plant into a single report
SELECT 'Total Production QTY' AS measure_name, SUM(production_qty) AS measure_value FROM production
UNION ALL
SELECT 'Total Defect QTY', SUM(defect_qty) FROM inspection
UNION ALL
SELECT 'Total Production Orders', COUNT(production_id) FROM production
UNION ALL
SELECT 'Average Production Quantity', ROUND(AVG(production_qty),2) FROM production
UNION ALL
SELECT 'Average Cycle Time', ROUND(AVG(cycle_time_min),2) FROM production
UNION ALL
SELECT 'Overall Yield', ROUND(SUM(pass_qty)/SUM(production_qty)::numeric*100,2) FROM inspection
UNION ALL 
SELECT 'Overall Defect Rate', ROUND(SUM(defect_qty)/SUM(production_qty)::numeric*1000000,2) FROM inspection
UNION ALL
SELECT 'Cost of Quality', SUM(repair_or_scrap_cost) FROM defects
;


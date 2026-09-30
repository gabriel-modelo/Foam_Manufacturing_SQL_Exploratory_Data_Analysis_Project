 
/* 
=====================================================================================================================

Foam Manufacturing Quality & Defect Analysis
	PART 5: OPERATIONS INSIGHTS AND ANALYSIS

=====================================================================================================================
Purpose:
	- To gain and understand key insights on the manufacturing data
	- To evaluate and investigate key performance metrics


SQL Functions Used:
    - Functions: SUM(), COUNT(), AVG(), MIN(), MAX(), ROUND(), PERCENTILE_CONT(), EXTRACT(), RANK(), NULLIF()
	- Clauses: CASE WHEN, OVER(), PARTITION BY, ORDER BY, GROUP BY, CTE, JOIN, CROSS JOIN, USING, ON, WHERE, 
		DISTINCT, LIMIT, DROP TABLE IF EXISTS, CREATE TEMP TABLE, WITHIN GROUP, TYPE CASTING (::NUMERIC)
=====================================================================================================================
Key Performance Metrics (and Superficial Targets) to Evaluate (Monthly):
	- Yield (Lower Limit: 99.40%)
	- Defect Rate (Upper Limit: 6000 DPPM)

=====================================================================================================================
Yield and Defects Rate Analysis
=====================================================================================================================
*/

-- Overall Yield (%)
SELECT SUM(pass_qty)/SUM(production_qty)::numeric*100 AS overall_yield
FROM inspection;

-- Monthly Yield (%)
SELECT 
	c.month AS m, 
	c.month_name AS month, 
	SUM(p.production_qty) AS total_production_qty, 
	SUM(i.pass_qty) AS total_passed_qty,
	ROUND(SUM(i.pass_qty)/SUM(p.production_qty)::numeric*100,2) AS total_yield
FROM calendar AS c
JOIN production AS p
	ON c.date = p.production_date
JOIN inspection as i
	USING (production_id)
GROUP BY c.month, c.month_name
ORDER BY c.month;

-- Overall Defect Rate (DPPM)
SELECT ROUND(SUM(defect_qty)/SUM(production_qty)::numeric*1000000,2) AS overall_dppm
FROM inspection;

-- Monthly Defect Rate (DPPM)
SELECT 
	c.month AS m, 
	c.month_name AS month, 
	SUM(p.production_qty) AS total_production_qty, 
	SUM(i.defect_qty) AS total_defect_qty,
	ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) AS total_dppm
FROM calendar AS c
JOIN production AS p
	ON c.date = p.production_date
JOIN inspection as i
	USING (production_id)
GROUP BY c.month, c.month_name
ORDER BY c.month;

-- Monthly Defect Rate + 3-Month Rolling Average
WITH monthly_dppm AS (
SELECT 
	c.month AS m, 
	c.month_name AS month, 
	SUM(p.production_qty) AS total_production_qty, 
	SUM(i.defect_qty) AS total_defect_qty,
	ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) AS total_dppm
FROM calendar AS c
JOIN production AS p
	ON c.date = p.production_date
JOIN inspection as i
	USING (production_id)
GROUP BY c.month, c.month_name
ORDER BY c.month
)
SELECT
	m,
	month,
	total_dppm,
	ROUND(AVG(total_dppm) OVER(ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_dppm_3_months
FROM monthly_dppm
ORDER BY m;

-- Question 1: In which months of 2025 was the plant non-compliant to the yield lower limit, and defect rate upper limit?
SELECT 
	c.month AS m, 
	c.month_name AS month, 
	ROUND(SUM(i.pass_qty)/SUM(p.production_qty)::numeric*100,2) AS total_yield,
	CASE 
		WHEN ROUND(SUM(i.pass_qty)/SUM(p.production_qty)::numeric*100,2) >= 99.4 
			THEN 'Passed' ELSE 'Failed' 
		END AS yield_compliance,
	ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) AS total_dppm,
	CASE 
		WHEN ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) <= 6000 
			THEN 'Passed' ELSE 'Failed' 
		END AS dppm_compliance
FROM calendar AS c
JOIN production AS p
	ON c.date = p.production_date
JOIN inspection as i
	USING (production_id)
GROUP BY c.month, c.month_name
ORDER BY c.month;
-- Answer: February and March

-- Question 2: List the performances of the individual products and rank from the top performer to the least performer. 
SELECT
	DISTINCT pr.product_name,
	SUM(i.pass_qty) AS total_passed_qty,
	SUM(p.production_qty) AS total_production_qty,
	ROUND(SUM(i.pass_qty)/SUM(p.production_qty)::numeric*100,3) AS total_yield,
	RANK() OVER(ORDER BY ROUND(SUM(i.pass_qty)/SUM(p.production_qty)::numeric*100,3) DESC) AS ranking
FROM production AS p
JOIN inspection AS i
	USING (production_id)
JOIN products AS pr
	USING (product_id)
GROUP BY pr.product_name
ORDER BY ranking;


-- Question 3: For the failing months, list the breakdown of the defects. Which defects must be addressed first?

-- Create temporary table to store inspection data from February and March 2025:
DROP TABLE IF EXISTS insp_defects_feb_march; 
CREATE TEMP TABLE insp_defects_feb_march AS 
	SELECT 
		i.production_id, 
		i.production_date, 
		p.shift,
		pr.product_name,
		i.production_qty, 
		m.machine_id,
		m.machine_name,
		p.operator_id,
		o.operator_name,
		i.inspection_id, 
		i.inspected_qty, 
		i.defect_qty, 
		i.defect_rate_pct, 
		i.pass_qty, 
		d.defect_id, 
		d.defect_type, 
		d.severity,
		d.disposition,
		d.repair_or_scrap_cost
	FROM inspection AS i
	JOIN defects AS d
		ON i.inspection_id = d.inspection_id
	JOIN production AS p
		ON i.production_id = p.production_id
	JOIN machines AS m
		ON p.machine_id = m.machine_id
	JOIN operators as o
		ON p.operator_id = o.operator_id
	JOIN products AS pr
		ON pr.product_id = p.product_id
	WHERE EXTRACT(MONTH FROM p.production_date) = 2 OR
	EXTRACT(MONTH FROM p.production_date) = 3;

-- Pareto analysis by quantity
WITH total_defects AS (
	SELECT SUM(defect_qty) AS grand_total FROM insp_defects_feb_march
),
defect_breakdown AS (
	SELECT 
		defect_type,
		SUM(defect_qty) AS total_defect_qty
	FROM insp_defects_feb_march
	GROUP BY defect_type
	ORDER BY total_defect_qty DESC
)
SELECT 
	defect_type,
	total_defect_qty,
	SUM(total_defect_qty) OVER(ORDER BY total_defect_qty DESC) as running_total,
	ROUND(SUM(total_defect_qty) OVER(ORDER BY total_defect_qty DESC)/t.grand_total::numeric*100,2) AS running_percentage,
	CASE 
		WHEN ROUND(SUM(total_defect_qty) OVER(ORDER BY total_defect_qty DESC)/t.grand_total::numeric*100,2) <= 80.00 THEN 'Top 80%'
		ELSE 'Bottom 20%' 
	END AS pareto_class
FROM defect_breakdown
CROSS JOIN total_defects AS t;

-- Pareto analysis by cost of quality:
WITH total_coq AS (
	SELECT SUM(repair_or_scrap_cost) AS grand_total FROM insp_defects_feb_march
),
defect_breakdown AS (
	SELECT 
		defect_type,
		SUM(repair_or_scrap_cost) AS total_defect_cost
	FROM insp_defects_feb_march
	GROUP BY defect_type
	ORDER BY total_defect_cost DESC
)
SELECT 
	defect_type,
	total_defect_cost,
	SUM(total_defect_cost) OVER(ORDER BY total_defect_cost DESC) as running_total,
	ROUND(SUM(total_defect_cost) OVER(ORDER BY total_defect_cost DESC)/t.grand_total::numeric*100,2) AS running_percentage,
	CASE 
		WHEN ROUND(SUM(total_defect_cost) OVER(ORDER BY total_defect_cost DESC)/t.grand_total::numeric*100,2) <= 80.00 THEN 'Top 80%'
		ELSE 'Bottom 20%' 
	END AS pareto_class
FROM defect_breakdown
CROSS JOIN total_coq AS t;

-- Through pareto analysis of affected qty and cost of quality: Uneven Height, Density Variation, Wrong Dimension, Poor Bonding, and Crack

-- Question 4.1: Which machine has the highest rejection rate?  
SELECT
	machine_name, 
	SUM(defect_qty) AS total_defect_qty,
	SUM(production_qty) AS total_production_qty,
	ROUND(SUM(defect_qty)/SUM(production_qty)::numeric*1000000,2) AS total_dppm
FROM insp_defects_feb_march
GROUP BY machine_name
ORDER BY total_dppm DESC
LIMIT 1;
-- Rebond Press 03

-- Question 4.2: Show the defect rate per defect type for each machine ranked from highest to lowest DPPM.
SELECT
	machine_name, 
	defect_type, 
	SUM(defect_qty) AS total_defect_qty,
	ROUND(SUM(defect_qty)/SUM(production_qty)::numeric*1000000,2) AS total_dppm,
	RANK() OVER(PARTITION BY machine_name ORDER BY ROUND(SUM(defect_qty)/SUM(production_qty)::numeric*1000000,2) DESC) AS dppm_rank
FROM insp_defects_feb_march
GROUP BY machine_name, defect_type
ORDER BY machine_name, dppm_rank ASC;


-- Question 5: Which shift produces the most defective products?
SELECT
	DISTINCT shift,
	SUM(defect_qty) AS total_defect_qty
FROM insp_defects_feb_march
GROUP BY shift
ORDER BY total_defect_qty DESC;
-- Day shift generates the most defects.

-- Question 6: Factor of machine operator? Show the top three operators contributing to defects generation.
SELECT 
	operator_name,
	SUM(defect_qty) AS total_defect_qty
FROM insp_defects_feb_march
GROUP BY operator_name
ORDER BY total_defect_qty DESC
LIMIT 3;
-- Operator 10, 11, and 8 

-- Question 7: Which defects cost the plant the most money?
SELECT
	DISTINCT defect_type,
	COUNT(defect_type) AS total_count,
	SUM(repair_or_scrap_cost) AS total_cost,
	ROUND(AVG(repair_or_scrap_cost),2) AS avg_cost
FROM insp_defects_feb_march
GROUP BY defect_type
ORDER BY total_cost DESC;
-- Uneven height with the most number of occurrences costed the most, but contamination with the least occurrences has the most expensive cost per unit.

/*
=====================================================================================================================
Machine Maintenance Analysis
=====================================================================================================================
*/
-- Question 8: Does quality deteriorate as machines go longer without maintenance?
SELECT
	CASE 
		WHEN p.days_since_maintenance <=15 THEN '0-15 days'
		WHEN p.days_since_maintenance >15 AND p.days_since_maintenance <=30 THEN '16-30 days'
		WHEN p.days_since_maintenance >30 AND p.days_since_maintenance <=45 THEN '31-45 days'
		WHEN p.days_since_maintenance >45 THEN '46+ days'
		ELSE NULL
		END AS days_since_maintenance_range,
	SUM(i.defect_qty) AS total_defect_qty
FROM production AS p
JOIN inspection AS i
	USING (production_id)
GROUP BY days_since_maintenance_range
ORDER BY days_since_maintenance_range ASC;
-- Machine conditions with >30 days since maintenance generally had more defect occurrences than <30 days.

-- Question 9: How does each machine compare in performance to the overall defect rate?
WITH overall_defect_rate AS (
SELECT ROUND(SUM(defect_qty)/SUM(production_qty)::numeric*1000000,2) AS overall_dppm
FROM inspection
),
machine_defect_rate AS (
SELECT 
	m.machine_name,
	SUM(i.defect_qty) AS total_defect_qty,
	SUM(p.production_qty) AS total_production_qty,
	ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) AS total_dppm
FROM machines AS m
JOIN production AS p
	USING (machine_id)
JOIN inspection AS i
	USING (production_id)
GROUP BY m.machine_name
)
SELECT 
	mdr.machine_name,
	mdr.total_dppm,
	odr.overall_dppm,
	ROUND(mdr.total_dppm-odr.overall_dppm,2) AS diff_from_overall_dppm
FROM machine_defect_rate AS mdr
CROSS JOIN overall_defect_rate AS odr
GROUP BY mdr.machine_name, mdr.total_dppm, odr.overall_dppm
ORDER BY diff_from_overall_dppm DESC;
-- Rebond Press 03 and Cutter 01 generates higher defect rate than the plant's overall defect rate.

/*
=====================================================================================================================
Process Conditions Analysis
=====================================================================================================================
*/

-- Question 10: Did environmental conditions affect the generation of defects?

-- Factor of Humidity
-- Exploring humidity distribution through box plot analysis
SELECT 
	MIN(humidity_pct) AS min_hum, 
	PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY humidity_pct) AS first_quartile,
	AVG(humidity_pct) AS avg_hum, 
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY humidity_pct) AS median_hum,
	PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY humidity_pct) AS third_quartile,
	MAX(humidity_pct) AS max_hum,
	MAX(humidity_pct)-MIN(humidity_pct) AS hum_range
FROM production;

-- Grouping affected quantities by humidity range, side-by-side with logged humidity data per production batch
SELECT
	CASE 
		WHEN p.humidity_pct <= 49.9 THEN '45-49%'
		WHEN p.humidity_pct BETWEEN 50 AND 54.9 THEN '50-54%'
		WHEN p.humidity_pct BETWEEN 55 AND 59.9 THEN '55-59%'
		WHEN p.humidity_pct BETWEEN 60 AND 64.9 THEN '60-64%'
		WHEN p.humidity_pct BETWEEN 65 AND 69.9 THEN '65-69%'
		WHEN p.humidity_pct BETWEEN 70 AND 74.9 THEN '70-74%'
		WHEN p.humidity_pct BETWEEN 75 AND 79.9 THEN '75-79%'
		WHEN p.humidity_pct BETWEEN 80 AND 84.9 THEN '80-84%'
		WHEN p.humidity_pct >= 85 THEN '85-90%'
		ELSE NULL
		END AS humidity_range,
	SUM(i.defect_qty) AS total_defect_qty,
	SUM(p.production_qty) AS batch_qty,
	COUNT(p.production_id) AS batch_count,
	ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) AS dppm
FROM production AS p
JOIN inspection AS i
	USING (production_id)
GROUP BY humidity_range
ORDER BY humidity_range ASC;

-- Factor of Temperature
-- Explore ambient temp range of the production area - box plot analysis
SELECT 
	MIN(ambient_temp_c) AS min_temp, 
	PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY ambient_temp_c) AS first_quartile,
	AVG(ambient_temp_c) AS avg_temp, 
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY ambient_temp_c) AS median_temp,
	PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY ambient_temp_c) AS third_quartile,
	MAX(ambient_temp_c) AS max_temp,
	MAX(ambient_temp_c)-MIN(ambient_temp_c) AS temp_range
FROM production;

-- Grouping affected quantities by temperature range, side-by-side with logged ambient temperatures per production batch
SELECT
	CASE 
		WHEN p.ambient_temp_c <=23 THEN '23.0degC and below'
		WHEN p.ambient_temp_c BETWEEN 23.1 AND 25 THEN '23.1-25degC'
		WHEN p.ambient_temp_c BETWEEN 25.1 AND 27 THEN '25.1-27degC'
		WHEN p.ambient_temp_c BETWEEN 27.1 AND 29 THEN '27.1-29degC'
		WHEN p.ambient_temp_c BETWEEN 29.1 AND 31 THEN '29.1-31degC'
		WHEN p.ambient_temp_c BETWEEN 31.1 AND 33 THEN '31.1-33degC'
		WHEN p.ambient_temp_c BETWEEN 33.1 AND 35 THEN '33.1-35degC'
		WHEN p.ambient_temp_c BETWEEN 35.1 AND 37 THEN '35.1-37degC'
		WHEN p.ambient_temp_c >=37.1 THEN '37.1degC and above'
		ELSE NULL
		END AS ambient_temp_range,
	SUM(i.defect_qty) AS total_defect_qty,
	SUM(p.production_qty) AS batch_qty,
	COUNT(p.production_id) AS batch_count,
	ROUND(SUM(i.defect_qty)/SUM(p.production_qty)::numeric*1000000,2) AS dppm
FROM production AS p
JOIN inspection AS i
	USING (production_id)
GROUP BY ambient_temp_range
ORDER BY ambient_temp_range ASC;
-- Defect rate (DPPM) was observed to increase as ambient temperature increases.

/*
=====================================================================================================================
Cycle Time Analysis
=====================================================================================================================
*/

-- Question 11: Is there a relationship between product cycle time to the generation of defects?
WITH cycle_time_per_batch AS (
SELECT
    p.production_id,
    p.product_id,
    pr.product_name,
    p.cycle_time_min AS actual_cycle_time,
    pr.standard_cycle_min AS standard_cycle_time,
    CASE
        WHEN p.cycle_time_min < pr.standard_cycle_min * 0.95 THEN 'Below Standard'
        WHEN p.cycle_time_min <= pr.standard_cycle_min * 1.05 THEN 'Near Standard'
        ELSE 'Above Standard'
    END AS cycle_time_category
FROM production p
JOIN products pr
    USING (product_id)
)
SELECT
	ctpb.cycle_time_category,
    COUNT(p.production_id) AS production_batches,
    SUM(i.inspected_qty) AS inspected_qty,
    SUM(i.defect_qty) AS defect_qty,
    ROUND(SUM(i.defect_qty)::numeric/NULLIF(SUM(i.inspected_qty),0)*1000000,2) AS defect_rate_dppm
FROM production AS p
JOIN products AS pr
    ON p.product_id = pr.product_id
JOIN inspection i
    ON p.production_id = i.production_id
JOIN cycle_time_per_batch AS ctpb
	ON p.production_id = ctpb.production_id
GROUP BY cycle_time_category
ORDER BY
    CASE cycle_time_category
        WHEN 'Below Standard' THEN 1
        WHEN 'Near Standard' THEN 2
        WHEN 'Above Standard' THEN 3
    END;
-- Defect rate (DPPM) was observed to be higher as cycle time deviates away from the standard.





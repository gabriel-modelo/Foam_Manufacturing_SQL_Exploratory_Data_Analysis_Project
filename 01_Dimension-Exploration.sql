/* 
=====================================================================================================================

Foam Manufacturing Quality & Defect Analysis
PART 1: DIMENSION EXPLORATION

=====================================================================================================================
Purpose:
	- To explore the dimension values of the tables of the dataset

SQL Functions Used:
    - DISTINCT, ORDER BY
=====================================================================================================================
*/

-- List the products and the product categories produced by the plant.
SELECT DISTINCT category, product_name
FROM products
ORDER BY category;

-- List the machine type, line, and machine names of the foam manufacturing plant.
SELECT machine_type, line, machine_name
FROM machines;

-- List the defect types and their severities
SELECT DISTINCT severity, defect_type
FROM defects
ORDER BY severity, defect_type;

-- List the different dispositions 
SELECT DISTINCT disposition
FROM defects
ORDER BY disposition;

-- List the types of maintenance for the machines
SELECT DISTINCT maintenance_type
FROM maintenance
ORDER BY maintenance_type;

-- List the shifts of the production
SELECT DISTINCT shift
FROM production;

-- List the process status of the machines in production
SELECT DISTINCT process_status
FROM production;

-- List the operators of the production plant
SELECT DISTINCT operator_name
FROM operators
ORDER BY operator_name ASC;


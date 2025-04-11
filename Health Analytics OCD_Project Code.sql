-- 1. Count & Pct of F VS. M that have OCD & -- Average Obsession Score by Gender
SELECT 
Gender,
COUNT(`Patient ID`) AS patient_count,
-- Two methods to calculate the gender percentages 
	-- 1. Used Window function for row-level%
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS gender_percentage,
	-- 2. Used COUNT(*) with a subquery
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ocd_patient_dataset) , 2) AS gender_percentage2,
-- Average Obsession Score by Gender
ROUND(AVG(`Y-BOCS Score (Obsessions)`),2) * 100  AS avg_obs_score
	FROM health_data.ocd_patient_dataset
GROUP BY 1
ORDER BY 2;
    
-- 2. Count OF Patients by Ethnicities and their respective Average Obsession Score
SELECT
Ethnicity,
COUNT(`Patient ID`) AS patient_count,
ROUND(AVG(`Y-BOCS Score (Obsessions)`),2) * 100  AS avg_obs_score
FROM ocd_patient_dataset
GROUP BY 1
ORDER BY 2;

-- 3. Number of people diagnosed with OCD MoM
-- Convert text to date
	-- disable Mysql safe updates mode temporarily
SET SQL_SAFE_UPDATES = 0;
UPDATE ocd_patient_dataset
SET `OCD Diagnosis Date` = str_to_date(`OCD Diagnosis Date`, "%m-%d-%y");
SET SQL_SAFE_UPDATES = 1;
	-- change the column type tp DATE
ALTER TABLE ocd_patient_dataset
MODIFY column `OCD Diagnosis Date` DATE;

SELECT 
-- Extract month 
-- EXTRACT(MONTH FROM `OCD Diagnosis Date`) AS month,
-- Get the first day of the datetime
DATE_FORMAT(`OCD Diagnosis Date`, '%Y-%m') AS Month,
COUNT(`Patient ID`) AS patient_count
FROM ocd_patient_dataset
GROUP BY Month
ORDER BY Month;

-- 4. What is the most common Obsession Type (Count) & it's respective Average Obsession Score
SELECT  
`Obsession Type`,
COUNT(`Patient ID`) AS patient_count,
ROUND(AVG(`Y-BOCS Score (Obsessions)`),2) AS obs_score
FROM ocd_patient_dataset
GROUP BY 1
ORDER BY 2;


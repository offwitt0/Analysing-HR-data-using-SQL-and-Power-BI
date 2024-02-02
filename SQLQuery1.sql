create database HR;
--------------
use hr;
--------------
select *
from HR;
--------------
select termdate
from HR
order by termdate desc;
--------------
-- There is some issue in termdate format and data type so let's fix it
update HR
set termdate = format(convert(datetime, left(termdate, 19), 120), 'yyyy-mm-dd');
--------------
-- in MSsql we can't update column data type so we well create another column
alter table HR
add new_termdate date;
--------------
-- now after creating column let's add data to it from termdate
update HR
set new_termdate = case when termdate is not null and isdate(termdate) = 1 then cast(termdate as datetime) else null end;
--------------
--let's create new column called age
alter table HR
add age nvarchar(50);
--------------
-- calculate age from birthdate
update HR
set age  = datediff(year, birthdate, getdate())
--------------
select age
from HR;
--------------
-- Q1 what's is the age distributionin the company?
-- age distribution
select max(age) as oldest, min(age) youngest
from HR;
--------------
-- age distribution 
SELECT age_group, COUNT(*) AS count
FROM
(SELECT CASE
			WHEN age <= 22 AND age <= 30 THEN '21 to 30'
			WHEN age <= 31 AND age <= 40 THEN '31 to 40'
			WHEN age <= 41 AND age <= 50 THEN '41-50'
			ELSE '50+'
		END AS age_group
		FROM HR
		WHERE new_termdate IS NULL -- meaning in not termented
) AS Subquery
GROUP BY age_group
ORDER BY age_group;
---------------
-- age group by gender
SELECT age_group, gender, COUNT(*) AS count
FROM
(SELECT CASE
			WHEN age <= 22 AND age <= 30 THEN '22 to 30'
			WHEN age <= 31 AND age <= 40 THEN '31 to 40'
			WHEN age <= 41 AND age <= 50 THEN '41-50'
			ELSE '50+'
		END AS age_group, gender
		FROM HR
		WHERE new_termdate IS NULL -- meaning in not termented
) AS Subquery
GROUP BY age_group, gender
ORDER BY age_group, gender;
---------------
-- Q2 what's the gender breakdown in the company?
SELECT gender, COUNT(gender) AS count
FROM HR
WHERE new_termdate IS NULL -- meaning in not termented
GROUP BY gender
ORDER BY gender ASC;
---------------
-- Q3 How does gender vary across departments and job titles?
SELECT department, gender, count(*) as count
FROM HR
WHERE new_termdate IS NULL
GROUP BY department, gender
ORDER BY department;

-- job titles
SELECT department, jobtitle, gender, count(gender) AS count
FROM HR
WHERE new_termdate IS NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender ASC;
----------------
-- Q4 What's the race distribution in the company?
SELECT race, COUNT(*) AS count
FROM HR
WHERE new_termdate IS NULL
GROUP BY race
ORDER BY count DESC;
----------------
-- Q5 What's the average length of employment in the company?
SELECT AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
 FROM HR
 WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE();
 ---------------
-- Q6 Which department has the highest turnover rate?
-- get total count
-- get terminated count
-- terminated count/total count

SELECT department, total_count, terminated_count, 
		round(CAST(terminated_count AS FLOAT)/total_count, 2) AS turnover_rate
FROM 
(SELECT department, count(*) AS total_count, SUM(CASE
													WHEN new_termdate IS NOT NULL AND new_termdate <= getdate()
													THEN 1 ELSE 0
													END
												) AS terminated_count
FROM HR
GROUP BY department
) AS Subquery
ORDER BY turnover_rate DESC;
-------------------
-- Q7 What is the tenure distribution for each department?
SELECT department, AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
FROM HR
WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()
GROUP BY department;

SELECT department, DATEDIFF(year, MIN(hire_date), MAX(new_termdate)) AS tenure
FROM HR
WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()
GROUP BY department
ORDER BY tenure DESC;
-------------------
-- Q8 How many employees work remotely for each department?
SELECT location, count(*) AS count
 FROM HR
 WHERE new_termdate IS NULL
 GROUP BY location;
 -------------------
-- Q9 What's the distribution of employees across different states?
SELECT location_state, count(*) AS count
FROM HR
WHERE new_termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;
--------------------
-- Q10 How are job titles distributed in the company?
SELECT jobtitle, count(*) AS count
FROM HR
WHERE new_termdate IS NULL
GROUP BY jobtitle
ORDER BY count DESC;
---------------------
-- Q11 How have employee hire counts varied over time?
SELECT hire_yr, hires, terminations, hires - terminations AS net_change, (hires - terminations)/hires AS percent_hire_change
FROM  
	(SELECT
		YEAR(hire_date) AS hire_yr,
		count(*) as hires,
		SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
		FROM Hr
		GROUP BY year(hire_date)
	) AS subquery
ORDER BY percent_hire_change ASC;

-- fixes zero values from the above query

SELECT hire_yr, hires, terminations, hires - terminations AS net_change, 
		(round(CAST(hires - terminations AS FLOAT) / NULLIF(hires, 0), 2)) *100 AS percent_hire_change
FROM  
    (SELECT
        YEAR(hire_date) AS hire_yr,
        COUNT(*) AS hires,
        SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
    FROM HR
    GROUP BY YEAR(hire_date)
    ) AS subquery
ORDER BY hire_yr ASC;
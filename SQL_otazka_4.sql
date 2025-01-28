--4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
--o kolik byl vetsi mezirocni narust
--mzdy v letech
SELECT 
	pay1.price_year AS this_year,
	round((avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll)*100,2) AS wage_increase
FROM t_katerina_janku_project_SQL_primary_final pay1
JOIN t_katerina_janku_project_SQL_primary_final pay2
	ON pay1.price_year = pay2.price_year + 1
WHERE pay1.payroll_industry_id IS NULL	
AND pay2.payroll_industry_id IS NULL	
GROUP BY 
	this_year
ORDER BY 
	this_year;

--zmeny v letech
WITH w_changes AS 
	(SELECT 
		pay1.price_year AS this_year,
		round((avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll)*100,2) AS wage_increase
	FROM t_katerina_janku_project_SQL_primary_final pay1
	JOIN t_katerina_janku_project_SQL_primary_final pay2
		ON pay1.price_year = pay2.price_year + 1
	WHERE pay1.payroll_industry_id IS NULL	
	AND pay2.payroll_industry_id IS NULL	
	GROUP BY 
		this_year),
	pr_changes AS (SELECT 
		pr1.price_year AS this_year,
		round((avg(pr1.avg_price) - avg(pr2.avg_price))/avg(pr2.avg_price)*100,2) AS price_increase
	FROM t_katerina_janku_project_SQL_primary_final pr1
	JOIN t_katerina_janku_project_SQL_primary_final pr2
		ON pr1.price_year = pr2.price_year + 1
	GROUP BY 
		this_year)
SELECT w_changes.*,
	pr_changes.price_increase,
	pr_changes.price_increase - w_changes.wage_increase AS price_wages_difference
FROM w_changes 
JOIN pr_changes 
	ON w_changes.this_year = pr_changes.this_year
ORDER BY price_wages_difference;
	


--OTAZKA 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

-- tento dotaz zobrazi odvetvi u kterych byl v nejakem roce pokles prumernych mezd
SELECT 
	pay1.price_year AS this_year,
	pay1.payroll_industry_name, 
	avg(pay1.avg_payroll) AS this_year_payroll,
	avg(pay2.avg_payroll) AS last_year_payroll,
	round((avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll)*100,2) AS wage_increase
FROM t_katerina_janku_project_SQL_primary_final pay1
JOIN t_katerina_janku_project_SQL_primary_final pay2
	ON pay1.payroll_industry_id = pay2.payroll_industry_id
	AND pay1.price_year = pay2.price_year + 1
GROUP BY 
	this_year,
	pay1.payroll_industry_name
HAVING (avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll) <0
ORDER BY 
	wage_increase;



--modifikace predchoziho dotazu, ktera zobrazi kolikrat za sledovane obdobi mzdy poklesly v jednotlivych odvetvich
WITH wage_decrease AS 
	(SELECT 
		pay1.price_year AS current_year,
		pay1.payroll_industry_name
	FROM t_katerina_janku_project_SQL_primary_final pay1
	JOIN t_katerina_janku_project_SQL_primary_final pay2
		ON pay1.payroll_industry_id = pay2.payroll_industry_id
		AND pay1.price_year = pay2.price_year + 1
	GROUP BY 
		current_year,
		pay1.payroll_industry_name
	HAVING (avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll) <0
	) 
SELECT 
	payroll_industry_name,
	count(current_year) AS decrease_count
FROM wage_decrease
GROUP BY 
	payroll_industry_name 
ORDER BY 
	decrease_count DESC;

--a naopak odvetvi u kterych nikdy prumerne mzdy neklesali
-- celkovy pocet odvetvi
 
SELECT DISTINCT payroll_industry_name
FROM t_katerina_janku_project_SQL_primary_final
WHERE payroll_industry_name IS NOT NULL 
EXCEPT 
SELECT DISTINCT pay1.payroll_industry_name
FROM t_katerina_janku_project_SQL_primary_final pay1
JOIN t_katerina_janku_project_SQL_primary_final pay2
	ON pay1.payroll_industry_id = pay2.payroll_industry_id
	AND pay1.price_year = pay2.price_year + 1
GROUP BY 
		pay1.price_year,
		pay1.payroll_industry_name
HAVING (avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll) <0;

--modifikace predchoziho dotazu, ktera v kterych letech klesaly mzdy pro nejvice obdobi
WITH wage_decrease AS 
	(SELECT 
		pay1.price_year AS current_year,
		pay1.payroll_industry_name
	FROM t_katerina_janku_project_SQL_primary_final pay1
	JOIN t_katerina_janku_project_SQL_primary_final pay2
		ON pay1.payroll_industry_id = pay2.payroll_industry_id
		AND pay1.price_year = pay2.price_year + 1
	GROUP BY 
		current_year,
		pay1.payroll_industry_name
	HAVING (avg(pay1.avg_payroll) - avg(pay2.avg_payroll))/avg(pay2.avg_payroll) <0
	) 
SELECT 
	current_year,
	count (payroll_industry_name) AS industry_count
FROM wage_decrease
GROUP BY 
	current_year 
ORDER BY 
	industry_count DESC;

-- podobny dotaz k prvnimu dotazu s pouzitim windows functions, narozdil od prvniho dotazu zobrazi i nullove industry name, tedy souhrn za vsechna odvetvi a neomezuje se jen na poklesy, 
-- takze muzeme videt ze prumerne mzdy v prubehu let v jednotlivych odvetvich vetsinou stoupali
WITH payroll_table AS (
	SELECT
		price_year AS current_year,
		payroll_industry_id,
		payroll_industry_name,
		avg(avg_payroll) AS this_year_payroll
	FROM t_katerina_janku_project_SQL_primary_final
	GROUP BY 
		current_year,
		payroll_industry_id,
		payroll_industry_name
),
pay AS (
	SELECT 
		pt.*,
		LAG(this_year_payroll) OVER 
			(PARTITION BY payroll_industry_id 
			ORDER BY current_year
			) AS last_year_payroll
	FROM payroll_table pt
	)
SELECT 
	current_year,
	payroll_industry_name,
	this_year_payroll,
	last_year_payroll,
	round((this_year_payroll - last_year_payroll)/last_year_payroll * 100, 2) AS wage_increase
FROM pay
WHERE 
	((this_year_payroll - last_year_payroll)/last_year_payroll) IS NOT NULL 
ORDER BY wage_increase DESC;














	

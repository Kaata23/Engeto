--2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT 
	price_year,
	price_category_name,
	avg_price,
	avg_payroll,
	price_value, 
	price_unit,
	round(avg_payroll/avg_price/price_value :: numeric,0) AS ammount_bought
FROM t_katerina_janku_project_SQL_primary_final
WHERE 
	payroll_industry_id IS NULL
	AND price_category_id IN ('114201','111301')
	AND price_year IN ('2006','2018');



--- o kolik chleba/mleka vic bylo mozne koupit v r.2018
WITH comp AS (
	SELECT 
		price_year,
		price_category_name,
		round(avg_payroll/avg_price/price_value :: numeric,0) AS ammount_bought
	FROM t_katerina_janku_project_SQL_primary_final
	WHERE 
		payroll_industry_id IS NULL
		AND price_category_id IN ('114201','111301')
		AND price_year IN ('2006','2018')
		)
SELECT 
	price_year,
	price_category_name,
	ammount_bought,
	ammount_bought - LAG (ammount_bought) OVER (PARTITION BY price_category_name ORDER BY price_year) AS difference
FROM comp;
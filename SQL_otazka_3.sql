--3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
---potraviny co nejvice klesali v prubehu let

SELECT 
	pr1.price_year AS this_year,
	pr1.price_category_name ,
	avg(pr1.avg_price) AS this_year_price,
	avg(pr2.avg_price) AS last_year_price,
	round((avg(pr1.avg_price) - avg(pr2.avg_price))/avg(pr2.avg_price)*100,2) AS price_increase
FROM t_katerina_janku_project_SQL_primary_final pr1
JOIN t_katerina_janku_project_SQL_primary_final pr2
	ON pr1.price_category_id  = pr2.price_category_id 
	AND pr1.price_year = pr2.price_year + 1
GROUP BY 
	this_year,
	pr1.price_category_name 
HAVING (avg(pr1.avg_price) - avg(pr2.avg_price))/avg(pr2.avg_price) <0
ORDER BY 
	price_increase
LIMIT 10;

--z predchozi tabulky udelam prumer prumeru s pouzitim klauzule WITH neboli zjistim prumer rustu cen za cele sledovane odbobi u jednotlivych kategorii
WITH pr_changes AS (
	SELECT 
		pr1.price_year AS this_year,
		pr1.price_category_name ,
		avg(pr1.avg_price) AS this_year_price,
		avg(pr2.avg_price) AS last_year_price,
		round((avg(pr1.avg_price) - avg(pr2.avg_price))/avg(pr2.avg_price)*100,2) AS price_increase
	FROM t_katerina_janku_project_SQL_primary_final pr1
	JOIN t_katerina_janku_project_SQL_primary_final pr2
		ON pr1.price_category_id  = pr2.price_category_id 
		AND pr1.price_year = pr2.price_year + 1
	GROUP BY 
		this_year,
		pr1.price_category_name)
SELECT 
	pr_changes.price_category_name,
	round(avg(pr_changes.price_increase),2) AS average_price_change
FROM pr_changes 
GROUP BY 
	price_category_name
ORDER BY
	average_price_change;
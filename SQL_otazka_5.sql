
--5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
--projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

--vyber dat pro CR
SELECT *
FROM t_katerina_janku_project_SQL_secondary_final
WHERE country= 'Czech Republic';

--rust HDP v CR
SELECT 
	gdp1.year AS this_year,
	round(((avg(gdp1.gdp ) - avg(gdp2.gdp))/avg(gdp2.gdp)*100)::numeric,2) AS gdp_increase
FROM t_katerina_janku_project_SQL_secondary_final gdp1
JOIN t_katerina_janku_project_SQL_secondary_final gdp2
	ON gdp1.year = gdp2.year + 1
	AND gdp1.country = gdp2.country 
WHERE gdp1.country = 'Czech Republic' 	
GROUP BY 
	this_year
ORDER BY 
	this_year;

-- spojim tabulky pro porovnani rustu mezd, cen a hdp
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
			this_year),
	gdp_changes AS (
		SELECT 
			gdp1.year AS this_year,
			round(((avg(gdp1.gdp ) - avg(gdp2.gdp))/avg(gdp2.gdp)*100)::numeric,2) AS gdp_increase
		FROM t_katerina_janku_project_SQL_secondary_final gdp1
		JOIN t_katerina_janku_project_SQL_secondary_final gdp2
			ON gdp1.year = gdp2.year + 1
			AND gdp1.country = gdp2.country 
		WHERE gdp1.country = 'Czech Republic' 	
		GROUP BY 
			this_year)
SELECT w.this_year,
	w.wage_increase,
	p.price_increase,
	g.gdp_increase 
FROM w_changes w
JOIN pr_changes p
	ON w.this_year = p.this_year
JOIN gdp_changes g
	ON w.this_year = g.this_year;


-- vytvorim si z toho VIEW

CREATE OR REPLACE VIEW v_increases AS
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
			this_year),
	gdp_changes AS (
		SELECT 
			gdp1.year AS this_year,
			round(((avg(gdp1.gdp ) - avg(gdp2.gdp))/avg(gdp2.gdp)*100)::numeric,2) AS gdp_increase
		FROM t_katerina_janku_project_SQL_secondary_final gdp1
		JOIN t_katerina_janku_project_SQL_secondary_final gdp2
			ON gdp1.year = gdp2.year + 1
			AND gdp1.country = gdp2.country 
		WHERE gdp1.country = 'Czech Republic' 	
		GROUP BY 
			this_year)
SELECT w.this_year,
	w.wage_increase,
	p.price_increase,
	g.gdp_increase 
FROM w_changes w
JOIN pr_changes p
	ON w.this_year = p.this_year
JOIN gdp_changes g
	ON w.this_year = g.this_year;


--vypocet korelacniho koeficientu

WITH stats AS (
    SELECT
        AVG(wage_increase) AS avg_wage_increase,
        AVG(price_increase) AS avg_price_increase,
        AVG(gdp_increase) AS avg_gdp_increase,
        COUNT(*) AS n
    FROM v_increases
),
sums AS (
    SELECT
        SUM((gdp_increase - avg_gdp_increase) * (price_increase - avg_price_increase)) AS sum_gdp_price,
        SUM((gdp_increase - avg_gdp_increase) * (wage_increase - avg_wage_increase)) AS sum_gdp_wage,
        SUM((gdp_increase - avg_gdp_increase) * (gdp_increase - avg_gdp_increase)) AS sum_gdp_gdp,
        SUM((price_increase - avg_price_increase) * (price_increase - avg_price_increase)) AS sum_price_price,
        SUM((wage_increase - avg_wage_increase) * (wage_increase - avg_wage_increase)) AS sum_wage_wage
    FROM v_increases, stats
)
SELECT
    sum_gdp_price / SQRT(sum_gdp_gdp * sum_price_price) AS corr_gdp_price,
    sum_gdp_wage / SQRT(sum_gdp_gdp * sum_wage_wage) AS corr_gdp_wage
FROM sums;


-- spojim tabulky pro porovnani rustu mezd, cen a hdp - gdp posunuto o rok - zpozdene DPH - a vytvorim novy view
CREATE OR REPLACE VIEW v_lagged_gdp AS
SELECT
	v1.this_year,
	v1.wage_increase,
	v1.price_increase,
	v2.gdp_increase
FROM v_increases v1
LEFT JOIN v_increases v2 
	ON v1.this_year = v2.this_year + 1
WHERE v2.gdp_increase IS NOT NULL;

--vypocitam korelacni koeficienty


WITH stats AS (
    SELECT
        AVG(wage_increase) AS avg_wage_increase,
        AVG(price_increase) AS avg_price_increase,
        AVG(gdp_increase) AS avg_gdp_increase,
        COUNT(*) AS n
    FROM v_lagged_gdp
),
sums AS (
    SELECT
        SUM((gdp_increase - avg_gdp_increase) * (price_increase - avg_price_increase)) AS sum_gdp_price,
        SUM((gdp_increase - avg_gdp_increase) * (wage_increase - avg_wage_increase)) AS sum_gdp_wage,
        SUM((gdp_increase - avg_gdp_increase) * (gdp_increase - avg_gdp_increase)) AS sum_gdp_gdp,
        SUM((price_increase - avg_price_increase) * (price_increase - avg_price_increase)) AS sum_price_price,
        SUM((wage_increase - avg_wage_increase) * (wage_increase - avg_wage_increase)) AS sum_wage_wage
    FROM v_lagged_gdp, stats
)
SELECT
    sum_gdp_price / SQRT(sum_gdp_gdp * sum_price_price) AS corr_gdp_price_lagged,
    sum_gdp_wage / SQRT(sum_gdp_gdp * sum_wage_wage) AS corr_gdp_wage_lagged
FROM sums;

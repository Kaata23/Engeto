
/* 
 * Příprava primární tabulky

Při tvorbě primární tabulky jsem si nejprve vyselektovala relevantní data z tabulek czechia_payroll a czechia_price a připojila k nim jejich číselníky a zagregovala je po rocích, 
po kterých budeme tabulky spojovat.

Z tabulky czechia_price potřebujeme zjistit jak se měnili průměrné ceny kategorií v letech, údaje o regionu nepotřebujeme, vyfiltrujeme tedy kde je region_code prazdný, což představuje úhrn pro celou republiku. 
Dále z výběru vyloučíme Jakostní víno bílé, které se narozdíl ostatních sleduje az od roku 2015, a mohlo by nám tak zkreslit celkový průměr všech sledovaných kategoriíí.

SELECT 
	date_part('year',cp.date_from) AS price_year,
	cp.category_code AS price_category_id,
	cpc.name AS price_category_name,
	cpc.price_value,
	cpc.price_unit,
	round(avg(cp.value)::numeric,2) AS avg_price
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc
	ON cpc.code=cp.category_code
WHERE cp.region_code IS NULL
	AND cp.category_code != '212101'
GROUP BY 
	price_year,
	price_category_id,
	price_category_name,
	cpc.price_value,
	cpc.price_unit
ORDER BY 
	price_year,
	price_category_id;

Z tabulky czechia_payroll potřebujeme zjistit jak se měnili průměrné platy v jednotlivých odvětvích v letech, vyfiltrujeme value_type_code 5958, tj. průměrnou hrubou mzdu na zaměstnance 
a calculation_code 200, tj. přepočtený počet zaměstnanců na plný úvazek.

SELECT 
	cpay.payroll_year,
	cpay.industry_branch_code AS payroll_industry_id,
	cpib."name" AS payroll_industry_name,
	round(avg(cpay.value)::numeric,2) AS avg_payroll
FROM czechia_payroll cpay
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON cpib.code = cpay.industry_branch_code 
WHERE 
	cpay.value_type_code = '5958'
	AND cpay.calculation_code = '200'
GROUP BY 
	cpay.payroll_year,
	payroll_industry_id,
	payroll_industry_name 
ORDER BY 
	cpay.payroll_year,
	payroll_industry_id;

Finální tabulku připravíme spojením těchto dvou tabulek na sloupci rok, což zajistí že v tabulce budou jen data za roky, pro které máme údaje jak pro mzdy tak pro ceny.
 */

CREATE TABLE IF NOT EXISTS t_katerina_janku_project_SQL_primary_final AS
	SELECT 
		pr.*,
		pa.payroll_industry_id,
		pa.payroll_industry_name,
		pa.avg_payroll 
	FROM 
		(SELECT 
			date_part('year',cp.date_from) AS price_year,
			cp.category_code AS price_category_id,
			cpc.name AS price_category_name,
			cpc.price_value,
			cpc.price_unit,
			round(avg(cp.value)::numeric,2) AS avg_price
		FROM czechia_price cp
		LEFT JOIN czechia_price_category cpc
			ON cpc.code=cp.category_code
		WHERE 
			cp.region_code IS NULL
			AND cp.category_code != '212101'
		GROUP BY 
			price_year,
			price_category_id,
			price_category_name,
			cpc.price_value,
			cpc.price_unit) pr
	JOIN 
		(SELECT 
			cpay.payroll_year,
			cpay.industry_branch_code AS payroll_industry_id,
			cpib."name" AS payroll_industry_name,
			round(avg(cpay.value)::numeric,2) AS avg_payroll
		FROM czechia_payroll cpay
		LEFT JOIN czechia_payroll_industry_branch cpib 
			ON cpib.code = cpay.industry_branch_code
		WHERE 
			cpay.value_type_code = '5958'
			AND cpay.calculation_code = '200'
		GROUP BY 
			cpay.payroll_year,
			payroll_industry_id,
			payroll_industry_name ) pa
	ON pa.payroll_year = pr.price_year
	ORDER BY 
		pr.price_year,
		pr.price_category_id, 
		pa.payroll_industry_id;	


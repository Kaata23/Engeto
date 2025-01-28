/*
 * Sekundární tabulka bude obsahovat data s HDP, GINI koeficientem a populací dalších evropských států za stejné období, 
 * jako primární přehled pro Českou republiku.
 */


CREATE TABLE IF NOT EXISTS t_katerina_janku_project_SQL_secondary_final AS
	SELECT 
		e.country,
		e."year",
		e.gdp,
		e.population,
		e.gini,
		e.taxes
	FROM economies e 
	JOIN countries c
		ON e.country = c.country
	WHERE 
		c.continent = 'Europe'
		AND e."year" BETWEEN 
			(SELECT min(price_year) FROM t_katerina_janku_project_SQL_primary_final)
			AND 
			(SELECT max(price_year) FROM t_katerina_janku_project_SQL_primary_final); 

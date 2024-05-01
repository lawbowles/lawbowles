SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio.covid_deaths
ORDER BY 1, 2
LIMIT 100
;

-- What is the mortality rate in different countries?

SELECT location, date, total_cases, total_deaths, 100*(total_deaths/total_cases) as mortality
FROM portfolio.covid_deaths
WHERE location = 'Ireland'
ORDER BY date
;

-- What is the infection rate in different countries?
-- This is just the number of cases per capita (doesn't account for the same person testing positive multiple times)

SELECT location, MAX(total_cases), (MAX(total_cases)/population)*100 as perc_infected
FROM portfolio.covid_deaths
GROUP BY location, population
ORDER BY perc_infected DESC
;

-- What continents have the highest death counts?

SELECT location, MAX(total_deaths) as death_count
FROM portfolio.covid_deaths
WHERE continent IS NULL
GROUP BY location, population
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY death_count DESC
;


-- What countries have the highest death counts?

SELECT location, MAX(total_deaths) as death_count
FROM portfolio.covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY death_count DESC
;

-- What is the total number of deaths per capita by country?
-- Less double counting here as most people only die once

SELECT location, MAX(total_deaths) as death_count, (MAX(total_deaths)/population)*100 as perc_mortality
FROM portfolio.covid_deaths
GROUP BY location, population
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY perc_mortality DESC
;

-- What's going on with Hong Kong?
SELECT * FROM portfolio.covid_deaths
WHERE location = 'Hong Kong'
;

-- Hong Kong publishes test data monthly and doesn't publish cases or deaths, so the Covid Deaths table is empty.


-- Vaccination rate

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
	SUM(vaccine.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumul_vaccines
FROM portfolio.covid_deaths AS death
JOIN portfolio.covid_vaccines AS vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date
WHERE death.continent IS NOT NULL AND death.location = 'Ireland'
ORDER BY 2,3
;

-- Temp table

DROP TABLE IF EXISTS vaccines_per_pop;
CREATE TEMPORARY TABLE vaccines_per_pop(
	continent TEXT,
	location TEXT,
	date DATE,
	population NUMERIC,
	new_vaccinations NUMERIC,
	cumul_vaccines NUMERIC
);

INSERT INTO vaccines_per_pop
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
	SUM(vaccine.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumul_vaccines
FROM portfolio.covid_deaths AS death
JOIN portfolio.covid_vaccines AS vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3
;

SELECT *, (cumul_vaccines/population) AS vaccines_per_person FROM vaccines_per_pop;

-- Creating a view for visualisations

CREATE VIEW perc
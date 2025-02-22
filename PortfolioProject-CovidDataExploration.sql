SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL;

-- Total Cases vs. Total Deaths per Country (with Death Percentage)
SELECT location, date, total_cases, total_deaths, 
CASE
	WHEN total_cases = 0 THEN 0
	ELSE (total_deaths / total_cases) * 100
END AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs. Population per Country (with Infection Percentage)
SELECT location, date, total_cases, population, 
       (CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL)) * 100 AS infected_population_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Countries with the Highest Infection Rate Relative to Population
SELECT location, MAX(total_cases) AS highest_total_cases, population, 
       MAX((CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL))) * 100 AS highest_infected_population_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_infected_population_percentage DESC;

-- Countries with the Highest Total Death Count
SELECT location, MAX(total_deaths) AS highest_total_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_total_deaths DESC;

-- Continents with the Highest Total Death Count
SELECT continent, MAX(total_deaths) AS highest_total_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_total_deaths DESC;

-- Countries with the Highest Total Death Count per Continent
SELECT continent, location, MAX(total_deaths) AS highest_total_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent
ORDER BY highest_total_deaths DESC;

-- Countries with the Highest Infection Rate Relative to Population (Including Continent)
SELECT continent, location, MAX(total_cases) AS highest_total_cases, population, 
       MAX((CAST(total_cases AS DECIMAL) / CAST(population AS DECIMAL))) * 100 AS highest_infected_population_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY highest_infected_population_percentage DESC;

-- Global summary of relatively Total Cases and Total Deaths by Dates
SELECT date, SUM(new_cases) AS relative_total_cases, SUM(new_deaths) AS relative_total_deaths, 
CASE
	WHEN SUM(new_deaths) = 0 THEN 0
	ELSE (CAST(SUM(new_deaths) AS decimal)/CAST(SUM(new_cases) AS decimal))*100
END AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Global summary of Total Cases over Total Deaths
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (CAST(SUM(new_deaths) AS decimal)/CAST(SUM(new_cases) AS decimal))*100
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL;

-- TOTAL POPULATION VS VACCINATION
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.location, CD.Date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths CD
INNER JOIN PortfolioProject.dbo.CovidVaccinations CV
	ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

-- CTE
-- TOTAL POPULATION VS VACCINATION (WITH VACCINATION PERCENTAGE)
WITH PopVsVac (continent, location, date, population, new_vaccinations, total_vaccinations) AS (
	SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
		SUM(new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.location, CD.Date) AS total_vaccinations
	FROM PortfolioProject.dbo.CovidDeaths CD
	INNER JOIN PortfolioProject.dbo.CovidVaccinations CV
		ON CD.location = CV.location AND CD.date = CV.date
	WHERE CD.continent IS NOT NULL
)
SELECT *, CAST(total_vaccinations AS decimal) / CAST(population AS decimal) * 100 AS vaccinated_percentage
FROM PopVsVac 
--WHERE location LIKE '%states'
ORDER BY 2, 3;

-- TEMP TABLE
-- TOTAL POPULATION VS VACCINATION (WITH VACCINATION PERCENTAGE)
DROP TABLE IF EXISTS #PopulationVaccinationPerLocationAndDate
CREATE TABLE #PopulationVaccinationPerLocationAndDate (
	continent NVARCHAR(50),
	location NVARCHAR(50),
	date DATE,
	population BIGINT,
	new_vaccinations BIGINT,
	total_vaccinations BIGINT
)

INSERT INTO #PopulationVaccinationPerLocationAndDate
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.location, CD.Date) AS total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths CD
INNER JOIN PortfolioProject.dbo.CovidVaccinations CV
	ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 1,2,3

SELECT *, CAST(total_vaccinations AS decimal) / CAST(population AS decimal) * 100 AS vaccinated_percentage
FROM #PopulationVaccinationPerLocationAndDate 
--WHERE location LIKE '%states'
ORDER BY 2, 3;

-- CREATE VIEW 
-- TOTAL POPULATION VS VACCINATION (WITH VACCINATION PERCENTAGE)
GO  -- Ensure the previous batch is completed

-- Drop the view if it already exists
IF OBJECT_ID('PortfolioProject.dbo.PopulationVaccinationView', 'V') IS NOT NULL
    DROP VIEW PopulationVaccinationView;
GO

-- Create the view
CREATE VIEW PopulationVaccinationView AS
WITH PopVsVac (continent, location, date, population, new_vaccinations, total_vaccinations) AS (
	SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
		SUM(new_vaccinations) OVER (PARTITION BY CD.Location ORDER BY CD.location, CD.Date) AS total_vaccinations
	FROM PortfolioProject.dbo.CovidDeaths CD
	INNER JOIN PortfolioProject.dbo.CovidVaccinations CV
		ON CD.location = CV.location AND CD.date = CV.date
	WHERE CD.continent IS NOT NULL
)
SELECT *, CAST(total_vaccinations AS DECIMAL) / CAST(population AS DECIMAL) * 100 AS vaccinated_percentage
FROM PopVsVac;
GO  -- End the batch

SELECT *
FROM PopulationVaccinationView;

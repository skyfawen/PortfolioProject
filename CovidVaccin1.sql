-- Looking at Total Cases vs Total Deaths
DECLARE @total_cases INT
DECLARE @total_deaths INT
DECLARE @POPULATION INT


SELECT location, date, total_cases, new_cases, total_deaths, population,
CASE 
	WHEN TRY_CAST(total_cases AS float) = 0 THEN NULL
	ELSE ROUND(TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float) * 100, 2)
END AS death_rate
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%china%'
ORDER BY 1,2

SELECT location, date, total_cases, new_cases, total_deaths, population,
CASE 
	WHEN TRY_CAST(population AS float) = 0 THEN NULL
	ELSE ROUND(TRY_CAST(total_cases AS float) / TRY_CAST(population AS float) * 100, 2)
END AS cases_rate
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%china%'
ORDER BY 1,2

SELECT location, population, 
MAX(total_cases) AS HighestInfectionCount,
MAX(
CASE 
	WHEN TRY_CAST(population AS float) = 0 THEN NULL
	ELSE ROUND(TRY_CAST(total_cases AS float) / TRY_CAST(population AS float) * 100, 2)
END) AS cases_rate

FROM PortfolioProject..CovidDeaths
GROUP BY location,population
ORDER BY cases_rate DESC

SELECT continent,
MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND TRIM(continent) != ''
GROUP BY continent
ORDER BY HighestDeathCount DESC

--- Globle numbers
SELECT CAST(date AS datetime), SUM(CAST(new_cases AS INT)) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
ROUND (CASE
 WHEN SUM(CAST(new_cases AS float)) = 0 THEN NULL
 ELSE SUM(CAST(new_deaths AS float)) * 100 / SUM(CAST(new_cases AS INT))
END , 2)
 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND TRIM(continent) != ''
GROUP BY CAST(date AS datetime)
ORDER BY 1, 2

SELECT SUM(CAST(new_cases AS INT)) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
ROUND (CASE
 WHEN SUM(CAST(new_cases AS float)) = 0 THEN NULL
 ELSE SUM(CAST(new_deaths AS float)) * 100 / SUM(CAST(new_cases AS INT))
END , 2)
 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND TRIM(continent) != ''
ORDER BY 1, 2


SELECT * 
INTO CovidDeathsDedup
FROM (
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY location,date ORDER BY date) AS ROWN
	FROM PortfolioProject..CovidDeaths
) AS deduped
WHERE ROWN=1

SELECT continent, CAST(date AS date)
FROM CovidDeathsDedup
WHERE TRIM(continent) != ''
ORDER  BY continent,CAST(date AS datetime)
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY

SELECT continent, CAST(date AS date)
FROM PortfolioProject..CovidVaccinations
WHERE TRIM(continent) != ''
ORDER  BY continent,CAST(date AS datetime)
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY


--Use CTE
WITH vacc_rate (Continent, Location, report_date, population, new_vaccinations, running_total_vaccinations) 
AS (
	SELECT dea.continent,
	dea.location, 
	CAST(dea.date AS date) AS report_date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS date)) AS running_total_vaccinations
	FROM CovidDeathsDedup AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac
		on dea.location = vac.location
		and CAST(dea.date AS date) = CAST(vac.date AS date)
	WHERE dea.continent IS NOT NULL 
		AND TRIM(dea.continent) != '' 
		AND vac.new_vaccinations IS NOT NULL 
		AND TRIM(vac.new_vaccinations) != '' 
)

SELECT 
	*, 
	ROUND((CAST(running_total_vaccinations AS float) / NULLIF(CAST(population AS float),0)) * 100 , 3) AS vacc_rate
FROM vacc_rate

-- Temp table
DROP Table IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
running_total_vaccinations numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent,
	dea.location, 
	CAST(dea.date AS date) AS report_date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS date)) AS running_total_vaccinations
	FROM CovidDeathsDedup AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac
		on dea.location = vac.location
		and CAST(dea.date AS date) = CAST(vac.date AS date)
	WHERE dea.continent IS NOT NULL 
		AND TRIM(dea.continent) != '' 
		AND vac.new_vaccinations IS NOT NULL 
		AND TRIM(vac.new_vaccinations) != '' 

SELECT 
	*, 
	ROUND((running_total_vaccinations * 100 / NULLIF(population,0)),3) AS vacc_rate
FROM #PercentPopulationVaccinated

--Create View to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;
GO
Create View dbo.PercentPopulationVaccinated AS
SELECT dea.continent,
	dea.location, 
	CAST(dea.date AS date) AS report_date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS date)) AS running_total_vaccinations
	FROM CovidDeathsDedup AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac
		on dea.location = vac.location
		and CAST(dea.date AS date) = CAST(vac.date AS date)
	WHERE dea.continent IS NOT NULL 
		AND TRIM(dea.continent) != '' 
		AND vac.new_vaccinations IS NOT NULL 
		AND TRIM(vac.new_vaccinations) != '' 

SELECT * 
FROM PercentPopulationVaccinated
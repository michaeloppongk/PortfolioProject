/* 
COVID-19 Data Exploration and Analysis
Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Data Conversion, Subqueries, UNION, GROUP BY, HAVING
*/

--------------------------------------------------------------------------------------------------------------------------
-- 1. INITIAL DATA PREVIEW FOR COVID DEATHS DATASET

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3, 4;  -- SORTING BY LOCATION AND DATE

--------------------------------------------------------------------------------------------------------------------------
-- 2. FOCUSING ON KEY DATA COLUMNS FOR ANALYSIS

SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;  -- SORTING BY LOCATION AND DATE

--------------------------------------------------------------------------------------------------------------------------
-- 3. CALCULATING DEATH PERCENTAGE (TOTAL DEATHS VS TOTAL CASES)

SELECT Location, Date, Total_Cases, Total_Deaths, 
       (Total_Deaths / Total_Cases) * 100 AS DeathPercentage  -- PERCENTAGE OF DEATH FROM TOTAL CASES
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'  -- FOCUSING ON UNITED STATES DATA ONLY
  AND continent IS NOT NULL 
ORDER BY 1, 2;

--------------------------------------------------------------------------------------------------------------------------
-- 4. CALCULATING INFECTION PERCENTAGE (TOTAL CASES VS POPULATION)

SELECT Location, Date, Population, Total_Cases,  
       (Total_Cases / Population) * 100 AS PercentPopulationInfected  -- PERCENT OF POPULATION INFECTED
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;  -- SORTING BY LOCATION AND DATE

--------------------------------------------------------------------------------------------------------------------------
-- 5. IDENTIFYING COUNTRIES WITH THE HIGHEST INFECTION RATES

SELECT Location, Population, 
       MAX(Total_Cases) AS HighestInfectionCount,  -- MAX TOTAL CASES FOR EACH COUNTRY
       MAX((Total_Cases / Population) * 100) AS PercentPopulationInfected  -- PERCENT OF POPULATION INFECTED
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population  -- GROUPING BY COUNTRY AND POPULATION
HAVING MAX((Total_Cases / Population) * 100) > 10  -- ONLY SHOWING COUNTRIES WITH INFECTION RATES ABOVE 10%
ORDER BY PercentPopulationInfected DESC;  -- SORTING IN DESCENDING ORDER OF INFECTION RATE

--------------------------------------------------------------------------------------------------------------------------
-- 6. IDENTIFYING COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION

SELECT Location, 
       MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount  -- CONVERTING TOTAL DEATHS TO INTEGER FOR CALCULATION
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location  -- GROUPING BY LOCATION TO SUMMARIZE BY COUNTRY
HAVING MAX(CAST(Total_Deaths AS INT)) > 1000  -- ONLY SHOWING COUNTRIES WITH TOTAL DEATHS ABOVE 1000
ORDER BY TotalDeathCount DESC;  -- SORTING BY HIGHEST DEATH COUNT

--------------------------------------------------------------------------------------------------------------------------
-- 7. BREAKING DOWN DATA BY CONTINENTS - HIGHEST DEATH COUNT PER CONTINENT

SELECT continent, 
       SUM(CAST(Total_Deaths AS INT)) AS TotalDeathCount  -- SUMMING TOTAL DEATHS PER CONTINENT
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent  -- GROUPING BY CONTINENT
HAVING SUM(CAST(Total_Deaths AS INT)) > 50000  -- ONLY SHOWING CONTINENTS WITH TOTAL DEATHS ABOVE 50,000
ORDER BY TotalDeathCount DESC;  -- SORTING BY HIGHEST DEATH COUNT

--------------------------------------------------------------------------------------------------------------------------
-- 8. GLOBAL STATISTICS FOR COVID-19

SELECT SUM(New_Cases) AS Total_Cases, 
       SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, 
       SUM(CAST(New_Deaths AS INT)) / NULLIF(SUM(New_Cases), 0) * 100 AS DeathPercentage  -- GLOBAL DEATH PERCENTAGE
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

--------------------------------------------------------------------------------------------------------------------------
-- 9. VACCINATION DATA ANALYSIS - TOTAL POPULATION VS VACCINATIONS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated  -- CUMULATIVE VACCINATIONS FOR EACH COUNTRY
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date  -- JOINING BASED ON LOCATION AND DATE
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;  -- SORTING BY LOCATION AND DATE

--------------------------------------------------------------------------------------------------------------------------
-- 10. USING CTE (COMMON TABLE EXPRESSION) FOR POPULATION VS VACCINATION CALCULATION

WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated  -- CUMULATIVE VACCINATIONS
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated  -- CALCULATING VACCINATION PERCENTAGE
FROM PopvsVac;

--------------------------------------------------------------------------------------------------------------------------
-- 11. USING TEMP TABLE FOR POPULATION VS VACCINATION CALCULATION

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- INSERTING CALCULATED VALUES INTO THE TEMP TABLE
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- SELECTING AND CALCULATING VACCINATION PERCENTAGE
SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

--------------------------------------------------------------------------------------------------------------------------
-- 12. CREATING A VIEW TO STORE THE VACCINATION DATA FOR FUTURE VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

--------------------------------------------------------------------------------------------------------------------------
-- 13. COMPARING VACCINATION RATES BETWEEN CONTINENTS

SELECT Continent, 
       AVG(RollingPeopleVaccinated / Population * 100) AS AvgVaccinationRate  -- AVERAGE VACCINATION RATE BY CONTINENT
FROM #PercentPopulationVaccinated
GROUP BY Continent
ORDER BY AvgVaccinationRate DESC;  -- SORTING BY AVERAGE VACCINATION RATE

--------------------------------------------------------------------------------------------------------------------------
-- 14. UNION TO COMBINE VACCINATION DATA WITH COVID DATA

SELECT Location, Date, Total_Cases, Total_Deaths, Population, 'COVID' AS Source
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

UNION ALL

SELECT Location, Date, NULL AS Total_Cases, NULL AS Total_Deaths, Population, 'VACCINATION' AS Source
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL;

--------------------------------------------------------------------------------------------------------------------------
-- 15. SUBQUERY TO FIND LOCATIONS WITH HIGH VACCINATION RATES

SELECT Location, Population
FROM PortfolioProject..CovidVaccinations vac
WHERE New_Vaccinations > (SELECT AVG(New_Vaccinations) FROM PortfolioProject..CovidVaccinations)  -- LOCATIONS WITH ABOVE AVERAGE VACCINATIONS
ORDER BY Location;

--------------------------------------------------------------------------------------------------------------------------
-- 16. CREATING AN INDEX FOR IMPROVED QUERY PERFORMANCE

CREATE INDEX idx_covid_data ON PortfolioProject..CovidDeaths(Location, Date);  -- CREATING AN INDEX ON LOCATION AND DATE FOR PERFORMANCE

SELECT *
FROM [COVID-19Project]..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM [COVID-19Project]..CovidVaccinations
--ORDER BY 3,4

-- SELECT Data which is to be explored

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [COVID-19Project]..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------------
-- BREAKING THINGS BY LOCATION
----------------------------------------------------------------------------------------------------------------------------------
--LOOKING AT TOTAL_CASES VS TOTAL_DEATHS
--Showing likelihood of dying if you contract Covid-19

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [COVID-19Project]..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


----------------------------------------------------------------------------------------------------------------------------------
--LOOKING AT TOTAL_CASES VS POPULATION
-- Showing percentage of Population that has Covid-19

SELECT location, date, total_cases, population, (total_cases/population)*100 
FROM [COVID-19Project]..CovidDeaths
WHERE location LIKE '%states%'
and continent is not null
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------------
--LOOKING AT COUNTRIES WITH THE HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max(total_cases/population)*100 as PercentPopuInfected
FROM [COVID-19Project]..CovidDeaths
--WHERE location LIKE '%zimbab%'
WHERE continent is not null
GROUP BY location, population 
ORDER BY PercentPopuInfected DESC

----------------------------------------------------------------------------------------------------------------------------------
-- Showing Countries with the Highest Death Count per Population

SELECT location, population, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [COVID-19Project]..CovidDeaths
--WHERE location LIKE '%zimbab%'
--(total_deaths datatype initially not read as a numeric when using the MAX aggregate function hence CAST used)
WHERE continent is not null
GROUP BY location, population 
ORDER BY TotalDeathCount DESC


----------------------------------------------------------------------------------------------------------------------------------
-------------------BREAK THINGS BY CONTINENT--------------------
----------------------------------------------------------------------------------------------------------------------------------

-- Showing Continents with the Highest Death Count 

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [COVID-19Project]..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

CREATE VIEW DeathCountContinents as
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [COVID-19Project]..CovidDeaths
WHERE continent is null
GROUP BY location
--ORDER BY TotalDeathCount DESC

Select*
From DeathCountContinents



----------------------------------------------------------------------------------------------------------------------------------
-------------------GLOBAL NUMBERS--------------------
----------------------------------------------------------------------------------------------------------------------------------

--GRAND GLOBAL TOTALS--
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [COVID-19Project]..CovidDeaths
--WHERE location LIKE '%states%'
Where continent is not null
--GROUP BY date
ORDER BY 1,2

--TOTALS BY CONTINENT--
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [COVID-19Project]..CovidDeaths
--WHERE location LIKE '%states%'
Where continent is not null
GROUP BY date
ORDER BY 1,2



----------------------------------------------------------------------------------------------------------------------------------
----JOINING CovidDeaths & CovidVaccinations----
----------------------------------------------------------------------------------------------------------------------------------

--Looking at Total Population vs Vaccinations

--Use CTE to look at percentage of vaccinated people
WITH PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingTotalVaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
----Rolling Count of Total Vaccinations according to the LOCATION and or 'DATE'
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingTotalVaccinations
FROM [COVID-19Project]..CovidDeaths dea
JOIN [COVID-19Project]..CovidVaccinations vac
     ON dea.location = vac.location
	 and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingTotalVaccinations/Population)*100 as PercentagePopulationVaccinations
FROM PopVsVac
Order by 2,3


--Use TempTable

--Drop Table if exists (#PercentPopuVaccinated)
CREATE TABLE #PercentPopuVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingTotalVaccinations numeric
)

Insert into #PercentPopuVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
----Rolling Count of Total Vaccinations according to the LOCATION and or 'DATE'
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingTotalVaccinations
FROM [COVID-19Project]..CovidDeaths dea
JOIN [COVID-19Project]..CovidVaccinations vac
     ON dea.location = vac.location
	 and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingTotalVaccinations/Population)*100 as PercentagePopulationVaccinations
FROM #PercentPopuVaccinated
Order by 2,3



----------------------------------------------------------------------------------------------------------------------------------
----CREATING A VIEW TO STORE DATA FOR LATER VISUALISATIONS----
----------------------------------------------------------------------------------------------------------------------------------

CREATE VIEW PercentPopuVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
----Rolling Count of Total Vaccinations according to the LOCATION and or 'DATE'
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingTotalVaccinations
FROM [COVID-19Project]..CovidDeaths dea
JOIN [COVID-19Project]..CovidVaccinations vac
     ON dea.location = vac.location
	 and dea.date = vac.date
WHERE dea.continent is not null

Select *
From PercentPopuVaccinated

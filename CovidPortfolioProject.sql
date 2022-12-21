--SELECT *
--FROM covidDeaths
--ORDER BY 3,4

--SELECT *
--FROM covidvaccinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location, date

--Looking at the total cases vs total Deaths
--Shows likelihood of death by covid in the UK
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 as DeathPercentage
FROM coviddeaths
WHERE location like 'United Kingdom'
ORDER BY location, date

--Looking at the Total Cases vs Population
--Shows what percentage of population contracted Covid
SELECT location, date, population, total_cases, (total_cases/population) *100 as PercentPopulationInfected
FROM coviddeaths
--WHERE location like 'United Kingdom'
ORDER BY location, date


--Looking at countries with highest infection reate compared to Population
SELECT location, 
	population, 
	max(total_cases) as Highest_Infection_Count, 
	MAX((total_cases/population)) *100 as PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Showing the continent with the highest death count


SELECT continent,  
	max(CAST (total_deaths AS INT)) as TotalDeathCount
FROM coviddeaths
WHERE continent IS not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Global numbers

SELECT  date, 
	sum(new_cases) AS total_cases, 
	SUM(cast(new_deaths as INT)) as total_deaths,
	(SUM(cast(new_deaths as INT))/SUM(new_cases))*100 AS death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Total cases/death percentage globally
SELECT   
	sum(new_cases) AS total_cases, 
	SUM(cast(new_deaths as INT)) as total_deaths,
	(SUM(cast(new_deaths as INT))/SUM(new_cases))*100 AS death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--USING CTEs
WITH PopvsVac AS
(
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.date) 
	AS rolling_people_vaccinated
from CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location=vac.location
	AND dea.date=vac.date
	
WHERE dea.continent IS NOT NULL
)



select *,	
	(rolling_people_vaccinated/population)*100
FROM PopvsVac

--TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated

(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.date) 
	AS rolling_people_vaccinated
from CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location=vac.location
	AND dea.date=vac.date
	
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating view to store datea for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.date) 
	AS rolling_people_vaccinated
from CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT 
	location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeath
-- WHERE location = 'China'
ORDER BY location, date;

-- looking for countries with highest infection rate compared to population
SELECT 
	location,
    population,
    MAX(total_cases) AS highestInfectionCountry,
    MAX((total_cases / population))* 100 AS infectionPercentage
FROM CovidDeath
GROUP BY location, population
ORDER BY infectionPercentage DESC;

-- showing countries with highest death count per population
SELECT
	location,
    MAX(total_deaths) AS totalDeathCount
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totalDeathCount DESC;

-- let's break things down by continent
SELECT
	continent,
    MAX(total_deaths) AS totalDeathCount
FROM CovidDeath
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY totalDeathCount DESC;

-- global numbers
SELECT 
	date,
    SUM(new_cases),
    SUM(new_deaths),
    SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- USE CTE(Common Table Expression)
WITH popVsVacc AS(
SELECT 
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(new_vaccinations)
		OVER (PARTITION BY cd.location
				ORDER BY cd.location, cd.date) AS rollingPeopleVaccinated
	-- (rollingPeopleVaccinated / population) * 100
FROM CovidDeath cd
JOIN CovidVaccine cv
ON cd.location = cv.location AND cd.date = cv.date 
WHERE cd.continent IS NOT NULL
)
SELECT 
	*, 
    (rollingPeopleVaccinated / population) * 100
FROM popVsVacc;
-- ---------------------------------------------
-- create table
DROP TABLE IF EXISTS percentPopulationVaccinated;
CREATE TABLE IF NOT EXISTS percentPopulationVaccinated
(
	Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population INT,
    NewVaccinations INT,
    RollingPeopleVaccinated DOUBLE
) AS
SELECT 
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(new_vaccinations)
		OVER (PARTITION BY cd.location
				ORDER BY cd.location, cd.date) AS rollingPeopleVaccinated
	-- (rollingPeopleVaccinated / population) * 100
FROM CovidDeath cd
JOIN CovidVaccine cv
ON cd.location = cv.location AND cd.date = cv.date 
WHERE cd.continent IS NOT NULL;
SELECT 
	*, 
    (rollingPeopleVaccinated / population) * 100
FROM percentPopulationVaccinated;

-- creating view to store data for later visualizations
CREATE VIEW PopulationVaccinated AS
SELECT 
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(new_vaccinations)
		OVER (PARTITION BY cd.location
				ORDER BY cd.location, cd.date) AS rollingPeopleVaccinated
	-- (rollingPeopleVaccinated / population) * 100
FROM CovidDeath cd
JOIN CovidVaccine cv
ON cd.location = cv.location AND cd.date = cv.date 
WHERE cd.continent IS NOT NULL
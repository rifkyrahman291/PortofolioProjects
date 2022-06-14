--SHOW ALL data ON Covid death and covid vaccination

SELECT *
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location

SELECT *
FROM Project1..CovidVaccinations
ORDER BY location

-- SELECT DATA THAT WILL BE USED

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- TOTAL DEATHS VS TOTAL CASES 

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location,date

-- TOTAL DEATHS VS TOTAL CASES IN INDONESIA

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
WHERE location = 'Indonesia'
ORDER BY date

-- TOTAL CASES VS POPULATION

SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,5) AS cases_percentage
FROM Project1..CovidDeaths
ORDER BY location,date

-- TOTAL CASES VS POPULATION IN INDONESIA

SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,5) AS cases_percentage
FROM Project1..CovidDeaths
WHERE location = 'Indonesia'
ORDER BY date

-- COUNTRIES WITH HIGHEST INFECTION RATE VS POPULATION

SELECT location, MAX (total_cases) AS highest_infection, population, ROUND(MAX ((total_cases/population)*100),2) AS infection_rate
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate DESC

--COUNTRIES WITH HIGHEST DEATH COUNT 

SELECT location, MAX (cast(total_deaths as int)) AS total_deaths_count
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_deaths_count DESC

--SHOWING CONTINENT WITH HIGHEST DEATH COUNT 

SELECT continent, MAX (cast(total_deaths as int)) AS total_deaths_count
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths_count DESC

-- GOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int)) / SUM(new_cases) AS global_death_percentage
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

--JOIN COVID DEATHS TABLE WITH COVID VACCINATION TABLE 

SELECT * 
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- TOTAL POPULATION VS VACCINATION

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location,date

-- ROLLING PEOPLE VACCINATION EACH DAY EACH LOCATION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location,date

-- USE CTE

with PopvsVac (continent, location, date, population, new_vaccination, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *
FROM PopvsVac

-- People vaccinated percentage each day

with PopvsVac (continent, location, date, population, new_vaccination, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT location,date, ROUND((rolling_people_vaccinated/population)*100,2) AS rolling_people_vacc_perc
FROM PopvsVac


-- TEMP TABLE

DROP TABLE IF EXISTS #PeopleVaccinatedPercentage
CREATE TABLE #PeopleVaccinatedPercentage
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PeopleVaccinatedPercentage

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT location,date, ROUND((rolling_people_vaccinated/population)*100,2) AS rolling_people_vacc_perc
FROM #PeopleVaccinatedPercentage

--CREATING VIEW FOR STORE DATA TO LATER VISUALIZATION

CREATE VIEW PeopleVaccinatedPercentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
Select * from PortfolioProject..CovidDeaths$
Select * from PortfolioProject..CovidVaccinations$

-- ** THE DATA THAT WE ARE USING **
Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
order by 1

------------- DATA EXPLORATION -------------

-- Finding the total deaths out of the total cases
-- Estimates the chance of dying if you have COVID
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathPercent
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1

-- Countries with highest infection rate by population
Select location, population, MAX(total_cases) as highestInfection, MAX((total_cases/population))*100 as percentInfected
from PortfolioProject..CovidDeaths$
GROUP BY location, population
order by percentInfected DESC

-- Countries with highest death percentage by population
Select location, population, MAX(cast(total_deaths as int)) as numberOfDeaths, MAX(total_deaths)/population*100 as deathPercent
from PortfolioProject..CovidDeaths$
where continent is not null
GROUP BY location, population
order by numberofDeaths DESC

-- Highest death counts by continent
-- have to cast total_deaths since it is an nvarchar
Select location, MAX(cast(total_deaths as int)) as deathCount
from PortfolioProject..CovidDeaths$
where continent is null
group by location
order by deathCount DESC

-- Total death percentage in the world based off of new cases
-- have to cast new_deaths since it is an nvarchar
Select date, SUM(new_cases) as totalNewCases, SUM(cast(new_deaths as int)) as totalNewDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathPercentage 
from PortfolioProject..CovidDeaths$
where continent is not null
group by date
order by 1

-- Total vaccinations in the population 
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations 
 ,SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as totalVaccinated
from PortfolioProject..CovidDeaths$ death
join PortfolioProject..CovidVaccinations$ vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
order by location, date

-- CTE for total vaccinations
-- use to calculate total vaccinated %

With popVacc (continent, location, date, population, new_vaccinations, totalVaccinated)
as
(
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations 
 ,SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as totalVaccinated
from PortfolioProject..CovidDeaths$ death
join PortfolioProject..CovidVaccinations$ vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
)
Select *, (totalVaccinated/population)*100
from popVacc

-- Temp table for total vaccinations
-- nvarchar for limited chars
DROP Table if exists #PercentVaccinated
Create Table #PercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
population numeric,
new_vaccinations numeric,
totalVaccinated numeric
)

Insert into #PercentVaccinated
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations 
 ,SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as totalVaccinated
from PortfolioProject..CovidDeaths$ death
join PortfolioProject..CovidVaccinations$ vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
order by location, date

Select *, (totalVaccinated/population)*100
from #PercentVaccinated

-- View for Tableau Visualizations
Create View test as
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations 
 ,SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as totalVaccinated
from PortfolioProject..CovidDeaths$ death
join PortfolioProject..CovidVaccinations$ vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null

Select *
From test

------- Queries for Tableau Visualization -------

-- 1. Global Death Percentage for new cases --
SELECT SUM(new_cases) as totalNewCases, SUM(cast(new_deaths as int)) as totalNewDeaths, 
(SUM(cast(new_deaths as int)) / SUM(new_cases)) * 100 as deathPercentage
from PortfolioProject..CovidDeaths$

-- 2. Total new deaths per continent --
SELECT location, SUM(cast(new_deaths as int)) as totalDeaths
from PortfolioProject..CovidDeaths$
where continent is null
and location not in ('World', 'European Union', 'International')
group by location
order by totalDeaths desc

-- 3. Infection Rate for countries --
Select location, population, MAX(total_cases) as highestInfection, MAX((total_cases/population))*100 as percentInfected
from PortfolioProject..CovidDeaths$
GROUP BY location, population
order by percentInfected DESC

-- 4. Infection Rate for specified countries with. Same as #3, but with a date to keep track of infected timeline --
Select location, population, date, MAX(total_cases) as highestInfection, MAX((total_cases/population))*100 as percentInfected
from PortfolioProject..CovidDeaths$
where continent is null
and location not in ('World', 'European Union', 'International')
GROUP BY location, population, date
order by percentInfected DESC
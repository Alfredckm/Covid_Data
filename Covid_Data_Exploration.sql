create table coviddeaths
(
iso_code varchar(20), continent varchar(20), location varchar(50), date date, population bigint, 
total_cases int, new_cases int, new_cases_smoothed decimal(10,4), total_deaths int, new_deaths int,
new_deaths_smoothed decimal, total_cases_per_million decimal(10,4), new_cases_per_million decimal(10,4), new_cases_smoothed_per_million decimal(10,4), 
total_deaths_per_million decimal(10,4), new_deaths_per_million decimal(10,4), new_deaths_smoothed_per_million decimal(10,4), reproduction_rate decimal(10,4),
icu_patients int, icu_patients_per_million decimal(10,4), hosp_patients int, hosp_patients_per_million decimal(10,4), 
weekly_icu_admissions int, weekly_icu_admissions_per_million decimal(10,4), weekly_hosp_admissions int, 
weekly_hosp_admissions_per_million decimal(10,4)
);

LOAD DATA LOCAL INFILE "C:/Users/Alfre/Downloads/coviddeaths.csv" 
INTO TABLE coviddeaths
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'      
IGNORE 1 ROWS;                        
                        
create table covidvaccinations
(
iso_code varchar(20), continent varchar(20),location varchar(50),date date, population bigint,
total_tests int, new_tests int, total_tests_per_thousand decimal(10,4), new_tests_per_thousand decimal(10,4), new_tests_smoothed int,
new_tests_smoothed_per_thousand decimal(10,4), positive_rate decimal(10,4), tests_per_case decimal(10,4), tests_units varchar(50), total_vaccinations int,
people_vaccinated int, people_fully_vaccinated int, total_boosters int, new_vaccinations int, new_vaccinations_smoothed int,
total_vaccinations_per_hundred decimal(10,4), people_vaccinated_per_hundred decimal(10,4), people_fully_vaccinated_per_hundred decimal(10,4),
total_boosters_per_hundred decimal(10,4), new_vaccinations_smoothed_per_million int, new_people_vaccinated_smoothed int,
new_people_vaccinated_smoothed_per_hundred decimal(10,4), stringency_index decimal(10,4), population_density decimal(10,4),
median_age decimal(10,4), aged_65_older decimal(10,4), aged_70_older decimal(10,4), gdp_per_capita decimal(10,4), extreme_poverty decimal(10,4),
cardiovasc_death_rate decimal(10,4), diabetes_prevalence decimal(10,4), female_smokers decimal(10,4), male_smokers decimal(10,4),
handwashing_facilities decimal(10,4), hospital_beds_per_thousand decimal(10,4), life_expectancy decimal(10,4), human_development_index decimal(10,4),
excess_mortality_cumulative_absolute decimal(10,4), excess_mortality_cumulative decimal(10,4), excess_mortality decimal(10,4), 
excess_mortality_cumulative_per_million decimal(10,4));
                                
LOAD DATA LOCAL INFILE "C:/Users/Alfre/Downloads/covidvaccinations.csv"
INTO TABLE covidvaccinations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'      
IGNORE 1 ROWS;      

Select * 
From coviddeaths
Where continent is not null
Order by 3,4;         

# Select Data that we are going to be using
Select location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
Where continent is not null and continent <> ''
Order by 1,2;

# Looking at Total Cases vs Total Deaths
# Shows likelihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From coviddeaths
Where continent is not null and continent <> ''
Order by 1,2;

# Looking at Total Cases vs Population
# Show what percentage of population got covid
Select location, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
From coviddeaths
Where continent is not null and continent <> ''
Order by 1,2;

# Looking at Coutries with Highest Infection Rate compared to Population
Select location, population, max(total_cases) as highest_infection_count, max((total_cases/population))*100 as percent_population_infected
From coviddeaths
# Where location like "%States%"
Where continent is not null and continent <> ''
Group by location, population
Order by 4 desc;

# Showing Countries with Highest Death Count per Population
Select location, MAX(total_deaths) as total_death_count
From coviddeaths
Where continent is not null and continent <> ''
Group by location
Order by 2 asc;

# Showing Continent with Highest Death Count per Population
Select location, max(total_deaths) as total_death_count
From coviddeaths
Where continent = ''
Group by location
Order by 2 asc;

# Global Numbers
# Shows world's death_percentage by date
Select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as sum_death_percentage
From coviddeaths
Where continent is not null and continent <> ''
Group by date
Order by 1;

# Showing world's total death_percentage
Select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as sum_death_percentage
From coviddeaths
Where continent is not null and continent <> ''
Order by 1;

# Looking at total population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) Over (Partition by dea.location Order by dea.date) as rolling_people_vaccinated
#, (rolling_people_vaccinated/population)*100
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date
Where dea.location is not null and dea.continent <> ''
Order by 2,3;

# Use CTE
With popvsVac (Continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) Over (Partition by dea.location Order by dea.date) as rolling_people_vaccinated
#, (rolling_people_vaccinated/population)*100
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date
Where dea.location is not null and dea.continent <> ''
#Order by 2,3;
)
Select * , (rolling_people_vaccinated/population)*100 as Vaccination_rate
from popvsvac;

# Temp table
Drop table if exists PercentPopulationVaccinated;
create table PercentPopulationVaccinated
(
Continent varchar(20), Location varchar(50), Date date, 
Population bigint, New_Vaccinations int, rolling_people_vaccinated bigint
);
Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) Over (Partition by dea.location Order by dea.date) as rolling_people_vaccinated
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date;
#Where dea.location is not null and dea.continent <> ''
#Order by 2,3;

Select * , (rolling_people_vaccinated/population)*100 as Vaccination_rate
from PercentPopulationVaccinated;

# Creating view to store data for later visualizations
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) Over (Partition by dea.location Order by dea.date) as rolling_people_vaccinated
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date
Where dea.location is not null and dea.continent <> '';
#Order by 2,3;

SELECT * FROM profolioproject.percentpopulationvaccinated;
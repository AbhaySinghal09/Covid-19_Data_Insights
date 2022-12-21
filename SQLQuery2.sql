select * from Project1_Covid..covid_death
order by 3,4;

select Location, date, total_cases_per_million, total_deaths, population 
from Project1_Covid..covid_death 
order by 1,2;

--Total cases vs total deaths per million

select Location, date, total_cases_per_million, total_deaths_per_million,
(total_deaths_per_million/total_cases_per_million)  as death_percentage_per_million
from Project1_Covid..covid_death 
--where location like 'india'
order by 1,2;

--We do not have a column of total cases so we want to add a column which will show all the cases upto that day.
-- I have multiplied here ( (population/1 million)*total_cases_per_million) to get total no of cases.

select Location, date, total_cases_per_million, total_deaths_per_million, population,
((population/1000000)*total_cases_per_million ) as total_cases,
total_deaths
from Project1_Covid..covid_death 
--where location like 'india'
order by 1,2;

-- Nowm i will add a column in table bcz it is difficult to write this long code again and again.

--ALTER TABLE Project1_Covid..covid_death
--ADD total_cases int;

--update Project1_Covid..covid_death
--set total_cases=((population/1000000)*total_cases_per_million );

--Now i want to see how many countries have more infection rate.

select Location, population, MAX(total_cases) as max_cases, Max(Total_cases/population)*100 as Infected_Percentage
from Project1_Covid..covid_death 
group by Location, population
order by Infected_Percentage desc;

--Now i want to see how many countries have more death rate with respect to population.

select Location, population, MAX(total_deaths) as max_death, Max(total_deaths/population)*100 as Death_Percentage
from Project1_Covid..covid_death 
group by Location, population
order by Death_Percentage desc;
--Now u can see that the max_death is showing a weird type of dat format, i.e 999,998,99,997,99, 986,... its bcz of the column format,
-- So, we have to convert the datatype to int --->MAX(cast(total_deaths as int))

select Location, population, MAX(cast(total_deaths as int)) as max_death, Max(total_deaths/population)*100 as Death_Percentage
from Project1_Covid..covid_death 
group by Location, population
order by location desc;

--Now if u will see the locations then it will  also include the continents like asia and europe, 
--So, to correct this first see the data in xlsx file and see what is written in the the Continent part, its Null
--So, we will write NOT NULL querry.

select Location, population, MAX(cast(total_deaths as int)) as max_death, Max(total_deaths/population)*100 as Death_Percentage
from Project1_Covid..covid_death
where continent is NOT NULL
group by Location, population
order by location desc;

--Data by continent

select Location, MAX(cast(total_deaths as int)) as max_death
from Project1_Covid..covid_death
where continent is NULL
group by Location
order by location desc;

--grouping data of all countries by date

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project1_Covid..covid_death
where continent is not null 
Group By date
order by 1,2

--Total cases up of Covid
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project1_Covid..covid_death
where continent is not null 
--Group By date
order by 1,2


--Now we will select the covid_vaccine data and join it with the covid_death data

select cd.continent,cd.location, cd.date, cd.population, cv.new_vaccinations
from Project1_Covid..covid_vaccine as cv
join Project1_Covid..covid_death as cd
	ON cv.location=cd.location
	and cv.date=cd.date
where cd.continent is not null
order by 1;

--PARTITION defenition
--https://www.youtube.com/watch?v=6trOvsL80Oo


--here we have made a column in which i am getting the rolling people vaccinated == means the value if new_vaccine will add everyday in this column
select cd.continent,cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
from Project1_Covid..covid_vaccine as cv
join Project1_Covid..covid_death as cd
	ON cv.location=cd.location
	and cv.date=cd.date
where cd.continent is not null
order by 1;


--New Concept CTE(Common Table Expression) -
--here we are using it as we want to add newcolumn temporarily-> RollingPeopleVaccinated but, we cant do it withput using this method.

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select cd.continent,cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
from Project1_Covid..covid_vaccine as cv
join Project1_Covid..covid_death as cd
	ON cv.location=cd.location
	and cv.date=cd.date
where cd.continent is not null
--order by 1;
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
select cd.continent,cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
from Project1_Covid..covid_vaccine as cv
join Project1_Covid..covid_death as cd
	ON cv.location=cd.location
	and cv.date=cd.date
--where cd.continent is not null
--order by 1;

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating VIEW(it is a sub table from the main table we make to select some particular columns) to store data for later visualizations

Create View PercentPopulationVaccinated as
select cd.continent,cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
from Project1_Covid..covid_vaccine as cv
join Project1_Covid..covid_death as cd
	ON cv.location=cd.location
	and cv.date=cd.date
where cd.continent is not null
--order by 2,3


select * from PercentPopulationVaccinated;
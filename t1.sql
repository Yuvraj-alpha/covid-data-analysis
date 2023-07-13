use covid_dataanalysis;

select * from deaths;

select * from vaccines;

DELETE FROM vaccines
WHERE Location IN ('Thailand', 'Timor', 'Yemen', 'Vietnam', 'Turkmenistan', 'Tajikistan');

DELETE FROM deaths
WHERE Location IN ('Timor', 'Tajikistan', 'Taiwan', 'Syria', 'Sri Lanka', 'South Korea', 'Singapore', 'Saudi Arabia', 'Qatar',
                   'Yemen', 'Vietnam', 'Uzbekistan', 'United Arab Emirates', 'Turkmenistan', 'Turkey');

########################
select * from deaths
order by 3,4;
select * from vaccines
order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population 
from deaths
order by day(date) ;

#looking at total cases vs total deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death rate'
from deaths
order by 1,day(date) ;


#percentage of population that got covid
select location, date, total_cases, population, (total_cases/population)*100 as 'infected rate'
from deaths
order by 1,day(date) ;

#highest infection rate and their population per location
select location, max(cast(total_cases as unsigned)) as casecount, population, max((total_cases/population))*100 as 'infected rate'
from deaths
group by population, location
order by 4 desc ;


#highest death rate 
select location,population,max(total_deaths/total_cases)*100 as 'Death rate'
from deaths
group by location, population;

#countries with highest death count  per location
select location, max(cast(total_deaths as unsigned)) as deathcount
from deaths
group by location
order by deathcount desc;


#GLOBAL NUMBERS
#global death rates
SELECT 
    date,
    SUM(new_cases) AS 'total cases',
    SUM(CAST(new_deaths AS UNSIGNED)) AS 'total deaths',
    SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases) * 100 AS 'global death rate'
FROM
    deaths
WHERE
    continent IS NOT NULL
GROUP BY date
ORDER BY STR_TO_DATE(date, '%d-%m-%Y');

#GLOBAL SUM 
SELECT 
    SUM(new_cases) AS 'total cases',
    SUM(CAST(new_deaths AS UNSIGNED)) AS 'total deaths',
    SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases) * 100 AS 'global death rate'
FROM
    deaths
WHERE
    continent IS NOT NULL;
    
select d.location, d.date, d.population, v.total_tests, d.total_deaths
from deaths as d
join vaccines as v 
on d.location = v.location
and d.date = v.date
order by 1,2;

ALTER TABLE vaccines ADD COLUMN new_date DATE;
SET SQL_SAFE_UPDATES = 0;

UPDATE vaccines SET new_date = STR_TO_DATE(date, '%Y-%m-%d');
SELECT new_date FROM vaccines;
ALTER TABLE deaths DROP COLUMN new_date;
ALTER TABLE vaccines CHANGE new_date date DATE;

select date from vaccines;
select date from deaths;    

select d.location, d.date, d.population, v.total_tests, v.new_vaccinations
from deaths as d
join vaccines as v 
on d.location = v.location
and d.date = v.date
order by 1,2;


#total population vs vaccinated people as on date 
SELECT
    d.location,
    d.date,
    d.population,
    v.new_vaccinations AS 'new vaccinations/day',
    SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations,
    (SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) / d.population) * 100 AS vaccination_rate
FROM
    deaths AS d
JOIN
    vaccines AS v ON d.location = v.location AND d.date = v.date
ORDER BY
    1, 2;

#using a CTE to get vaccinactions vs population 
with popvsvacc (location, date, population, new_vaccincations, cumulative_vaccinations)
as 
(
select d.location, d.date, d.population,v.new_vaccinations as 'new vaccinations/day', sum(cast(v.new_vaccinations as unsigned)) over (partition by d.location
order by d.location, d.date) as  cumulative_vaccinations
from deaths as d
join vaccines as v 
on d.location = v.location
and d.date = v.date
 )
select *, (cumulative_vaccinations/population)*100 as vaccinated_ratio
from popvsvacc;


#TEMP TABLE
#drop table if exists percentpopulationvaccinated;
CREATE TABLE percentpopulationvaccinated 
(
    location CHAR(255) CHARACTER SET UTF8MB4,
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    cumulative_vaccinations NUMERIC
);

INSERT INTO percentpopulationvaccinated
SELECT
    d.location,
    d.date,
    d.population,
    NULLIF(v.new_vaccinations, '') AS new_vaccinations,
    SUM(CAST(NULLIF(v.new_vaccinations, '') AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
FROM
    deaths AS d
JOIN
    vaccines AS v ON d.location = v.location AND d.date = v.date;

SELECT
    *,
    (cumulative_vaccinations / population) * 100 AS vaccinated_ratio
FROM
    percentpopulationvaccinated;


#creating a view to store data for a later visualization 
create view percentpopulationvaccinated_view as
SELECT
    location,
    date,
    population,
    new_vaccinations,
    cumulative_vaccinations
FROM
percentpopulationvaccinated;

select* from percentpopulationvaccinated_view;






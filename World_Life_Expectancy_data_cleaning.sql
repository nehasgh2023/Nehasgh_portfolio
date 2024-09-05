-- world life expectancy data cleaning -2022--


select *
from world_life_expectancy;
 
 -- data cleaning step 1: finding the duplicates. 
 -- here in this data the country should only have 1 unique row and the Row_Id should also have unique data in each row
 -- we concatenated country and year to find the duplicate row in respect of the ROW_Id and deleted the duplicate Row_Id.

select country, year ,concat(country, year), count(concat(country, year)) 
from world_life_expectancy
group by country, year ,concat(country, year)
having count(concat(country, year)) > 1
;

select *
from(	
	select Row_ID,
	concat(country, year),
	ROW_NUMBER() OVER(PARTITION BY concat(country, year) ORDER BY concat(country, year)) AS row_num 
	from world_life_expectancy
	) as row_table
where row_num > 1
 ;

DELETE FROM world_life_expectancy
where 
Row_ID in (
	select Row_ID
	from(	
		select Row_ID,
		concat(country, year),
		ROW_NUMBER() OVER(PARTITION BY concat(country, year) ORDER BY concat(country, year)) AS row_num 
		from world_life_expectancy
		) as row_table
	where row_num > 1
 );
 
 -- data cleaning step 2: look at the data again to find the columns where they have blank data 
 -- and see whether we can populate them 

select *
from world_life_expectancy where status = '';

--  logic: we can check how many data are there in the staus columna and populate the column where 
-- there is blank data from the countries which has data from the previous years

select  Country, Status
from world_life_expectancy ;

-- if its a developing country, populate that where it is blank 

select distinct(status)
from world_life_expectancy
where status <> '';

select Country
from world_life_expectancy
where Status = 'Developing' ;

update world_life_expectancy
set Status = 'Developing'
where Country in (
	select Country
	from world_life_expectancy
	where Status = 'Developing'
    );
-- above logic is correct but it will throw an error that update can't be done in from clause 
-- use method below
-- you need to do a self join 

update world_life_expectancy t1
join world_life_expectancy t2
	on t1.Country = t2.Country
set t1.Status = 'Developing'  
where t1.Status = ''
and t2.Status <> '' 
and t2.Status = 'Developing' 
;

-- check : we only populated the ones that are developing but not those who are in developed 
select *
from world_life_expectancy
where status = '';

select *
from world_life_expectancy
where Country = 'United States of America';


update world_life_expectancy t1
join world_life_expectancy t2
	on t1.Country = t2.Country
set t1.Status = 'Developed'  
where t1.Status = ''
and t2.Status <> '' 
and t2.Status = 'Developed' 
;
 -- check for united states: it should work now 
select *
from world_life_expectancy
where Country = 'United States of America';


-- as per data we know that the life expectancy is increasing per year by some values
-- we can populate the table by taking average of two consecutive years. we need to tir the 
-- world_life_expectancy table two times
-- step1: find the year with missing value  join the table t1 to t2 with country and year  

select Country, Year, `life expectancy`
from world_life_expectancy
-- where `life expectancy` = ''
 ;
 
 select 
 t1.Country, t1.Year, t1.`life expectancy`, -- blank table 
 t2.Country, t2.Year, t2.`life expectancy`, -- one table up
 t3.Country, t3.Year, t3.`life expectancy`, -- one table down
 round((t2.`life expectancy` + t3.`life expectancy`) /2,1) as avg_life_expectancy
from world_life_expectancy t1
# where `life expectancy` = ''
join world_life_expectancy t2
	on t1.Country = t2.Country 
    and t1.Year = t2.Year - 1
join world_life_expectancy t3
	on t2.Country = t3.Country 
    and t1.Year = t3.Year + 1
where t1.`Life expectancy` = ''
 ;
 
 -- populate the empty columns
 update world_life_expectancy t1
 join world_life_expectancy t2
	on t1.Country = t2.Country 
    and t1.Year = t2.Year - 1
join world_life_expectancy t3
	on t2.Country = t3.Country 
    and t1.Year = t3.Year + 1
set t1.`Life expectancy` = round((t2.`life expectancy` + t3.`life expectancy`) /2,1) 
where t1.`Life expectancy` = ''
 ;
    
  -- exploratory data aanalysis
  -- by looking at the data we can see there are tables likes life expectancy, bml, dtatus, adult mortality rate
  -- we can try to find out if there is any corelation between the data 
  
  select *
  from world_life_expectancy;
  
-- lets see how the countries have done with thier life expectancy over the years 

select Country,min(`Life expectancy`),max(`Life expectancy`)
from world_life_expectancy
group by Country
having min(`Life expectancy`) <> 0
and max(`Life expectancy`) <> 0
order by country desc;

--  which countries have made the max strides. 
-- over 15 years 
select Country,
min(`Life expectancy`),
max(`Life expectancy`),
round(max(`Life expectancy`) -min(`Life expectancy`),1) as Life_Increase_15_Years
from world_life_expectancy
group by Country
having min(`Life expectancy`) <> 0
and max(`Life expectancy`) <> 0
order by Life_Increase_15_Years asc;

-- life expectancy for average years 

select Year, round(avg(`Life expectancy`),1)
from world_life_expectancy
where `Life expectancy` <> 0
group by Year
order by Year;

-- try to find corelation between life expectancy and all the columns

  select *
  from world_life_expectancy;
  
select country, round(avg(`Life expectancy`),1) Life_exp, round(avg(GDP)) GDP
from world_life_expectancy
group by Country
having Life_exp > 0
and GDP > 0
order by GDP desc;

-- we can see that the countries with lower life expectancy had lower gdp and vice versa

select 
sum(case when GDP > 1500 then '1' else '0' end ) high_GDP_count,
avg(case when GDP > 1500 then `Life expectancy` else null end ) high_GDP_Life_expectancy,
sum(case when GDP < 1500 then '1' else '0' end ) low_GDP_count,
avg(case when GDP < 1500 then `Life expectancy` else null end ) low_GDP_Life_expectancy
from world_life_expectancy
;

-- we can make this comparization with every data and in the table 

  select Status , round(avg(`Life expectancy`),1)
  from world_life_expectancy
  Group by Status;
  
  select Status , count(distinct Country), round(avg(`Life expectancy`),1)
  from world_life_expectancy
  Group by Status;

-- from above query its kind of clear that developing countries have lower life expectancy
-- and viceversa

 select *
  from world_life_expectancy;

select country, round(avg(`Life expectancy`),1) Life_exp, round(avg(BMI)) BMI
from world_life_expectancy
group by Country
having Life_exp > 0
and BMI > 0
order by BMI asc;

-- lower bmi definitely means low life expectancy 
-- but higher bmi can be seen is developed countries with higher life expectancy

 select *
  from world_life_expectancy;
  
 select 
 Country, 
 Year, 
 `Life expectancy`,
 `Adult Mortality`,
 sum(`Adult Mortality`) over(partition by Country Order by Year) as rolling_total
  from world_life_expectancy
  where Country like '%United%';
  
-- we could compare it with total population because adult mortality is how many people are dying 
-- and with population we could say a number in comparison to the total population
-- in real world problem we could pull that data from web and merge into this table 
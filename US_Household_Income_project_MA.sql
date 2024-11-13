#US Household Income Project Data Cleaning

SELECT * 
FROM us_project.us_household_income
;

SELECT * 
FROM us_project.us_household_income_statistics
;
#Upon looking at the Income statistics table we are getting a column name called ï»¿id, we need to fix this: 
ALTER TABLE us_project.us_household_income_statistics RENAME COLUMN `ï»¿id` TO `id`;
#Now lets check and make sure it was fixed
SELECT * 
FROM us_project.us_household_income_statistics
;

#Let's look at counts of both tables
SELECT COUNT(id)
FROM us_project.us_household_income
;

SELECT COUNT(id)
FROM us_project.us_household_income_statistics
;
#Household income table returned 32292 rows and statistics table returned 32526 rows which means there was an issue brining in some of the data from that first table. only about 230 rows it is minimal. Lets identify some duplicates: 

SELECT id, COUNT(id)
FROM us_project.us_household_income
GROUP BY id
HAVING COUNT(id) > 1
;

#This returns 6 ids with duplicates. Lets use the row id to drop these duplicates. This below is going to be our subquery. 
SELECT row_id,
id,
ROW_NUMBER() OVER(PARTITION BY id ORDER BY id)
FROM us_project.us_household_income
;
#Here is the whole thing together:

SELECT *
FROM(
	SELECT row_id,
	id,
	ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
	FROM us_project.us_household_income
	) duplicates
WHERE row_num > 1
;
#This allows us to see our duplicates as well as the associated row ids

DELETE FROM us_household_income
WHERE row_id IN (
	SELECT row_id
	FROM(
		SELECT row_id,
		id,
		ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
		FROM us_project.us_household_income
		) duplicates
	WHERE row_num > 1)
;
#This removed duplicates from us household income table. Lets do the same thing for our statistics table:

SELECT id, COUNT(id)
FROM us_household_income_statistics
GROUP BY id
HAVING COUNT(id) > 1
;
#This table has no duplicates! Now lets fix the lower case alabama in the state name 

SELECT State_Name, COUNT(State_Name)
FROM us_project.us_household_income
GROUP BY State_Name
;

SELECT DISTINCT State_Name
FROM us_project.us_household_income
ORDER BY 1
;

#Let's fix the row that says georia and make is Georgia
UPDATE us_project.us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia'
;
UPDATE us_project.us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama'
;
#Let's Make sure we did fix this:
SELECT * 
FROM us_project.us_household_income
;
#and we fixed both errors in the State_Name and lets check State_ab

SELECT DISTINCT State_ab
FROM us_project.us_household_income
ORDER BY 1
;

SELECT *
FROM us_project.us_household_income
WHERE Place = ''
ORDER BY 1
;
#There is a blank for autauga county lets fix it, only 1 row. 
SELECT *
FROM us_project.us_household_income
WHERE County = 'Autauga County'
ORDER BY 1
;

UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
AND City = 'Vinemont'
;
#Running this query shows us that we have borough and boroughs, thats a data quality issue we need to fix. 
SELECT Type, Count(Type)
FROM us_project.us_household_income
GROUP BY Type
#ORDER BY 1
;
#Lets fix that
UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs'
;
#Lets see what else needs cleaning
SELECT * 
FROM us_project.us_household_income
;

SELECT ALand, AWater
FROM us_project.us_household_income
WHERE AWater = 0 OR AWater = '' OR AWater = NULL
;

SELECT DISTINCT AWater
FROM us_project.us_household_income
WHERE AWater = 0 OR AWater = '' OR AWater = NULL
;

SELECT ALand, AWater
FROM us_project.us_household_income
WHERE (AWater = 0 OR AWater = '' OR AWater = NULL)
AND (ALand = 0 OR ALand = '' OR ALand = NULL)
;
#Data Cleaning appears to be completed for now

#US Household Income EDA 
SELECT * 
FROM us_project.us_household_income
;

SELECT * 
FROM us_project.us_household_income_statistics
;

#Right now this data goes down to the city level for Aland and Awater, so we may have to aggregate if we do higher level functions. 
SELECT State_Name, County, City, ALand, AWater
FROM us_project.us_household_income
;
#Below 2 means second column or ALand
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
;
#Now lets see what state has most AWater:
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
;

#Lets get the top 10 largest states by land:
SELECT State_Name, SUM(ALand)
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
LIMIT 10
;
#Lets get the top 10 largest states by water:
SELECT State_Name, SUM(AWater)
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
LIMIT 10
;

#Lets bring our tables together joining by id with an inner join
SELECT *
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
;

#Right Join This shows us all those rows that didn't come in from our first table when we imported it 
SELECT *
FROM us_project.us_household_income u
RIGHT JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
    WHERE u.id IS NULL
;
#Lets stick with our inner join
SELECT *
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
;
#Some of the mean median and SD data is blank, we need to filter that out. 
SELECT *
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
;
#Now we can use this data. The following is more categorical data, we want to look at this for a while. 
SELECT u.State_Name, County, Type, `Primary`, Mean, Median
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
;

SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2
;
#This query showing that MIssisippi has the lowest average household income. Lets see the bottom 5
SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2
LIMIT 5
;
#Now Lets see the top 5 highest household incomes by state
SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2 DESC
LIMIT 10
;
#Now lets look at highest median or value that shows up the most.
SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 3 DESC
LIMIT 10
;

#Now lets look at lowest median or value that shows up the most.
SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 3 ASC
LIMIT 10
;
#Lets look at type and primary
SELECT Type, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY Type
ORDER BY 2 DESC
LIMIT 20
;

SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY Type
ORDER BY 2 DESC
LIMIT 20
;
#The average is so higfh for municipality because thats only based on 1 value. 
#Now lets look at median
SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY Type
ORDER BY 4 DESC
LIMIT 20
;
#What States have Community, which happens to only be Puerto Rico
SELECT u.State_Name
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Type LIKE '%Community%'
;
#WE have some outliers that we may wnat to filter out, like municipality with only 1 value. 
SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY 1
HAVING COUNT(Type) > 100
ORDER BY 4 DESC
LIMIT 20
;
#Lets look at the big cities and see if the salaries in the larger cities are very high. 
SELECT u.State_Name, City, Round(AVG(Mean),1), Round(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
GROUP BY u.State_Name, City
ORDER BY Round(AVG(Mean),1) DESC
;

#The highest mean salary in the US is 'Delta Junction' alaska 242857 a year
#Lets look at Median salary in cities
SELECT u.State_Name, City, Round(AVG(Mean),1), Round(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
GROUP BY u.State_Name, City
ORDER BY Round(AVG(Median),1)DESC
;

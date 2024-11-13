#World Life Expectancy Project(Data Cleaning) 
#Line here was done due to My SQL having the safe updates option set. The line below undoes this 
SET SQL_SAFE_UPDATES = 0;
#Data Set before Data Cleaning begins below
SELECT * 
FROM world_life_expectancy
;

#Data cleaning steps. First lets see if we can remove some duplicates. Lets see if we have duplicates, we should only have 1 year for each country so Afghanistan should only have 1 row with the year 2022. Below we are going to combine the country and year into a new column and then we will group by both the Country, Year, Concat(Country, Year). After that we will filter by Count(Concat(Country, Year)) using a HAVING Command and then say > 1 which will tell us if we have any duplicates. 

SELECT Country, Year, Concat(Country, Year), Count(Concat(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, Concat(Country, Year)
HAVING Count(Concat(Country, Year)) > 1 
;

#This returned 3 duplicates Ireland 2022, Senegal 2009 and Zimbabwe 2019. We will need to use the below code as a subquery in the From statement because we won't be able to filter on this. 

SELECT Row_ID, 
Concat(Country, Year),
ROW_NUMBER() OVER( PARTITION BY Concat(Country, Year) ORDER BY Concat(Country, Year)) as Row_Num
FROM world_life_expectancy
;

#Subquery
SELECT *
FROM(
	SELECT Row_ID, 
	Concat(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY Concat(Country, Year) ORDER BY Concat(Country, Year)) as Row_Num
	FROM world_life_expectancy
	) AS Row_Table
WHERE Row_Num > 1
;

#We needed a subquery like above in order to filter with the Where Statement. Now we want to delete the duplicates

DELETE FROM world_life_expectancy
WHERE 
	Row_ID IN (
    SELECT Row_ID
FROM(
	SELECT Row_ID, 
	Concat(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY Concat(Country, Year) ORDER BY Concat(Country, Year)) as Row_Num
	FROM world_life_expectancy
	) AS Row_Table
WHERE Row_Num > 1
)
;
#It says 3 rows were affected in the output lets check and make sure things were deleted by re running this query:
SELECT *
FROM(
	SELECT Row_ID, 
	Concat(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY Concat(Country, Year) ORDER BY Concat(Country, Year)) as Row_Num
	FROM world_life_expectancy
	) AS Row_Table
WHERE Row_Num > 1
;
#When we ran this query the output showed nothing, meaning the duplicates were deleted. 

SELECT * 
FROM world_life_expectancy
;

#Now the next step will be to see how many null values we have:
SELECT *
FROM world_life_expectancy
WHERE Status = ''
;

#We returned 8 rows that have blanks under status, but the good thing is the countries have other years that do have status filled in. So here we can populate those blanks based on the other years for each country. The query below will let us know the 2 distinct options in the status column are Developing and Developed

SELECT DISTINCT(Status)
FROM world_life_expectancy
WHERE Status <> ''
;

#This query will be used to show us all the countries that are developing
SELECT DISTINCT(Country)
FROM world_life_expectancy
WHERE Status = 'Developing'
;

UPDATE world_life_expectancy
SET Status = 'Developing'
WHERE Country IN (
				SELECT DISTINCT(Country)
				FROM world_life_expectancy
				WHERE Status = 'Developing'
				)
                ;
#The above query gave us an error code 1093, cant update from the FROM clause. Here is our work around:
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = '' 
AND t2.Status <> ''
AND t2.Status = 'Developing'
;

#Lets take a look and see if it updated: United States of America is left but that is Developed not Developing 
SELECT *
FROM world_life_expectancy
WHERE Status = ''
;

SELECT *
FROM world_life_expectancy
WHERE Country = 'United States of America'
;

#So NOw we need to do the same thing but for developed: 

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = '' 
AND t2.Status <> ''
AND t2.Status = 'Developed'
;

SELECT *
FROM world_life_expectancy
WHERE Status = ''
;

#Now Duplicates have been removed and Blanks and Status have been addressed. Let's look at all the data and see what to clean next. 

SELECT * 
FROM world_life_expectancy
;

#Life Expectancy has blanks TRhe query below shows that there are 2  rows Afghanistan and Albania. If you look at the afghanistan data we see since 2007 data is slowly going up. We may want to take the year before this blank and year after this blank and populate it with the average.
SELECT * 
FROM world_life_expectancy
Where `Life expectancy` = ''
;

SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
;
#What we had to do here was join the tables with a self join and do year plus 1 and year minus 1 to get a row with values from 2017 2018 and 2019. Then we had to do the average  and update t1.life expectancy
SELECT t1.Country, t1.Year, t1.`Life expectancy`,
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	On t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	On t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = ''
;

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	On t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	On t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1)
WHERE t1.`Life expectancy` = ''
;
#Lets Check our Work
SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
;

SELECT *
FROM world_life_expectancy
;
#For Now Data Cleaning Phase appears to be completed

#World Life Expectancy Project(Exploratory Data Analysis EDA)
#Let's see what insights we are able to find in this data

SELECT *
FROM world_life_expectancy
;
#Let's use the following query to see how much life expectancy has changed from the oldest entry to the newest
SELECT Country, MIN(`Life expectancy`), MAX(`Life expectancy`)
FROM world_life_expectancy
GROUP BY Country
ORDER BY Country DESC
;
#So we have some data with zeroes which doesnt make sense, likely a data quality issue. Let's filter this out with a HAVING: 

SELECT Country,
MIN(`Life expectancy`),
MAX(`Life expectancy`)
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Country DESC
;

#Now we want to see which country has made the largest leap between its lowest and highest life expectancy and lets order by our new column LIFE_INCREASE_15_YEARS

SELECT Country,
MIN(`Life expectancy`),
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) AS LIFE_INCREASE_15_YEARS
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY LIFE_INCREASE_15_YEARS DESC
;
#Now Lets check the lowest life increase:
SELECT Country,
MIN(`Life expectancy`),
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) AS LIFE_INCREASE_15_YEARS
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY LIFE_INCREASE_15_YEARS ASC
;
#Now Lets check average life expectancy for each year:

SELECT Year, ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancy
GROUP BY Year
ORDER BY Year DESC
;

#Right now we have our averages for each year but we need to filter out those zero values which could be bringing down our averages: We need to use WHERE instead of HAVING, because having is only for aggregations. Where goes before group by, having goes after group by but before order by

SELECT Year, ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancy
WHERE `Life expectancy` <> 0
AND `Life expectancy` <> 0
GROUP BY Year
ORDER BY Year 
;

#World Life Expectancy has increased about 6 years from 2007 to 2022 in this data set. 

SELECT *
FROM world_life_expectancy
;

#Lets check the correlation of Life expectancy to all other columns. EX. Does GDP have correlation to life expectancy? Let's be sure to get rid of the 0 values as well with a having statement since these are aggregations. 

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS AVG_LE, ROUND(AVG(GDP),1) AS AVG_GDP
FROM world_life_expectancy
GROUP BY Country
HAVING AVG_LE > 0
AND AVG_GDP > 0
ORDER BY AVG_LE
;
#Order BY GDP 
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS AVG_LE, ROUND(AVG(GDP),1) AS AVG_GDP
FROM world_life_expectancy
GROUP BY Country
HAVING AVG_LE > 0
AND AVG_GDP > 0
ORDER BY AVG_GDP
;

#Were seeing that lower GDPS have lower life expectancy. The countries that make more money have higher life expectancy. Positive correlation at first glance. 

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS AVG_LE, ROUND(AVG(GDP),1) AS AVG_GDP
FROM world_life_expectancy
GROUP BY Country
HAVING AVG_LE > 0
AND AVG_GDP > 0
ORDER BY AVG_GDP DESC
;

#We are going to write a case statement below to put things into category so we can group on them. 
SELECT 
CASE 
	WHEN GDP >= 1500 THEN 1 
    ELSE 0
END High_GDP_Count
FROM world_life_expectancy
;
#WE actually want the sum of the case statement which will show we have 1326 rows that have a GDP higher than 1500
SELECT 
SUM(CASE 
	WHEN GDP >= 1500 THEN 1 
    ELSE 0
END) High_GDP_Count
FROM world_life_expectancy
;
#Now lets add to this, lets add an average in: When we say this: AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE 0 END) High_GDP_Count we are doing the average of life expectancy when they have a high GDP
SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE 0 END) High_GDP_Life_Expectancy
FROM world_life_expectancy
;
#Avg life expectancy here is showing 33 which seems wrong, lets change the 0 in our else statement to null. This shows avg life expectancy to be 74, which does make more sense here. 
SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END) High_GDP_Life_Expectancy
FROM world_life_expectancy
;
#Now Lets add in the inverse of the above statement. The retun shows High GDP countries with average LE of 74 while its 64.6 for the Low GDP countries. 

SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END) High_GDP_Life_Expectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) LOW_GDP_Count,
AVG(CASE WHEN GDP <= 1500 THEN `Life expectancy` ELSE NULL END) LOW_GDP_Life_Expectancy
FROM world_life_expectancy
;

SELECT *
FROM world_life_expectancy
;

#Now lets look at average life expectancy between the 2 statuses, developing and developed. Return of the query shows Developing avg LE 66.8 and 79.2 for developed. But we need a query to show how many countries are in each status category. 

SELECT Status, ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status
;
#32 developed and 161 developing. the numbers for LE average are skewed a bit because there are less developed countries being averaged than developing. 
SELECT Status, COUNT(DISTINCT Country)
FROM world_life_expectancy
GROUP BY Status
;

#Lets Combine our last 2 queries: 
SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status
;

#Now lets look at BMI:
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS AVG_LE, ROUND(AVG(BMI),1) AS AVG_BMI
FROM world_life_expectancy
GROUP BY Country
HAVING AVG_LE > 0
AND AVG_BMI > 0
ORDER BY AVG_BMI DESC
;
#The data is howing that the countries with higher life expectancy also have high BMI. Usually BMI is associated with bad health and dying earlier, but it could be that if you have a high GDP your people eat better and are likely to have a higher BMI. 

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS AVG_LE, ROUND(AVG(BMI),1) AS AVG_BMI
FROM world_life_expectancy
GROUP BY Country
HAVING AVG_LE > 0
AND AVG_BMI > 0
ORDER BY AVG_BMI ASC
;

SELECT *
FROM world_life_expectancy
;

#Were going to do a rolling total using adult mortality. like 263 plus the row below 271 and so on. this is how we are going to do it SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) we have to order by year so it will add the adult mortaility year after year. 

SELECT Country,
Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Mortality_Total
FROM world_life_expectancy
;
#So for afghanistan 4305 adults have died within the last 15 years. 

SELECT Country,
Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Mortality_Total
FROM world_life_expectancy
WHERE Country LIKE '%United%'
;

#Lets do the same thing for infant deaths that we did for adult mortality
SELECT Country,
Year,
`Life expectancy`,
`infant deaths`,
SUM(`infant deaths`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_infantd_Total
FROM world_life_expectancy
;

#Lets combine the last 2 queries:
SELECT Country,
Year,
`Life expectancy`,
`infant deaths`,
SUM(`infant deaths`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_infantd_Total,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Mortality_Total
FROM world_life_expectancy
;

#Now lets look specifically at the United States:
SELECT Country,
Year,
`Life expectancy`,
`infant deaths`,
SUM(`infant deaths`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_infantd_Total,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Mortality_Total
FROM world_life_expectancy
WHERE Country LIKE '%United States of America%'
;
#This query shows us that over the last 15 years we have had 419 infant deaths and 931 adult deaths. 

SELECT *
FROM world_life_expectancy
;
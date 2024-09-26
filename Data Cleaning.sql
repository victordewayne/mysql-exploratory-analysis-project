#Data Cleaning

SELECT *
FROM layoffs;

#1. REMOVE DUPLICATES
#2. STANDARDIZE DATA
#3. NULL VALUES OR BLANK VALUES
#4. REMOVE ANY COLUMNS

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;


#How to identify dupes, using by adding a row num to give unique value to each row

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

#AFTER ADDING A ROW NUM TO EACH ROW WE DO A CTE (COMMON TABLE EXPRESSION)

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT*
FROM duplicate_cte
WHERE row_num > 1
;

#we want to remove one of the duplicates, not the whole row. CTE can't be updated 
#we copy the cte and put in another table and deleting the original


#created a table named layoff_staging2 and put the existing data in this new table

CREATE TABLE `layoffs_staging2`(
	`company` text,
    `location` text,
    `industry` text,
    `total_laid_off` int DEFAULT NULL,
    `percentage_laid_off` text, 
    `date` text,
    `stage` text,
    `country` text,
    `funds_raised_millions` int DEFAULT NULL,
    `row_num` int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



SELECT*
FROM layoffs_staging2;

#Inserted the data into the new table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

#DELETED THE ROWS WHICH HAD ROW_NUM GREATER THAN 1 WHICH ARE DUPLICATES 
#Delete wont work until you change preference in sql editor, the safe mode thing and untick it then 
#restart the workbench to take effect 

DELETE
FROM layoffs_staging2
WHERE row_num > 1 ;

SELECT * 
FROM layoffs_staging2
;

# STANDARDIZING DATA

#Removing the white space of the data in the company column using TRIM() 
SELECT DISTINCT (company), TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT *
FROM layoffs_staging2;

#Checking the industry column 
SELECT DISTINCT (industry)
FROM layoffs_staging2
ORDER BY 1;

#Selecting crypto specifically because there are multiple rows in the name similar to crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

#Updating the crypto currency into crypto 
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

#Checking location column
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

#Checking country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

#One way to fix this because the united states had a period afterwards and only single data is like that
#but if there is more data then there is another method to follow
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

#Method two to fix trailing, means the last symbol in a data i guess as per my understanding and
#we are mentioning the column name as country so if there is a period in any rows its gonna be removed
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


#Date time series  using `date` because date is a keyword so we use backtick 
#using str_to_date which converts the date type text into date format
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');


#This is to change data type of the `date` column
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


#NULL VALUE AND BLANK

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT DISTINCT industry 
FROM layoffs_staging2;

#Updating the blank value to null values
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '' ;


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry ='';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

#Joining the same table to populate the null value with the existing row for airbnb
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry  IS NOT NULL
;
UPDATE  layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

#If there is no row then we cant populate the null with


#Deleting both total laid off and percentage if it is Null 
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

#Finalized cleaned data
SELECT *   
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP row_num;

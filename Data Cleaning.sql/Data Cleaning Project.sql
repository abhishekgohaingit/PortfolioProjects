-- Data Cleaning

SELECT *
FROM layoffs;

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens

CREATE TABLE layoffs_staging AS
SELECT *
FROM layoffs;

-- now when we are data cleaning we usually follow a few steps
-- 1. Check for duplicates and remove any
-- 2. Standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. Remove any columns and rows that are not necessary - few ways


-- 1. Remove Duplicates

# First let's check for duplicates

SELECT *
FROM layoffs_staging;

SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, `date`) AS row_num
FROM layoffs_staging;

SELECT *
FROM (
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, `date`) AS row_num
	FROM layoffs_staging
    ) AS duplicates
WHERE row_num > 1;

-- let's just look at oda to confirm

SELECT *
FROM layoffs_staging
WHERE company = 'Oda';

-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- these are our real duplicates 

SELECT *
FROM (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
     FROM layoffs_staging
     ) AS duplicates
WHERE row_num > 1;

-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially
-- As cte's are not updatable we need to create a new layoffs_staging2 table with the additional row_num column
-- and delete those records where row_num > 1.

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Now we can insert all the data with the additional row_num column

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
     FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- now that we have this we can delete rows were row_num is greater than 2

DELETE
FROM layoffs_staging2
WHERE row_num > 1;





-- 2. Standardize Data

-- if we look at company there are some white spaces

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. 
-- Let's standardize this.

SELECT DISTINCT(country)
FROM layoffs_staging
ORDER BY country;

UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Let's also fix the date columns:

SELECT 
	`date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- we can use str to date to update this field

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now we can convert the data type properly

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these

SELECT DISTINCT(industry)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with

UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NUll;

-- now we can populate those null values easily

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. 
-- but records having nulls in both total_laif_off and percentage_laid_off are useless as they cannot be used in any eda process.
-- We can delete those useless data.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 4. remove any columns and rows we need to

SELECT *
FROM layoffs_staging2;

-- we don't need the row_num column anymore, so we can drop it

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

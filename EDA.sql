-- Exploratory Data Analysis

-- Here we are jsut going to explore the data and find trends or patterns or anything interesting like outliers
-- normally when you start the EDA process you have some idea of what you're looking for
-- with this info we are just going to look around and see what we find!

SELECT * 
FROM layoffs_staging2;

-- Max and min laid offat one go

SELECT MAX(total_laid_off), MIN(total_laid_off)
FROM layoffs_staging2;


-- Looking at Percentage to see how big these layoffs were

SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM layoffs_staging2;

-- Which companies had 1 which is basically 100 percent of they company laid off
-- these are mostly startups it looks like who all went out of business during this time

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- if we order by funcs_raised_millions we can see how big some of these companies were

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- BritishVolt and Quibi raised like 2 billion dollars and went under

------------------------------------------------------------------------------------------------------------------

-- Companies with the biggest single Layoff
SELECT company, total_laid_off
FROM layoffs_staging2
ORDER BY 2 DESC
LIMIT 5;
-- now that's just on a single day

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- this it total in the past 3 years or in the dataset

-- by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY industry
ORDER BY 2 DESC;

-- by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY country
ORDER BY 2 DESC;

-- by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- by stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY stage
ORDER BY 2 DESC;

--------------------------------------------------------------------------------------------

-- Rolling Total of Layoffs Per Month

SELECT DATE_FORMAT(`date`, '%Y-%m') AS `month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
GROUP BY `month`
ORDER BY 1;

WITH Rolling_Total AS
(
	SELECT DATE_FORMAT(`date`, '%Y-%m') AS `month`, SUM(total_laid_off) AS total_off
	FROM layoffs_staging2
	WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
	GROUP BY `month`
	ORDER BY 1
)
SELECT *,
	SUM(total_off) OVER(ORDER BY `month` ASC) AS rolling_total
FROM Rolling_Total;

-- Earlier we looked at Companies with the most Layoffs. Now let's look at that per year.
-- we want to see top 5 companies that laid off most employees in a year

SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, `year_month`
ORDER BY total_laid_off DESC;

WITH company_year AS
(
	SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS total_laid_off 
FROM layoffs_staging2
GROUP BY company, years
), company_year_rank AS
(
SELECT *,
	DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
)
SELECT *
FROM company_year_rank
WHERE ranking <= 5;

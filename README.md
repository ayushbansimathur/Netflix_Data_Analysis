# Netflix Movies and TV Shows Data Analysis using SQL

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
CREATE TABLE IF NOT EXISTS netflix_data 
    (
    show_id	VARCHAR(10),
    type VARCHAR(10),
    title VARCHAR(150),
    director VARCHAR(250),
    casts VARCHAR(800),
    country VARCHAR(150),
    date_added DATE,
    release_year INT,
    rating VARCHAR(10),
    duration VARCHAR(15),
    listed_in VARCHAR(100),
    description VARCHAR(500)
    );
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
    SELECT DISTINCT
        type,
        COUNT(*) OVER(PARTITION BY type)
    FROM netflix_data;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
    WITH rank_1 AS
        (
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY COALESCE(movie_rating_count,0) DESC) AS rank_movie,
            DENSE_RANK() OVER (ORDER BY COALESCE(TV_rating_count,0) DESC) AS rank_tv_shows
        FROM (
            SELECT
                type,
                rating,
                CASE 
                    WHEN type = 'Movie' THEN COUNT(*)
                END AS movie_rating_count,
                CASE 
                    WHEN type = 'TV Show' THEN COUNT(*)
                END AS TV_rating_count
            FROM netflix_data
            GROUP BY 1,2
            ORDER BY movie_rating_count DESC, TV_rating_count DESC
        )
        )

SELECT type, rating FROM rank_1
WHERE rank_movie = 1 OR rank_tv_shows =1
```
**Alternate_Solution**
```sql
    WITH ranks AS 
            (
            SELECT
                type,
                rating,
                count_rating,
                DENSE_RANK() OVER(PARTITION BY type ORDER BY count_rating DESC) AS rank_per_ratings
            FROM 
                (
                    SELECT 
                        type,
                        rating,
                        COUNT(*) AS count_rating
                    FROM netflix_data
                    GROUP BY 1,2
                    ORDER BY count_rating DESC
                )
            )

    SELECT * FROM ranks WHERE rank_per_ratings = 1 
```
**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
    SELECT * 
    FROM netflix
    WHERE release_year = 2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
    WITH rank_per_country_content AS (
        SELECT 
            country,
            COUNT(*) AS count_countries,
            DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking_countries
        FROM
            (
            SELECT 
                country,
                UNNEST(STRING_TO_ARRAY(country,','))
                --STRING_TO_ARRAY(country,',')
            FROM netflix_data 
            WHERE country IS NOT NULL
            )
        GROUP BY country
        ORDER BY count_countries DESC
    )

    SELECT * FROM rank_per_country_content
    WHERE ranking_countries <= 5;
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
    SELECT 
        type,
        title,
        COALESCE(SPLIT_PART(duration,' ', 1):: INT,0) AS time_duration
    FROM netflix_data 
    WHERE   type = 'Movie' AND 
            SPLIT_PART(duration,' ', 1):: INT IS NOT NULL
    ORDER BY time_duration DESC
    LIMIT 5;
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
    SELECT
        * 
    FROM netflix_data
    WHERE date_added >= current_date - INTERVAL '5 years';
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
    SELECT * FROM 
        (
        SELECT 
            UNNEST(STRING_TO_ARRAY(director,',')) AS directors_list,
            title,
            type
        FROM netflix_data
        WHERE 
            type = 'Movie'
        )
    WHERE directors_list = 'Rajiv Chilaka';
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
    SELECT
        type,
        title,
        SPLIT_PART(duration,' ',1)::INT AS seasons_number
    FROM netflix_data
    WHERE 
        type = 'TV Show' AND
        SPLIT_PART(duration,' ',1)::INT > 5
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
    SELECT distinct
        STRING_TO_TABLE(listed_in,',') AS distinct_genre,
        COUNT(*) AS count_per_genre
    FROM netflix_data
    GROUP BY STRING_TO_TABLE(listed_in,',')
    ORDER BY count_per_genre DESC
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
    SELECT 
        country, 
        release_year, 
        COUNT(show_id) AS total_release, 
        ROUND
            (COUNT(show_id)::numeric / (SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100, 2) 
        AS avg_release 
    FROM netflix 
    WHERE country = 'India' 
    GROUP BY country, release_year 
    ORDER BY avg_release DESC 
    LIMIT 5;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
    SELECT  
        type,
        title
    FROM
        (
        SELECT 
            type,
            title,
            UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre
        FROM netflix_data
        WHERE type = 'Movie'
        )
    WHERE genre = 'Documentaries'
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
    SELECT 
        *
    FROM netflix_data 
    WHERE director IS NULL
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
    SELECT
        COUNT(*) 
    FROM netflix_data
    WHERE 
        casts LIKE '%Salman Khan%' AND
        release_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
    SELECT * FROM
        (
            SELECT
                casts_1,
                COUNT(*) AS apperance,
                DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
            FROM 
                (
                    SELECT 
                        type, 
                        title,
                        country,
                        STRING_TO_TABLE(casts,',') AS casts_1
                    FROM netflix_data
                    WHERE
                        casts IS NOT NULL AND 
                        country LIKE '%India%'
                )
            GROUP BY 1
            ORDER BY 2 DESC
        )
    WHERE ranking <= 10
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
    SELECT
        (CASE
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END) AS category,
        COUNT(*) AS count_per_category
    FROM netflix_data
    GROUP BY 1

```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.

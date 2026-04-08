-- 1. Count the number of Movies vs TV Shows
    SELECT DISTINCT
        type,
        COUNT(*) OVER(PARTITION BY type)
    FROM netflix_data;

-- 2. Find the most common rating for movies and TV shows
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

    -- Alternative Method (More Efficient)--
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

-- 3. List all movies released in a specific year (e.g., 2020)
    SELECT * 
    FROM netflix
    WHERE release_year = 2020;

-- 4. Find the top 5 countries with the most content on Netflix
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

-- 5. Identify the longest movie
    SELECT 
        type,
        title,
        COALESCE(SPLIT_PART(duration,' ', 1):: INT,0) AS time_duration
    FROM netflix_data 
    WHERE   type = 'Movie' AND 
            SPLIT_PART(duration,' ', 1):: INT IS NOT NULL
    ORDER BY time_duration DESC
    LIMIT 5;

-- 6. Find content added in the last 5 years
    SELECT
        * 
    FROM netflix_data
    WHERE date_added >= current_date - INTERVAL '5 years';

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'! 
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

-- 8. List all TV shows with more than 5 seasons
    SELECT
        type,
        title,
        SPLIT_PART(duration,' ',1)::INT AS seasons_number
    FROM netflix_data
    WHERE 
        type = 'TV Show' AND
        SPLIT_PART(duration,' ',1)::INT > 5

-- 9. Count the number of content items in each genre
    SELECT distinct
        STRING_TO_TABLE(listed_in,',') AS distinct_genre,
        COUNT(*) AS count_per_genre
    FROM netflix_data
    GROUP BY STRING_TO_TABLE(listed_in,',')
    ORDER BY count_per_genre DESC

-- 10.Find each year and the average numbers of content release in India on netflix. 
    --return top 5 year with highest avg content release!
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

-- 11. List all movies that are documentaries

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

    -- Alternative Method
    SELECT * 
    FROM netflix_data
    WHERE listed_in LIKE '%Documentaries';

-- 12. Find all content without a director
    SELECT 
        *
    FROM netflix_data 
    WHERE director IS NULL

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
    SELECT
        COUNT(*) 
    FROM netflix_data
    WHERE 
        casts LIKE '%Salman Khan%' AND
        release_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 20

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
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

-- 15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
    -- the description field. Label content containing these keywords as 'Bad' and all other 
    -- content as 'Good'. Count how many items fall into each category.
    SELECT
        (CASE
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END) AS category,
        COUNT(*) AS count_per_category
    FROM netflix_data
    GROUP BY 1


#Observing and Understanding
select * from netflix_country
-- order by show_id;
-- where country ='South Korea'
ORDER BY CAST(SUBSTRING(show_id, 2) AS UNSIGNED);

-- Handling foreign characters
# Mysql i changed CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci

-- Remove duplicates 
select show_id,COUNT(*) 
from netflix_raw
group by show_id 
having COUNT(*)>1;

#No duplicated found on show_id

select title,type, count(*)
from netflix_raw
group by title,type
having COUNT(*)>1;

-- Primary key ==>show id
# also chnaged its format 

-- SELECT *
-- FROM netflix_raw
-- WHERE (upper(title), type) IN (
--     SELECT upper(title), type
--     FROM netflix_raw
--     GROUP BY upper(title), type
--     HAVING COUNT(*) > 1
-- )
-- ORDER BY title;


-- select * from netflix_raw
-- where concat(upper(title),type)  in (
-- select concat(upper(title),type) 
-- from (
-- select upper(title),type
-- from netflix_raw
-- group by upper(title) ,type
-- having COUNT(*)>1
-- ) as t
-- )
-- order by title;
WITH cte AS (
    SELECT TRIM(UPPER(title)) AS clean_title, 
           TRIM(UPPER(type)) AS clean_type,
           COUNT(*) as duplicate_count
    FROM netflix_raw 
    GROUP BY TRIM(UPPER(title)), TRIM(UPPER(type))
    HAVING duplicate_count>1
)
SELECT nr.* 
FROM netflix_raw nr
WHERE (TRIM(UPPER(nr.title)), TRIM(UPPER(nr.type))) IN (
    SELECT clean_title, clean_type 
    FROM cte
)
ORDER BY nr.title;
-- with cte as (
-- select upper(title),upper(type),count(title) as no_ from netflix_raw
-- group by upper(title),upper(type)
-- having no_>1
-- )
-- select * from netflix_raw 
-- where (TRIM(upper(title)), TRIM(upper(type))) in
-- (
-- 	select TRIM(upper(title)), TRIM(upper(type)) from cte

-- )
-- order by title;

WITH cte AS (
    SELECT 
        TRIM(UPPER(title)) AS title_upper,
        TRIM(UPPER(type)) AS type_upper,
        COUNT(*) AS no_
    FROM netflix_raw
    GROUP BY title_upper, type_upper
    HAVING no_ > 1
)
SELECT nr.*
FROM netflix_raw nr
JOIN cte
  ON TRIM(UPPER(nr.title)) = cte.title_upper
 AND TRIM(UPPER(nr.type)) = cte.type_upper
ORDER BY nr.title;


CREATE TABLE netflix AS
with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from netflix_raw
)
select show_id,type,title, STR_TO_DATE(date_added, '%M %d, %Y') as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description
from cte;

select * from netflix
order by show_id;


select count(*) from cte
where rn=1;

-- new table for listed_in,director, country,cast
-- SELECT 
--     show_id,
--     TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(director, ','),-1)) AS director
-- FROM netflix_raw;


-- select show_id , trim(value) as director
-- into netflix_directors
-- from netflix_raw
-- cross apply string_split(director,',')


-- select show_id , trim(value) as genre
-- into netflix_genre
-- from netflix_raw
-- cross apply string_split(listed_in,',')


-- data type conversions for date added 
select show_id,country from netflix_raw where country is null;

select show_id,country from netflix_country order by show_id;



-- populate missing values in country,duration columns
insert into netflix_country
select  show_id,m.country 
from netflix_raw nr
inner join (
select director,country
from  netflix_country nc
inner join netflix_directors nd on nc.show_id=nd.show_id
group by director,country
) m on nr.director=m.director
where nr.country is null
order by show_id;

select * from netflix_raw where director='Ahishor Solomon';

select director,country
from  netflix_country nc
inner join netflix_directors nd on nc.show_id=nd.show_id
group by director,country;

-------------------
select * from netflix_raw where duration is null;


-- populate rest of the nulls as not_available
-- drop columns director , listed_in,country,cast








-- netflix data analysis

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */
select nd.director 
,COUNT(distinct case when n.type='Movie' then n.show_id end) as no_of_movies
,COUNT(distinct case when n.type='TV Show' then n.show_id end) as no_of_tvshow
from netflix n
inner join netflix_directors nd on n.show_id=nd.show_id
group by nd.director
having COUNT(distinct n.type)>1;


-- 2 which country has highest number of comedy movies 
select nc.country , COUNT(distinct ng.show_id ) as no_of_movies
from netflix_genre ng
inner join netflix_country nc on ng.show_id=nc.show_id
inner join netflix n on ng.show_id=nc.show_id
where ng.listed_in='Comedies' and n.type='Movie'
group by  nc.country
order by no_of_movies desc
limit 1;


-- 3 for each year (as per date added to netflix), which director has maximum number of movies released
with cte as (
select nd.director,YEAR(date_added) as date_year,count(n.show_id) as no_of_movies
from netflix n
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie'
group by nd.director,YEAR(date_added)
)
, cte2 as (
select *
, ROW_NUMBER() over(partition by date_year order by no_of_movies desc, director) as rn
from cte
-- order by date_year, no_of_movies desc
)
select * from cte2 where rn=1;



-- 4 what is average duration of movies in each genre
select ng.listed_in , avg(cast(REPLACE(duration,' min','') AS UNSIGNED)) as avg_duration
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
where type='Movie'
group by ng.listed_in;

-- 5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 
select nd.director
, count(distinct case when ng.listed_in='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.listed_in='Horror Movies' then n.show_id end) as no_of_horror
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie' and ng.listed_in in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct ng.listed_in)=2;

select * from netflix_genre where show_id in 
(select show_id from netflix_directors where director='Steve Brill')
order by listed_in;

-- Steve Brill	5	1


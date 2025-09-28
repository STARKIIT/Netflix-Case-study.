RENAME TABLE netflix_raw TO netflix_raw_backup;
DROP TABLE netflix_raw;
create TABLE `netflix_raw`
 ( `show_id`  VARCHAR(20) primary key,
 `type` VARCHAR(7),
 `title` VARCHAR(150),
 `director` VARCHAR(250), 
 `cast` VARCHAR(1000),
 `country` VARCHAR(150),
 `date_added` VARCHAR(25),
 `release_year` int DEFAULT NULL,
 `rating` VARCHAR(10),
 `duration` VARCHAR(15),
 `listed_in` VARCHAR(80),
 `description` VARCHAR(500))
 ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci

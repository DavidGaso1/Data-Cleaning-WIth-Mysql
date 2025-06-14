--Created by Davidson Ahuruezenma.
Complete data query using data from kegal (olympic games played)
the purpose of this is to carefully draw insights and understand fully the nature of olympic games played and how best it informs our
knowledge of games and best guess into future occurances.

DROP TABLE IF EXISTS OLYMPICS_HISTORY;
CREATE TABLE IF NOT EXISTS "MDBS"."OLYMPICS_HISTORY"
(
    id          INT,
    name        VARCHAR,
    sex         VARCHAR,
    age         VARCHAR,
    height      VARCHAR,
    weight      VARCHAR,
    team        VARCHAR,
    noc         VARCHAR,
    games       VARCHAR,
    year        INT,
    season      VARCHAR,
    city        VARCHAR,
    sport       VARCHAR,
    event       VARCHAR,
    medal       VARCHAR
);

DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_REGIONS;
CREATE TABLE IF NOT EXISTS "MDBS"."OLYMPICS_HISTORY_NOC_REGIONS"
(
    noc         VARCHAR,
    region      VARCHAR,
    notes       VARCHAR
);

select * from "MDBS"."OLYMPICS_HISTORY_NOC_REGIONS";
select * from "MDBS"."OLYMPICS_HISTORY";

CREATE TABLE IF NOT EXISTS "MDBS"."OLY_HIS" AS "MDBS"."OLYMPICS_HISTORY";

CREATE TABLE IF NOT EXISTS "MDBS"."OLY_REG" AS "MDBS"."OLYMPICS_HISTORY_NOC_REGIONS";

select count(distinct games) as total_olympic_games
    from "MDBS"."OLY_HIS";


1. How many olympics games have been held?
select count(distinct games) as total_olympic_games
    from "MDBS"."OLY_HIS";

  
2. List down all Olympics games held so far. (Data issue at 1956-"Summer"-"Stockholm")

    select distinct oh.year,oh.season,oh.city
    from "MDBS"."OLY_HIS" oh
    order by year;
    
3. Mention the total no of nations who participated in each olympics game?

select nr.region as country,medal, count(1) as total_medal 
        from "MDBS"."OLY_HIS" oh
        join "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
		where medal <>'NA'
        group by nr.region, medal
        order by nr.region, medal;

   with all_countries as
        (select games, nr.region from "MDBS"."OLY_HIS" oh
        join "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
        group by games,nr.region)
	select games, count(1) as total_countries from all_countries
        group by games
		order by games; 

4. Which year saw the highest and lowest no of countries participating in olympics

      with all_countries as
              (select games, nr.region
              from  "MDBS"."OLY_HIS" oh
              join  "MDBS"."OLY_REG" nr ON nr.noc=oh.noc
              group by games, nr.region),
          total_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from total_countries
      order by 1;


5. Which nation has participated in all of the olympic games
      with total_games as
              (select count(distinct games) as total_games
              from "MDBS"."OLY_HIS"),
          countries as
              (select games, nr.region as country
              from "MDBS"."OLY_HIS" oh
              join "MDBS"."OLY_REG" nr ON nr.noc=oh.noc
              group by games, nr.region),
          countries_participated as
              (select country, count(1) as total_participated_games
              from countries
              group by country)
      select cp.*
      from countries_participated cp
      join total_games tg on tg.total_games = cp.total_participated_games
      order by 1;


6. Identify the sport which was played in all summer olympics.
       with t1 as
          	(select count(distinct games) as total_games
          	from "MDBS"."OLY_HIS" where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from "MDBS"."OLY_HIS" where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;
 
7. Which Sports were just played only once in the olympics.
       with t1 as
          	(select distinct games, sport
          	from "MDBS"."OLY_HIS"),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;



8. Fetch the total no of sports played in each olympic games.
      with t1 as
      	(select distinct games, sport
      	from "MDBS"."OLY_HIS"),
        t2 as
      	(select games, count(1) as no_of_sports
      	from t1
      	group by games)
      select * from t2
      order by no_of_sports desc;


9. Fetch oldest athletes to win a gold medal
    with temp as
            (select name,sex,cast(case when age = 'NA' then '0' else age end as int) as age
              ,team,games,city,sport, event, medal
            from "MDBS"."OLY_HIS"),
        ranking as
            (select *, rank() over(order by age desc) as rnk
            from temp
            where medal='Gold')
    select *
    from ranking
    where rnk = 1;


10. Find the Ratio of male and female athletes participated in all olympic games.
    with t1 as
        	(select sex, count(1) as cnt
        	from "MDBS"."OLY_HIS"
        	group by sex),
        t2 as
        	(select *, row_number() over(order by cnt) as rn
        	 from t1),
        min_cnt as
        	(select cnt from t2	where rn = 1),
        max_cnt as
        	(select cnt from t2	where rn = 2)
    select concat('1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as ratio
    from min_cnt, max_cnt;


11. Top 5 athletes who have won the most gold medals.
    with t1 as
            (select name, team, count(1) as total_gold_medals
            from "MDBS"."OLY_HIS"
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;


12. Top 5 athletes who have won the most medals (gold/silver/bronze).
    with t1 as
            (select name, team, count(1) as total_medals
            from "MDBS"."OLY_HIS"
            where medal in ('Gold', 'Silver', 'Bronze')
            group by name, team
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_medals desc) as rnk
            from t1)
    select name, team, total_medals
    from t2
    where rnk <= 5;

13. Top 5 most successful countries in olympics. Success is defined by no of medals won.
     with t1 as
            (select nr.region, count(1) as total_medals
            from "MDBS"."OLY_HIS" oh
            join "MDBS"."OLY_REG" nr on nr.noc = oh.noc
            where medal <> 'NA'
            group by nr.region
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over(order by total_medals desc) as rnk
            from t1)
    select *
    from t2
    where rnk <= 5;


-- PIVOT
In Postgresql, we can use crosstab function to create pivot table.
crosstab function is part of a PostgreSQL extension called tablefunc.
To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION "MDBS".TABLEFUNC;

14. List down total gold, silver and broze medals won by each country.

    SELECT * FROM "MDBS".CROSSTAB('select nr.region as country,medal, count(1) as total_medal 
				        from "MDBS"."OLY_HIS" oh
				       	join "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
						where medal <> ''NA''
				        group by nr.region, medal
				        order by nr.region, medal')
				AS RESULT("COUNTRY" VARCHAR, "BRONZE" BIGINT, "SILVER" BIGINT);



15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.

   SELECT substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country
        , coalesce(gold, 0) as gold
        , coalesce(silver, 0) as silver
        , coalesce(bronze, 0) as bronze
    FROM  "MDBS". CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM  "MDBS"."OLY_HIS" oh
                JOIN  "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint);


-- PIVOT
In Postgresql, we can use crosstab function to create pivot table.
crosstab function is part of a PostgreSQL extension called tablefunc.
To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;



16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

   WITH temp as
    	(SELECT substring(games, 1, position(' _ ' in games) - 1) as games
    	 	, substring(games, position(' _ ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM "MDBS".CROSSTAB('SELECT concat(games, '' _ '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM  "MDBS"."OLY_HIS" oh
    				  JOIN  "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    		select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    	 , first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;





17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

    with temp as
    	(SELECT substring(games, 1, position(' _ ' in games) - 1) as games
    		, substring(games, position(' _ ' in games) + 3) as country
    		, coalesce(gold, 0) as gold
    		, coalesce(silver, 0) as silver
    		, coalesce(bronze, 0) as bronze
    	FROM "MDBS".CROSSTAB('SELECT concat(games, '' _ '', nr.region) as games
    					, medal
    					, count(1) as total_medals
    				  FROM "MDBS"."OLY_HIS" oh
    				  JOIN  "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)),
    	tot_medals as
    		(SELECT games, nr.region as country, count(1) as total_medals
    		FROM "MDBS"."OLY_HIS" oh
    		JOIN "MDBS"."OLY_REG" nr ON nr.noc = oh.noc
    		where medal <> 'NA'
    		GROUP BY games,nr.region order BY 1, 2)
    select distinct t.games
    	, concat(first_value(t.country) over(partition by t.games order by gold desc)
    			, ' - '
    			, first_value(t.gold) over(partition by t.games order by gold desc)) as Max_Gold
    	, concat(first_value(t.country) over(partition by t.games order by silver desc)
    			, ' - '
    			, first_value(t.silver) over(partition by t.games order by silver desc)) as Max_Silver
    	, concat(first_value(t.country) over(partition by t.games order by bronze desc)
    			, ' - '
    			, first_value(t.bronze) over(partition by t.games order by bronze desc)) as Max_Bronze
    	, concat(first_value(tm.country) over (partition by tm.games order by total_medals desc nulls last)
    			, ' - '
    			, first_value(tm.total_medals) over(partition by tm.games order by total_medals desc nulls last)) as Max_Medals
    from temp t
    join tot_medals tm on tm.games = t.games and tm.country = t.country
    order by games;
	 



18. Which countries have never won gold medal but have won silver/bronze medals?
   
   select * from (
    	SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
    		FROM "MDBS".CROSSTAB('SELECT nr.region as country
    					, medal, count(1) as total_medals
    					FROM "MDBS"."OLY_HIS" oh
    					JOIN "MDBS"."OLY_REG" nr ON nr.noc=oh.noc
    					where medal <> ''NA''
    					GROUP BY nr.region,medal order BY nr.region,medal',
                    'values (''Bronze''), (''Gold''), (''Silver'')')
    		AS FINAL_RESULT(country varchar,
    		bronze bigint, gold bigint, silver bigint)) x
    where gold = 0 and (silver > 0 or bronze > 0)
    order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;



19. In which Sport/event, Nigeria has won highest medals.
     
	 With t1 as
        	(select sport, count(1) as total_medals
        	from  "MDBS"."OLY_HIS"
        	where medal <> 'NA'
        	and team = 'Nigeria'
        	group by sport
        	order by total_medals desc),
        t2 as
        	(select *, rank() over(order by total_medals desc) as rnk
        	from t1)
    select sport, total_medals
    from t2
    where rnk = 1;

20. Break down all olympic games where Nigeria won medal for Basketball and how many medals in each olympic games
   
   select team, sport, games, count(1) as total_medals
    from "MDBS"."OLY_HIS"
    where medal <> 'NA'
    and team = 'Nigeria' and sport = 'Football'
    group by team, sport, games
    order by total_medals desc;
CREATE TABLE ball(match_id int,over_id int,ball_id int,innings_no int,team_batting text,
team_bowling text,striker_batting_position int,extra_type text,runs_scored int,extra_runs int,
wides int,legbyes int,byes int,noballs int,penalty int,bowler_extras int,out_type text,caught int,
bowled int,run_out int,lbw int,retired_hurt int,stumped int,caught_bowled int,hit_wicket int,
obstructingfield int,bowler_wicket int,match_date text,season int,striker int,non_striker int,
bowler int,player_out int,fielders int,striker_match_sk int,strikersk int,nonstriker_match_sk int,
nonstriker_sk int,fielder_match_sk int,fielder_sk int,bowler_match_sk int,bowler_sk int,
playerout_match_sk int,battingteam_sk int,bowlingteam_sk int,keeper_catch int,player_out_sk int,matchdatesk text);

create view overs_runs as select bowler, player_name, over_id,match_id,innings_no, sum(runs_scored) as runs_given from ball,player where bowler = player.player_id
      group by (bowler, player_name, over_id,match_id,innings_no) order by bowler;

COPY ball FROM '/Users/rahulbansal/Desktop/8th_Sem/Database/ipl/ipl-data-till-2017/Balls.csv' delimiter ',' csv header;

CREATE TABLE teams(Team_SK int, Team_Id int, Team_Name text);
COPY teams FROM '/Users/rahulbansal/Desktop/8th_Sem/Database/ipl/ipl-data-till-2017/Team.csv' delimiter ',' csv header;


CREATE TABLE match(Match_SK int ,match_id int ,Team1 text ,Team2 text,match_date text,Season_Year int ,Venue_Name text ,
City_Name text ,Country_Name text,Toss_Winner text ,match_winner text,Toss_Name text,Win_Type text,
Outcome_Type text ,ManOfMach text ,Win_Margin text ,Country_id int);


COPY match FROM '/Users/rahulbansal/Desktop/8th_Sem/Database/ipl/ipl-data-till-2017/Match.csv' delimiter ',' csv header;


CREATE TABLE player(PLAYER_SK int ,Player_Id int ,Player_Name text,DOB text ,Batting_hand text ,Bowling_skill text ,Country_Name text);
COPY player FROM '/Users/rahulbansal/Desktop/8th_Sem/Database/ipl/ipl-data-till-2017/Player.csv' delimiter ',' csv header;



create view playerscore as select striker,sum(runs_scored) as total_runs from ball group by striker;

create view playerfs as select striker,count(ball_id) as total_balls, count(ball_id) filter(where runs_scored=6) as total_six,
	count(ball_id) filter(where runs_scored=4) as total_four,sum(runs_scored) as total_runs, (sum(runs_scored)/cast(count(ball_id) as decimal))*100 as strike_rate
	 from ball group by striker order by striker asc;

create view match_stats as select match_id, striker, sum(runs_scored) as runs 
 from ball group by (match_id,striker) order by striker; 

create view per_striker_match_stats as select striker, count(match_id) filter(where runs>=100) as Hundreds,
count(match_id) filter(where runs>=50 and runs<100) as Fiftys, count(match_id) as matches, max(runs) as top_score,
AVG(runs) as Average from match_stats group by striker order by striker;

create view Batting_stats as select playerfs.striker, player.Player_Name,player.Batting_hand, playerfs.total_runs, per_striker_match_stats.top_score, 
per_striker_match_stats.Hundreds, per_striker_match_stats.Fiftys, per_striker_match_stats.matches,
ROUND(cast(per_striker_match_stats.Average as numeric),2) as Average, playerfs.total_balls, playerfs.total_six, playerfs.total_four, 
ROUND(cast(playerfs.strike_rate as numeric),2) as Strike_rate
from playerfs,per_striker_match_stats,player
where playerfs.striker = per_striker_match_stats.striker and playerfs.striker = player.Player_Id order by striker; 


create view Bowling_stats as select bowler, player.Player_Name, sum(runs_scored) as Runs, sum(bowler_wicket) as Wickets_taken, count(ball_id) as total_balls, 
count(ball_id) filter(where runs_scored=6) as total_six, count(ball_id) filter(where runs_scored=4) as total_four, 
count(match_id) as Matches, ROUND(cast((sum(runs_scored)/cast(count(ball_id) as decimal)) as numeric),2)*6 as Economy
from ball,player where player.Player_Id = ball.bowler group by (bowler, player.Player_Name) order by bowler;





-- Fastest fiftey

create view ball_cum_runs as 
                  select match_id,innings_no,striker,over_id,ball_id,count(ball_id) filter(where extra_type not in ('wides')) over w
                  as num_balls,count(ball_id) filter(where runs_scored=6) over w as num_6s,
                  count(ball_id) filter(where runs_scored=4) over w as num_4s,
                  sum(runs_scored) over w as cumm_runs 
                  from ball where innings_no<=2
                  window w as (partition by match_id,striker order by over_id,ball_id);


create view ball_cum_runs1 as
                  select match_id,innings_no,player.player_name,min(num_balls) as balls_faced,max(num_6s) as num_6s,max(num_4s) as num_4s,max(cumm_runs) as runs
                  from ball_cum_runs join player on ball_cum_runs.striker=player.player_id
                  where cumm_runs>=50
                  group by match_id,striker,player.player_name,innings_no
                  order by Balls_Faced
                  limit 100;

create view team_match as
select match_id,innings_no,team_batting,cast(team_bowling as int) from ball group by (match_id,innings_no,team_batting,team_bowling) order by match_id;


create view ball_cum_runs2 as
                  select ball_cum_runs1.match_id,player_name,team_bowling as team_id,match_date,balls_faced,num_6s,num_4s,runs
                  from ball_cum_runs1 join team_match on ball_cum_runs1.match_id=team_match.match_id and ball_cum_runs1.innings_no=team_match.innings_no
                  join match on ball_cum_runs1.match_id=match.match_id;

select player_name,team_name as Against,match_date,balls_faced,num_6s,num_4s,runs
                  from ball_cum_runs2 join teams on ball_cum_runs2.team_id=teams.team_id
                  order by balls_faced,runs desc,num_6s desc,num_4s desc;


-- Fastest 100

create view ball_cumm_runs as 
                  select match_id,innings_no,striker,over_id,ball_id,count(ball_id) filter(where extra_type not in ('wides')) over w
                  as num_balls,count(ball_id) filter(where runs_scored=6) over w as num_6s,
                  count(ball_id) filter(where runs_scored=4) over w as num_4s,
                  sum(runs_scored) over w as cumm_runs 
                  from ball where innings_no<=2
                  window w as (partition by match_id,striker order by over_id,ball_id);


create view ball_cumm_runs1 as
                  select match_id,innings_no,player.player_name,min(num_balls) as balls_faced,max(num_6s) as num_6s,max(num_4s) as num_4s,max(cumm_runs) as runs
                  from ball_cumm_runs join player on ball_cumm_runs.striker=player.player_id
                  where cumm_runs>=100
                  group by match_id,striker,player.player_name,innings_no
                  order by Balls_Faced
                  limit 100;


create view ball_cumm_runs2 as
                  select ball_cumm_runs1.match_id,player_name,team_bowling as team_id,match_date,balls_faced,num_6s,num_4s,runs
                  from ball_cumm_runs1 join team_match on ball_cumm_runs1.match_id=team_match.match_id and ball_cumm_runs1.innings_no=team_match.innings_no
                  join match on ball_cumm_runs1.match_id=match.match_id;


select player_name,team_name as Against,match_date,balls_faced,num_6s,num_4s,runs
                  from ball_cumm_runs2 join teams on ball_cumm_runs2.team_id=teams.team_id
                  order by balls_faced,runs desc,num_6s desc,num_4s desc;

--Dot balls
create view balls_dot as select bowler, player_name, count(ball_id) from ball,player where bowler = player.player_id and runs_scored=0 group by (bowler,player_name) order by bowler;

--Maiden Overs
create view maiden_overs as
select player_name, count(*) as nmaiden
from (
select distinct bowler, over_id, count(*)
from ball
where runs_scored = 0
and ( ( extra_runs = 0 and (extra_type = 'wides' or extra_type = 'noballs' or extra_type = 'No Extras') ) or ( extra_type = 'legbyes' or extra_type = 'byes' or extra_type = 'penalty') )
group by match_id, bowler, over_id) as nmaiden1, player
where nmaiden1.count = 6
and bowler = player_id
group by player_name
order by nmaiden desc;


-- Matches Stats

create view num_matches_1 as select Team1,Season_Year, count(*) from match group by (Team1,Season_Year) order by Season_Year;
create view num_matches_2 as select Team2,Season_Year, count(*) from match group by (Team2,Season_Year) order by Season_Year;
create view num_matches as select Team1, num_matches_1.Season_Year, num_matches_1.count+num_matches_2.count as matches_played from num_matches_1,num_matches_2 
      where num_matches_2.Team2 = Team1 and num_matches_2.Season_Year = num_matches_1.Season_Year  order by Team1;

create view matches_won as select match_winner,Season_Year,count(*) from match group by (match_winner,Season_Year) order by Season_Year;

create view matches_stats as select Team1, matches_won.Season_Year, matches_played, matches_won.count as matches_won,  
      matches_played - matches_won.count as matches_lost, (matches_won.count)*2 as points from matches_won,num_matches 
      where Team1 = matches_won.match_winner and matches_won.Season_Year = num_matches.Season_Year order by matches_won.Season_Year;


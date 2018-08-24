--
-- Scripts used for the integration between gps tracks and questionnaires 
-- coming from the experiment
-- Part B: evaluating trip shapes
--


-- View for the trips as an straight line from origin to destination

drop view shapes.trips_answers;
create view shapes.trips_answers as
select t.trip_count, t.device, q.group,
	q.dem_gender gender, q.profile_cycling_8, q.profile_cycling_10, q.profile_cycling_15, q.profile_cycling_1,
	q.gaming_app_cycling, q.gaming_app_cycling_strava, q.satisfaction_2,
	q.engagement_any_app_future, q.engagement_a3,
	t.geometry geometry
from trips.trips_simple t, questionnaire.answers q
where t.device = q.device and 
	q.group != 'none';


select * 
from shapes.trips_answers
order by trip_count

drop view shapes.test
create view shapes.test as
select t.*
from trips.trips_simple t, questionnaire.answers q
where t.device = q.device

select *
from shapes.trips_answers where trip_count = 1602
group by trip_count, device
having count(trip_count) > 1

-- View for the trips as an straight line from origin to destination

drop view shapes.trips_answers_area;
create view shapes.trips_answers_area as
select t.trip_count, t.device,
	ST_ConcaveHull(geometry, 0.9) geometry
from trips.trips_simple t
group by t.device



questionnaire.answers q
where t.device = q.device and 
	q.group != 'none';
	
	
	ST_ConcaveHull(t.geometry, 0.8) geometry
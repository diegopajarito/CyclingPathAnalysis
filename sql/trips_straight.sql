--
-- Scripts used for the integration between gps tracks and questionnaires 
-- coming from the experiment
-- Part A: simplifying trips using lines
--


-- View for the trips as an straight line from origin to destination

drop view shapes.trips_line
create view shapes.trips_line as
select trip_count, device, ST_MakeLine(ST_StartPoint(geometry), ST_EndPoint(geometry)) geometry
from trips.trips_simple



-- View for the trips as an straight line from origin to destination

drop view shapes.trips_line_centred
create view shapes.trips_line_centred as
select trip_count, device, 
	ST_MakeLine(st_makepoint(-0.03752, 39.98583),
				st_makepoint(st_x(ST_StartPoint(geometry)) - st_x(ST_EndPoint(geometry)) + (-0.03752),
							st_y(ST_StartPoint(geometry)) - st_y(ST_EndPoint(geometry)) + 39.98583)
				) geometry
from trips.trips_simple
where st_y(st_centroid(geometry)) between 39.92 and 40.203
union
select trip_count, device, 
	ST_MakeLine(st_makepoint(7.6251, 51.9632),
				st_makepoint(st_x(ST_StartPoint(geometry)) - st_x(ST_EndPoint(geometry)) + 7.6251,
							st_y(ST_StartPoint(geometry)) - st_y(ST_EndPoint(geometry)) + 51.9632)
				) geometry
from trips.trips_simple
where st_y(st_centroid(geometry)) between 51.89 and 52.11
union
select trip_count, device, 
	ST_MakeLine(st_makepoint(14.48246, 35.90132),
				st_makepoint(st_x(ST_StartPoint(geometry)) - st_x(ST_EndPoint(geometry)) + 14.48246,
							st_y(ST_StartPoint(geometry)) - st_y(ST_EndPoint(geometry)) + 35.90132)
				) geometry
from trips.trips_simple
where st_y(st_centroid(geometry)) between 35.82 and 35.97













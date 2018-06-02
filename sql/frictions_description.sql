
-- Data Management for describing frictions
-- We start from the dissolved grid spots with proportion of
-- walking / cycling segments between 50% and 150%


----------------------------------------------------------
--- Second Attempt 
----------------------------------------------------------

-- Spatial aggregation of the places possibly having frictions
-- A) the grid spots filling the different conditions
drop materialized view grid.level3_places;
create materialized view grid.level3_places as
select *, round((n_segments_l_5kmh * 100.0 / n_cycling_segments),2) intensity
from grid.grid_reduced
where n_segments_l_5kmh > 2 and
	n_cycling_segments > 2 and
	(n_segments_l_5kmh * 100.0 / n_cycling_segments) > 50.0 and
	(n_segments_l_5kmh * 100.0 / n_cycling_segments) < 200.0 and
	st_intersects(geometry, (select st_union(st_buffer(geometry, 0.00025))
							 from trips.od)) = FALSE;
	
CREATE INDEX sidx_level3_places ON grid.level3_places USING gist (geometry);

-- B) the aggregated spots
drop materialized view grid.level3_places_agg;
create materialized view grid.level3_places_agg as
select (st_dump(st_union(geometry))).path[1] id, (st_dump(st_union(geometry))).geom geometry
from grid.level3_places;
CREATE INDEX sidx_level3_places_agg ON grid.level3_places_agg USING gist (geometry);

-- C) Summary statistics of aggregated spots or frictions!!
drop materialized view grid.frictions_level3;
create materialized view grid.frictions_level3 as
select a.id, count(g.*) n_grid_spots, 
	round(avg(g.n_segments_l_5kmh),0) n_segments_l_5kmh,
	round(avg(g.n_cycling_segments),0) n_cycling_segments,
	round(avg(g.intensity),2) intensity,
	round(avg(g.n_trips),0) n_trips,
	round(avg(g.n_segments),0) n_segments,
	max(g.city) city,
	max(in_umz) in_umz,
	a.geometry geometry
from grid.level3_places_agg a, grid.level3_places g
where ST_Contains(a.geometry, g.geometry)
group by a.id, a.geometry
order by count(g.*);
CREATE INDEX sidx_frictions_level3 ON grid.frictions_level3 USING gist (geometry);


----------------------------------------------------------
--- Firt Attempt 
----------------------------------------------------------

drop table grid.frictions;
select * from grid.frictions;

-- 1) Update UMZ and FUA
update grid.frictions f
set in_fua = 1
from  aoi.fua u
where st_intersects(f.geometry,u.geometry);

update grid.frictions f
set in_umz = 1
from  aoi.umz u
where st_intersects(f.geometry,u.geometry);

-- 2) Update trips count
update grid.frictions f
set has_trips = 1
from  trips.trips_raw t
where st_intersects(f.geometry,t.geometry);

update grid.frictions f
set n_trips = (select count(*)
			   from trips.trips_raw ti
			   where st_intersects(ti.geometry, f.geometry))
from trips.trips_raw t
where st_intersects(f.geometry, t.geometry);

-- 3) Update segments count
update grid.frictions f
set n_segments = (select count(*)
			   from trips.segments si
			   where st_intersects(si.geometry, f.geometry))
from trips.segments s
where st_intersects(f.geometry, s.geometry);

-- < 5 km/h
update grid.frictions f
set n_segments_l_5kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry < 5 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry < 5 and
	st_intersects(f.geometry, s.geometry);

-- 5 - 10 km/h
update grid.frictions f
set n_segments_b_5_10kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 5 and 10 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry between 5 and 10 and
	st_intersects(f.geometry, s.geometry);

-- 10 - 20 km/h
update grid.frictions f
set n_segments_b_10_20kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 10 and 20 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry between 10 and 20 and
	st_intersects(f.geometry, s.geometry);

-- 20 - 30 km/h
update grid.frictions f
set n_segments_b_20_30kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 20 and 30 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry between 20 and 30 and
	st_intersects(f.geometry, s.geometry);

-- 30 - 50 km/h
update grid.frictions f
set n_segments_b_30_50kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 30 and 50 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry between 30 and 50 and
	st_intersects(f.geometry, s.geometry);

-- 50 - 70 km/h
update grid.frictions f
set n_segments_b_50_70kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 50 and 70 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry between 50 and 70 and
	st_intersects(f.geometry, s.geometry);

-- > 70 km/h
update grid.frictions f
set n_segments_h_70kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry > 70 and
				  st_intersects(si.geometry, f.geometry))
from trips.segments s
where s.speed_geometry > 70 and
	st_intersects(f.geometry, s.geometry);


-- Updatint cycling segments
update grid.frictions
set n_cycling_segments = n_segments_b_5_10kmh + n_segments_b_10_20kmh + n_segments_b_20_30kmh + n_segments_b_30_50kmh;


-- count trips origin and destination
update grid.frictions f
set n_origin = (select count(*)
			   from trips.od od
			   where od.type = 'origin' and
				  st_intersects(od.geometry, f.geometry))
from trips.od o
where o.type = 'origin' and
	st_intersects(f.geometry, o.geometry);

update grid.frictions f
set n_destination = (select count(*)
			   from trips.od od
			   where od.type = 'destination' and
				  st_intersects(od.geometry, f.geometry))
from trips.od o
where o.type = 'destination' and
	st_intersects(f.geometry, o.geometry);


-- Create a view with the relevant frictions
create or replace view grid.relevant_frictions as
select fid, in_umz, in_fua, n_segments, n_trips, n_segments_l_5kmh, n_cycling_segments, city, area, geometry
from grid.frictions;
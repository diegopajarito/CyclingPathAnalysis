--------
--
-- This script compiles a series of SQL commands using the spatial capabilities
-- PostGIS and PostgreSQL to calculate the metrics that support the analysis
-- to replicate this procedures you need to setup an spatial database
-- following the structure described in the documentation
-- This scripts are just indicative of the process followed
-- Author: Diego Pajarito
--
------


-- In the following commands we mostly use st_intersection for identifying
-- overlapping objects and count them

-- find the grids crossed by at least a trip
update grid.grid
set has_trips = 1
from trips.trips_raw t
where st_intersects(grid.grid.geometry, t.geometry);

-- find the grids inside a functiona urban area - fua
update grid.grid
set in_fua = 1
from aoi.fua ua
where st_intersects(grid.grid.geometry, ua.geometry);

-- if the grid is inside a urban morphological zone - umz
update grid.grid
set in_umz = 1
from aoi.umz u
where st_intersects(grid.grid.geometry, u.geometry);

-- count the number of trips crosing each grid element
update grid.grid g
set n_trips = (select count(*)
			   from trips.trips_raw ti
			   where st_intersects(ti.geometry, g.geometry))
from trips.trips_raw t
where st_intersects(g.geometry, t.geometry);

-- count the total number of segments crossing each grid
update grid.grid g
set n_segments = (select count(*)
			   from trips.segments si
			   where st_intersects(si.geometry, g.geometry))
from trips.segments s
where st_intersects(g.geometry, s.geometry);


-- count the total number of segments with speed lower than 5kmh at each grid
update grid.grid g
set n_segments_l_5kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry < 5 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry < 5 and
	st_intersects(g.geometry, s.geometry);


-- count the total number of segments with speed between 5 and 10kmh at each grid
update grid.grid g
set n_segments_b_5_10kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 5 and 10 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry between 5 and 10 and
	st_intersects(g.geometry, s.geometry);

-- count the total number of segments with speed between 10 and 20kmh at each grid
update grid.grid g
set n_segments_b_10_20kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 10 and 20 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry between 10 and 20 and
	st_intersects(g.geometry, s.geometry);


-- count the total number of segments with speed between 20 and 30kmh at each grid
update grid.grid g
set n_segments_b_20_30kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 20 and 30 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry between 20 and 30 and
	st_intersects(g.geometry, s.geometry);


-- count the total number of segments with speed between 30 and 50kmh at each grid
update grid.grid g
set n_segments_b_30_50kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 30 and 50 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry between 30 and 50 and
	st_intersects(g.geometry, s.geometry);

-- count the total number of segments with speed between 50 and 70kmh at each grid
update grid.grid g
set n_segments_b_50_70kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry between 50 and 70 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry between 50 and 70 and
	st_intersects(g.geometry, s.geometry);

-- count the total number of segments with speed higher than 70kmh at each grid
update grid.grid g
set n_segments_h_70kmh = (select count(*)
			   from trips.segments si
			   where si.speed_geometry > 70 and
				  st_intersects(si.geometry, g.geometry))
from trips.segments s
where s.speed_geometry > 70 and
	st_intersects(g.geometry, s.geometry);


-- count the total number of origins at each grid
update grid.grid g
set n_origin = (select count(*)
			   from trips.od od
			   where od.type = 'origin' and
				  st_intersects(od.geometry, g.geometry))
from trips.od o
where o.type = 'origin' and
	st_intersects(g.geometry, o.geometry);

-- count the total number of destinations at each grid
update grid.grid g
set n_destination = (select count(*)
			   from trips.od od
			   where od.type = 'destination' and
				  st_intersects(od.geometry, g.geometry))
from trips.od o
where o.type = 'destination' and
	st_intersects(g.geometry, o.geometry);



select count(*)
from trips.od si
where si.type = 'origin'
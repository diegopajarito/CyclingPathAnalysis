--------
--
-- This script compiles a series of SQL commands using the spatial capabilities
-- PostGIS and PostgreSQL to define the data structure needed for the analysis
-- to replicate this procedures you need to setup an spatial database
-- following the structure described in the documentation
-- This scritps are just indicative of the process followed
-- Author: Diego Pajarito
--
------

-- Updating ids for grids to join city grids into one table
update grid.grid_ms
set id = id + 2000000

update grid.grid_mt
set id = id + 3000000

-- Union of the three grids into one single table
drop table grid;
create table grid.grid as
select *
from grid.grid_ms
union
select *
from grid.grid_cs
union
select *
from grid.grid_mt

-- Setting up the primary key and spatial index
alter table grid.grid add constraint grid_pkey primary key (id)

CREATE INDEX sidx_grid_geometry ON grid.grid USING GIST (geometry);



-- Updating ids for bikepaths to join city paths into one table
select count(*)
from infrastructure.bikepaths_mt

update infrastructure.bikepaths_cs
set id = id + 5000

update infrastructure.bikepaths_mt
set id = id + 6000

-- Union of the bikepaths of the three cities into one single table
drop table infrastructure.bikepaths;
create table infrastructure.bikepaths as
select *
from infrastructure.bikepaths_ms
union
select *
from infrastructure.bikepaths_cs
union
select *
from infrastructure.bikepaths_mt;

-- Setting up the primary key and spatial index
alter table infrastructure.bikepaths add constraint bikepaths_pkey primary key (id);

CREATE INDEX sidx_bikepaths_geometry ON infrastructure.bikepaths USING GIST (geometry);

-- Creating the fields needed
alter table grid.grid add column has_trips integer;
alter table grid.grid add column n_trips integer;
alter table grid.grid add column n_segments integer;
alter table grid.grid add column n_segments_l_5kmh integer;
alter table grid.grid add column n_segments_b_5_10kmh integer;
alter table grid.grid add column n_segments_b_10_20kmh integer;
alter table grid.grid add column n_segments_b_20_30kmh integer;
alter table grid.grid add column n_segments_b_30_50kmh integer;
alter table grid.grid add column n_segments_b_50_70kmh integer;
alter table grid.grid add column n_segments_h_70kmh integer;
alter table grid.grid add column n_origin integer;
alter table grid.grid add column n_destination integer;

alter table trips.segments add column in_fua integer;
alter table trips.segments add column in_umz integer;
alter table trips.segments add column city varchar(20);
alter table trips.segments add column closest_bikepath double precision;
alter table trips.segments add column distance_to_bikepath double precision;


-- Clearing up the differnt fields and dealing with null values in count
update grid.grid
set in_umz = NULL;
update grid.grid
set in_umz = NULL;
update grid.grid
set n_segments_l_5kmh = NULL;
update grid.grid
set n_segments_l_5kmh = 0
where n_segments_l_5kmh is null;
update grid.grid
set n_segments_b_5_10kmh = 0
where n_segments_b_5_10kmh is null;
update grid.grid
set n_segments_b_10_20kmh = 0
where n_segments_b_10_20kmh is null;
update grid.grid
set n_segments_b_20_30kmh = 0
where n_segments_b_20_30kmh is null;
update grid.grid
set n_segments_b_30_50kmh = 0
where n_segments_b_30_50kmh is null;
update grid.grid
set n_segments_b_50_70kmh = 0
where n_segments_b_50_70kmh is null;
update grid.grid
set n_segments_h_70kmh = 0
where n_segments_h_70kmh is null;

select max(n_segments_l_5kmh) as max, min(n_segments_l_5kmh) min
from grid.grid


-- adding fields for segements ad


-- Preparing data for visualization in GIS

-- Get the grid with just the spots inside the aoi, urban area or having trips/segments
create or replace view grid.grid_reduced as
select *,
n_segments_b_5_10kmh + n_segments_b_10_20kmh + n_segments_b_20_30kmh + n_segments_b_30_50kmh as n_cycling_segments,
CASE WHEN id<2000000 THEN 'Castelló'
	WHEN id between 2000000 and 2999999 THEN 'Münster'
	ELSE 'Malta'
END as city
from grid.grid
where in_umz>1 or in_fua>1 or n_trips>1 or n_segments>0;



-- Get the segments with day of the week and hour of the day
drop view trips.segments_full;
create or replace view trips.segments_full as
select *, EXTRACT(DOW FROM start_time) day_of_the_week, EXTRACT(HOUR FROM start_time) hour_of_the_day
from trips.segments;

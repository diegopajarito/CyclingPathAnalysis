# Description: This script loads the datasets needed for the analysis 
# it sets variables based on data coming from the questionnaire and
# the mobile application
# It also creates the join those tables if they are needed
#
# Comments: set your working directory to the project folder
# Author: Diego Pajarito 

# Setup
library(jsonlite)

table_segments <- fromJSON('output/segments_full.geojson')
table_segments <- table_segments$features
table_segments <- data.frame(table_segments$properties)

table_grid <- fromJSON('output/grid_reduced.geojson')
table_grid <- table_grid$features
table_grid <- data.frame(table_grid$properties)
table_grid$city <- 'none'
table_grid[table_grid$id < 2000000,]$city = 'Castelló'
table_grid[table_grid$id >= 2000000 & table_grid$id < 3000000,]$city = 'Münster'
table_grid[table_grid$id >= 3000000,]$city = 'Malta'

table_trip_app <- read.csv('data/Cyclist_Trip.csv')

table_frictions <- fromJSON('output/frictions.geojson')
table_frictions <- table_frictions$features
table_frictions <- data.frame(table_frictions$properties)
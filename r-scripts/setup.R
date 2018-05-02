# Description: This script loads the datasets needed for the analysis 
# it sets variables based on data coming from the questionnaire and
# the mobile application
# It also creates the join those tables if they are needed
#
# Comments: set your working directory to the project folder
# Author: Diego Pajarito 

# Setup
library(jsonlite)

table_segments_cs <- fromJSON('data/temp/segments_cs.geojson')
table_segments_cs <- table_segments_cs$features
table_segments_cs <- data.frame(table_segments_cs$properties)

table_trip_app <- read.csv('data/Cyclist_Trip.csv')


# Description: This script generates the graphs and tests to compare 
# the use of bicycle paths in the different cities 
#
# Comments: set your working directory to 
# Author: Diego Pajarito 


# Setup
source('r-scripts/setup.R')
library(ggplot2)
library(lubridate)
library(dplyr)

# Names of the city in terms of ID
table_bike_paths$city <- ''
table_bike_paths[table_bike_paths$id < 5000,]$city = 'Münster'
table_bike_paths[table_bike_paths$id > 5000 & table_bike_paths$id < 6000,]$city = 'Castello'
table_bike_paths[table_bike_paths$id > 6000,]$city = 'Valletta'
table_bike_paths$having_trips = FALSE
table_bike_paths[table_bike_paths$n_trips_in >0,]$having_trips <- TRUE
table_bike_paths[is.na(table_bike_paths$avg_speed_in),]$avg_speed_in <- 0
table_bike_paths[is.na(table_bike_paths$distance_in),]$distance_in <- 0
table_bike_paths[is.na(table_bike_paths$prop_cycled_distance),]$prop_cycled_distance <- 0


# Use of bicycle paths
ggplot(table_bike_paths, aes(city, fill=having_trips)) +
  geom_bar(stat = 'count', position = "fill", show.legend=F) +
  geom_label(stat = 'count', position = 'fill', aes(label=..count..)) +
  coord_flip() + xlab('') + ylab('Bicycle paths used during the experiment') +
  theme_bw() +
  theme(legend.position = 'bottom', legend.title = element_blank())

# Average speed per city in/out bicycle 
cycling_segments <- table_segments[table_segments$speed_geometry>5 & table_segments$speed_geometry<50,]
cycling_segments <- cycling_segments[!is.na(cycling_segments$city),]
cycling_segments[cycling_segments$city == 'Malta',]$city = 'Valletta'
cycling_segments$in_bicycle_path = FALSE
cycling_segments[!is.na(cycling_segments$distance_to_bikepath) & cycling_segments$distance_to_bikepath < 0.00025,]$in_bicycle_path = TRUE

ggplot(cycling_segments, aes(in_bicycle_path, speed_geometry, fill=in_bicycle_path)) + 
  geom_boxplot(alpha=0.7, outlier.shape = NA, show_guide=FALSE) + 
  ylab('Speed') + xlab('') + ylim(0,40) +
  theme_bw() +
  facet_grid(city ~ day_of_the_week)

  
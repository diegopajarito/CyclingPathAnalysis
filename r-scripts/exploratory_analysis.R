# Description: This script generates the graphs and tests to compare 
# participants answers about their perception of competition 
# and collaboration when using the bicycle.
#
# Comments: set your working directory to 
# Author: Diego Pajarito 


# Setup
source('r-scripts/setup.R')
library(ggplot2)

table_segments_cs$in_bikepath = FALSE
table_segments_cs[is.na(table_segments_cs$id_bikepath), ]$in_bikepath = TRUE
# Histogram based on geometry
ggplot(table_segments_cs, aes(speed_geometry, fill = in_bikepath)) + geom_histogram(binwidth = 0.5) + xlim(-1,70)
ggplot(table_segments_cs, aes(distance_geometry, fill = in_bikepath)) + geom_histogram(binwidth = 0.5) 
# Histogram based on device sensor
ggplot(table_segments_cs, aes(last_speed, fill = in_bikepath)) + geom_histogram(binwidth = 0.5) + xlim(-1,70)
ggplot(table_segments_cs, aes(last_distance_a, fill = in_bikepath)) + geom_histogram(binwidth = 0.5) 
ggplot(table_segments_cs, aes(last_distance_b, fill = in_bikepath)) + geom_histogram(binwidth = 0.5) 


# Trips distance and use of bike paths
t_distance <- ggplot(table_segments_cs, aes(device, fill = in_bikepath))
t_distance + geom_bar(stat = 'count')

# number of segments close to a bikepath
ggplot(table_segments_cs, aes(id_bikepath, fill = in_bikepath)) + geom_bar(stat = 'count')

# Trips distance and the uses of bikepath
ggplot(table_segments_cs, aes(reorder(factor(trip_count), distance_geometry, function(x){ sum(x) }), distance_geometry, fill = in_bikepath)) +
  geom_bar( stat = 'sum') + coord_flip()




# Description: This script generates the graphs and merges the 
# results from the segments and frictions identified with the answeres  
# from participants in experiment one 
#
# Comments: set your working directory to 
# Author: Diego Pajarito 


# Setup
source('r-scripts/setup.R')
library(ggplot2)
library(lubridate)
library(dplyr)
library(gridExtra)


###### 
###### 
###### Data Setup
###### 
###### 


table_frictions_segments[table_frictions_segments$city == 'Malta',]$city <- 'Valletta'

# Fixing data taken with the two devices from the institute (used for tests in CS and for experiment un Valletta)
# Also removing the segments out of any of the three cities
table_frictions_segments[table_frictions_segments$device == '5ed0527e1fa659da',]
table_frictions_segments[table_frictions_segments$device == '43719b7c983f3578',]
table_frictions_segments[table_frictions_segments$device == '5ed0527e1fa659da' & 
                           table_frictions_segments$city == 'Castelló',]$device <- '5ed0527e1fa659da_'
table_frictions_segments[table_frictions_segments$device == '43719b7c983f3578' & 
                           table_frictions_segments$city == 'Castelló',]$device <- '43719b7c983f3578_'


ggplot (table_frictions_segments, aes(day_of_the_week, fill=city)) + 
  geom_bar(stat='count')

ggplot (table_frictions_segments, aes(friction_id,trip_count, color=city, size = intensity)) +
  geom_point(alpha=0.1)

ggplot (table_frictions_segments, aes(intensity, fill=city)) + 
  geom_bar(binwidth = 10)

# Aggregation by frictions
summary_intensity <- data.frame(table_frictions_segments %>%
  group_by(friction_id) %>% 
  summarise(segments = n(),
            trips = n_distinct(trip_count),
            participants = n_distinct(device),
            intensity = mean(intensity),
            city = mode(city),
            hour = mean(hour_of_the_day),
            day = mode(day_of_the_week)
  ))

ggplot(summary_intensity, aes(friction_id)) + 
  geom_point(aes(y=trips)) 


#
# Aggregation by trips
summary_trips_frictions <- data.frame(table_frictions_segments %>%
                                  group_by(device, trip_count) %>% 
                                  summarise(segments = n(),
                                            frictions = n_distinct(friction_id),
                                            intensity = mean(intensity),
                                            n_grid_spots = mean(n_grid_spots),
                                            avg_speed = mean(speed_geometry)
                                  ))
summary_trips_frictions <- merge(summary_trips_frictions, participant_details)

trip_details <- table_segments[, c('device', 'trip_count', 'speed_geometry', 'distance_geometry', 'distance_to_bikepath',
                                   'day_of_the_week', 'hour_of_the_day' )]
trip_details$cycling_speed <- NA
trip_details[trip_details$speed_geometry > 5 & trip_details$speed_geometry < 50,]$cycling_speed <- 
  trip_details[trip_details$speed_geometry > 5 & trip_details$speed_geometry < 50,]$speed_geometry
trip_details$cycling_distance <- 0
trip_details[trip_details$speed_geometry > 5 & trip_details$speed_geometry < 50,]$cycling_distance <- 
  trip_details[trip_details$speed_geometry > 5 & trip_details$speed_geometry < 50,]$distance_geometry

trip_details <- trip_details %>% 
  group_by(device,trip_count) %>%
  summarise(total_distance = sum(distance_geometry),
            cycling_distance = sum(cycling_distance, na.rm=TRUE),
            cycling_speed = mean(cycling_speed, na.rm=TRUE),
            day_of_the_week = max(day_of_the_week),
            hour_of_the_day = max(hour_of_the_day))
summary_trips_frictions <- merge(summary_trips_frictions, trip_details)

participant_details <- table_questionnaire[,c('device', 'city', 'group', 'dem_gender', 'dem_age', 'dem_postcode',
                       'profile_cycling_1', 'profile_cycling_5', 'profile_cycling_8', 'profile_cycling_10', 
                       'profile_cycling_13', 'profile_cycling_15', 'gaming_app_cycling', 'gaming_app_cycling_strava',
                       'engagement_A1', 'engagement_A3', 'engagement_cycling_future', 'engagement_any_app_future',
                       'satisfaction_1', 'satisfaction_2'
                       )]
participant_details[is.na(participant_details$gaming_app_cycling_strava),]$gaming_app_cycling_strava <- 0
summary_trips_frictions <- merge(summary_trips_frictions, participant_details)

names(summary_trips_frictions)

ggplot(summary_trips_frictions, aes(cycling_speed, color = satisfaction_1)) + 
  scale_color_gradient2(low="red", mid="yellow", high="green", space ="Lab" ) +
  geom_point(alpha = 0.3, aes(y=frictions, size=intensity)) + facet_grid(. ~ city) +
  ylab('Frictions faced per trip') + xlab('Cycling speed (Km/h)') + theme_bw()
#  geom_histogram(binwidth = 10)
 

ggplot(summary_trips_frictions, aes(reorder(trip_count, trip_count), fill = city)) + 
  geom_bar(stat = 'identity', aes(y=trip_count))

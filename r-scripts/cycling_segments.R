# Description: This script generates the graphs and tests to compare 
# participants answers about their perception of competition 
# and collaboration when using the bicycle.
#
# Comments: set your working directory to 
# Author: Diego Pajarito 


# Setup
source('r-scripts/setup.R')
library(ggplot2)
library(lubridate)
library(dplyr)

# Some new fields to simplify the graphs labels  
table_segments[which(is.na(table_segments$in_umz)),]$in_umz <- 0
days_of_the_week <- c('0' = "Sunday", 
                      '1' = "Monday", 
                      '2' = "Tuesday", 
                      '3' = "Wednesday",
                      '4' = "Thursday", 
                      '5' = "Friday",
                      '6' = "Saturday")
in_urban_zone <- c('0' = "Out of a urban area", 
                   '1' = "In an urban area")
in_urban_zone_city <- c('No' = "Out of a urban area", 
                   'Yes' = "In an urban area",
                   'Castelló' = 'Castelló',
                   'Münster' = 'Münster', 
                   'Malta' = 'Valletta')
table_segments$cycling_speed <- 'a- Stopped or walking speed'
table_segments[table_segments$speed_geometry > 5,]$cycling_speed <- 'b- Cycling speed'
table_segments[table_segments$speed_geometry > 50,]$cycling_speed <- 'c- Very fast cycling speed'
table_segments[table_segments$speed_geometry > 70,]$cycling_speed <- 'd- Not cycling speed'
table_segments$gps_precission <- "a- Very high"
table_segments[table_segments$precision_end > 5,]$gps_precission <- "b- Normal"
table_segments[table_segments$precision_end > 50,]$gps_precission <- "c- Very low"
table_segments[table_segments$precision_end > 100,]$gps_precission <- "d- Not useful"
table_segments$start <- strptime(table_segments$start_time, "%Y/%m/%d %H:%M:%S")
table_segments$start <- ymd_hms(table_segments$start)
table_segments$start <- hour(table_segments$start) + minute(table_segments$start)/60
table_segments$stop <- strptime(table_segments$end_time, "%Y/%m/%d %H:%M:%S")
table_segments[table_segments$in_umz== 'TRUE',]$in_umz <- 'Yes'
table_segments[table_segments$in_umz== 'FALSE',]$in_umz <- 'No'
table_segments$in_umz

# Distribution of segments at cycling speed
ggplot(table_segments[!is.na(table_segments$city),], aes(city, fill = cycling_speed)) + geom_bar(stat = 'count') + 
  theme(legend.position = 'bottom')


# Number of trips distributed buy day of the week and hour of the day
ggplot(table_segments, aes(hour_of_the_day, y = distance_geometry / 1000, fill= as.factor(in_umz))) + 
  geom_bar( stat = 'identity') + facet_grid(day_of_the_week ~ ., labeller = as_labeller(days_of_the_week)) + 
  xlab("Hour the day") +  ylab("Cycled distance") + labs(fill = 'Inside the urban morphological zone') +
  theme_bw() + theme(legend.position="bottom") 


# A comparison beteen the speed estimated from geometry and the one reported by google fit
ggplot(table_segments[table_segments$cycling_speed != 'd- Not cycling speed',], aes(speed_geometry, last_speed, color = cycling_speed)) + 
  geom_point(alpha = 1/5) + facet_grid(cycling_speed ~ .)


# A comparison beteen the speed estimated from geometry and the precision reported by the device
ggplot(table_segments, aes( cycling_speed)) + 
  geom_bar()


# Speed and hour of the day
ggplot(table_segments[!is.na(table_segments$city) & table_segments$cycling_speed != 'd- Not cycling speed',], 
       aes(start, speed_geometry, color = cycling_speed)) + geom_point(alpha = 1/8) + 
  theme_bw() + theme(legend.position = 'bottom', legend.title = element_blank()) + 
  xlab('Hour of day') + ylab('Speed in Km/h') + xlim(0,24) +
  facet_grid(city ~ ., labeller = as_labeller(in_urban_zone_city))


# Segment order and speed
ggplot(table_segments[!is.na(table_segments$city) & table_segments$cycling_speed != 'd- Not cycling speed',], 
       aes(segment_count, speed_geometry)) +
  geom_point(aes(size=1/precision_end), alpha = 1/50) + xlim(1,1000) +
  facet_grid(city ~ .)


ggplot(table_segments[!is.na(table_segments$city) & table_segments$speed_geometry< 70,], 
       aes(start, day_of_the_week + (speed_geometry-40)/150)) +
  geom_point(aes(color=speed_geometry), alpha = 1/3) + 
  scale_color_gradient2(low = "red", mid = 'green', high = "grey", midpoint = 25) +
  scale_y_discrete( limits=c(0,1,2,3,4,5,6), labels=c("S", "M", "T", "W", "T","F", "S")) +
  scale_x_discrete( limits=c(0,6,12,18,24)) +
  xlab('Hour of day') + ylab('Day of week') + labs(color='Speed (Km/h)') + 
  theme_bw() + theme(legend.position = 'bottom') +
  facet_grid(city ~ in_umz, labeller = as_labeller(in_urban_zone_city))




#sum of trip distance 
ggplot(table_segments[!is.na(table_segments$city),], 
       aes(day_of_the_week, cycling_speed, speed_geometry)) +
  geom_tile(stat = 'sum')

segments_distance <- data.frame(table_segments$day_of_the_week, table_segments$cycling_speed, table_segments$distance_geometry)
names(segments_distance) <- c('day_of_the_week', 'cycling_speed', 'distance_geometry')

segments_sum_distance <- segments_distance %>%
  group_by(day_of_the_week, cycling_speed) %>%
  summarise(z=sum(distance_geometry))

segments_sum_distance$cycling_speed_num <- 0
segments_sum_distance[segments_sum_distance$cycling_speed == 'a- Stopped or walking speed',]$cycling_speed_num <- 1
segments_sum_distance[segments_sum_distance$cycling_speed == 'b- Cycling speed',]$cycling_speed_num <- 2
segments_sum_distance[segments_sum_distance$cycling_speed == 'c- Very fast cycling speed',]$cycling_speed_num <- 3
segments_sum_distance[segments_sum_distance$cycling_speed == 'd- Not cycling speed',]$cycling_speed_num <- 4

ggplot(segments_sum_distance, aes(day_of_the_week, cycling_speed_num)) +
  geom_tile(aes(fill = z/1000)) + 
  scale_fill_gradient(low = "black", high = "steelblue")




# using base::strptime
t.str <- strptime(foo$start.time, "%Y-%m-%d %H:%M:%S")

# using lubridate::ymd_hms
library(lubridate)
t.lub <- ymd_hms(foo$start.time)

range(table_segments[which(table_segments$cycling_speed != 'Cycling speed'),]$speed_geometry)


# Trips and accuracy
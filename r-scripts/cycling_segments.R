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
table_segments[table_segments$in_umz== 1,]$in_umz <- 'Yes'
table_segments[table_segments$in_umz== 0,]$in_umz <- 'No'
table_segments$in_bicycle_path <- 'No'
table_segments[!is.na(table_segments$distance_to_bikepath) & table_segments$distance_to_bikepath< 0.00025,]$in_bicycle_path <- 'Yes'

# Number of trips distributed buy day of the week and hour of the day
# Figure 5
ggplot(table_segments, aes(hour_of_the_day, y = distance_geometry / 1000.0)) + 
  geom_bar( stat = 'identity', aes(fill= as.factor(in_umz))) + 
  stat_density(geom="line", color="blue", aes(y=..density..*400)) +
  facet_grid(day_of_the_week ~ ., labeller = as_labeller(days_of_the_week)) + 
  xlab("Hour of the day") +  ylab("Cycled distance") + 
  labs(fill = 'Inside the UMZ') +
  theme_bw() + theme(legend.position="bottom") 


# Cycled distance in/out bicycle path
distance <- table_segments[c('city', 'in_umz', 'distance_geometry', 'in_bicycle_path')] 

distance %>%
  group_by(city, in_umz, in_bicycle_path) %>%
  summarise(total = sum(distance_geometry)/1000.0, n = n())
total_cs <- 414 / ( 940 + 414)
total_mt <- 144 / (911+144)
total_ms <- 409 / (409+215)

in_umz_cs <- 273 / (273+539)
in_umz_mt <- 143 / (143+949)
in_umz_ms <- 365 / (365+191)






# Speed and hour of the day
# Figure 3
ggplot(table_segments[!is.na(table_segments$city) & table_segments$cycling_speed == 'b- Cycling speed',], 
       aes(start, speed_geometry)) + geom_point(alpha = 1/20) + 
  scale_x_discrete( limits=c(0,6,12,18,24)) +
  theme_bw() + theme(legend.position = 'bottom', legend.title = element_blank()) + 
  xlab('Hour of day') + ylab('Speed in Km/h') +
  facet_grid(city ~ ., labeller = as_labeller(in_urban_zone_city))

# Average cycling speed
speed <- table_segments[c('city', 'cycling_speed', 'speed_geometry', 'in_bicycle_path')]
speed <- speed[!is.na(speed$city) & speed$cycling_speed == 'b- Cycling speed',]
speed %>%
  group_by(city, cycling_speed) %>%
  summarise(mean_speed = mean(speed_geometry), n = n())



# Cycled distance in/out bicycle path per city
# Figure 8
trips <- table_segments[table_segments$cycling_speed == 'b- Cycling speed',c('city', 'trip_count', 'distance_geometry', 'in_bicycle_path')]
trips <- trips[!is.na(trips$city),]
trips[trips$city == 'Malta',]$city <- 'Valletta'
trips <- trips %>%
  group_by(city, trip_count, in_bicycle_path) %>%
  summarise(cycled_distance = sum(distance_geometry))
bikepaths <- trips[trips$in_bicycle_path == 'Yes', c('city', 'trip_count', 'cycled_distance')]
names(bikepaths) <- c('city', 'trip_count', 'distance_in_bikepath')
bikepaths_out <- trips[trips$in_bicycle_path == 'No', c('city', 'trip_count', 'cycled_distance')]
names(bikepaths_out) <- c('city', 'trip_count', 'distance_out_bikepath')
trips <- merge(bikepaths, bikepaths_out)

ggplot(trips, aes(reorder(trip_count, cycled_distance), cycled_distance/1000.0, fill = in_bicycle_path)) +
  geom_bar(stat='identity', alpha = 0.7) +
  labs(fill = 'In bicycle Path') + guides(size = 'none') +
  ylab('Distance (Km)') +
  theme( axis.title.x = element_blank(), axis.text.x=element_blank(), legend.position = 'bottom', axis.ticks.x = element_blank()) +
  facet_grid(. ~ city)
#+
  #coord_polar(start = 0)





# Aggregated Distance in and out
trips_distance <- table_segments[c('city', 'day_of_the_week', 'trip_count', 'distance_geometry', 'speed_geometry', 'cycling_speed', 'in_bicycle_path')]
trips_distance <- trips_distance[!is.na(trips_distance$city) & trips_distance$cycling_speed == 'b- Cycling speed',]
trips_distance_in <- trips_distance[trips_distance$in_bicycle_path == 'Yes',]
trips_distance_out <- trips_distance[trips_distance$in_bicycle_path == 'No',]
distance_in <- data.frame(trips_distance_in %>%
                            group_by(city, trip_count, day_of_the_week) %>%
                            summarise(distance_in = sum(distance_geometry), mean_speed_in = mean(speed_geometry), n_segments_in= n()))
distance_out <- data.frame(trips_distance_out %>%
                            group_by(city, trip_count, day_of_the_week) %>%
                            summarise(distance_out = sum(distance_geometry), mean_speed_out = mean(speed_geometry), n_segments_out= n()))
total_in_out <- merge(distance_in, distance_out,by=c('city', 'trip_count', 'day_of_the_week'),all = TRUE)
total_in_out$total_distance <- total_in_out$distance_in + total_in_out$distance_out
total_in_out$percentage_in <- total_in_out$distance_in / total_in_out$total_distance
total_in_out$percentage_out <- total_in_out$distance_out / total_in_out$total_distance
total_in_out[total_in_out$city == 'Malta',]$city <- 'Valletta'
total_in_out$position <- 0
total_in_out[total_in_out$city == 'Castelló',]$position <- -1
total_in_out[total_in_out$city == 'Valletta',]$position <- 1


# Cycled distance in bikepath per day
# Figure 8

ggplot(total_in_out, aes(day_of_the_week + 0.15 * position, percentage_in * 100, color = city))+
  geom_point(alpha=1/2,aes(size=total_distance/1000)) +
  labs(size = 'Cycled distance (Km)', color = '') + xlab('') + ylab('Distance in bicycle path (%)') +
  scale_x_discrete( limits=c(0,1,2,3,4,5,6), labels=c("S", "M", "T", "W", "T","F", "S")) +
  theme_bw() +
  theme(legend.position = 'bottom') 






# Official Cycled Distances (just considering the cycling segments)
cycled_city <- total_in_out %>%
  group_by(city)  %>%
  summarise(total_distance = sum(total_distance, na.rm=TRUE), 
            distance_in = sum(distance_in, na.rm=TRUE), 
            distance_out = sum(distance_out, na.rm=TRUE),
            percentage_in = sum(distance_in, na.rm=TRUE)/sum(total_distance, na.rm=TRUE))



# Official Number of segments and proportion of cycling segments
segments_count <- table_segments[!is.na(table_segments$city),c('id', 'segment_count', 'device', 'trip_count', 'distance_geometry', 
                                   'city', 'cycling_speed', 'in_bicycle_path')]
segments_city <- segments_count %>%
  group_by(city, cycling_speed) %>%
  summarise(number_segments = n(),
            distance = sum(distance_geometry, na.rm=TRUE))
cycling_segments_ms = 5832 / (5356+5832+104+3433)
cycling_segments_cs = 13898 / (6607+13898+286+4887)
cycling_segments_mt = 5407 / (13384+5407+130+3644)




# Distance cycled by UMZ
distance <- table_segments[c('city', 'in_umz', 'distance_geometry', 'in_bicycle_path', 'day_of_the_week')] 
distance$weekday <- 'Yes'
distance[distance$day_of_the_week == 0,]$weekday <- 'No'
distance[distance$day_of_the_week == 6,]$weekday <- 'No'
distance %>%
  group_by(city, in_umz, weekday) %>%
  summarise(total = sum(distance_geometry)/1000.0, n = n())
urban_ms <- 556 / (556+67.5)
urban_mt <- 991 / (991+63.9)
urban_cs <- 812 / (812+542)
urban_cs_week_day <- 690/(690+122)

# Cycled Distance cycled by UMZ
distance <- table_segments[c('city', 'distance_geometry', 'in_bicycle_path', 'day_of_the_week')] 
distance$weekday <- 'Yes'
distance[distance$day_of_the_week == 0,]$weekday <- 'No'
distance[distance$day_of_the_week == 6,]$weekday <- 'No'
a <- distance %>%
  group_by(city, in_bicycle_path) %>%
  summarise(cycled_distance = sum(distance_geometry)/1000.0, n = n())


urban_ms <- 556 / (556+67.5)
urban_mt <- 991 / (991+63.9)
urban_cs <- 812 / (812+542)
urban_cs_week_day <- 690/(690+122)



# Speed and hour of the day
ggplot(table_segments[!is.na(table_segments$city) & table_segments$cycling_speed == 'b- Cycling speed',], 
       aes(start, day_of_the_week + (speed_geometry-40)/150)) +
  geom_point(aes(color=speed_geometry)) + 
  scale_color_gradient2(low = "green", high = "blue") +
  scale_y_discrete( limits=c(0,1,2,3,4,5,6), labels=c("S", "M", "T", "W", "T","F", "S")) +
  scale_x_discrete( limits=c(0,6,12,18,24)) +
  xlab('Hour of day') + ylab('Day of week') + labs(color='Speed (Km/h)') + 
  theme_bw() + theme(legend.position = 'bottom') +
  facet_grid(city ~ in_umz, labeller = as_labeller(in_urban_zone_city))


ggplot(table_segments[!is.na(table_segments$city) & table_segments$cycling_speed == 'b- Cycling speed',], 
       aes(start, day_of_the_week + (speed_geometry/65))) +
  geom_point(aes(color=speed_geometry)) + 
  stat_smooth(aes(group=day_of_the_week), colour="green") +
  scale_color_gradient2(low = "blue", mid = 'green', high = 'blue') +
  scale_y_discrete( limits=c(0,1,2,3,4,5,6), labels=c("S", "M", "T", "W", "T","F", "S")) +
  scale_x_discrete( limits=c(0,6,12,18,24)) +
  xlab('Hour of day') + ylab('Day of week') + labs(color='Speed (Km/h)') + 
  theme_bw() + theme(legend.position = 'bottom') +
  facet_grid(city ~ in_umz, labeller = as_labeller(in_urban_zone_city))




# Segment order and speed
ggplot(table_segments[!is.na(table_segments$city) & table_segments$cycling_speed != 'd- Not cycling speed',], 
       aes(segment_count, speed_geometry)) +
  geom_point(aes(size=1/precision_end), alpha = 1/50) + xlim(1,1000) +
  facet_grid(city ~ .)








# Distribution of segments at cycling speed
ggplot(table_segments[!is.na(table_segments$city),], aes(city, fill = cycling_speed)) + geom_bar(stat = 'count') + 
  theme(legend.position = 'bottom')


# A comparison beteen the speed estimated from geometry and the one reported by google fit
ggplot(table_segments[table_segments$cycling_speed != 'd- Not cycling speed',], aes(speed_geometry, last_speed, color = cycling_speed)) + 
  geom_point(alpha = 1/5) + facet_grid(cycling_speed ~ .)


# A comparison beteen the speed estimated from geometry and the precision reported by the device
ggplot(table_segments, aes( cycling_speed)) + 
  geom_bar()




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


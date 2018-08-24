# Description: This script generates the graphs and merges the 
# results form questionnaires from experiment one 
# and the segment analysis of experiment two
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


table_segments[table_segments$city == 'Malta',]$city <- 'Valletta'

# Fixing data taken with the two devices from the institute (used for tests in CS and for experiment un Valletta)
# Also removing the segments out of any of the three cities
table_segments <- table_segments[which(!is.na(table_segments$city)),]
table_segments[table_segments$device == '5ed0527e1fa659da',]
table_segments[table_segments$device == '43719b7c983f3578',]
table_segments[table_segments$device == '5ed0527e1fa659da' & 
               table_segments$city == 'Castelló',]$device <- '5ed0527e1fa659da_'
table_segments[table_segments$device == '43719b7c983f3578' & 
               table_segments$city == 'Castelló',]$device <- '43719b7c983f3578_'



# Building general statistics. Cycling detals per participant
# Aggregated statistics
summary_segments <- data.frame( table_segments %>%
  group_by(device) %>%
  summarise(n_segments = n(),
            total_distance = sum(distance_geometry),
            avg_distance = mean(distance_geometry),
            avg_speed = mean(speed_geometry),
            n_trips = n_distinct(trip_count),
            n_segments = n()
            ))
duplicated(summary_segments$device)



# Cycling segments' statistics
cycling_segments <- table_segments[table_segments$speed_geometry < 50.0 & table_segments$speed_geometry > 5.0,]
summary_cycling <- data.frame( cycling_segments %>%
  group_by(device) %>%
  summarise(cycling_segments = n(),
            cycling_distance = sum(distance_geometry),
            cycling_speed = mean(speed_geometry),
            cycling_segments = n()))
global_avg_cycling_speed = mean(cycling_segments$speed_geometry)

# Cycled distance in bikepat out of bike path 
cycling_segments$in_bikepath <- 'No'
cycling_segments[!is.na(cycling_segments$distance_to_bikepath) & cycling_segments$distance_to_bikepath < 0.00025,]$in_bikepath <- 'Yes'
summary_bikepath <- data.frame( cycling_segments %>%
  group_by(device, in_bikepath) %>%
  summarise(segments = n(),
            distance = sum(distance_geometry),
            avg_speed = mean(speed_geometry)))

on_bikepath <- summary_bikepath[summary_bikepath$in_bikepath == 'Yes', c('device', 'segments', 'distance', 'avg_speed')]
names(on_bikepath) <- c('device', 'segments_on_bp', 'distance_on_bp', 'avg_speed_on_bp')
out_bikepath <- summary_bikepath[summary_bikepath$in_bikepath == 'No', c('device', 'segments', 'distance', 'avg_speed')]
names(out_bikepath) <- c('device', 'segments_out_bp', 'distance_out_bp', 'avg_speed_out_bp')
summary_bikepath <- merge(out_bikepath, on_bikepath, all.x = TRUE)

# Cycled distance in umz out of umz
summary_fua <- data.frame( cycling_segments %>%
  group_by(device, in_fua) %>%
  summarise(segments = n(),
            distance = sum(distance_geometry),
            avg_speed = mean(speed_geometry)) )
in_fua <- summary_fua[!is.na(summary_fua$in_fua), c('device', 'segments', 'distance', 'avg_speed')]
names(in_fua) <- c('device', 'segments_in_fua', 'distance_in_fua', 'avg_speed_in_fua')
out_fua <- summary_fua[is.na(summary_fua$in_fua), c('device', 'segments', 'distance', 'avg_speed')]
names(out_fua) <- c('device', 'segments_out_fua', 'distance_out_fua', 'avg_speed_out_fua')
summary_fua <- merge(in_fua, out_fua, all.x = TRUE)



cities <- data.frame( table_segments %>%
  group_by(device,city) %>%
  summarise(n = n()))
cities <- cities[!is.na(cities$city), c('device', 'city')]



# summary of recorded segments, differenciated by
# general statistics, cycling segments, in/out bikepath, in/out fua
summary_segments <- merge(summary_segments, cities)
summary_segments <- merge(summary_segments, summary_cycling)
summary_segments <- merge(summary_segments, summary_bikepath)
summary_segments <- merge(summary_segments, summary_fua)


# Merging the questionnaire and the segments summary
table_questionnaire <- merge(table_questionnaire, summary_segments, all.x = TRUE)
table_questionnaire <- table_questionnaire[table_questionnaire$group != 'none',]
names(summary_segments)










#####
#####
###### General mobility graphs
#####
##

# Plots

# Speed in/out bike path and fua per city 
summary_segments$avg_speed_on_bp
summary_segments$avg_speed_out_bp
ggplot(summary_segments, aes( color = city)) +
  geom_point(shape=15, size = 2, aes(x=cycling_speed, y=cycling_distance)) +
#  geom_point(shape=2, size = 6, aes(x=avg_speed_out_fua, y=avg_speed_in_fua)) +
  geom_abline(intercept = 0, slope = 1) 


# Relevant
# Average cycling Speed and speed difference between on/out bikepath  
ggplot(summary_segments, aes(reorder(device, cycling_speed), fill = city)) +
  geom_bar(stat='identity', aes(y=cycling_speed)) +
  geom_segment( aes(xend = device, y = avg_speed_out_bp, yend = avg_speed_on_bp, linetype='Speed difference at bikepath')) +
  scale_linetype_manual('',values=c("Speed difference at bikepath"=1))+
  geom_point(size=1, shape='a', aes(y=avg_speed_out_bp)) +
  geom_point(size=2, aes(y=avg_speed_on_bp)) +
  scale_shape_manual('', values=c('a'=0), labels="pt") +
  theme_bw() + xlab('') + ylab('Participant average cycling speed (Km/h)') +
  theme(axis.ticks.x=element_blank(), axis.text.x=element_blank(), legend.position = 'bottom', legend.title=element_blank())

ggplot(summary_segments, aes(reorder(device, avg_speed_on_bp - avg_speed_out_bp), color = city)) +
  geom_hline(yintercept = 0.0) +
  geom_segment(size=1.2, aes(xend = device, y = 0, yend = avg_speed_on_bp - avg_speed_out_bp)) +
  geom_point(size=2, aes(y=avg_speed_on_bp - avg_speed_out_bp)) + 
  theme_bw() + xlab('') + ylab('Speed difference at bikepath (Km/h)') +
  theme(axis.ticks.x=element_blank(), axis.text.x=element_blank(),legend.position = 'bottom')

grid.arrange(pl_avg_speed, pl_speed_bp, nrow = 1)



# Relevant
# Distance in/out bike
ggplot(summary_segments, aes(reorder(device, distance_on_bp), color = city)) +
  geom_segment(size=0.8, aes(xend = device, y = 0, yend = distance_out_bp /1000 * -1)) +
  geom_segment(size=3, aes(xend = device, y = 0, yend = distance_on_bp /1000 )) +
  geom_hline(yintercept = 0.0) +
  theme_bw() + xlab('') + ylab('Out of a bicycle path (-)               - Cyclied distance in Km  - On a bicycle path') +
  theme(axis.ticks.x=element_blank(), axis.text.x=element_blank(), 
        legend.title = element_blank(), legend.position = 'bottom')


# Trips / distance
ggplot(summary_segments, aes( color = city)) +
  #  geom_point(shape=16, size = 1, aes(x=n_segments, y=cycling_segments)) +
  geom_point(shape=16, size = 6, alpha=1/2, aes(x=n_trips, y=cycling_distance/1000)) +
  geom_abline(intercept = 0, slope = 1) +
  facet_grid(.~city)





ggplot(summary_segments, aes(n_trips, color = city)) +
  geom_point(size=1, aes(y=cycling_speed)) 


  geom_segment(size=0.8, aes(xend = device, y = 0, yend = distance_out_bp /1000 * -1)) +
  geom_segment(size=3, aes(xend = device, y = 0, yend = distance_on_bp /1000 )) +
  geom_hline(yintercept = 0.0) +
  theme_bw() + xlab('') + ylab('Out of a bicycle path (-)               - Cyclied distance in Km  - On a bicycle path') +
  theme(axis.ticks.x=element_blank(), axis.text.x=element_blank(), 
        legend.title = element_blank(), legend.position = 'bottom')




# Average cycling Speed and speed difference between on/out bikepath  
ggplot(summary_segments, aes(reorder(device, cycling_distance), fill = city)) +
  geom_bar(alpha=1/2, stat='identity', aes(y=cycling_distance/1000.0)) +
theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  geom_point(shape=0, aes(y=avg_speed_out_bp)) +
  geom_point(aes(y=avg_speed_on_bp)) +
  geom_segment(aes(xend = device, y = avg_speed_out_bp, yend = avg_speed_on_bp))







#####
#####
###### Integrated analysis of questionnaire answers and segments
#####
##


table_questionnaire[,c('device','participant','group', 'city', 'cycling_distance')]
names(table_questionnaire)
# Average cycling distance per group 
ggplot(table_questionnaire, aes(city, color = group)) +
  geom_point(aplha = 1/20, size = 5, aes(y=cycling_distance)) 

# Average cycling Speed per group  
ggplot(table_questionnaire, aes(city, color = group)) +
  geom_point(aplha = 1/20, size = 5, aes(y=cycling_speed)) 

# Number of trips per group  
ggplot(table_questionnaire, aes(city, color = group)) +
  geom_point(aplha = 1/20, size = 5, aes(y=n_trips)) 

# Average cycling Speed and speed difference between on/out bikepath  
ggplot(table_questionnaire, aes(distance_on_bp, distance_out_bp, color = group)) +
  geom_point(alpha = 0.5, size = 5) + 
  facet_grid(.~city)

# Average cycling Speed and speed difference between on/out bikepath  
ggplot(table_questionnaire, aes(profile_cycling_1, distance_out_bp, color = group)) +
  geom_point(alpha = 0.5, size = 5) + 
  facet_grid(.~city)



names(table_questionnaire)
table_questionnaire[is.na(table_questionnaire$gaming_app_cycling_strava),]$gaming_app_cycling_strava <- 0

ggplot(table_questionnaire, aes(n_trips, cycling_distance, color = engagement_A1)) +
#  scale_color_gradient2(low="red", mid="yellow", high="green", space ="Lab" ) +
  geom_point(alpha = 0.5, size = 5) + 
  geom_abline(intercept = 0, slope = 1) + theme_bw() +
  facet_grid(.~city)
ggplot(table_questionnaire, aes(engagement_any_app_2w)) +
  geom_point(alpha = 0.5, size = 3, aes(y=distance_on_bp/cycling_distance)) +
  geom_smooth(method = 'lm', aes(y=distance_on_bp/cycling_distance))  + theme_bw() + facet_grid(.~city) +
  geom_point(alpha = 0.5, size = 3, shape = 0, aes(y=cycling_distance/10000)) +
  geom_point(alpha = 0.5, size = 5, shape = 1, aes(y=n_trips/10)) +
  theme_bw() + facet_grid(.~city)

group1 <- table_questionnaire[!is.na(table_questionnaire$cycling_speed) & table_questionnaire$gaming_app_cycling == 'Y',]$cycling_speed
group2 <- table_questionnaire[!is.na(table_questionnaire$cycling_speed) & table_questionnaire$gaming_app_cycling == 'N',]$cycling_speed
wilcox.test(group1,group2)
mean(group1)
mean(group2)
summary_segments[,c('group')]
cor(data.frame(summary_segments[,c('group')]))


cor(data.frame(summary_segments[,c(2:6,8:22)]))

# Average cycling Speed and speed difference between on/out bikepath  
ggplot(table_questionnaire, aes(cycling_speed)) +
  geom_point(alpha = 0.5, size = 1, shape = 1, aes(y=profile_cycling_6, color = cycling_speed)) +
  geom_point(alpha = 0.5, size = 5, shape = 2, aes(y=profile_cycling_7, color = cycling_speed)) +
  geom_point(alpha = 0.5, size = 5, shape = 3, aes(y=profile_cycling_2, color = cycling_speed))









# Relevant
# Cycling speed on and out of a bikepath and difference in mean in CS by gender 
ggplot(table_questionnaire, aes(avg_speed_out_bp, avg_speed_on_bp, color = dem_gender)) +
  geom_point(alpha = 0.5, size = 3) + 
  geom_abline(intercept = 0, slope = 1) +
  facet_grid(.~city)

group1 <- table_questionnaire[!is.na(table_questionnaire$avg_speed_out_bp) & table_questionnaire$dem_gender == 1 &
                                table_questionnaire$city == 'Castelló',]$avg_speed_out_bp
group2 <- table_questionnaire[!is.na(table_questionnaire$avg_speed_out_bp) & table_questionnaire$dem_gender == 2 &
                                table_questionnaire$city == 'Castelló',]$avg_speed_out_bp
wilcox.test(group1,group2)
mean(group1)
mean(group2)
summary_segments[,c('group')]




# test this https://www.r-graph-gallery.com/violin-plot/



questions <- table_questionnaire[,c("profile_cycling_1")]

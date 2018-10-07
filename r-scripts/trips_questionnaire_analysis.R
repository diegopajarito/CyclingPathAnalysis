# Description: This script generates the graphs and merges the 
# results form questionnaires from experiment one 
# and the trip analysis of experiment two
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

# Fix the name of Valletta city and creates a column for the cycling speed
table_segments$cycling_speed <- NA
table_segments[table_segments$speed_geometry > 5 & table_segments$speed_geometry < 50,]$cycling_speed <- 
  table_segments[table_segments$speed_geometry > 5 & table_segments$speed_geometry < 50,]$speed_geometry


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
# Aggregated statistics - General
summary_trips <- data.frame( table_segments %>%
                                  group_by(device, trip_count) %>%
                                  summarise(n_segments = n(),
                                            total_distance = sum(distance_geometry),
                                            avg_speed = mean(cycling_speed)
                                  ))
# Aggregated statistics - Cycling
summary_trips_temp <- data.frame( table_segments[!is.na(table_segments$cycling_speed),] %>%
                               group_by(device, trip_count) %>%
                               summarise(cycling_segments = n(),
                                         cycling_distance = sum(distance_geometry),
                                         cycling_speed = mean(cycling_speed)
                               ))
summary_trips <- merge(summary_trips, summary_trips_temp, all.x = TRUE)

# Aggregated statistics - Cycling on a Bikepath
summary_trips_temp <- data.frame( table_segments[!is.na(table_segments$cycling_speed) & table_segments$distance_to_bikepath < 0.00025,] %>%
                               group_by(device, trip_count) %>%
                               summarise(bpath_segments = n(),
                                         bpath_distance = sum(distance_geometry),
                                         bpath_speed = mean(cycling_speed)
                               ))
summary_trips_temp[is.na(summary_trips_temp$bpath_distance),]$bpath_distance <- 0
summary_trips <- merge(summary_trips, summary_trips_temp, all.x = TRUE)

# Aggregated statistics - Cycling in fua
summary_trips_temp <- data.frame( table_segments[!is.na(table_segments$cycling_speed) & table_segments$in_fua == 1,] %>%
                                    group_by(device, trip_count) %>%
                                    summarise(infua_segments = n(),
                                              infua_distance = sum(distance_geometry),
                                              infua_speed = mean(cycling_speed)
                                    ))
summary_trips <- merge(summary_trips, summary_trips_temp, all.x = TRUE)

# Aggregated statistics - Cycling in fua
summary_trips_temp <- data.frame( table_segments[!is.na(table_segments$cycling_speed) & table_segments$in_fua != 1,] %>%
                                    group_by(device, trip_count) %>%
                                    summarise(outfua_segments = n(),
                                              outfua_distance = sum(distance_geometry),
                                              outfua_speed = mean(cycling_speed)
                                    ))
summary_trips <- merge(summary_trips, summary_trips_temp, all.x = TRUE)
summary_trips$id <- as.character(c(1:nrow(summary_trips)))


# Questionnaire about bikepaths
answers_bpaths <- table_questionnaire[,c('device','dem_gender','City','profile_cycling_1', 'profile_cycling_3', 'profile_cycling_5', 'profile_cycling_8', 
                                         'profile_cycling_10', 'profile_cycling_13',
                                         'profile_cycling_15', 'gaming_app_cycling', 'gaming_app_cycling_strava', 'engagement_A1', 'engagement_A3', 
                                         'engagement_any_app_future', 'satisfaction_1', 'satisfaction_2', 'group')]
summary_trips <- merge(summary_trips, answers_bpaths, all.x = TRUE)
names(summary_trips)



summary_trips$City <- as.character(summary_trips$City)
summary_trips[!is.na(summary_trips$City) & summary_trips$City == 'Malta',]$City <- 'Valletta'
summary_trips$gender <- NA
summary_trips[!is.na(summary_trips$dem_gender) & summary_trips$dem_gender == 1,]$gender <- 'Male'
summary_trips[!is.na(summary_trips$dem_gender) & summary_trips$dem_gender == 2,]$gender <- 'Female'


# Figure 1 - Chapter 5 Thesis
# General, average cycling speed versus distance cycled in a bicycle paths. 
# Differences by city and gender

summary_trips_cs_ms <- summary_trips[summary_trips$City == 'Münster' | summary_trips$City == 'Castelló',]
ggplot(summary_trips_cs_ms[!is.na(summary_trips_cs_ms$gender),], 
       aes(bpath_distance/total_distance*100.0, cycling_speed, color = gender, size = cycling_distance/1000.0)) +
  geom_point(alpha=0.6) + 
  ylab('Average cycling speed (Km/h)') + xlab('Distance cycled on a bicycle path per trip (%)') + 
  labs(color='', size = 'Cycled distance (Km)') +
  theme_bw() + theme(legend.position = 'bottom') + 
  facet_grid(.~City) 
# ch5_tripsgender



# Figure 2 - Chapter 5 Thesis
# General, cycling profile comparison versus distance cycled in a bicycle paths. 
# Differences in the number of trips per answer cathegory and by city
profile_a <- data.frame(summary_trips[,c('profile_cycling_10', 'City')])
profile_a$label <- "'It would be too much \n physical effort'"
names(profile_a) <- c('answer', 'city', 'label')
profile_b <- data.frame(summary_trips[,c('profile_cycling_8', 'City')])
profile_b$label <- "'It would be a bad \n experience using the \n existing roads'"
names(profile_b) <- c('answer', 'city', 'label')
profile_c <- data.frame(summary_trips[,c('profile_cycling_15', 'City')])
profile_c$label <- "'It would mean I have  \n to negotiate difficult \n road junctions'"
names(profile_c) <- c('answer', 'city', 'label')
profile_answers <- rbind(profile_a, profile_b, profile_c)

ggplot(profile_answers[!is.na(profile_answers$city),], aes(answer, label, color = city)) +
  geom_jitter(alpha = 0.6, width = 0.35) +
  scale_x_discrete(name ="",limits=c(-3, -2, -1, 0, 1, 2, 3), labels=c('Strongly disagree','','','Neutral','','','Strongly agree')) +
  ylab('') + ggtitle("Scenario: 'If I make, or were to make, journeys by bicycle:'") +
  labs(color='') +
  theme_bw() + theme(legend.position = 'bottom', axis.ticks.x = element_blank(), plot.title = element_text(hjust = 0.5))

ggplot(summary_trips, aes(gaming_app_cycling, engagement_A3)) + geom_point()

# Figure 3 - Chapter 5 Thesis
# Use of bicycle path, cycling distance in a bicycle path compared to the total trip distance 
# Differences by gender and trip distance
pgender <- ggplot(summary_trips[!is.na(summary_trips$gender),], aes(engagement_A3, bpath_distance/total_distance*100.0,  
                                                         color = gender, size = cycling_distance/1000.0)) +
  geom_point(alpha=0.6, position = "jitter") + 
  scale_x_discrete(limits=c(-3, -2, -1, 0, 1, 2, 3), labels=c('Very weak','','','','','','Very strong')) +
  ylab('Distance cycled on bicycle paths per trip (%)') + xlab('My intention to use an app while cycling is...') + 
  labs(color='', size = 'Cycled distance (Km)') +
  theme_bw() + theme(legend.position = 'bottom', axis.ticks.x = element_blank())

pcity <- ggplot(summary_trips[!is.na(summary_trips$City),], aes(engagement_A3, bpath_distance/total_distance*100.0)) +
  geom_point(alpha=0.5, position = "jitter") + 
  scale_x_discrete(limits=c(-3, -2, -1, 0, 1, 2, 3), labels=c('','','','','','','')) +
  scale_y_discrete(limits=c(0, 100), labels=c('','')) +
  ylab('') + xlab('') + 
  theme_bw() + theme(legend.position = 'none', axis.ticks.x = element_blank()) +
  facet_grid(.~City)

grid.arrange(pgender, pcity, heights = 2:1)


# Figure 4 - Chapter 5 Thesis
# Use of bicycle path, cycling distance in a bicycle path compared to the total trip distance 
# Differences by use of cycling applications
summary_trips$gaming_app_cycling <- as.character(summary_trips$gaming_app_cycling)
summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == '',]$gaming_app_cycling <- NA
summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == 'N',]$gaming_app_cycling <- 'No'
summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == 'Y',]$gaming_app_cycling <- 'Yes'
ggplot(summary_trips[!is.na(summary_trips$gaming_app_cycling),], aes(engagement_A3, cycling_distance/1000.0,
                                                         color = gaming_app_cycling)) +
  geom_point(alpha=0.6, position = "jitter") + 
  scale_x_discrete(limits=c(-3, -2, -1, 0, 1, 2, 3), labels=c('Very weak','','','','','','Very strong')) +
  ylab('Distance cycled per trip (Km)') + xlab('My intention to use an application while cycling is...') + 
  ylim(0,20) +
  labs(color='Using Cyclists mobile Apps', size = 'Trip lenght (Km)') +
  theme_bw() + theme(legend.position = 'bottom', axis.ticks.x = element_blank())




# Mean difference tests
# Three tests for Castelló
cs_trips <- summary_trips[!is.na(summary_trips$City) & summary_trips$City == 'Castelló', ]
group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$bpath_distance /
  cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$total_distance*100.0
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$bpath_distance /
  cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$total_distance*100

group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$cycling_speed
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$cycling_speed

group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$bpath_speed
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$bpath_speed

wilcox.test(group1,group2)
mean(group1, na.rm = TRUE)
mean(group2, na.rm = TRUE)

# Mean difference tests
# Three tests for Münster
cs_trips <- summary_trips[!is.na(summary_trips$City) & summary_trips$City == 'Münster', ]
group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$bpath_distance /
  cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$total_distance*100.0
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$bpath_distance /
  cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$total_distance*100

group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$cycling_speed
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$cycling_speed

group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$bpath_speed
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$bpath_speed

wilcox.test(group1,group2)
mean(group1, na.rm = TRUE)
mean(group2, na.rm = TRUE)


# Mean difference tests
# Three tests for Malta
cs_trips <- summary_trips[!is.na(summary_trips$City) & summary_trips$City == 'Valletta', ]

group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$cycling_speed
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$cycling_speed

group1 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Male',]$total_distance/1000.0
group2 <- cs_trips[!is.na(cs_trips$gender) & cs_trips$gender == 'Female',]$total_distance/1000.0

wilcox.test(group1,group2)
mean(group1, na.rm = TRUE)
mean(group2, na.rm = TRUE)



# Mean difference tests
# Cycled distance and number of trips when using cycling apps
group1 <- summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == 'Yes',]$cycling_distance/1000.0
group2 <- summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == 'No',]$cycling_distance/1000.0

group1 <- summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == 'Yes',]$cycling_speed
group2 <- summary_trips[!is.na(summary_trips$gaming_app_cycling) & summary_trips$gaming_app_cycling == 'No',]$cycling_speed

group1 <- table_questionnaire[!is.na(table_questionnaire$gaming_app_cycling) & table_questionnaire$gaming_app_cycling == 'Y',]$engagement_B3
group2 <- table_questionnaire[!is.na(table_questionnaire$gaming_app_cycling) & table_questionnaire$gaming_app_cycling == 'N',]$engagement_B3

wilcox.test(group1,group2)
mean(group1, na.rm = TRUE)
mean(group2, na.rm = TRUE)



# histogram / n_segments / distance / speed / ()
ggplot(summary_trips, aes(bpath_speed/cycling_speed)) +
  geom_histogram() 


# lines / segments
ggplot(summary_trips, aes(x=reorder(id,bpath_distance)))+
  geom_segment( aes(xend = id, y = 0, yend = bpath_distance, color = 'a')) +
  geom_segment( aes(xend = id, y = 0, yend = (bpath_distance - cycling_distance), color = 'b')) 
  

ggplot(summary_trips[!is.na(summary_trips$dem_gender),], aes(cycling_distance, bpath_distance/cycling_distance, color = as.character(dem_gender))) +
#  scale_color_continuous(low="red", high="green", space ="Lab" ) +
  geom_point(size=3,alpha=0.7)

ggplot(summary_trips, aes(x=reorder(id,cycling_distance), color = profile_cycling_8)) +
  scale_color_continuous(low="red", high="green", space ="Lab" ) +
  geom_segment( aes(xend = id, y = 0, yend = bpath_distance)) +
  geom_segment( aes(xend = id, y = 0, yend = cycling_distance * -1))

ggplot(summary_trips, aes(profile_cycling_8, cycling_distance)) +
  geom_point() + xlim(0,10) + ylab('Cycling speed (Km/h)') + xlab('Cycling Distance (Km)') +
  theme_bw() + theme(legend.position = 'bottom') +
  facet_grid(.~City) 

group1 <- summary_trips[!is.na(summary_trips$dem_gender) & summary_trips$dem_gender == 1,]$bpath_distance /
  summary_trips[!is.na(summary_trips$dem_gender) & summary_trips$dem_gender == 1,]$cycling_distance 
group2 <- summary_trips[!is.na(summary_trips$dem_gender) & summary_trips$dem_gender == 2,]$bpath_distance /
  summary_trips[!is.na(summary_trips$dem_gender) & summary_trips$dem_gender == 2,]$cycling_distance

wilcox.test(group1,group2)
mean(group1, na.rm = TRUE)
mean(group2, na.rm = TRUE)



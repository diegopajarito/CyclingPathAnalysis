# Description: This script generates the graphs and tests to compare 
# the identified frictions in the different cities 
#
# Comments: set your working directory to 
# Author: Diego Pajarito 


# Setup
source('r-scripts/setup.R')
library(ggplot2)
library(lubridate)
library(dplyr)

# Frictions intensity
# Figure 5
table_frictions[table_frictions$city == 'Malta',]$city = 'Valletta'
table_frictions$h_position <- 0
table_frictions[table_frictions$city == 'Valletta',]$h_position = 1
table_frictions[table_frictions$city == 'Castelló',]$h_position = -1
mean_spots <- mean(table_frictions$n_grid_spots)
mean_intensity <- mean(table_frictions$intensity)

ggplot(table_frictions, aes(n_grid_spots + 0.15 * h_position, intensity, color=city)) +
  geom_point(alpha = 0.6, aes(size = n_trips)) +
  geom_vline(xintercept = mean_spots, linetype = 'longdash', color = 'grey60') +
  geom_hline(yintercept = mean_intensity, linetype = 'longdash', color = 'grey60') +
  ylab('Friction intensity') + ylim(50,200) +
  scale_x_discrete(name = 'Size of grid areas', limits=c('1','2','3','4','5','6','7')) +
  labs(size='Trips', colour='') +
  theme_bw() +
  theme(legend.position = 'bottom', axis.ticks.x = element_blank()) 

top_right_q <- table_frictions[table_frictions$n_grid_spots > mean_spots & table_frictions$intensity > mean_intensity,]
top_left_q <- table_frictions[table_frictions$n_grid_spots < mean_spots & table_frictions$intensity > mean_intensity,]

ggplot(top_right_q, aes(city)) + 
  geom_bar() +
  geom_label(stat = 'count', aes(label = ..count..))

ggplot(top_left_q, aes(city)) + 
  geom_bar() +
  geom_label(stat = 'count', aes(label = ..count..))



# Trips distribution
ggplot(table_frictions, aes(x = reorder(id, n_trips), 
                            y = n_trips,
                            fill = city)) +
  geom_bar(stat = 'identity') + coord_flip() +
  theme_bw() + theme(axis.text.y = element_blank(), axis.ticks = element_blank(),
                     panel.grid.major.y = element_line(colour = "white"))

# Segments distribution
ggplot(table_frictions, aes(x = reorder(id, n_segments), 
                            y = n_segments,
                            fill = city)) +
  geom_bar(stat = 'identity') + coord_flip() +
  theme_bw() + theme(axis.text.y = element_blank(), axis.ticks = element_blank(),
                     panel.grid.major.y = element_line(colour = "white"))

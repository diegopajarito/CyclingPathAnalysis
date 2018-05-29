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
table_frictions[table_frictions$city == 'Malta',]$city = 'Valletta'
table_frictions$intensity = 0
table_frictions$intensity = table_frictions$n_segments_l_5kmh * 100.0 / table_frictions$n_cycling_segments
table_frictions$representative = 0
table_frictions[table_frictions$n_segments_l_5kmh,]$representative = 1

# Representative frictions are those with more than 5 walking segments
representative_frictions = table_frictions[table_frictions$representative == 1,]
mean_intensity = mean(representative_frictions$intensity)
ggplot(table_frictions, aes(x = reorder(id, n_segments_l_5kmh * 100.0 / n_cycling_segments), 
                            y = n_segments_l_5kmh * 100.0 / n_cycling_segments,
                            fill = city)) +
  geom_bar(stat = 'identity', aes(alpha = intensity / 2000 + representative)) +
  geom_hline(yintercept = mean_intensity, linetype="dashed", size=1) +
  coord_flip() +
  theme_bw() + theme(axis.text.y = element_blank(), axis.ticks = element_blank(),
                     panel.grid.major.y = element_line(colour = "white"),
                     legend.position = 'bottom', legend.title = element_blank()) +
  scale_alpha(guide = 'none') +
  xlab('') + ylab('Friction intensity (%)') 

mean(table_frictions[table_frictions$city == 'Münster',]$intensity)
mean(table_frictions[table_frictions$city == 'Castelló',]$intensity)
mean(table_frictions[table_frictions$city == 'Valletta',]$intensity)

mean(representative_frictions[representative_frictions$city == 'Münster',]$intensity)
mean(representative_frictions[representative_frictions$city == 'Castelló',]$intensity)
mean(representative_frictions[representative_frictions$city == 'Valletta',]$intensity)

table_frictions[representative_frictions$city == 'Münster',]$intensity
table_frictions[representative_frictions$city == 'Castelló',]$intensity
table_frictions[representative_frictions$city == 'Valletta',]$intensity

representative_frictions[representative_frictions$city == 'Münster',]$intensity
representative_frictions[representative_frictions$city == 'Castelló',]$intensity
representative_frictions[representative_frictions$city == 'Valletta',]$intensity


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

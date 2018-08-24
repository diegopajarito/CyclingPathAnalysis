# Description: This script generates the graphs and tests to compare 
# participants answers about their perception of competition 
# and collaboration when using the bicycle.
#
# Comments: set your working directory to 
# Author: Diego Pajarito 


# Setup
source('r-scripts/setup.R')
library(ggplot2)



# Going deep into frictions
# Paper: Figure 4
table_grid[which(is.na(table_grid$n_origin)),]$n_origin = 0 # if there are no origin 
table_grid[which(is.na(table_grid$n_destination)),]$n_destination = 0

table_grid$has_od = 'Without Origin / Destination'
table_grid[table_grid$n_origin>0 | table_grid$n_destination>0,]$has_od = 'Has Origin or Destination'

cities <- c('Castelló' = 'Castelló',
            'Münster' = 'Münster', 
            'Malta' = 'Valletta')
ggplot(table_grid, aes(n_segments/n_trips, n_trips, color = has_od, shape = has_od)) + 
  geom_point(alpha = 0.7) + 
  scale_shape_manual(values=c(4, 20)) +
  scale_size_manual(values=c(1.5, 0.5)) +
  scale_x_continuous(breaks=c(3.0, 10.0, 20.0, 50.0, 100.0), labels=c('3x', '10x', '20x', '50x', '100x')) +
  #geom_abline(intercept = 0, color = 'grey') +
  ylab('Number of trips') + xlab('Segments per trip') +
  #ylim(0,50) + xlim(0,50) +
  labs(color='', shape='') +
  theme_bw() + theme(legend.position = 'bottom', legend.box = "vertical", panel.grid.minor.x = element_blank()) +  
  facet_grid(city ~ ., labeller = as_labeller(cities))




p_seg <- ggplot(table_grid, aes(n_trips, n_segments_l_5kmh / n_trips, color = city)) + 
  geom_point()
ggplot(table_grid, aes(n_segments, n_segments_l_5kmh/n_segments, color = city)) + 
  geom_point() + facet_grid(city ~ .)

ggplot(table_grid, aes(n_segments, n_cycling_segments/n_segments, color = city)) + 
  geom_point() + facet_grid(city ~ .)

ggplot(table_grid, aes(n_segments_l_5kmh, n_cycling_segments, color = city)) + 
  geom_point() + facet_grid(city ~ .) + xlim(0,100)

ggplot(table_grid, aes(n_trips, n_segments, color = city)) + 
  geom_point() + facet_grid(city ~ .)

mean(table_grid$n_segments, na.rm = TRUE)
mean(table_grid[table_grid$n_segments_l_5kmh>0,]$n_segments_l_5kmh, na.rm = FALSE)
mean(table_grid[table_grid$n_cycling_segments>0,]$n_cycling_segments, na.rm = FALSE)






ggplot(table_segments, aes(day_of_the_week, y = distance_geometry / 1000)) +  geom_bar( stat = 'sum')


#table_segments_cs$in_bikepath = FALSE
#table_segments_cs[is.na(table_segments_cs$id_bikepath), ]$in_bikepath = TRUE
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




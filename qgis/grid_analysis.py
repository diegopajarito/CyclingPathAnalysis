"""
This script uses the python qgis libraries to perform geospatial analysis
It takes a grid and counts the number of objects intersecting at each spot

Layers should be on the same projection
You should provide a polygon layer for the grid. provide a name grid_lyr_name
The grid layer must have an attribute for the count. provide count_attribute
You should provide a vector layer for the trips and the name at trips_lyr_name

Author: Diego Pajarito
"""
# Qgis modules
from qgis.core import *
import qgis.utils

# Setup
lyr_grid_set = False
lyr_trips_set = False
grid_lyr_name = 'Grid'
counter_field_name = 'n_trips'
trips_lyr_name = 'trips_cs_3042'
field_idx = -1
grid_counter = 0
counter = 0

mapcanvas = iface.mapCanvas()

layers = mapcanvas.layers()


for l in layers:
    if l.name() == grid_lyr_name:
        lyr_grid = l
        lyr_grid_set = True
        print ('grids layer: ' + l.name())
    elif l.name() == trips_lyr_name:
        lyr_trips = l
        lyr_trips_set = True
        print ('trips layer:' + l.name())
    else:
        print ('Layer excluded: ' + l.name())

print ('All layers read')

if lyr_grid_set & lyr_trips_set:
    print ('lyrs set OK')
    indexes = lyr_grid.attributeList ()
    for id in indexes:
        if lyr_grid.attributeDisplayName (id) == counter_field_name:
            print (lyr_grid.attributeDisplayName (id))
            field_idx = id
    
    if field_idx != -1:
        lyr_grid.startEditing()
        print ('Count started')
        for g in lyr_grid.getFeatures():
            for t in lyr_trips.getFeatures():
                intersection = g.geometry().intersects(t.geometry())
                #print(intersection)
                if intersection:
                    counter = counter + 1
            lyr_grid.changeAttributeValue(g.id(), field_idx, counter)
            #print ('grid processed: ' + str(g.id()) + ' - trips: ' + str(counter))
            counter = 0
            grid_counter = grid_counter + 1
            if grid_counter % 1000 == 0:
                print ('Updated grids: ' + str(grid_counter))
        lyr_grid.commitChanges()
    else:
        print ('set the attribute name for recording the trips count')
else:
    print('provide the right name of the grid and trips layers')

print('Count finished')










#
#lyr = iface.activeLayer()
#
#features = lyr.getFeatures()
#
#for feat in features:
#    attrs = feat.attributes()
#    print (attrs[1])
#    
#    
#    
#
#print layers[0].name() #gebaeude
#print layers[1].name()
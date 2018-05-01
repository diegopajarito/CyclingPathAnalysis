"""
This script uses the python qgis libraries to perform geospatial analysis
It takes two layers and calculates for the first one the closest object
from the other and the distance to it 

Layers should be on the same projection
You can provide vector layers with any kind of geometry. 
Provide the name of the first layer at name segments_lyr_name
The segments layer must have two attributes for storing the distance and id
You should provide a vector layer for the objects at objects_lyr_name
You must provide the max distance to measure as a threshold

Author: Diego Pajarito
"""
# Qgis modules
from qgis.core import *
import qgis.utils

# Setup
lyr_segments_set = False
lyr_objects_set = False
segments_lyr_name = 'segments_cs'
distance_field_name = 'd_bikepath'
oid_field_name = 'id_bikepath'
object_lyr_name = 'carrils_bici_2_2017_02'
field_d_idx = -1
field_id_idx = -1
max_distance = 0.0005
counter = 0

mapcanvas = iface.mapCanvas()
layers = mapcanvas.layers()

for l in layers:
    if l.name() == segments_lyr_name:
        lyr_segments = l
        lyr_segments_set = True
        print ('segments layer: ' + l.name())
    elif l.name() == object_lyr_name:
        lyr_objects = l
        lyr_objects_set = True
        print ('objects layer:' + l.name())
    else:
        print ('Layer excluded: ' + l.name())

print ('All layers read')

if lyr_segments_set & lyr_objects_set:
    print ('lyrs set OK')
    indexes = lyr_segments.attributeList ()
    for id in indexes:
        if lyr_segments.attributeDisplayName (id) == distance_field_name:
            field_d_idx = id
        elif lyr_segments.attributeDisplayName (id) == oid_field_name:
            field_id_idx = id
    if (field_d_idx > -1) & (field_id_idx > -1):
        lyr_segments.startEditing()
        print ('Getting the closest object and its distance')
        for s in lyr_segments.getFeatures():
            geom_buffer = s.geometry().buffer(max_distance, -1)
            
            for o in lyr_objects.getFeatures():
                intersects = o.geometry().intersects(geom_buffer)
                
                if intersects:
                    print ('intersects')
                    intersection = o.geometry().intersection(geom_buffer)
                    #select by location and iterate the selection to estimate d
                    #distances
                    print(intersection.asWkt())
                    for i in intersection.getfeatures():
                        distance = s.geometry().distance(i)
                        id = i.id()
                        print ('closest point found for segment ' + (s.id()))
                        lyr_segments.changeAttributeValue(s.id(), field_d_idx, distance)
                        lyr_segments.changeAttributeValue(s.id(), field_id_idx, i.id())
                #else:
                    #print('no closest point found for segment ' + str(s.id()))
            counter = counter + 1
            #if grid_counter % 1000 == 0:
            if counter > 100:
                break
#                lyr_segments_set.commitChanges()
#                print ('Updated grids: ' + str(grid_counter))
#                lyr_segments_set.startEditing()
        lyr_segments.commitChanges()
    else:
        print ('set the attribute name for distance and id')
else:
    print('provide the right name of the segments and objects layers')

print('Closest point finding finished')

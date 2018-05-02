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
import processing

# Setup
lyr_segments_set = False
lyr_objects_set = False
segments_lyr_name = 'segments_cs'
distance_field_name = 'd_bikepath'
oid_field_name = 'id_bikepath'
object_lyr_name = 'bikepaths_cs'
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
            # create a vector layer in memory to store the buffer
            buffer_geom = s.geometry().buffer(max_distance, -1)
            buffer_lyr = QgsVectorLayer("Polygon?crs=epsg:4326&index=yes", "temporal_buffer", "memory")
            buffer_pr = buffer_lyr.dataProvider()
            buffer_ftr = QgsFeature()
            buffer_ftr.setGeometry(buffer_geom)
            buffer_pr.addFeatures([buffer_ftr])
            buffer_lyr.updateExtents()

            # use the layer in memory to select objects
            selection_parameters = {'INPUT': lyr_objects, 'INTERSECT': buffer_lyr, 'PREDICATE': 0, 'METHOD': 0}
            processing.run("qgis:selectbylocation", selection_parameters)
            print ('qgis:select executed')
            
            selected_count = lyr_objects.selectedFeatureCount()

            
            if selected_count > 0:
                print ('segment: ' + str(s.id()) + ' has ' + str(selected_count) + ' objets closeby')
                selectedList = lyr_objects.selectedFeatureIds()
                for i in selectedList:
                    lyr_segments.changeAttributeValue(s.id(), field_id_idx, i)
                    print('segment: ' + str(s.id()) + ' updated with object id: ' + str(i))
                    #distance = s.geometry().distance(i)
                    
                
            else:
                print ('no selected')
            
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

from qgis.core import *
import processing

# creating the BBOXes for the trhee cities
base_path = "/Users/pajarito/Documents/QGIS/Magike/trips/"

reference_systems = ["epsg:25830", "epsg:32733", "epsg:32633"]
bboxes = []
#coords_cs = [[QgsPoint(-0.826, 39.352), QgsPoint(0.276, 39.352), QgsPoint(0.276, 40.661), QgsPoint(-0.826, 40.661)]]
coords_cs = [[QgsPoint(14.3579, 35.7922), QgsPoint(14.5740, 35.7922), QgsPoint(14.5740, 36.0311), QgsPoint(14.3579, 36.0311)]]
bboxes.append(QgsGeometry.fromPolygon(coords_cs))
coords_mt = [[QgsPoint(14.3579, 35.7922), QgsPoint(14.5740, 35.7922), QgsPoint(14.5740, 36.0311), QgsPoint(14.3579, 36.0311)]]
bboxes.append(QgsGeometry.fromPolygon(coords_mt))
coords_ms = [[QgsPoint(7.4334, 51.6860), QgsPoint(7.7600, 51.6860), QgsPoint(7.7600, 52.1970), QgsPoint(7.4334, 52.1970)]]
bboxes.append(QgsGeometry.fromPolygon(coords_ms))
    

#selectionof the layer with the trips
trips = processing.getObject("trips")
features_trips = trips.getFeatures()

for i in range(0,3):
    trips.removeSelection()
    print(bboxes[i])
    for f in features_trips:
        if f.geometry().intersects(bboxes[i]):
            trips.select(f.id())
    path = base_path + "temp/city" + str(i) + ".shp"
    path_pl = base_path + "temp/city" + str(i) + "pl.shp"
    processing.runalg('qgis:saveselectedfeatures', trips, path)
    processing.runalg("qgis:reprojectlayer", path, reference_systems[i], path_pl)
    print(str(i) + " - " + path_pl)
    
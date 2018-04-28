"""
This script allow us to convert a list of coordinates into a string geometry
It does not consider the information of trips
It just considers location, distance and time

Author: Diego Pajarito
"""

import geojson
import pandas as pd
from LatLon import LatLon, Latitude, Longitude
from geojson import FeatureCollection, Feature, LineString

from data import data_setup as data


def build_feature(ftr_geometry, ftr_properties):
    ftr = Feature(properties=ftr_properties, geometry=ftr_geometry)
    if ftr.is_valid:
        return ftr
    else:
        print(ftr)
        return False


def get_start_stop_linestring(point):
    tp = []
    tp.append(point)
    tp.append(point)
    return LineString(tp)


def get_generic_linestring():
    pt = (0, 0)
    pt1 = (0.0001, 0.001)
    return LineString([pt, pt1])


def get_distance(point1, point2):
    point1_coordinates = LatLon(Latitude(point1[1]), Longitude(point1[0]))
    point2_coordinates = LatLon(Latitude(point2[1]), Longitude(point2[0]))
    distance = point1_coordinates.distance(point2_coordinates)
    return distance * 1000


def main():
    mls_points = []
    feature_lines = []
    new_trip = True
    trip_count = 0
    last_device = ''

    location = data.getLocation()
    location_sort = location.sort_values(['device', 'time_gps'])

    for i, row in location_sort.iterrows():

        lat = location['latitude'][i]
        lon = location['longitude'][i]
        alt = location['altitude'][i]
        device = location['device'][i]
        timestamp = pd.to_datetime(location_sort['time_gps'][i])
        point = (lon, lat, alt)

        if new_trip:
            new_trip = False
            trip_start = timestamp
            trip_count = trip_count + 1

            last_point = point
            last_device = device
            last_timestamp = timestamp
            mls_points.append(point)
        else:
            distance = get_distance(last_point, point)
            time_difference_min = pd.Timedelta(timestamp - last_timestamp).total_seconds() / 60
            if distance > 500 or time_difference_min > 5 or last_device != device:
                trip_end = timestamp
                device = location_sort['device'][i]
                properties = {'device': device, 'start_time': str(trip_start), 'end_time': str(trip_end),
                              'trip_count': trip_count, 'point_count': len(mls_points)}
                ls = LineString(mls_points)
                if ls.is_valid:
                    feature = build_feature(ls, properties)
                else:
                    if len(mls_points) == 1:
                        ls = LineString(get_start_stop_linestring(last_point))
                        feature = build_feature(ls, properties)
                        print ("trip with only one point: " + str(device))
                    else:
                        ls = LineString(get_generic_linestring())
                        feature = build_feature(ls, properties)
                        print ("Trip with empty Linestring: " + str(device))
                if feature:
                    feature_lines.append(feature)

                new_trip = False
                trip_start = timestamp
                trip_count = trip_count + 1

                last_point = point
                last_device = device
                last_timestamp = timestamp
                mls_points = [point]

            else:
                mls_points.append(point)
                last_point = point
                last_timestamp = timestamp
                new_trip = False



    crs_4326 = {
        "type": "name",
        "properties": {
            "name": "urn:ogc:def:crs:OGC:1.3:CRS84"
        }
    }

    feature_collection = FeatureCollection(feature_lines)
    print("Trips Feature is valid: " + str(feature_collection.is_valid))

    with open(data.getTripsRawPath(), 'w') as outfile:
        geojson.dump(feature_collection, outfile)


if __name__ == "__main__":
    main()

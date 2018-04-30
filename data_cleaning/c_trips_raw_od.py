"""
This script allow us to convert a list of coordinates into a string geometry
It does not consider the information of trips
It just considers location, distance and time

Author: Diego Pajarito
"""

import datetime

import geojson
import pandas as pd
from LatLon import LatLon, Latitude, Longitude
from geojson import FeatureCollection, Feature, LineString, Point

from data import data_setup as data

location = data.getLocation()
measurement = data.getMeasurement()


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


def build_trip_feature(properties, points):
    linestring = LineString(points)
    if linestring.is_valid:
        feature = build_feature(linestring, properties)
    else:
        if len(points) == 1:
            ls = LineString(get_start_stop_linestring(points[0]))
            feature = build_feature(ls, properties)
            print ("trip with only one point: " + str(properties))
        else:
            ls = LineString(get_generic_linestring())
            feature = build_feature(ls, properties)
            print ("Trip with empty Linestring: " + str(properties))
    return feature


def build_segment_feature(properties, start_point, end_point):
    ls = LineString([start_point, end_point])
    if ls.is_valid:
        feature = build_feature(ls, properties)
    else:
        ls = LineString(get_generic_linestring())
        feature = build_feature(ls, properties)
        print ("Segment with empty Linestring: " + str(properties))
    return feature


def get_distance(point1, point2):
    point1_coordinates = LatLon(Latitude(point1[1]), Longitude(point1[0]))
    point2_coordinates = LatLon(Latitude(point2[1]), Longitude(point2[0]))
    distance = point1_coordinates.distance(point2_coordinates)
    return distance * 1000


def get_last_speed(device, time):
    values = measurement[measurement.measurement == 'speed']
    values = values[values.device == device]
    values = values[values.time_device < time]
    if values.size > 1:
        values_sort = values.sort_values('time_device', ascending=False)
        value = values_sort['value'].iloc[0] * 3.6
    else:
        value = -1
    return value


def get_last_distance_a(device, time):
    values = measurement[measurement.measurement == 'distance']
    values = values[values.device == device]
    values = values[values.time_device < time]
    if values.size > 1:
        values_sort = values.sort_values('time_device', ascending=False)
        value = values_sort['value'].iloc[0]
    else:
        value = -1
    return value


def get_last_distance_b(device, time):
    values = measurement[measurement.measurement == 'last_distance']
    values = values[values.device == device]
    values = values[values.time_device < time]
    if values.size > 1:
        values_sort = values.sort_values('time_device', ascending=False)
        value = values_sort['value'].iloc[0]
    else:
        value = -1
    return value


def build_od_feature(device, time, od, trip, point):
    ftr_properties = {'device': device, 'timestamp': str(time), 'type': od, 'trip_count': trip}
    ftr_geometry = Point(point)
    feature = Feature(properties=ftr_properties, geometry=ftr_geometry)
    return feature


def main():
    od_points = []
    trip_points = []
    feature_segments = []
    feature_trips = []
    new_trip = True
    trip_count = 0

    location_sort = location.sort_values(['device', 'time_gps'])

    for i, row in location_sort.iterrows():

        lat = location['latitude'][i]
        lon = location['longitude'][i]
        alt = location['altitude'][i]
        device = location['device'][i]
        precision = location['precision'][i]
        timestamp = pd.to_datetime(location_sort['time_gps'][i])
        point = (lon, lat, alt)

        if new_trip:
            new_trip = False
            segment_count = 1
            trip_count = trip_count + 1
            trip_points.append(point)

            segment_start = timestamp
            trip_start = timestamp
            last_point = point
            last_device = device
            last_timestamp = timestamp
            od_feature = build_od_feature(device, timestamp, 'origin', trip_count, point)
            od_points.append(od_feature)

        else:

            distance = get_distance(last_point, point)
            time_difference_min = pd.Timedelta(timestamp - last_timestamp).total_seconds() / 60

            if distance > 500 or time_difference_min > 5 or last_device != device:
                properties_trip = {'device': last_device, 'start_time': str(trip_start),
                                   'end_time': str(last_timestamp),
                                   'trip_count': trip_count, 'point_count': len(trip_points)}
                feature_trip = build_trip_feature(properties_trip, trip_points)
                od_feature = build_od_feature(last_device, last_timestamp, 'destination', trip_count, last_point)
                od_points.append(od_feature)

                if feature_trip:
                    feature_trips.append(feature_trip)

                trip_count = trip_count + 1
                trip_start = timestamp
                trip_points = [point]
                segment_start = timestamp
                segment_count = 1
                last_point = point
                last_device = device
                last_timestamp = timestamp
                od_feature = build_od_feature(device, timestamp, 'origin', trip_count, point)
                od_points.append(od_feature)

            else:
                last_distance_a = get_last_distance_a(device, location_sort['time_gps'][i])
                last_distance_b = get_last_distance_b(device, location_sort['time_gps'][i])
                last_speed = get_last_speed(device, location_sort['time_gps'][i])
                if time_difference_min == 0:
                    speed_geometry = 0
                else:
                    speed_geometry = (distance / 1000) / (time_difference_min / 60)
                # get last distance
                properties_segment = {'device': device, 'start_time': str(segment_start), 'end_time': str(timestamp),
                                      'segment_count': segment_count, 'distance_geometry': distance,
                                      'last_distance_a': last_distance_a, 'last_distance_b': last_distance_b,
                                      'speed_geometry': speed_geometry, 'last_speed': last_speed,
                                      'precision_end': precision, 'trip_count': trip_count}
                feature_segment = build_segment_feature(properties_segment, last_point, point)
                if feature_segment:
                    feature_segments.append(feature_segment)

                trip_points.append(point)
                segment_start = timestamp
                segment_count = segment_count + 1
                last_point = point
                last_device = device
                last_timestamp = timestamp

    # last point to build a trip
    properties_trip = {'device': last_device, 'start_time': str(trip_start), 'end_time': str(last_timestamp),
                       'trip_count': trip_count, 'point_count': len(trip_points)}
    feature_trip = build_trip_feature(properties_trip, trip_points)
    if feature_trip:
        feature_trips.append(feature_trip)

    feature_collection_trips = FeatureCollection(feature_trips)
    print("Trips Feature collection is valid: " + str(feature_collection_trips.is_valid))
    with open(data.getTripsRawPath(), 'w') as outfile:
        geojson.dump(feature_collection_trips, outfile)

    feature_collection_segments = FeatureCollection(feature_segments)
    print("Segments Feature collection is valid: " + str(feature_collection_segments.is_valid))
    with open(data.getSegmentsPath(), 'w') as outfile:
        geojson.dump(feature_collection_segments, outfile)

    feature_collection_od = FeatureCollection(od_points)
    print("Origin Destination Feature collection is valid: " + str(feature_collection_od.is_valid))
    with open(data.getTripsODPath(), 'w') as outfile:
        geojson.dump(feature_collection_od, outfile)

    print("Processed %d points, finished at %s" % {location.size, str(datetime.datetime.now().time())})


if __name__ == "__main__":
    print ("Processing started at %s" % str(datetime.datetime.now().time()))
    main()

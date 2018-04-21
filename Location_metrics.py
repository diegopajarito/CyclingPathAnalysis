import data_setup as data
import geojson
from geojson import FeatureCollection, Feature, Point, LineString
import pandas as pd

location = data.getLocation()
measurement = data.getMeasurement()


def getLastRecordedSpeed(device, date):
    recorded_speed = measurement[(measurement.device == device) &
                                 (measurement.measurement == 'speed') &
                                 (measurement.time_device < date)]
    if recorded_speed.size > 0:
        recorded_speed_sort = recorded_speed.sort_values(by=['time_device'], ascending=False)
        speed = recorded_speed_sort.iloc[0]['value']
        time = recorded_speed_sort.iloc[0]['time_device']
    else:
        speed = -1
        time = 0

    last_speed = {'time': time, 'speed': speed}
    return last_speed


def getLastRecordedDistance(device, date):
    recorded_distance = measurement[(measurement.device == device) &
                                 (measurement.measurement == 'distance') &
                                 (measurement.time_device < date)]
    if recorded_distance.size > 0:
        recorded_distance_sort = recorded_distance.sort_values(by=['time_device'], ascending=False)
        distance = recorded_distance_sort.iloc[0]['value']
        time = recorded_distance_sort.iloc[0]['time_device']
    else:
        distance = -1
        time = 0

    last_distance = {'time': time, 'distance': distance}
    return last_distance


def getLastRecordedDistanceLast(device, date):
    recorded_distance = measurement[(measurement.device == device) &
                                 (measurement.measurement == 'last_distance') &
                                 (measurement.time_device < date)]
    if recorded_distance.size > 0:
        recorded_distance_sort = recorded_distance.sort_values(by=['time_device'], ascending=False)
        distance = recorded_distance_sort.iloc[0]['value']
        time = recorded_distance_sort.iloc[0]['time_device']
    else:
        distance = -1
        time = 0

    last_distance = {'time': time, 'distance': distance}
    return last_distance


def build_feature(ftr_geometry, ftr_properties):
    ftr = Feature(properties=ftr_properties, geometry=ftr_geometry)
    if ftr.is_valid:
        return ftr
    else:
        print(ftr)
        return False


def main():

    feature_points = []
    feature_lines = []
    last_device = ""
    last_time = 0
    counter = 0

    location_sort = location.sort_values(['device', 'time_gps'])

    for i, row in location_sort.iterrows():
        # Get data of points and check the associated measurement
        device = row.device
        time_gps = row.time_gps
        lat = row.latitude
        lon = row.longitude
        alt = row.altitude
        precision = row.precision
        recorded_speed = getLastRecordedSpeed(device, time_gps)
        speed = recorded_speed['speed']
        time_speed = recorded_speed['time']
        recorded_distance = getLastRecordedDistance(device, time_gps)
        distance = recorded_distance['distance']
        distance_time = recorded_distance['time']
        recorded_distance_last = getLastRecordedDistanceLast(device, time_gps)
        distance_last = recorded_distance_last['distance']
        distance_last_time = recorded_distance_last['time']
        properties = {'device': device, 'time_gps': str(time_gps), 'altitude': alt, 'precision': precision,
                      'speed': speed, 'speed_time': time_speed, 'distance': distance, 'distance_time': distance_time,
                      'distance_last': distance_last, 'distance_last_time': distance_last_time}
        point_coordinates = (lon, lat, alt)
        geometry = Point(point_coordinates)
        if geometry.is_valid:
            point = build_feature(geometry, properties)
            if point:
                feature_points.append(point)

        # Build segments
        time_difference = pd.Timedelta(pd.to_datetime(time_gps) - pd.to_datetime(last_time)).microseconds / 6000000.0
        if (device == last_device) & (time_difference < 10):
            ls_properties = {'device': device, 'time_start': last_time, 'time_end': time_gps, 'speed_start': last_speed,
                             'speed_end': speed, 'distance': distance, 'last_distance': distance_last,
                             'precision_start': last_precision, 'precision_end': precision}
            points = [last_point_coordinates, point_coordinates]
            ls_geometry = LineString (points)
            if ls_geometry.is_valid:
                linestring = build_feature(ls_geometry, ls_properties)
                if linestring:
                    feature_lines.append(linestring)

        last_device = device
        last_time = time_gps
        last_speed = speed
        last_precision = precision
        last_point_coordinates = point_coordinates

        counter = counter + 1
        if counter % 500 == 0:
            print("We have processed : " + str(counter) + " Points")

    feature_collection_points = FeatureCollection(feature_points)
    print("Locations Feature is valid: " + str(feature_collection_points.is_valid))
    feature_collection_segments = FeatureCollection(feature_lines)
    print("Segments Feature is valid: " + str(feature_collection_segments.is_valid))

    with open('./output/location.geojson', 'w') as outfile:
        geojson.dump(feature_collection_points, outfile)

    with open('./output/segments.geojson', 'w') as outfile:
        geojson.dump(feature_collection_segments, outfile)


if __name__ == "__main__":
    main()

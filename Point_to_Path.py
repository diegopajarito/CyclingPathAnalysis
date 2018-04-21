import data_setup as data
import geojson
from geojson import FeatureCollection, Feature, LineString
import pandas as pd


def build_feature (ftr_geometry, ftr_properties):
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
    pt = (0,0)
    pt1 = (0.0001, 0.001)
    return LineString([pt, pt1])


def main():
    mls_points = []
    ftrc_lines = []

    trips = data.getTrips()
    location = data.getLocation()
    trips_sort = trips.sort_values(['device', 'trip_count'])

    for i, row in trips_sort.iterrows():
        trip_start = pd.to_datetime(trips['trip_start'][i])
        trip_end = pd.to_datetime(trips['trip_stop'][i])
        device = trips['device'][i]
        trip_count = trips['trip_count'][i]
        location['time_gps'] = pd.to_datetime(location['time_gps'])
        points_trip = location.loc[(location['device'] == device) & (location['time_gps'].between(trip_start, trip_end))]

        if points_trip.size > 1:
            points_sort = points_trip.sort_values(['time_gps'])
            for j, row in points_sort.iterrows():
                lat = location['latitude'][j]
                lon = location['longitude'][j]
                alt = location['altitude'][j]
                timestamp = pd.to_datetime(location['time_gps'][j])
                pt = (lon, lat, alt)
                mls_points.append(pt)

            properties = {'device': device, 'start_time': str(trip_start), 'end_time': str(trip_end),
                          'trip_count': trip_count, 'point_count': len(mls_points)}
            ls = LineString(mls_points)
            if ls.is_valid:
                ftr = build_feature(ls, properties)
            else:
                if len(mls_points) == 1:
                    ls = LineString(get_start_stop_linestring(pt))
                    ftr = build_feature(ls, properties)
                    print ("trip with only one point: " + str(device))
                else:
                    ls = LineString(get_generic_linestring())
                    ftr = build_feature(ls, properties)
                    print ("Trip with empty Linestring: " + str(device))
            if ftr:
                ftrc_lines.append(ftr)
            else:
                print("Error in Feature" + str(device) + " - " + str(trip_count) + " - " + str(ftr))
            mls_points = []



    crs_4326 = {
        "type": "name",
        "properties": {
            "name": "urn:ogc:def:crs:OGC:1.3:CRS84"
        }
    }


    ftrc = FeatureCollection(ftrc_lines)
    print("Trips Feature is valid: " + ftrc.is_valid)

    with open('./output/trips.geojson', 'w') as outfile:
        geojson.dump(ftrc, outfile)


if __name__ == "__main__":
    main()



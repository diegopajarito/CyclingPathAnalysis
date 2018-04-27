"""
This script processes the information about trips recorded by the application, its start/stop times
as well as the relationship with the tags reported by the users
I also processes the tags translations and equivalences as well as the basic text mining methods

Author: Diego Pajarito
"""


import pandas as pd
import datetime
import data_setup as data
import geojson
from geojson import Feature, FeatureCollection
trips_raw = data.getTripsRaw()
trips_app = data.getTrips()
tags = data.getTags()
tags_polarity = data.getTagsPolarity()


def update_trip_properties(properties):
    start = properties['start_time']
    stop = properties['end_time']
    trip_range = pd.date_range(start, stop)
    device = properties['device']

    trips_device = trips_app[trips_app.device == device]
    if trips_device.size >0:
        for td in trips_device:
            trips_device_range = pd.date_range(td.trip_start, td.trip_stop)
        trip_app = trips_device[trips_device.trip_start > start]
        trip_app = trip_app[trip_app.trip_start < stop]
        if trip_app.size > 0:
            print 'overlap'
        else:
            trip_app = trips_device[trips_device.trip_stop > start]
            trip_app = trip_app[trip_app.trip_stop < stop]
            if trip_app.size > 0:
                print 'overlap'
            else:
                trip_app = trips_device[trips_device.trip_start < start]
                trip_app = trip_app[trip_app.trip_stop > stop]
                if trip_app.size > 0:
                    print 'overlap'

    return properties


def main():
    trips_tags_features = []

    for trip in trips_raw['features']:
        trip['properties'] = update_trip_properties(trip['properties'])
        feature = Feature(trip['properties'], trip['geometry'])
        trips_tags_features.append(feature)

    trips_tags_feature_collection = FeatureCollection(trips_tags_features)

    print("Trips Tags Feature collection is valid: " + str(trips_tags_feature_collection.is_valid))
    with open('./output/trips_tags.geojson', 'w') as outfile:
        geojson.dump(trips_tags_feature_collection, outfile)

if __name__ == "__main__":
    print ("Processing started at %s" % str(datetime.datetime.now().time()))
    main()

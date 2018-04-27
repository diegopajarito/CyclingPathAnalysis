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


def get_sentiment_polarity(text):
    tag = tags_polarity[tags_polarity.text == text]
    if len(tag.index):
        polarity = {'text_en': tag['text_en'].iloc[0], 'sentiment_polarity': tag['sentiment_polarity'].iloc[0],
                    'category': tag['category'].iloc[0]}
    else:
        polarity = {'text_en': '', 'sentiment_polarity': '', 'category': ''}
    return polarity


def update_trip_properties(properties):
    start = properties['start_time']
    stop = properties['end_time']
    device = properties['device']
    trips_device = trips_app[trips_app.device == device]
    if trips_device.size > 0:
        trips_between_time = trips_device[((pd.to_datetime(trips_device['trip_start']) >= pd.to_datetime(start)) &
                                           (pd.to_datetime(trips_device['trip_start']) <= pd.to_datetime(stop))) |
                                          ((pd.to_datetime(trips_device['trip_stop']) >= pd.to_datetime(start)) &
                                           (pd.to_datetime(trips_device['trip_stop']) <= pd.to_datetime(stop))) |
                                          ((pd.to_datetime(trips_device['trip_start']) < pd.to_datetime(start)) &
                                           (pd.to_datetime(trips_device['trip_stop']) > pd.to_datetime(stop)))]
        if len(trips_between_time.index) > 0:
            print('Trips Matching %d' % len(trips_between_time.index))
            trip_id = trips_between_time['trip_count'].iloc[0]
            trip_tags = tags[(tags['device'] == device) & (tags['trip_count'] == trip_id)]
            if len(trip_tags.index) > 0:
                tag_counter = 1
                for text in trip_tags['text']:
                    label_text = 'tag_%d_text' % tag_counter
                    label_text_en = 'tag_%d_text_en' % tag_counter
                    label_polarity = 'tag_%d_polarity' % tag_counter
                    label_category = 'tag_%d_category' % tag_counter
                    tag_polarity = get_sentiment_polarity(text)
                    properties[label_text] = str(text)
                    properties[label_text_en] = tag_polarity['text_en']
                    properties[label_polarity] = tag_polarity['sentiment_polarity']
                    properties[label_category] = tag_polarity['category']
                    tag_counter = tag_counter + 1
    return properties


def main():
    trips_tags_features = []

    for trip in trips_raw['features']:
        trip['properties'] = update_trip_properties(trip['properties'])
        feature = Feature(properties=trip['properties'], geometry=trip['geometry'])
        trips_tags_features.append(feature)

    trips_tags_feature_collection = FeatureCollection(trips_tags_features)

    print("Trips Tags Feature collection is valid: " + str(trips_tags_feature_collection.is_valid))
    with open('./output/trips_tags.geojson', 'w') as outfile:
        geojson.dump(trips_tags_feature_collection, outfile)

if __name__ == "__main__":
    print ("Processing started at %s" % str(datetime.datetime.now().time()))
    main()

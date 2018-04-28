"""
This script handles data access and returns the variables needed in the rest of
strips

Author: Diego Pajarito
"""

import pandas as pd

file_location = '../data/Cyclist_Location.csv'
file_measurement = '../data/Cyclist_Measurement.csv'
file_trips = '../data/Cyclist_Trip.csv'
file_tags = '../data/Cyclist_Tag.csv'
file_tags_polarity = '../data/Tags_polarity.csv'

file_location_geo = '../output/location.geojson'
file_trips_raw = '../output/trips_raw.geojson'
file_segments_raw = '../output/segments_raw.geojson'
file_segments = '../output/segments.geojson'
file_trips_tags = '../output/trips_tags.geojson'
file_user_od = '../output/user_od.geojson'
file_trips_od = '../output/trips_od.geojson'


def main():
    print ("reading files ...")


def getLocation():
    return pd.read_csv(file_location, '\t')


def getMeasurement():
    return pd.read_csv(file_measurement, '\t')


def getTrips():
    return pd.read_csv(file_trips, '\t')


def getTripsRaw():
    return pd.read_json(file_trips_raw)


def getLocationPath():
    return file_location_geo


def getSegmentsRawPath():
    return file_segments_raw


def getSegmentsPath():
    return file_segments


def getTripsRawPath():
    return file_trips_raw


def getTripsTagsPath():
    return file_trips_tags


def getTripsODPath():
    return file_trips_od

def getTags():
    return pd.read_csv(file_tags, '\t')


def getTagsPolarity():
    return pd.read_csv(file_tags_polarity)


if __name__ == "__main__":
    main()
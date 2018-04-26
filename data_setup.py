"""
This script handles data access and creates the variables to be used in the scripts

Author: Diego Pajarito
"""

#Setup
import pandas as pd

file_trips = './data/Cyclist_Trip.csv'
file_trips_raw = './output/trips_raw.geojson'
file_location = './data/Cyclist_Location.csv'
file_measurement = './data/Cyclist_Measurement.csv'
file_tags = './data/Cyclist_Tag.csv'
file_tags_polarity = './data/Tags_polarity.csv'
trips = []
points = []


def main():
    print ("reading files ...")


def getTrips():
    return pd.read_csv(file_trips, '\t')


def getTripsRaw():
    return pd.read_json(file_trips_raw)


def getLocation():
    return pd.read_csv(file_location, '\t')


def getMeasurement():
    return pd.read_csv(file_measurement, '\t')


def getTags():
    return pd.read_csv(file_tags, '\t')


def getTagsPolarity():
    return pd.read_csv(file_tags_polarity, '\t')


if __name__ == "__main__":
    main()
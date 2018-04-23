"""
This script handles data access and creates the variables to be used in the scripts

Author: Diego Pajarito
"""

#Setup
import pandas as pd

file_trips = './data/Cyclist_Trip.csv'
file_location = './data/Cyclist_Location.csv'
file_measurement = './data/Cyclist_Measurement.csv'
trips = []
points = []


def main():
    print ("reading files ...")


def getTrips():
    return pd.read_csv(file_trips, '\t')


def getLocation():
    return pd.read_csv(file_location, '\t')


def getMeasurement():
    return pd.read_csv(file_measurement, '\t')


if __name__ == "__main__":
    main()
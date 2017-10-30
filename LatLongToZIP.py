import os
import numpy
import pandas
from math import radians, cos, sin, asin, sqrt


def haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians
    lat1 = lat1*numpy.pi/180
    lon1 = lon1*numpy.pi/180
    lat2 = lat2*numpy.pi/180
    lon2 = lon2*numpy.pi/180

    # haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = numpy.sin(dlat/2)**2 + numpy.cos(lat1) * numpy.cos(lat2) * numpy.sin(dlon/2)**2
    #c = 2 * numpy.arcsin(numpy.sqrt(a))
    c = 2 * numpy.arctan2(numpy.sqrt(a), numpy.sqrt(1-a))
    r = 3956  # Radius of earth in miles
    return c * r


def closestZIP(zip_latlong,point):
    dist = haversine(zip_latlong[:, 0], zip_latlong[:, 1], point[0], point[1])
    #dist = numpy.sqrt(numpy.sum((zip_latlong - point)**2, axis = 1))
    min_dist = numpy.argmin(dist)
    return dist[min_dist], min_dist

zip_dir = '/Users/gdevore21/Documents/Certificate Programs/Data Science/Deriving Knowledge from Data at Scale/Capstone Project/'
print('Loading zip codes...')
zip_array = numpy.loadtxt(os.path.join(zip_dir, 'zip_codes.csv'), delimiter=',', skiprows=1)
zip_codes = zip_array[:, 0]
zip_latlong = zip_array[:, 1::]
print('%i zip codes loaded' % len(zip_codes))

print('Loading taxi fare data...')
capstone_dir = '/Users/gdevore21/Documents/Certificate Programs/Data Science/Deriving Knowledge from Data at Scale/Capstone Project/'
taxi_fare = pandas.read_csv(os.path.join(capstone_dir,'NYC_Taxi_2013_One_Percent_Trip.csv'))
pickup_rows_to_swap = []
dropoff_rows_to_swap = []
pickup_zip = numpy.zeros((len(taxi_fare), 1))
pickup_dist = numpy.zeros((len(taxi_fare), 1))
dropoff_zip = numpy.zeros((len(taxi_fare), 1))
dropoff_dist = numpy.zeros((len(taxi_fare), 1))
for index, row in taxi_fare.iterrows():
    if index > 0 and index % 10000 == 0:
        print('Processed %d rows' % index)
    pickup_latlong = numpy.array([row['pickup_latitude'], row['pickup_longitude']])
    if pickup_latlong[0] < 0:
        pickup_latlong = numpy.flip(pickup_latlong, axis=0)
        pickup_rows_to_swap.append(index)
    dropoff_latlong = numpy.array([row['dropoff_latitude'], row['dropoff_longitude']])
    if dropoff_latlong[0] < 0:
        dropoff_latlong = numpy.flip(dropoff_latlong, axis=0)
        dropoff_rows_to_swap.append(index)
    [dist, pickup_ind] = closestZIP(zip_latlong, pickup_latlong)
    pickup_dist[index] = dist
    pickup_zip[index] = zip_codes[pickup_ind]
    [dist, dropoff_ind] = closestZIP(zip_latlong, dropoff_latlong)
    dropoff_dist[index] = dist
    dropoff_zip[index] = zip_codes[dropoff_ind]

fout = open(os.path.join(capstone_dir, 'trip_ZipCodeFeatures.csv'),'w')
fout.write('Pickup ZIP, Dropoff ZIP, Distance to Pickup ZIP, Distance to Dropoff ZIP\n')
for i in range(len(pickup_zip)):
    fout.write('%i,%i,%f,%f\n' % (pickup_zip[i], dropoff_zip[i], pickup_dist[i], dropoff_dist[i]))
fout.close()

fout = open(os.path.join(capstone_dir, 'pickup_rows_swap.csv'),'w')
fout.write('Row ID\n')
for i in range(len(pickup_rows_to_swap)):
    fout.write('%i\n' % (pickup_rows_to_swap[i] + 1))
fout.close()

fout = open(os.path.join(capstone_dir, 'dropoff_rows_swap.csv'),'w')
fout.write('Row ID\n')
for i in range(len(dropoff_rows_to_swap)):
    fout.write('%i\n' % (dropoff_rows_to_swap[i] + 1))
fout.close()
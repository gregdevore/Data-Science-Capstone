#read in files

trip <- read.csv('NYC_Taxi_2013_One_Percent_Trip.csv', header = TRUE, 
                      stringsAsFactors = FALSE)
fare <- read.csv('NYC_Taxi_2013_One_Percent_Fare.csv', header = TRUE, 
                      stringsAsFactors = FALSE)



#merge files(included vendor because didn't need to remove the dupe column later)
trip_and_fare <- merge(trip, fare, by=c("medallion","hack_license","pickup_datetime", "vendor_id"))



#remove duplicates of the join columns because they did exist after all
trip_and_fare <- trip_and_fare[!duplicated(trip_and_fare[, 1:3]), ] 


#flag bad values (not going to flag based on percentile...yet! but might)
trip_and_fare$badmoney <- ifelse(trip_and_fare$fare_amount < 0 | trip_and_fare$surcharge < 0 | trip_and_fare$mta_tax < 0 | trip_and_fare$tolls_amount < 0 | trip_and_fare$total_amount < 0, "Y", "N")

trip_and_fare$badtime <- ifelse(trip_and_fare$trip_time_in_sec < 15 | trip_and_fare$trip_time_in_secs > 10000, "Y", "N")

trip_and_fare$baddist <- ifelse(trip_and_fare$trip_distance < 0.1 | trip_and_fare$trip_distance > 300, "Y", "N")



#binarize tax and tolls column, might be useful for modeling
trip_and_fare$taxbinary <- ifelse(trip_and_fare$mta_tax > 0, "Y", "N")
trip_and_fare$tollsbinary <- ifelse(trip_and_fare$tolls_amount > 0, "Y", "N")



#get log values for distance and time, might be useful
trip_and_fare$logdistance <- log(trip_and_fare$trip_distance)
trip_and_fare$logtime <- log(trip_and_fare$trip_time_in_secs)

head(trip_and_fare,6)


#get cardinal directions for trip
trip_and_fare$angle <- atan2((trip_and_fare$dropoff_latitude-trip_and_fare$pickup_latitude),(trip_and_fare$dropoff_longitude-trip_and_fare$pickup_longitude))
trip_and_fare$angle <- ifelse(trip_and_fare$angle < 0,  2*pi+trip_and_fare$angle, trip_and_fare$angle)
trip_and_fare$direction<-
ifelse(trip_and_fare$angle <=1/16*pi | trip_and_fare$angle > 31/16*pi, 'E', 
ifelse(trip_and_fare$angle <=3/16*pi, 'ENE', 
ifelse(trip_and_fare$angle <=5/16*pi, 'NE', 
ifelse(trip_and_fare$angle <=7/16*pi, 'NNE', 
ifelse(trip_and_fare$angle <=9/16*pi, 'N', 
ifelse(trip_and_fare$angle <=11/16*pi, 'NNW', 
ifelse(trip_and_fare$angle <=13/16*pi, 'NW', 
ifelse(trip_and_fare$angle <=15/16*pi, 'WNW', 
ifelse(trip_and_fare$angle <=17/16*pi, 'W', 
ifelse(trip_and_fare$angle <=19/16*pi, 'WSW', 
ifelse(trip_and_fare$angle <=21/16*pi, 'SW', 
ifelse(trip_and_fare$angle <=23/16*pi, 'SSW', 
ifelse(trip_and_fare$angle <=25/16*pi, 'S', 
ifelse(trip_and_fare$angle <=27/16*pi, 'SSE', 
ifelse(trip_and_fare$angle <=29/16*pi, 'SE', 'ESE')))))))))))))))

#plot destinations by rate code
options(repr.plot.width=8, repr.plot.height=8)
ggplot(trip_and_fare, aes(dropoff_longitude, dropoff_latitude)) + geom_point() +
       xlab('lng') + ylab('lat') + 
facet_grid(rate_code ~ .) +
coord_cartesian(xlim = c(-75, -73),ylim = c(40, 42.5) ) +
    ggtitle('Dropoff by rate code')
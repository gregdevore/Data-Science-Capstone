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
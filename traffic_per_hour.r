library(data.table)

trip_and_fare$pickupseconds <- as.integer(as.POSIXct(trip_and_fare$pickup_datetime, format="%m/%d/%Y %I:%M:%S %p"))



setDT(trip_and_fare)[, traffic_in_hour := .SD[.(Pickup.ZIP = Pickup.ZIP, V1 = pickupseconds, V2 = pickupseconds - 3600), 
                             on = .(Pickup.ZIP, pickupseconds <= V1, pickupseconds >= V2), .N, by = .EACHI]$N][]

head(trip_and_fare[order(Pickup.ZIP, pickupseconds),c("Pickup.ZIP","pickup_datetime","pickupseconds","traffic_in_hour ")] , 30)
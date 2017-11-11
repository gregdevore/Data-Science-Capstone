# Greg DeVore
# Data Science at Scale
# Capstone Project Weather Feature
# November 10th, 2017

require(dplyr)

rm(list=ls()) # Clear Workspace
graphics.off() # Clear plots
cat("\014") # Clear Console

setwd('/Users/gdevore21/Documents/Certificate Programs/Data Science/Deriving Knowledge from Data at Scale/Capstone Project')
weather <- read.csv('JFK_weather_data.csv', stringsAsFactors = FALSE)
# Retain only relevant columns
weather_redux <- weather %>% select(STATION_NAME, DATE, HOURLYSKYCONDITIONS, 
                                    HOURLYVISIBILITY, HOURLYDRYBULBTEMPF, HOURLYWindSpeed, HOURLYPrecip)
# Change some to numeric
numeric_cols <- c('HOURLYVISIBILITY','HOURLYDRYBULBTEMPF','HOURLYWindSpeed','HOURLYPrecip')
weather_redux[, numeric_cols] <- sapply(weather_redux[, numeric_cols], as.numeric)

for (col in numeric_cols) {
  # Fill in missing data
  idx_missing <- which(is.na(weather_redux[, col]))
  idx_hasvalue <- which(!is.na(weather_redux[, col]))
  # Replace missing data with nearest non NA value (assuming weather data is continuous)
  idx_fill <- sapply(idx_missing, function(x) idx_hasvalue[which.min(abs(idx_hasvalue - x))])
  weather_redux[idx_missing, col] <- weather_redux[idx_fill, col]
}

# Process date and time data
weather_redux$date_string <- gsub(" .*$", "", weather_redux$DATE)
weather_redux$time_string <- gsub("^.* ", "", weather_redux$DATE)
date <- data.frame(matrix(unlist(strsplit(weather_redux$date_string,'-')), nrow = nrow(weather_redux), byrow = TRUE), stringsAsFactors = FALSE)
time <- data.frame(matrix(unlist(strsplit(weather_redux$time_string,':')), nrow = nrow(weather_redux), byrow = TRUE), stringsAsFactors = FALSE)
date[] <- lapply(date, function(x) as.numeric(x))
time[] <- lapply(time, function(x) as.numeric(x))
colnames(date) <- c('Year','Month','Day')
colnames(time) <- c('Hour','Minute')
weather_redux <- cbind(weather_redux,date,time)

# Find average precip for each hour
weather_summary <- weather_redux %>% group_by(Year,Month,Day,Hour) %>% summarise(Average_Precip = mean(HOURLYPrecip),
  Average_Vis = mean(HOURLYVISIBILITY), Average_Wind = mean(HOURLYWindSpeed), Average_Temp = mean(HOURLYDRYBULBTEMPF))
# Add weather summary features
weather_summary$Rain <- ifelse(weather_summary$Average_Precip > 0,'YES','NO')
temp_quant <- quantile(weather_summary$Average_Temp)
wind_quant <- quantile(weather_summary$Average_Wind)
# Move min to left to avoid NA's using cut function
temp_quant['0%'] <- -1
wind_quant['0%'] <- -1
weather_summary$Wind <- as.character(cut(weather_summary$Average_Wind, wind_quant, 
                            labels = c('Low','Medium','Medium-High','High')))
weather_summary$Temp <- as.character(cut(weather_summary$Average_Temp, temp_quant, 
                            labels = c('Cold','Chilly','Warm','Hot')))

# Load trip data to assign weather to each trip
date.time.features <- read.csv('trip_DateTimeFeatures.csv')
raining <- vector(length = nrow(date.time.features))
wind <- character(length = nrow(date.time.features))
temperature <- character(length = nrow(date.time.features))
for (row in seq(nrow(weather_summary))) {
  # Find all trips occuring at each hour
  idx <- which(date.time.features$pickUp_Month == weather_summary$Month[row] & 
                 date.time.features$pickUp_DayOfMonth == weather_summary$Day[row] &
                 date.time.features$pickUp_Hour == weather_summary$Hour[row])
  # Assign weather summary to those trips
  raining[idx] <- weather_summary$Rain[row]
  wind[idx] <- weather_summary$Wind[row]
  temperature[idx] <- weather_summary$Temp[row]
}
trip_weather <- data.frame(raining,wind,temperature)
write.csv(trip_weather,'JFK_Trip_Weather.csv')

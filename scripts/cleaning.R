library(data.table)
# List Files in Directory
files <- list.files(path = "data", full.names = T)
# Identify Indices containg daily or hourly as this is a processed version
# of the minutes data
files <- files[grep("(daily|hourly|Wide|Day)", files, invert = TRUE)]
# Extract Table Names from path
tablenames <- gsub("(.*/)(.*)(_.*)", r"(\2)", files)
# Read in all files
l <- lapply(files, fread, sep = ",", na.strings = c(""))

# Assign tables to variables in for-loop
for (row in 1:length(tablenames)) {
  assign(tablenames[row], l[[row]])
}
rm(tablenames, files, l, row)

library(lubridate)
# Convert DateTimes
heartrate_seconds[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(Time)
)][,Time := NULL]

minuteCaloriesNarrow[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(ActivityMinute)
)][,ActivityMinute := NULL]

minuteIntensitiesNarrow[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(ActivityMinute)
)][,ActivityMinute := NULL]

minuteMETsNarrow[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(ActivityMinute)
)][,ActivityMinute := NULL]

minuteSleep[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(date)
)][,date := NULL]

minuteStepsNarrow[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(ActivityMinute)
)][,ActivityMinute := NULL]

weightLogInfo[, `:=`(
  Id = factor(Id),
  DateTime = mdy_hms(Date)
)][,Date := NULL]

setkeyv(minuteCaloriesNarrow, c("Id", "DateTime"))
setkeyv(minuteIntensitiesNarrow, c("Id", "DateTime"))
setkeyv(minuteMETsNarrow, c("Id", "DateTime"))
setkeyv(minuteSleep, c("Id", "DateTime"))
setkeyv(minuteStepsNarrow, c("Id", "DateTime"))

activity <- minuteCaloriesNarrow[minuteIntensitiesNarrow][minuteMETsNarrow][minuteStepsNarrow]
activity[,`:=`(Date = date(DateTime),
               Time = hms::as_hms(DateTime),
               Day = wday(DateTime, label = TRUE),
               Hour = hour(DateTime))]

setnames(heartrate_seconds, "Value", "HeartRate")
heartrate_seconds[,`:=`(Date = date(DateTime),
               Time = hms::as_hms(DateTime),
               Day = wday(DateTime, label = TRUE))]

library(corrplot)
corrplot(cor(activity[,c("Calories", "Intensity", "METs", "Steps")]),
         method = 'number', order = 'AOE', type = 'upper')

#Lets Use METs as the measure of activity

minute <- activity[,lapply(.SD, mean),
         by = .(Time, Day),
         .SDcols = c("METs")]
daily <- activity[,lapply(.SD, mean),
                  by = .(Day),
                  .SDcols = c("METs")]

heart <- heartrate_seconds[,lapply(.SD, mean),
                           by = .(DateTime),
                           .SDcols = "HeartRate"]

library(ggplot2)
library(plotly)
ggplotly(minute %>%
  ggplot(aes(x= Time, y = METs, color = Day)) +
  geom_line())

ggplotly(heart %>%
           ggplot(aes(x= Time, y = HeartRate, colour = Day)) +
           geom_line(alpha = 0.5))


ggplotly(daily %>%
  ggplot(aes(x= Day, y = METs, fill = Day)) +
  geom_col())

            
library(MASS)
library(ISLR)

#to read the csv file to a dataframe.

cleandata <- read.csv("hubway_trips.csv")

#To remove 0 or lesser valued duration entries.

cleandata<-cleandata[(cleandata$duration>0),]



cleandata


write.csv(cleandata,"C:/Users/Shafee/Desktop/Hubway/Hubway_Trips_Clean.csv")

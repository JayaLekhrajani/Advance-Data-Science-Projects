library(MASS)
library(ISLR)
library(nnet)

seeds<- read.csv("hourly_filled_data.csv")
testdata<- read.csv("forecastInput.csv") 

meanKwh= mean(seeds$kWh)

# adding the column KWH_Class
seeds$KWH_Class <- seeds$kWh

val <- function (x){
  if(x > meanKwh) y <- "Above_Normal"
  if(x <= meanKwh) y <- "Optimal"
  return(y)
}

seeds$KWH_Class <- sapply(seeds$kWh,val)

summary(seeds)

seedstrain<- sample(1: nrow(cleandata),nrow(cleandata))
seedstest <- sample(1: nrow(testdata),nrow(testdata))
ideal <- class.ind(seeds$KWH_Class)

seedsANN = nnet(class.ind(KWH_Class)~Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, seeds[seedstrain,],size=10, softmax=TRUE, na.action = na.omit)

nn.predict = predict(seedsANN, seeds[seedstest,-12], type="class")


outputFrame<- testdata
outputFrame["kWH_Class"]<- NA
outputFrame["kWH_Class"]<- nn.predict

outputFrame[c("Date","Month","Day","Year","Hour","DayofWeek","Weekday","Peakhour","Temp","kWH_Class")]

write.csv(outputFrame, file = "/Users/rheakagti/Desktop/forcastNewdataOuput_ClassificationNeural.csv")






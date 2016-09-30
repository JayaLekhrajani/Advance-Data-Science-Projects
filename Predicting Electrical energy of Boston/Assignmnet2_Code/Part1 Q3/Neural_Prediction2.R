set.seed(500)
#import Data
data <-  read.csv("Hourly_filled_data.csv")
fdata <-  read.csv("forecastInput.csv")
apply(data,2,function(x) sum(is.na(x)))
apply(fdata,2,function(x) sum(is.na(x)))
#fit to Numeric data for neuralnet
data <- data[, sapply(data, is.numeric)]
fdata <- fdata[, sapply(fdata, is.numeric)]
head(fdata)
data <- subset(data , select = c(kWh,Month,Day,Hour,DayofWeek,Weekday,Peakhour,Temp))
maxs <- apply(data, 2, max) 
mins <- apply(data, 2, min)
#Scaling the data set
scaled <- as.data.frame(scale.default(data, center = mins, scale = maxs - mins))

library(neuralnet)
n <- names(scaled)
f <- as.formula(paste("kWh ~", paste(n[!n %in% "kWh"], collapse = " + ")))
nn <- neuralnet(f,scaled,hidden=c(5,2),threshold = 0.6, linear.output = FALSE)
#plot(nn)
#compute the Prediction
pr.nn <- compute(nn, fdata[,2:8])
print(pr.nn$net.result)
#rescale to get predicted values
pr.nn_ <- pr.nn$net.result*(max(data$kWh)-min(data$kWh))+min(data$kWh)
#insert in data frame
outputFrame<- fdata
outputFrame["kWh"]<- NA
outputFrame["kWh"]<- pr.nn_#predicted kWh

outputFrame[c("kWh","Month","Day","Hour","DayofWeek","Weekday","Peakhour","Temp")]
#write in CSV
write.csv(outputFrame, file = "/Users/Abhijeet/Documents/NeuralNetwork_ForcastOutput.csv")
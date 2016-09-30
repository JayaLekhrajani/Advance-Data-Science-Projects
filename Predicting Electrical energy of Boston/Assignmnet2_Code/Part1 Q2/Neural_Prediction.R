library(neuralnet)
set.seed(500)

#Import Data
data <-  read.csv("Hourly_filled_data.csv")
apply(data,2,function(x) sum(is.na(x)))

#to divide in two parts
smp_size <- floor(0.75 * nrow(data))
train_ind <- sample(seq_len(nrow(data)), size = smp_size)

#make dataset Numeric
data <- data[, sapply(data, is.numeric)]
data <- subset(data , select = c(Month,Day,kWh,Hour,DayofWeek,Weekday,Peakhour,Temp))
maxs <- apply(data, 2, max) 
mins <- apply(data, 2, min)

# scaling for neural network
scaled <- as.data.frame(scale.default(data, center = mins, scale = maxs - mins))
train_ <- scaled[train_ind,]
test_ <- scaled[-train_ind,]
n <- names(train_)

#Create Formula
f <- as.formula(paste("kWh ~", paste(n[!n %in% "kWh"], collapse = " + ")))
nn <- neuralnet(f,train_,hidden=c(5,2),threshold = 0.6, linear.output = FALSE)

#Plot Graph
plot(nn)
pr.nn <- compute(nn, test_[,2:8])
print(pr.nn$net.result)
pr.nn_ <- pr.nn$net.result*(max(data$kWh)-min(data$kWh))+min(data$kWh)
print(pr.nn$net.result)
test.r <- (test_$kWh)*(max(data$kWh)-min(data$kWh))+min(data$kWh)
MSE.nn <- sum((test.r - pr.nn_)^2)/nrow(test_)
print(paste(MSE.nn))

#RMSE 
RMSE.nn<-sqrt(MSE.nn)
print(paste(RMSE.nn))

# function to calculate the mean absolute error
MAE_NN <- function(actual, predicted) {
  mean(abs(actual - predicted))  
}

## MAE for our predictions
MAE=MAE_NN(test.r,  pr.nn_)

# Function that returns MAPE
MAPE_NN <- function(actual, predicted)
{
  mean(abs((actual - predicted)/actual))
}

## MAPE for our predictions
MAPE=MAPE_NN(test.r,  pr.nn_)
RMSEofNN <- c(RMSE.nn)
MSEofNN <- c(MSE.nn)
MAEofNN <- c(MAE)
MAPEofNN <- c(MAPE)
performanceMatrix <- data.frame(RMSEofNN,MSEofNN,MAEofNN,MAPEofNN)
performanceMatrix   
write.csv(performanceMatrix, file = "/Users/Abhijeet/Documents/performanceMatrix_PredictionNN.csv")

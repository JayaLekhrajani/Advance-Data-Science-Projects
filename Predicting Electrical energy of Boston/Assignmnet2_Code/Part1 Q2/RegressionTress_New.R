library(MASS)
library(ISLR)
library(tree)

set.seed(1)
cleandata<- read.csv("hourly_filled_data.csv")

train<- sample(1: nrow(cleandata),nrow(cleandata)/2)
tree.cleandata = tree(kWh~Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data= cleandata, subset= train)
summary(tree.cleandata)

plot(tree.cleandata)
text(tree.cleandata,pretty=0)

cv.cleandata= cv.tree(tree.cleandata)
plot(cv.cleandata$size, cv.cleandata$dev, type='b')

#pruning tree with 7 attributes
prune.cleandata= prune.tree(tree.cleandata, best=7)
plot(tree.cleandata)
text(tree.cleandata,pretty=0)

# predicting with tree, gives better values
yhat= predict(tree.cleandata, newdata = cleandata[-train,])
cleandata.test= cleandata[-train,"kWh"]
plot(yhat, cleandata.test)
abline(0,1)
#MSE value
MSE_tree=mean((yhat-cleandata.test)^2) 

# predicting with pruned tree
yhat= predict(prune.cleandata , newdata = cleandata[-train,])
cleandata.test= cleandata[-train,"kWh"]
plot(yhat, cleandata.test)
abline(0,1)
#MSE value for pruned tree
mean((yhat-cleandata.test)^2)

# function to calculate the mean absolute error
MAE_tree <- function(actual, predicted) {
  mean(abs(actual - predicted))  
}
## MAE for our predictions
MAE=MAE_tree(yhat,  cleandata.test)



# Function that returns MAPE
MAPE_tree <- function(actual, predicted)
{
  mean(abs((actual - predicted)/actual))
}
## MAPE for our predictions
MAPE=MAPE_tree(yhat,  cleandata.test)


MSEofTree <- c(MSE_tree)
MAEofTree <- c(MAE)
MAPEofTree <- c(MAPE)

performanceMatrix <- data.frame(MSEofTree,MAEofTree,MAPEofTree)
performanceMatrix


write.csv(performanceMatrix, file = "/Users/rheakagti/Desktop/performanceMatrix_PredictionTree.csv")




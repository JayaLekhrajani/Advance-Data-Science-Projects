library(MASS)
library(ISLR)
library(nnet)
library(NeuralNetTools)

seeds<- read.csv("hourly_filled_data.csv")
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

seedstrain<- sample(1: nrow(cleandata),5359)
seedstest <- setdiff(1:nrow(cleandata),seedstrain)
ideal <- class.ind(seeds$KWH_Class)

#seedsANN = nnet(seeds[seedstrain,-8], ideal[seedstrain,], size=10, softmax=TRUE)

seedsANN = nnet(class.ind(KWH_Class)~Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, seeds[seedstrain,],size=10, softmax=TRUE, na.action = na.omit)

predict(seedsANN, seeds[seedstrain,-12], type="class")


pMatrix=table(predict(seedsANN, seeds[seedstest,-12], type="class"),seeds[seedstest,]$KWH_Class)
pMatrix_neural<- data.frame(pMatrix)
#error= (143+242)/(635+1276)=20%

plotnet(seedsANN, alpha=0.6)

write.csv(pMatrix_neural, file = "/Users/rheakagti/Desktop/PerformanceMatrix_ClassificationNeural.csv")
table(predict(seedsANN, seeds[seedstest,-12], type="class"),seeds[seedstest,]$KWH_Class)

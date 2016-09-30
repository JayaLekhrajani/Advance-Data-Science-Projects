library(MASS)
library(ISLR)
library(tree)

set.seed(1)
cleandata<- read.csv("hourly_filled_data.csv")
testdata<- read.csv("forecastInput.csv")

train<- sample(1: nrow(cleandata),nrow(cleandata))
tree.cleandata = tree(kWh~Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data= cleandata, subset= train)
summary(tree.cleandata)

plot(tree.cleandata)
text(tree.cleandata,pretty=0)

# predicting with tree, gives better values
yhat= data.frame(predict(tree.cleandata, newdata = testdata))
#cleandata.test= cleandata[-train,"kWh"]
##abline(0,1)
#MSE value
#mean((yhat-cleandata.test)^2)

# generate predictions for the testing dataset
#p.rpart <-data.frame(predict(m.rpart, test)) 

#  distribution of predicted values 
#summary(p.rpart)

outputFrame<- testdata
outputFrame["kWh"]<- NA
outputFrame["kWh"]<- yhat #predicted kWh

outputFrame[c("Date","kWh","Month","Day","Year","Hour","DayofWeek","Weekday","Peakhour","Temp")]

write.csv(outputFrame, file = "/Users/rheakagti/Desktop/forcastNewdataOuput_Tree2.csv")







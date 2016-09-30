library(MASS)
library(ISLR)
library(tree)
library(forecast)

cleandata <- read.csv("hourly_filled_data.csv")


#finding mean of kWh
meanKwh= mean(cleandata$kWh)

#transform kWh variables

KWH_Class = ifelse(cleandata$kWh >meanKwh, "Above_Normal","Optimal")

cleandata = data.frame(cleandata,KWH_Class)
head(cleandata)

#using other variables except kWh to fit classification tree

tree = tree(KWH_Class~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, cleandata)
summary(tree)

#error rate 14.6%

#display tree structure
plot(tree)
text(tree,pretty = 0)



#test data
tdata <- read.csv("forecastInput.csv")
set.seed(2)
train =sample(1: nrow(cleandata), nrow(cleandata))


#building the tree based on the training set
tree.train= tree(as.factor(KWH_Class)~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month,cleandata, subset= train)

#prediction on test data
tree.pred = predict(tree.train, tdata, type="class")



# Determine optimal level
set.seed(3)
cv.cleandata= cv.tree(tree, FUN = prune.misclass)
names(cv.cleandata)
cv.cleandata


#prune tree
prune.cleandata = prune.misclass(tree, best= 12)
plot(prune.cleandata)
text(prune.cleandata, pretty=0)

#pruned tree performance
prune.pred= predict(prune.cleandata,tdata,type="class")

##pruned tree gives better output therefore prune.pred is used

#creating a new dataframe to create the final output csv file
outputFrame<-tdata 
outputFrame["KWH_Class"]<- NA
outputFrame["KWH_Class"]<- prune.pred

outputFrame[c("Date","Month","Day","Year","Hour","DayofWeek","Weekday","Peakhour","Temp","KWH_Class")]

write.csv(outputFrame, file = "/Users/rheakagti/Desktop/forcastOutput_ClassificationTree.csv")



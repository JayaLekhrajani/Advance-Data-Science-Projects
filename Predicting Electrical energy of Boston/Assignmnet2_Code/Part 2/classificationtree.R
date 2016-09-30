library(MASS)
library(ISLR)
library(tree)

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



#split dataset into train and test

set.seed(2)
train = sample(1: nrow(cleandata),200)
cleandata.test = cleandata [-train,]
KWH_Class.test = KWH_Class [-train]

#building the tree based on the training set
tree.train= tree(KWH_Class~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month,cleandata, subset= train)
#evaluating performance on test data
tree.pred = predict(tree.train, cleandata.test, type="class")
#tree.pred<- na.omit(tree.pred)
table(tree.pred, KWH_Class.test)


#error rate= (627+708)/(1862+4258)= 21%


# Determine optimal level
set.seed(3)
cv.cleandata= cv.tree(tree, FUN = prune.misclass)
names(cv.cleandata)
cv.cleandata
plot(cv.cleandata)
  
  
#prune tree
prune.cleandata = prune.misclass(tree, best= 12)
plot(prune.cleandata)
text(prune.cleandata, pretty=0)

#pruned tree performance
prune.pred= predict(prune.cleandata,cleandata.test,type="class")
pMatrix=table(prune.pred,KWH_Class.test)
pMatrix_tree<- data.frame(pMatrix)

#error rate= (718+367)/(1852+4518)=17.03 %

write.csv(pMatrix_neural, file = "/Users/rheakagti/Desktop/PerformanceMatrix_ClassificationTree.csv")

#therefore the pruned tree model needs to be used as the error rate is lower
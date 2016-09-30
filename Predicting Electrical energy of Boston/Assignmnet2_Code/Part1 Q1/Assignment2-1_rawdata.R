library(MASS)
library(ISLR)

cleandata <- read.csv("datacleanNewZero.csv")
cleandata
names(cleandata)
summary(cleandata)

#lm.fit= lm(kWh ~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data= cleandata)
#summary(lm.fit)

#75% of sample data
smp_size <- floor(0.75 * nrow(cleandata))

#set seed to make your partition reproductible
set.seed(123)
train_ind <- sample(seq_len(nrow(cleandata)), size = smp_size)

#split data into test and train
train <- cleandata[train_ind, ]
test <- cleandata[- train_ind, ]

#fit linear regression model
lm.fit= lm(kWh ~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data= cleandata)

#summary of fit
summary(lm.fit)

#measures of pedictive accuracy
library(forecast)
pred= predict(lm.fit,test)
accuracy(pred, train$kWh)

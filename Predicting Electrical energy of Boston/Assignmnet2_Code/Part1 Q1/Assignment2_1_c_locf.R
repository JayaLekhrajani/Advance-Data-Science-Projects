library(MASS)
library(ISLR)
library(dplyr)
library(zoo)

df<- read.csv("datacleanNewZero.csv")
#replacing 0 values of kWh with NA
df$kWh[df$kWh == 0]  <- NA

#using na.locf function
df=mutate(df,kWh=na.locf(df$kWh))

#75% of sample data
smp_size <- floor(0.75 * nrow(df))

#set seed to make your partition reproductible
set.seed(123)
train_ind <- sample(seq_len(nrow(df)), size = smp_size)

#split data into test and train
train <- df[train_ind, ]
test <- df[- train_ind, ]

#fit linear regression model
lm.fit= lm(kWh ~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data= df)

#summary of fit
summary(lm.fit)

#measures of pedictive accuracy

pred= predict(lm.fit,test)
accuracy(pred, train$kWh)

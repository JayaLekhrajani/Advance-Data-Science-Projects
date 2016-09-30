library(MASS)
library(ISLR)

cleandata <- read.csv("datacleanNewZero.csv")

names(cleandata)
summary(cleandata)

notemp <-cleandata
notemp$Temp <-NULL 

#dataframe with no temp & no Zero
notemp_nozero <- notemp
notemp_nozero<-notemp_nozero[(notemp_nozero$kWh!=0),]

#dataframe with no temp & only Zero
notemp_onlyzero <- notemp
notemp_onlyzero<-notemp_onlyzero[(notemp_onlyzero$kWh==0),]
notemp_onlyzero

#dataframe with temperature & no zero
tempnozero <-cleandata 
tempnozero<-tempnozero[(tempnozero$kWh!=0),]

#dataframe with temperature & only zero
temp_onlyzero <-cleandata 
temp_onlyzero<-temp_onlyzero[(temp_onlyzero$kWh==0),]



lm.fit= lm(kWh ~ Peakhour+Weekday+DayofWeek+Hour+Day+Month, data= notemp_nozero)
summary(lm.fit)


#split data into test and train
train <- notemp_nozero
test <- notemp_onlyzero


#measures of pedictive accuracy
library(forecast)
pred= data.frame(predict(lm.fit,test))
#accuracy(pred, train$kWh)

#replace kwh with predicted kWh
temp_onlyzero$kWh<- pred$predict.lm.fit..test.

#discarding rows with -ve kWh values
temp_onlyzero<-temp_onlyzero[(temp_onlyzero$kWh>=0),]

#merging the 2 dataframes
new<- rbind(tempnozero ,temp_onlyzero)

#sorting dataframe according to year and hour
new[order(new[,2], new[, 5]),]

#writing to csv 
#write.csv(new, file = "/Users/rheakagti/Desktop/Q2.csv")

##Regression for the new dataframe created by replacing 0 with predicted kWh values

#75% of sample data
smp_size <- floor(0.75 * nrow(new))

#set seed to make your partition reproductible
set.seed(123)
train_ind <- sample(seq_len(nrow(new)), size = smp_size)

#split data into test and train
train <- new[train_ind, ]
test <- new[- train_ind, ]

#fit linear regression model
lm.fit= lm(kWh ~ Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data= new)

#summary of fit
summary(lm.fit)

#measures of pedictive accuracy
library(forecast)
pred= predict(lm.fit,test)
accuracy(pred, train$kWh)



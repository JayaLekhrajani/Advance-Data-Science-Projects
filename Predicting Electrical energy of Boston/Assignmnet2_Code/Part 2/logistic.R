library(MASS)
library(ISLR)
library(caret)
library(ROCR)

cleandata <- read.csv("Hourly_filled_data.csv")
cleandata<-  na.omit(cleandata)

#finding mean of kWh
meanKwh= mean(cleandata$kWh)

# adding the column KWH_Class
cleandata$KWH_Class <- cleandata$kWh

val <- function (x){
  if(x > meanKwh) y <- "Above_Normal"
  if(x <= meanKwh) y <- "Optimal"
  return(y)
}

cleandata$KWH_Class <- sapply(cleandata$kWh,val)

summary(cleandata)

#adding dummy column
cleandata$nyClass[cleandata$KWH_Class=="Optimal"]<-1
cleandata$nyClass[cleandata$KWH_Class=="Above_Normal"]<-0

cleandata$nyClass<- factor(cleandata$nyClass,levels = c(0,1),labels = c("Optimal","Above_Normal"))
table(cleandata$nyClass)


#partitioning dataframe
smp_size<- floor(0.75* nrow(cleandata))
set.seed(123)
train_index<- sample(seq_len(nrow(cleandata)),size = smp_size)

#splitting data into test and train
train<- cleandata[train_index,]
test<- cleandata[- train_index,]




#construct logistic regression model for "Optimal" and "Above_Normal" values using other variables

fit1 <- glm(nyClass~Peakhour+Temp+Weekday+DayofWeek+Hour+Day+Month, data = train, family = binomial(link = "logit"))

summary(fit1)

coef(fit1)

#running model on test set
test.probs <- predict(fit1,test, type = 'response')
pred <- rep("Above_Normal", length(test.probs))

#set cutoff value= 0.5
pred[test.probs>=0.5]<- "Optimal"

#classification matrix
confusionMatrix(test$nyClass,pred)




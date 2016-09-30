library(MASS)
library(ISLR)
library(caret)
library(ROCR)
credit<- read.csv("/Users/rheakagti/Desktop/clean.csv") 

colnames(credit) <- c("Index","ID","Limit","Sex", "Education", "Marriage", "Age", "Pay_1","Pay_2","Pay_3","Pay_4","Pay_5","Pay_6","Bill_1","Bill_2","Bill_3","Bill_4","Bill_5","Bill_6","Paid_1","Paid_2","Paid_3","Paid_4","Paid_5","Paid_6","Default payment")


#creating new coulmn for the sum of total bill of 6 months
credit$Bill_1 <- as.numeric(credit$Bill_1)
credit$Bill_2 <- as.numeric(credit$Bill_2)
credit$Bill_3 <- as.numeric(credit$Bill_3)
credit$Bill_4 <- as.numeric(credit$Bill_4)
credit$Bill_5 <- as.numeric(credit$Bill_5)
credit$Bill_6 <- as.numeric(credit$Bill_6)
credit$TotalBill= credit$Bill_1+credit$Bill_2+credit$Bill_3+credit$Bill_4+credit$Bill_5+credit$Bill_6

#creating new coulmn for the sum of total bill paid of 6 months
credit$Paid_1<- as.numeric(credit$Paid_1)
credit$Paid_2<- as.numeric(credit$Paid_2)
credit$Paid_3<- as.numeric(credit$Paid_3)
credit$Paid_4<- as.numeric(credit$Paid_4)
credit$Paid_5<- as.numeric(credit$Paid_5)
credit$Paid_6<- as.numeric(credit$Paid_6)
credit$TotalPaid<- credit$Paid_1+credit$Paid_2+credit$Paid_3+credit$Paid_4+credit$Paid_5+credit$Paid_6

#count of non negative
credit$Pay_1<- as.numeric(as.character(credit$Pay_1))
credit$Pay_2<- as.numeric(as.character(credit$Pay_2))
credit$Pay_3<-as.numeric(as.character(credit$Pay_3))
credit$Pay_4<- as.numeric(as.character(credit$Pay_4))
credit$Pay_5<- as.numeric(as.character(credit$Pay_5))
credit$Pay_6<- as.numeric(as.character(credit$Pay_6))


credit$pay_fail1<-credit$Pay_1
credit$pay_fail2<-credit$Pay_2
credit$pay_fail3<-credit$Pay_3
credit$pay_fail4<-credit$Pay_4
credit$pay_fail5<-credit$Pay_5
credit$pay_fail6<-credit$Pay_6



credit$pay_fail1<-ifelse(credit$pay_fail1<=0,"paid","not paid")
credit$pay_fail2<-ifelse(credit$pay_fail2<=0,"paid","not paid")
credit$pay_fail3<-ifelse(credit$pay_fail3<=0,"paid","not paid")
credit$pay_fail4<-ifelse(credit$pay_fail4<=0,"paid","not paid")
credit$pay_fail5<-ifelse(credit$pay_fail5<=0,"paid","not paid")
credit$pay_fail6<-ifelse(credit$pay_fail6<=0,"paid","not paid")

#assumption for repayment status 1-> avg delays/not paid & 0-> avg on time/paid
credit$avg_status<-rowSums(credit == "paid")
credit$avg_status<-ifelse(credit$avg_status>3,0,1)

credit2<-data.frame(credit$Limit,credit$Sex,credit$Education,credit$Marriage,credit$Age,credit$Pay_1,credit$Pay_2,credit$Pay_3,credit$Pay_4,credit$Pay_5,credit$Pay_6,credit$Bill_1, credit$Bill_2, credit$Bill_3,credit$Bill_4,credit$Bill_5,credit$Bill_6,credit$Paid_1,credit$Paid_2,credit$Paid_3,credit$Paid_4,credit$Paid_5,credit$Paid_6,credit$TotalBill,credit$TotalPaid,credit$avg_status,credit$`Default payment`)
write.csv(credit2, file = "/Users/rheakagti/Desktop/test2.csv")

#logistic regression

credit2$ynDefault[credit$`Default payment`==1]<- 1
credit2$ynDefault[credit$`Default payment`==0]<- 0
credit2$ynDefault<- factor(credit2$ynDefault, levels = c(0,1), labels=c("No","Yes"))
table(credit2$ynDefault)

#construction of regression model
fit1<- glm(ynDefault ~ credit.Limit+credit.Sex+credit.Education+
             credit.Marriage+credit.Age+credit.avg_status+credit.TotalBill+credit.TotalPaid+
             credit.Pay_1+credit.Pay_2+credit.Pay_3+credit.Pay_4+credit.Pay_5+
             credit.Pay_6+credit.Bill_1+credit.Bill_2+credit.Bill_3+
             credit.Bill_4+credit.Bill_5+credit.Bill_6+credit.Paid_1+credit.Paid_2+credit.Paid_3+
             credit.Paid_4+credit.Paid_5+credit.Paid_6, data = credit2, family = binomial(link="logit"))
summary(fit1)


#partitioning dataframe
smp_size<- floor(0.75* nrow(credit2))
set.seed(123)
train_index<- sample(seq_len(nrow(credit2)),size = smp_size)

#splitting data into test and train
train<- credit2[train_index,]
test<- credit2[- train_index,]


#constructing regression model with significant factors
fit2<- glm(ynDefault ~ credit.Limit+credit.Sex+credit.Marriage+credit.Age
           +credit.avg_status+credit.TotalBill+credit.Pay_1+credit.Pay_3 
           +credit.Bill_1 +credit.Paid_1+credit.Paid_2
           +credit.TotalPaid, data = train, family = binomial(link="logit"))
summary(fit2)

coef(fit2)

#running model on test set
test.probs <- predict(fit2,test, type = 'response')

pred <- rep("No", length(test.probs))

#set cutoff value= 0.5
pred[test.probs>=0.5]<- "Yes"
as.character(test$ynDefault)

#classification matrix
confusionMatrix(test$ynDefault ,pred)
#accuracy: 0.8113
#Sensitivity: 0.8308
#Specificity:  0.6401 

#ROC Curve
prediction<- prediction(test.probs,test$ynDefault)
performance<- performance(prediction, measure = "tpr", x.measure = "fpr")
plot(performance, main="ROC Curve", xlab="1-Specificity", ylab="Sensitivity")

#Lift Chart
test$probs<- test.probs
test$prob<- sort(test$probs, decreasing = T)
lift<- lift(ynDefault ~ prob, data = test)
lift
xyplot(lift, plot="gain")










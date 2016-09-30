library(caret)
library(ROCR)
library(nnet)
library(NeuralNetTools)
credit<- read.csv("C:/Users/Abhijeet/Desktop/Midterm/MidtermSubmission/Question1/clean.csv") 

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
colnames(credit2) <- c("Limit","Sex", "Education", "Marriage", "Age","Pay_1","Pay_2","Pay_3","Pay_4","Pay_5","Pay_6","Bill_1","Bill_2","Bill_3","Bill_4","Bill_5","Bill_6","Paid_1","Paid_2","Paid_3","Paid_4","Paid_5","Paid_6","avg_status","TotalBill","TotalPaid","Default payment")

#write.csv(credit2, file = "/Users/rheakagti/Desktop/test2.csv")
####################
#neural network
#adding new classification column
credit2$defaultpayment_Class <-credit2$default_payment_next_month

default_payment_next_month= ifelse (credit$`Default payment`==1, "Default", "No Default")
credit2= data.frame(credit2, default_payment_next_month)
summary(credit2)

#Partitioning the dataset into training and test
index <- sample(1:nrow(credit2),500)
train <- credit2[index,]
test <- credit2[-index,]


#Building Neural network model
seedsANN = nnet(class.ind(default_payment_next_month)~Limit+Sex+
                  Education+Marriage+Age+avg_status+TotalBill+
                  TotalPaid+Pay_1+Pay_2+Pay_3+Pay_4+Pay_5+Pay_6+
                  Bill_1+Bill_2+Bill_3+Bill_4+Bill_5+Bill_6+
                  Paid_1+Paid_2+Paid_3+Paid_4+Paid_5
                +Paid_6,train,size=10, softmax=TRUE, na.action = na.omit)

#predicting default_payment_next_month on train
predict(seedsANN, train, type="class")

#predicting on test
test.probs<-predict(seedsANN, test, type="class")
#plotting neural network
plotnet(seedsANN, alpha=0.6)

#Confusion Matrix
table(test$default_payment_next_month,predict(seedsANN,newdata=test,type="class"))

#plotting ROC curve
library(ROCR)
seedsANN1 = nnet(default_payment_next_month~Limit+Sex+Education+Marriage+Age+avg_status+
                   TotalBill+TotalPaid+Pay_1+Pay_2+Pay_3+Pay_4+Pay_5+Pay_6+Bill_1+Bill_2
                 +Bill_3+Bill_4+Bill_5+Bill_6+Paid_1+Paid_2+Paid_3+Paid_4+Paid_5+Paid_6,train,size=10, na.action = na.omit)
pred = prediction(predict(seedsANN1,newdata=test,type="raw"),test$default_payment_next_month)
perf = performance(pred,"tpr","fpr")
plot(perf,lwd=2,col="blue",main="ROC - Neural Network on Default")
abline(a=0,b=1)

#lift curve
test$probs<-test.probs
test$prob<- sort(test$probs, decreasing = T)
lift<- lift(default_payment_next_month ~ prob, data = test)
lift
xyplot(lift, plot="gain")


library(caret)
library(ROCR)
library(tree)
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

#classification tree

High= ifelse (credit$`Default payment`==1, "Yes", "No")
credit2= data.frame(credit2, High)

tree = tree(High ~ Limit+Sex+Education+Marriage+Age+avg_status+TotalBill+TotalPaid+Pay_1+Pay_2+Pay_3+Pay_4+Pay_5+Pay_6+Bill_1+Bill_2+Bill_3+Bill_4+Bill_5+Bill_6+Paid_1+Paid_2+Paid_3+Paid_4+Paid_5+Paid_6 , credit2)
summary(tree)
#error rate-> 5412 / 30000 =  0.1804
#RMS-> 0.94


#display tree structure
plot(tree)
text(tree,pretty = 0)


#split dataset into train and test

set.seed(2)
train = sample(1: nrow(credit2),200)
credit2.test = credit2 [-train,]
High.test = High [-train]

#building the tree based on the training set
tree.train= tree(High ~ Limit+Sex+Education+Marriage+Age+avg_status+TotalBill+TotalPaid+Pay_1+Pay_2+Pay_3+Pay_4+Pay_5+Pay_6+Bill_1+Bill_2+Bill_3+Bill_4+Bill_5+Bill_6+Paid_1+Paid_2+Paid_3+Paid_4+Paid_5+Paid_6 , credit2, subset=train)

#evaluating performance on test data
tree.pred = predict(tree.train, credit2.test, type="class")
table(tree.pred, High.test)


#error rate= (3467+4902)/(18309+3122)= 0.3905091

# Determine optimal level
set.seed(3)
cv.credit2= cv.tree(tree, FUN = prune.misclass)
names(cv.credit2)
cv.credit2
plot(cv.credit2)

#prune tree
prune.credit2 = prune.misclass(tree, best= 3)
plot(prune.credit2 )
text(prune.credit2 , pretty=0)

#confusion matrix
prune.pred= predict(prune.credit2,credit2.test,type = "class")
table(High.test,prune.pred)
#error rate=(4360+1490)/(21721+2229)= 22%

#converting to vector for ROC curve
prune.pred1= predict(prune.credit2,credit2.test,type = "vector")


#ROC Curve

prediction<- prediction(prune.pred1[,2],High.test)
performance<- performance(prediction, measure = "tpr", x.measure = "fpr")
plot(performance, main="ROC Curve", xlab="1-Specificity", ylab="Sensitivity")

#Lift Chart
credit2.test$probs<-prune.pred1[,2]
credit2.test$prob1<- sort(credit2.test$probs, decreasing = T)
lift<- lift(High ~ prob1, data = credit2.test)
lift
xyplot(lift, plot="gain")




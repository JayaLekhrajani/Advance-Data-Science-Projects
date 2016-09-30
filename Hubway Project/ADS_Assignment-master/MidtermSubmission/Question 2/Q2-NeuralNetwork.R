
library(MASS)
library(ISLR)
library(nnet)
library(NeuralNetTools)

#reading the data and the headings file
data1 <- read.delim("ad.data", header = FALSE, sep = ",", stringsAsFactors = TRUE)
headers <- read.delim("headers_ad.txt", sep = ":", header = FALSE)

#removing the rows from the names dataframes which are comments and not feature names
headers <- headers[-c(1,2,7,465,961,1434,1546),]

colnames_ad <- as.character(headers$V1)

#adding column headings to the data
names(data1) <- colnames_ad

#replacing "?" with NA
data1[] <- lapply(data1, gsub, pattern = "?", replacement = NA, fixed = TRUE)

for(i in c(1:(ncol(data1)-1))) {
  data1[,i] <- as.numeric(data1[,i])
}

colnames(data1)[1559] <- "Dep_Var"
data1$Dep_Var<- as.factor(data1$Dep_Var)
#data1$Dep_Var <- as.factor(data1$Dep_Var)

nonNAs <- function(x) {
  as.vector(apply(x, 2, function(x) length(which(!is.na(x)))))
}

count_NAs <- cbind(colnames = names(data1), Count_NAs = nrow(data1) - nonNAs(data1) )

write.csv(data1, "internet_Ads.csv", row.names = FALSE)

data2 <- data1[,names(data1) %in% count_NAs[which(count_NAs[,2] >0),1]]

# install.packages("Hmisc")
library(Hmisc)

set.seed(1992)

#using argImpute
impute_arg <- aregImpute(~ height + width + aratio + local, data = data1, n.impute = 5, match = "closest", type = "regression")

impute_arg

# Imputing Height

height_imp <- data.frame(impute_arg$imputed$height)

height_imp$median <- apply(height_imp, 1, median)

height_NA_Recs <- which(is.na(data1$height))

data1$height[height_NA_Recs] <- height_imp$median

# Imputing Width

width_imp <- data.frame(impute_arg$imputed$width)

width_imp$median <- apply(width_imp, 1, median)

width_NA_Recs <- which(is.na(data1$width))

data1$width[width_NA_Recs] <- width_imp$median

# computing aratio

data1$aratio <- data1$width / data1$height

# Imputing local

local_imp <- data.frame(impute_arg$imputed$local)

local_imp$median <- round(apply(local_imp, 1, median),0)

local_NA_Recs <- which(is.na(data1$local))

data1$local[local_NA_Recs] <- local_imp$median

write.csv(data1, "ÏmputedFile.csv", row.names = F)

#####################Neural Network 

library(usdm)

library(caret)

# Consider changing the freqcut
nzvoutput <- nearZeroVar(data1, freqCut = 95/5, saveMetrics = TRUE)
valVars_names <- row.names(nzvoutput[nzvoutput$nzv == F,])

allvars <- names(data1)

selectVars <- allvars[which(names(data1) %in% valVars_names)]

data2 <- data1[, selectVars]



unique(data2$Dep_Var)

data2$Dep_Var1 <- ifelse(data2$Dep_Var == "ad.", 1, 0)
################################

summary(data2)

#Partitioning the dataset into training and test
index <- sample(1:nrow(data2),round(0.75*nrow(data2)))
train <- data2[index,]
test <- data2[-index,]
#Building the neural network
data2ANN = nnet(class.ind(train$Dep_Var1)~ . - Dep_Var,train,size=15, softmax=TRUE, na.action = na.omit)
trialann=nnet(Dep_Var1~ . - Dep_Var,data=train,size=11,maxit=10000,decay=.001)
predict(data2ANN, train, type="class")
plotnet(data2ANN , alpha=0.6)



#confusion matrix
table(predict(data2ANN,test, type="class"),test$Dep_Var1)


#ROCR
library(ROCR)
pred = prediction(predict(trialann,newdata=test,type="raw"),test$Dep_Var1)
perf = performance(pred,"tpr","fpr")
plot(perf,lwd=2,col="blue",main="ROC - Neural Network")
abline(a=0,b=1)

#lift curve
test$probs<-predict(data2ANN,test, type="class")
test$prob<- sort(test$probs, decreasing = T)
lift<- lift(Dep_Var ~ prob, data = test)
lift
xyplot(lift, plot="gain")







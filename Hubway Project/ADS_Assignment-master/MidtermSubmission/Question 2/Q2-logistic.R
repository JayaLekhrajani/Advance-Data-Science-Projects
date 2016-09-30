

#reading the data and the headings file
data1 <- read.delim("ad.data", header = FALSE, sep = ",", stringsAsFactors = TRUE)
headers <- read.delim("ad.names", sep = ":", header = FALSE)

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

write.csv(data1, "?mputedFile.csv", row.names = F)

##################### Logistic Regression Model

library(usdm)

library(caret)

# Selecting columns which have 95% and 5% ratio of most commonly values
nzvoutput <- nearZeroVar(data1, freqCut = 95/5, saveMetrics = TRUE)
valVars_names <- row.names(nzvoutput[nzvoutput$nzv == F,])

allvars <- names(data1)

selectVars <- allvars[which(names(data1) %in% valVars_names)]

data2 <- data1[, selectVars]

unique(data2$Dep_Var)

data2$Dep_Var1 <- ifelse(data2$Dep_Var == "ad.", 1, 0)

#logistic regression
mylogit <- glm(Dep_Var1 ~ ., data = data2[,-22], family=binomial(link="logit"), na.action=na.pass)

step(mylogit, direction = "both")

summary(mylogit)
#splitting data into test and train
smp_size<- floor(0.75* nrow(data2))
set.seed(123)
train_index<- sample(seq_len(nrow(data2)),size = smp_size)

#splitting data into test and train
train<- data2[train_index,]
test<- data2[- train_index,]

mylogit1 <- glm(Dep_Var1 ~ width + local +`url*images` + `origurl*index` + `origurl*geocities.com`  +
                  `origurl*index+html` + 
                  `ancurl*com` + `ancurl*bin`+ `alt*click`, 
                family = binomial(link = "logit"), data = train[, -22], na.action = na.pass)

summary(mylogit1)

pred_ad <- predict(mylogit1, newdata=test[, -23], type="response")

head(pred_ad)

#specifying if predicted value is greater than 0.3 then it is an ad
pred_ad1 <- ifelse(pred_ad<0.3, 0, 1)

head(pred_ad1)

#confusion matrix
confusionMatrix(table(test$Dep_Var1, pred_ad1, dnn=list('actual','predicted')))

# install.packages("ROCR")
library(ROCR)
pr = prediction(pred_ad1, test$Dep_Var1)

prf = performance(pr,"tpr","fpr")

performance(pr,"auc")

plot(performance, main="ROC Curve", xlab="1-Specificity", ylab="Sensitivity")



#Lift Chart
test$probs<- pred_ad
test$prob<- sort(test$probs, decreasing = T)
lift<- lift(Dep_Var1 ~ prob, data = test)
lift
xyplot(lift, plot="gain")


write.csv(data1, "FinalOutFile.csv", row.names = FALSE)

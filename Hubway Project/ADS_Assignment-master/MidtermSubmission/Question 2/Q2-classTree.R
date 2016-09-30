

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

#write.csv(data1, "internet_Ads.csv", row.names = FALSE)

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

#write.csv(data1, "ÏmputedFile.csv", row.names = F)

##################### classification tree

library(usdm)

library(caret)

data1$Dep_Var1 <- ifelse(data1$Dep_Var == "ad.", 1, 0)

#fitting classification tree

set.seed(1)
train <- sample(1:nrow(data1), 0.75 * nrow(data1))

library(rpart)
library(rpart.plot)

adTree <- rpart(Dep_Var1 ~ . - Dep_Var, data = data1[train, ], method = 'class')
plot(adTree)
text(adTree, pretty = 0)
printcp(adTree)
summary(adTree)

#Root Node error
class.pred <- table(predict(adTree, type="class"), data1[train, ]$Dep_Var1)
1-sum(diag(class.pred))/sum(class.pred)

#prediction
AdPrediction <- predict(adTree, data1[-train, ], type = 'vector')
AdPrediction

#confusion matrix
table(AdPrediction, data1[-train, ]$Dep_Var1)

library(arulesViz)
#ROC Curve
prediction<- prediction(AdPrediction, data1[-train, ]$Dep_Var1)
performance<- performance(prediction, measure = "tpr", x.measure = "fpr")
plot(performance, main="ROC Curve", xlab="1-Specificity", ylab="Sensitivity")



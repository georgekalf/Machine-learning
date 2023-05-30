#### --- Question 1 --- ####

# ---+ loading the libraries
library(caret)
library(dplyr)
library(tree)
library(randomForest)
library(gbm)
library(ggplot2)
library(pROC)

# ---+ loading the dataset
data(GermanCredit)
# ---+ classify two status: good or bad

# ---+ checking the values of our dataset
str(GermanCredit) # ---+ checking the response variable if it is a Factor or not

# ---+ data cleaning
# ---+ delete two variables where all values are the same for both classes
GermanCredit[, c("Purpose.Vacation", "Personal.Female.Single")] <- list(NULL)

### --- Decision Tree --- ###
# ---+ random split to train and test sets
set.seed(12)
trainIndex <- createDataPartition(GermanCredit$Class, p = 0.7, list = FALSE, times = 1)
train <- GermanCredit[trainIndex, ]
test <- GermanCredit[-trainIndex, ]
test.actual <- GermanCredit$Class[-trainIndex] # test labels

# ---+ train the decision tree
credit.tree <- tree(Class ~ ., train)

# ---+ looking at the details of the tree
credit.tree

# ---+ plotting the tree
plot(credit.tree)
text(credit.tree, pretty = 1)
summary(credit.tree)

# ---+ predict the test instances before pruning
pred.dt <- predict(credit.tree, test, type = "class")
mean(pred.dt == test.actual)
print(error_rate_dt <- 1 - mean(pred.dt == test.actual))

### --- Pruning the decision Tree --- ###
set.seed(102)
credit.cv <- cv.tree(credit.tree, FUN = prune.misclass, K = 5)

# ---+ plotting CV results
par(mfrow = c(1, 1))
plot(credit.cv$size, credit.cv$dev, type = "b",
     xlab = "Number of leaves of the tree", ylab = "CV error rate %",
     cex.lab = 1.5, cex.axis = 1.5)

# ---+ pruning the tree
credit.prune <- prune.misclass(credit.tree, best = 8)
plot(credit.prune)
text(credit.prune, pretty = 1)
summary(credit.prune)

# ---+ predict the test instances after pruning
pred.dt.pruned <- predict(credit.prune, test, type = "class")
mean(pred.dt.pruned == test.actual)
print(error_rate_dt_pruned <- 1 - mean(pred.dt.pruned == test.actual))

### --- Caret for random forest --- ###

fitControl <- trainControl(method = "repeatedcv",
                         number = 5, # 5-fold cross-validation
                         repeats = 1)
set.seed(2)
rfFit <- train(Class ~ ., data = train, method = "rf",
            metric = "Accuracy",
            trControl = fitControl,
            tuneLength = 5,
            ntree = 1000)

rfFit
plot(rfFit)
rfFit$finalModel

# ---+ plot the Variable Importance

variable_imp <- varImp(rfFit, scale = TRUE)
plot(variable_imp, top = 15)

# ---+ predict the test instances
pred.rf <- predict(rfFit, test)
mean(pred.rf == test.actual)
print(error_rate_rf <- 1 - mean(pred.rf == test.actual))

# ---+ predicting probalities for random & decision tree
pred_dt_prob <- predict(credit.prune, test, type = "vector")[, 2] # predict probabilties for test instances after pruning
mean(as.numeric(pred.dt.pruned) > 0.5) == as.numeric(test.actual) # calculating accuravcy based on probability cutoff of 0.5

pred_rf_prob <- predict(rfFit, test, type = "prob")[, 2]
mean(as.numeric(pred_rf_prob) > 0.5) == as.numeric(test.actual)

# ---+ creating the roc curves

dev.off() # ---+ cleaning previous plots

roc_dt <- plot(roc(as.numeric(test.actual),
                   pred_dt_prob),
                   print.auc = TRUE,
                   col = "green", print.auc.y = .4)

roc_rf <- plot(roc(as.numeric(test.actual),
                   pred_rf_prob),
                   print.auc = TRUE,
                   col = "blue", print.auc.y = .4)

# ---+ plotting ROC plot

gl <- ggroc(list("AUC for Decision Tree" = roc_dt,
           "AUC for Random forest" = roc_rf),
          legacy.axes = TRUE)

gl + xlab("False Positive Rate (1 - Specificity)") +
  ylab("True Positive Rate (Sensitivity)") +
  annotate("text", x = 0.38, y = 0.85, label = "AUC for Random Forest: 0.7781") +
  annotate("text", x = 0.75, y = 0.84, label = "AUC for Decision Tree: 0.6851") +
  geom_segment(aes(x = 0, xend = 1, y = 0, yend = 1),
  color = "darkgrey", linetype = "dashed")

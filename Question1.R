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
str(GermanCredit) # ---+ the response variable is already a Factor

# ---+ data cleaning
# ---+ delete two variables where all values are the same for both classes
GermanCredit[, c("Purpose.Vacation","Personal.Female.Single")] <- list(NULL)

### --- Decision Tree --- ### 
# ---+ random split to train and test sets
set.seed(12)
trainIndex = createDataPartition(GermanCredit$Class, p = 0.7, list = FALSE, times = 1)
train = GermanCredit[trainIndex,]
test = GermanCredit[-trainIndex,]
test.actual = GermanCredit$Class[-trainIndex] # test labels

# ---+ train the decision tree
credit.tree = tree(Class ~ . , train)
summary(credit.tree)

# ---+ looking at the details of the tree
credit.tree

# ---+ plotting the tree
plot(credit.tree)
text(credit.tree, pretty = 1)
summary(credit.tree)

# ---+ predict the test instances before pruning
pred.dt = predict(credit.tree, test, type = "class")
mean(pred.dt == test.actual)
error_rate_dt = 1 - mean(pred.dt == test.actual)
error_rate_dt

### --- Pruning the decision Tree --- ###
set.seed(102)
credit.cv = cv.tree(credit.tree, FUN = prune.misclass, K = 5)
credit.cv

# ---+ plotting CV results
par(mfrow = c(1,1))
plot(credit.cv$size, credit.cv$dev, type = "b",
     xlab = "Number of leaves of the tree", ylab = "CV error rate %",
     cex.lab = 1.5, cex.axis = 1.5)

# ---+ pruning the tree
credit.prune = prune.misclass(credit.tree, best = 8)
plot(credit.prune)
text(credit.prune, pretty = 1)
summary(credit.prune)

# ---+ predict the test instances after pruning
pred.dt.pruned = predict(credit.prune, test, type = "class")
mean(pred.dt.pruned == test.actual)
error_rate_dt_pruned = 1 - mean(pred.dt.pruned == test.actual)
error_rate_dt_pruned

### --- Caret for random forest --- ###

fitControl = trainControl(method = "cv", 
                         number = 5)
set.seed(2) 
rfFit = train(Class ~ ., data = train, method = "rf",
            metric = "Accuracy",
            trControl = fitControl,
            tuneLength = 5, 
            ntree = 1000)

rfFit
plot(rfFit)
rfFit$finalModel
variable_Imp = varImp(rfFit, scale = TRUE)

# ---+ plot the variable importance

plot(variable_Imp, top = 15)

# ---+ predict the test instances
pred.rf = predict(rfFit, test)
mean(pred.rf == test.actual)
error_rate_rf = 1 - mean(pred.rf == test.actual)
error_rate_rf

# ---+ creating the roc curves 

roc_dt = plot(roc(as.numeric(test.actual), as.numeric(pred.dt.pruned)), print.auc = TRUE, 
                 col = "green", print.auc.y = .4, add = TRUE)


roc_rf = plot(roc(as.numeric(test.actual), as.numeric(pred.rf)), print.auc = TRUE, 
               col = "blue", print.auc.y = .4, add = TRUE)


# ---+ plotting ROC plot

gl = ggroc(list("AUC for Decision Tree" = roc_dt, 
           "AUC for Random forest" = roc_rf), 
          legacy.axes = TRUE)

gl + xlab("False Positive Rate (1 - Specificity)") + ylab("True Positive Rate (Sensitivity)") + 
  annotate("text", x = 0.48, y = 0.85, label = "AUC for RF: 0.6389") +
  annotate("text", x = 0.75, y = 0.84, label = "AUC for DT: 0.6024") + 
  geom_segment(aes(x = 0, xend = 1, y = 0, yend = 1), color="darkgrey", linetype="dashed")


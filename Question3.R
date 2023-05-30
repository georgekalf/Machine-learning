### --- Question 3 --- ###

# ---+ loading the dataset
data <- read.table("newthyroid.txt", header = TRUE, sep = ",")

# ---+ check missing values
sum(is.na(data))

# ---+ loading libraries
library(class)
library(MASS)
library(caret)
library(dplyr)
library(gbm)
library(ggplot2)
library(pROC)

# ---+ creating empty lists for our accuracies, setting different seed and the tuneGrid
auc_knn <- c()
auc_lda <- c()
accuracy_knn <- c()
accuracy_lda <- c()
gridlevel <- expand.grid(k = c(3, 5, 7, 9, 11, 13, 15))
seeds <- c(123, 238, 349, 473, 569, 621, 783, 842, 947, 989)


for (i in seeds){

  # ---+ kNN use
  # ---+ create training and test sets

  set.seed(i)
  trainIndex <- createDataPartition(data$class, p = 0.7, list = FALSE, times = 1)
  train.feature <- data[trainIndex, ] # training features
  train.feature$class <- NULL
  train.label <- data$class[trainIndex] # training labels
  test.feature <- data[-trainIndex, -1] # test features
  test.label <- data$class[-trainIndex] # test labels

  # ---+ set up train control

  fitControl <- trainControl(
    method = "cv",
    number = 5, # use 5-fold cross-validation
    summaryFunction = twoClassSummary,
    classProbs = TRUE)

  # ---+ training process
  # evaluate k = 3, 5, 7, 9, 11, 13, 15 on the training data

  knnFit <- train(train.feature, train.label, method = "knn",
                 trControl = fitControl,
                 metric = "ROC",
                 tuneGrid = gridlevel)

  # ---+ prediction for kNN

  pred_knn <- predict(knnFit, test.feature)
  acc_knn <- mean(pred_knn == test.label)
  accuracy_knn <- c(accuracy_knn, acc_knn)
  roc.knn <- roc(as.factor(test.label), as.numeric(pred_knn))
  auc_knn <- c(auc_knn, as.numeric(roc.knn$auc))

  ### --- LDA use --- ####

  # ---+ set up train control
  # ---+ fitting the LDA model
  ldaFit <- train(train.feature, train.label, method = "lda", # adding the method with which we want to split and train the sets
                 trControl = trainControl(method = "none"))

  # ---+ prediction for LDA
   pred_lda <- predict(ldaFit, test.feature)
   acc_lda <- mean(pred_lda == test.label)
   accuracy_lda <- c(accuracy_lda, acc_lda)
   roc.lda <- roc(as.factor(test.label), as.numeric(pred_lda))
   auc_lda <- c(auc_lda, as.numeric(roc.lda$auc))
}

# ---+ printing the different values of AUC
print(auc_lda)
print(auc_knn)

# ---+ printing the different values of accuracy
print(accuracy_knn)
print(accuracy_lda)

# ---+ printing the average accuracy for the kNN and LDA methods
mean(accuracy_knn)
mean(accuracy_lda)

# ---+ printing the average of the AUC for the kNN and LDA methods
mean(auc_knn)
mean(auc_lda)

# ---+ creating the dataframe for our AUC scores
boxplot_df <- data.frame(cbind(auc_lda, auc_knn))

# ---+ plotting the AUC boxplots
ggplot(stack(boxplot_df), aes(x = ind, y = values)) +
  geom_boxplot(fill = "lightblue", outlier.color = "red")
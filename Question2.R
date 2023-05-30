#### --- Question 2 --- ####

# ---+ loading libraries
library(e1071)
library(caret)
library(dplyr)
library(glue)
library(ggplot2)

# ---+ simulating the data

# ---+ creating the 2 columns (features) for the dataset
feature1 <- c(rnorm(75, 0, 1), rnorm(75, 3, 1))
feature2 <- rnorm(150)

# ---+ creating the 3 classes for the dataset (and making sure the response variable is a factor)
class <- factor(rep(1:3, each = 50))

# ---+ creating a dataframe with 150 observations and 2 features (+our response variable)
simulated_data <- data.frame(feature1, feature2, class)

# ---+ transforming into factor the response variable
simulated_data$class <- factor(simulated_data$class)

# ---+ plotting the data (classes by color)
ggplot(data = simulated_data, aes(feature1, feature2,color = class)) +
  geom_point() + ggtitle("Scatterplot of 3 non-linearly separable classes") +
  scale_color_manual(values = c("1" = "red", "2" = "blue", "3" = "green"))


### --- Use of SVM --- ###

### --- Using 3 different SVM methods for our dataset --- ###
# ---+ training-test split sets
set.seed(12)
trainIndex <- createDataPartition(simulated_data$class, p = 0.5, list = FALSE, times = 1)
train <- simulated_data[trainIndex,] # training set
test <- simulated_data[-trainIndex, -3] # test set
test.actual <- simulated_data$class[-trainIndex] # test labels

# ---+ train the model for SVM Linear
svmLinear <- tune.svm(class ~ .,data = train, kernel='linear', 
                         tunecontrol = tune.control(cross = 5), 
                         cost = seq(0.1,1, by = 0.1))
svmLinear
plot(svmLinear)

# ---+ predict the test instances for linear kernel
svmLinear$best.model
pred_linear <- predict(svmLinear$best.model, test)
confusion_matrix_linear <- table(pred_linear, test.actual) # ---+ confusion matrix
confusion_matrix_linear

# ---+ accuracy and classification error for linear kernel
acc.linear <- sum(diag(confusion_matrix_linear))/sum(confusion_matrix_linear)
classification_error_linear <- 1 - acc.linear
print(paste("Svm with linear kernel, accuracy is:", round(acc.linear, 1)))
print(paste("Svm with linear kernel, classification error is:",
            round(classification_error_linear, 1)))


# ---+ train the model for SVM Polynomial
set.seed(342)
svmPoly <- tune.svm(class ~.,data = train, kernel = 'poly',
                          tunecontrol = tune.control(cross = 5),
                          cost = seq(0.1, 1, by = 0.1),
                          sigma = c(0.01, 0.1, 1, 10))
svmPoly
plot(svmPoly)

# ---+ predict the test instances for polynomial kernel
svmPoly$best.model
pred_poly <- predict(svmPoly$best.model, test)
confusion_matrix_poly <- table(pred_poly, test.actual) # ---+ confusion matrix
confusion_matrix_poly

# ---+ accuracy and classification error for polynomial kernel
acc.poly <- sum(diag(confusion_matrix_poly))/sum(confusion_matrix_poly)
classification_error_poly = 1 - acc.poly
print(paste("Svm with polynomial kernel, accuracy is:", round(acc.poly, 1)))
print(paste("Svm with polynomial kernel, classification error is:",
            round(classification_error_poly, 1)))

# ---+ train the model for SVM RBF kernel
set.seed(342)
svmRadial <- tune.svm(class ~., data = train, kernel = 'radial', 
                       tunecontrol = tune.control(cross = 5), 
                       cost = seq(0.1, 1, by = 0.1), sigma = c(0.01, 0.1, 1, 10))
svmRadial
plot(svmRadial)

# ---+ predict the test instances for radial kernel
svmRadial$best.model
pred_radial <- predict(svmRadial$best.model, test)
confusion_matrix_radial <- table(pred_radial, test.actual) # ---+ confusion matrix
confusion_matrix_radial

# ---+ accuracy and classification error for radial kernel
acc.radial <- sum(diag(confusion_matrix_radial))/sum(confusion_matrix_radial)
classification_error_radial <- 1 - acc.radial
print(paste("Svm with radial kernel, accuracy is:", round(acc.radial, 1)))
print(paste("Svm with radial kernel, classification error is:",
            round(classification_error_radial, 1)))
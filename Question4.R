### --- Question 4 --- ###

# ---+ loading the libraries 
library(dplyr)
library(gbm)
library(caret)

# ---+ loading the dataset
data("GermanCredit")

# ---+ creating the function
cross_val_function <- function(label_vector, K, seeds){

# ---+ use of unique function for our label
freq.table = data.frame(table(label_vector))

# ---+ setting seed
set.seed(102)

# ---+ creating empty lists for the for loops
fold.list = c()
index.list = c()

for (i in unique(label_vector)) {
  
  # ---+ filter label_vector by label
  label.index = which(label_vector == i)
  
  # ---+ getting the size of the different labels 
  label.size = freq.table$Freq[freq.table$label_vector == i]
  
  fold.size = floor(label.size / K )  # ---+ size of each fold in every iteration
  
  # ---+ calculating the difference in the sizes of the labels based on the k-folds
  diff = label.size - (fold.size * K)
  
  # ---+ for loop to sample the index of the label.index(response variable)
  for (k in 1:K) {
    
    # ---+ sample from label vector with n = fold.size
    sample.index = sample(label.index, fold.size)
    
    # ---+ appending sample.index into index.list
    index.list = append(index.list, sample.index)
    
    # ---+ appending rep(k, length(sample.index)) into fold.list
    fold.list = append(fold.list, rep(k, length(sample.index)))
    
    # ---+ use setdiff() to update label.index
    label.index = setdiff(label.index, sample.index)
    
  }
  
  # ---+ for loop to sample the difference
  if (diff > 0) {
    for (j in 1:diff){
      
      # sampling label.index and distribute it equally
      sample.index = label.index[j]
      
      # ---+ appending the diff in index.list
      index.list = append(index.list, sample.index)
      fold.list = append(fold.list, j)
    }
  }
}

# ---+ creating dataframe with the fold list and the indexes
final.df = cbind(fold.list, index.list)

# ---+ for loop to create a dataframe with the folds and the indexes
for (i in 1:K){
  
  temp = final.df[fold.list == i, "index.list"]
  
  if (i == 1){
    df = data.frame(temp)
    df.size = length(temp)
  }
  else{
    if (length(temp) != df.size){
      temp = append(temp, rep(NaN, (df.size - length(temp))))
    }
    df_temp = data.frame(temp)
    df = cbind(df, df_temp) 
  }
}


# ---+ renaming the columns
colnames(df) = seq(1:K)

# ---+ creating the training indexes for each iteration 
for (i in 1:K) {
  if (i == 1) {
    results_df = data.frame(stack(df[-i])['values'])
  } else {
    temp_2 = data.frame(stack(df[-i])['values'])
    results_df = cbind(results_df, temp_2)
  }
}

colnames(results_df) = seq(1:K)

# ---+ returning the final dataframe
return(results_df)
}


### --- testing the function --- ### 
cross_val_function(GermanCredit$Class, K = ..., seeds = ...)

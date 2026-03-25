## One-time data setup script
library(dplyr)
set.seed(327)

sba <- read.csv("sba_loans_50k.csv")

sba_clean <- sba %>% na.omit()

print(paste("Number of rows removed:", nrow(sba) - nrow(sba_clean)))

n <- nrow(sba_clean)*0.8

idx <- sample(1:nrow(sba_clean), n)

sba_train <- sba_clean[idx,]
sba_test <- sba_clean[-idx,]

write.csv(sba_train, "sba_train.csv", row.names = FALSE)
write.csv(sba_test, "sba_test.csv", row.names = FALSE)

## Evaluation function — called from train.R, do not modify
evaluate <- function(preds, y_test) {
  library(caret)
  library(pROC)

  preds_class <- ifelse(preds >= 0.5, 1, 0)
  conf_mat <- confusionMatrix(factor(preds_class), factor(y_test), positive = "1")

  accuracy <- conf_mat$overall["Accuracy"]
  nir <- max(table(y_test)) / length(y_test)
  auc_val <- as.numeric(auc(roc(y_test, preds, quiet = TRUE)))

  cat(sprintf("Accuracy: %.4f\n", accuracy))
  cat(sprintf("No Information Rate: %.4f\n", nir))
  cat(sprintf("AUC: %.4f\n", auc_val))

  log_file <- "log.tsv"
  if (!file.exists(log_file)) {
    cat("timestamp\taccuracy\tnir\tauc\n", file = log_file)
  }
  cat(sprintf("%s\t%.4f\t%.4f\t%.4f\n", Sys.time(), accuracy, nir, auc_val),
      file = log_file, append = TRUE)
}
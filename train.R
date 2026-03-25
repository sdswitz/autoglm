library(data.table)
library(dplyr)
library(caret)
library(pROC)

sba_train <- read.csv("sba_train.csv")
sba_test <- read.csv("sba_test.csv")

# The baseline model I used in my miderm submission
mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + RevLineCr + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              NAICS_sector + State,
            data = sba_train, family = "binomial")
# summary(mod1)

# Predictions
preds_test <- predict(mod1, newdata = sba_test, type = "response")
preds_test_class <- ifelse(preds_test >= 0.5, 1, 0)
y_test <- sba_test$PaidInFull

# Metrics
conf_mat <- confusionMatrix(factor(preds_test_class),
                            factor(y_test),
                            positive = "1")

accuracy <- conf_mat$overall["Accuracy"]
nir <- max(table(y_test)) / length(y_test)

roc_mod1 <- roc(y_test, preds_test, quiet = TRUE)
auc_val <- as.numeric(auc(roc_mod1))

cat(sprintf("Accuracy: %.4f\n", accuracy))
cat(sprintf("No Information Rate: %.4f\n", nir))
cat(sprintf("AUC: %.4f\n", auc_val))

# Append to log
log_file <- "log.tsv"
if (!file.exists(log_file)) {
  cat("timestamp\taccuracy\tnir\tauc\n", file = log_file)
}
cat(sprintf("%s\t%.4f\t%.4f\t%.4f\n", Sys.time(), accuracy, nir, auc_val),
    file = log_file, append = TRUE)
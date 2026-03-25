library(data.table)
library(dplyr)
source("prepare.R")

sba_train <- read.csv("sba_train.csv")
sba_test <- read.csv("sba_test.csv")

# The baseline model I used in my miderm submission
sba_train$ApprovalFY <- as.factor(sba_train$ApprovalFY)
sba_test$ApprovalFY <- as.factor(sba_test$ApprovalFY)

mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + RevLineCr + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              NAICS_sector + State + ApprovalFY + Term:SBA_Portion,
            data = sba_train, family = "binomial")
# summary(mod1)

# Predictions and evaluation (do not modify evaluate function — it lives in prepare.R)
preds_test <- predict(mod1, newdata = sba_test, type = "response")
evaluate(preds_test, sba_test$PaidInFull)
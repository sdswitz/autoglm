library(data.table)
library(dplyr)
source("prepare.R")

sba_train <- read.csv("sba_train.csv")
sba_test <- read.csv("sba_test.csv")

# The baseline model I used in my miderm submission
# Feature engineering
sba_train$GFC <- as.integer(sba_train$ApprovalFY >= 2007 & sba_train$ApprovalFY <= 2009)
sba_test$GFC <- as.integer(sba_test$ApprovalFY >= 2007 & sba_test$ApprovalFY <= 2009)

sba_train$TotalJobs <- sba_train$CreateJob + sba_train$RetainedJob
sba_test$TotalJobs <- sba_test$CreateJob + sba_test$RetainedJob

mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + RevLineCr + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              NAICS_sector + State + GFC + Term:SBA_Portion +
              TotalJobs + log(GrAppv_num + 1),
            data = sba_train, family = "binomial")
# summary(mod1)

# Predictions and evaluation (do not modify evaluate function — it lives in prepare.R)
preds_test <- predict(mod1, newdata = sba_test, type = "response")
evaluate(preds_test, sba_test$PaidInFull)
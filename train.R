library(data.table)
library(dplyr)
source("prepare.R")

sba_train <- read.csv("sba_train.csv")
sba_test <- read.csv("sba_test.csv")

# The baseline model I used in my miderm submission
# Feature engineering
sba_train$ApprovalFY <- as.numeric(as.character(sba_train$ApprovalFY))
sba_test$ApprovalFY <- as.numeric(as.character(sba_test$ApprovalFY))
sba_train$GFC <- as.integer(sba_train$ApprovalFY >= 2007 & sba_train$ApprovalFY <= 2009)
sba_test$GFC <- as.integer(sba_test$ApprovalFY >= 2007 & sba_test$ApprovalFY <= 2009)
sba_train$Recession <- as.integer(sba_train$ApprovalFY %in% c(2001, 2002, 2007, 2008, 2009))
sba_test$Recession <- as.integer(sba_test$ApprovalFY %in% c(2001, 2002, 2007, 2008, 2009))

sba_train$TotalJobs <- sba_train$CreateJob + sba_train$RetainedJob
sba_test$TotalJobs <- sba_test$CreateJob + sba_test$RetainedJob

# Additional features
sba_train$RealEstate <- as.integer(sba_train$NAICS_sector %in% c("53"))
sba_test$RealEstate <- as.integer(sba_test$NAICS_sector %in% c("53"))
sba_train$LongTerm <- as.integer(sba_train$Term > 240)
sba_test$LongTerm <- as.integer(sba_test$Term > 240)

mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + RevLineCr + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              NAICS_sector + State + Recession + ApprovalFY + Term:SBA_Portion +
              TotalJobs + log(GrAppv_num + 1) +
              log(DisbursementGross_num):SBA_Portion +
              GFC:Term + BankState + RealEstate:GFC + LongTerm +
              NewExist_f:GFC + LowDoc:GFC + RevLineCr:Term +
              log(SBA_Appv_num + 1) + LongTerm:GFC + UrbanRural_f:GFC,
            data = sba_train, family = "binomial")
# summary(mod1)

# Predictions and evaluation (do not modify evaluate function — it lives in prepare.R)
preds_test <- predict(mod1, newdata = sba_test, type = "response")
evaluate(preds_test, sba_test$PaidInFull)
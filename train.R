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
sba_train$PostGFC <- as.integer(sba_train$ApprovalFY >= 2010)
sba_test$PostGFC <- as.integer(sba_test$ApprovalFY >= 2010)
sba_train$CreditBoom <- as.integer(sba_train$ApprovalFY >= 2004 & sba_train$ApprovalFY <= 2006)
sba_test$CreditBoom <- as.integer(sba_test$ApprovalFY >= 2004 & sba_test$ApprovalFY <= 2006)

sba_train$TotalJobs <- sba_train$CreateJob + sba_train$RetainedJob
sba_test$TotalJobs <- sba_test$CreateJob + sba_test$RetainedJob

# 3-digit NAICS subsector for finer industry granularity
sba_train$NAICS3 <- substr(as.character(sba_train$NAICS), 1, 3)
sba_test$NAICS3 <- substr(as.character(sba_test$NAICS), 1, 3)
# Only keep subsectors present in training to avoid factor level issues
naics3_levels <- unique(sba_train$NAICS3)
sba_test$NAICS3[!(sba_test$NAICS3 %in% naics3_levels)] <- "000"
sba_train$NAICS3 <- factor(sba_train$NAICS3)
sba_test$NAICS3 <- factor(sba_test$NAICS3, levels = levels(sba_train$NAICS3))

# Additional features
sba_train$RealEstate <- as.integer(sba_train$NAICS_sector %in% c("53"))
sba_test$RealEstate <- as.integer(sba_test$NAICS_sector %in% c("53"))
sba_train$LongTerm <- as.integer(sba_train$Term > 240)
sba_test$LongTerm <- as.integer(sba_test$Term > 240)

# Bucket Term into common loan length categories
term_bucket <- function(t) {
  cut(t, breaks = c(0, 60, 84, 120, 240, 360, Inf),
      labels = c("0-5yr", "5-7yr", "7-10yr", "10-20yr", "20-30yr", "30yr+"),
      include.lowest = TRUE)
}
sba_train$TermBucket <- term_bucket(sba_train$Term)
sba_test$TermBucket <- term_bucket(sba_test$Term)

mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + RevLineCr + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              NAICS_sector + State + Recession + ApprovalFY + Term:SBA_Portion +
              TotalJobs + log(GrAppv_num + 1) +
              log(DisbursementGross_num):SBA_Portion +
              GFC:Term + BankState + RealEstate:GFC + LongTerm +
              NewExist_f:GFC + LowDoc:GFC + RevLineCr:Term +
              log(SBA_Appv_num + 1) + LongTerm:GFC + UrbanRural_f:GFC +
              TermBucket + TermBucket:GFC + TermBucket:SBA_Portion +
              PostGFC + CreditBoom +
              CreditBoom:SBA_Portion + PostGFC:TermBucket +
              NAICS3,
            data = sba_train, family = "binomial")
# summary(mod1)

# Predictions and evaluation (do not modify evaluate function — it lives in prepare.R)
preds_test <- predict(mod1, newdata = sba_test, type = "response")
evaluate(preds_test, sba_test$PaidInFull)
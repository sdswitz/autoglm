library(data.table)
library(dplyr)
source("prepare.R")

# Load raw data and reproduce the exact same split as prepare.R
sba <- read.csv("sba_loans_50k.csv") %>% na.omit()
set.seed(327)
n <- nrow(sba) * 0.8
idx <- sample(1:nrow(sba), n)

# Feature engineering on full dataset before splitting
sba <- sba %>% mutate(
  ApprovalFY = as.numeric(as.character(ApprovalFY)),
  GFC = as.integer(ApprovalFY >= 2007 & ApprovalFY <= 2009),
  Recession = as.integer(ApprovalFY %in% c(2001, 2002, 2007, 2008, 2009)),
  PostGFC = as.integer(ApprovalFY >= 2010),
  CreditBoom = as.integer(ApprovalFY >= 2004 & ApprovalFY <= 2006),
  TotalJobs = CreateJob + RetainedJob,
  NAICS3 = factor(substr(as.character(NAICS), 1, 3)),
  RealEstate = as.integer(NAICS_sector %in% c("53")),
  LongTerm = as.integer(Term > 240),
  SameBankState = as.integer(State == BankState),
  TermBucket = cut(Term, breaks = c(0, 60, 84, 120, 240, 360, Inf),
                   labels = c("0-5yr", "5-7yr", "7-10yr", "10-20yr", "20-30yr", "30yr+"),
                   include.lowest = TRUE)
)

# Split
sba_train <- sba[idx, ]
sba_test <- sba[-idx, ]

# Model
mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + RevLineCr + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              State + Recession + ApprovalFY + Term:SBA_Portion +
              TotalJobs + log(GrAppv_num + 1) +
              log(DisbursementGross_num):SBA_Portion +
              GFC:Term + BankState + RealEstate:GFC + LongTerm +
              NewExist_f:GFC + LowDoc:GFC + RevLineCr:Term +
              log(SBA_Appv_num + 1) + LongTerm:GFC + UrbanRural_f:GFC +
              TermBucket + TermBucket:GFC + TermBucket:SBA_Portion +
              PostGFC + CreditBoom +
              CreditBoom:SBA_Portion + PostGFC:TermBucket +
              NAICS3 + SameBankState + Recession:SBA_Portion,
            data = sba_train, family = "binomial")

# Predictions and evaluation (do not modify evaluate function — it lives in prepare.R)
preds_test <- predict(mod1, newdata = sba_test, type = "response")
evaluate(preds_test, sba_test$PaidInFull)

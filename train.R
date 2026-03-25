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
  HasJobs = as.integer(CreateJob + RetainedJob > 0),
  IsRevLine = as.integer(RevLineCr == "Y"),
  NAICS3 = factor(substr(as.character(NAICS), 1, 3)),
  RealEstate = as.integer(NAICS_sector %in% c("53")),
  LongTerm = as.integer(Term > 240),
  SameBankState = as.integer(State == BankState),
  Pre1989 = as.integer(ApprovalFY < 1989),
  Peak90s = as.integer(ApprovalFY >= 1991 & ApprovalFY <= 1994),
  Late90s = as.integer(ApprovalFY >= 1997 & ApprovalFY <= 2000),
  ApprovalFY2 = ApprovalFY^2,
  ApprovalFY3 = ApprovalFY^3,
  ApprovalFY4 = ApprovalFY^4,
  LoanSizeRatio = GrAppv_num / pmax(DisbursementGross_num, 1),
  Term2 = Term^2,
  Term3 = Term^3,
  Term4 = Term^4,
  HighSBA = as.integer(SBA_Portion > 0.75),
  DisbMonth = factor(format(as.Date(DisbursementDate, format="%d-%b-%y"), "%m")),
  TermBucket = cut(Term, breaks = c(0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 180, 240, 360, Inf),
                   labels = c("0-1yr", "1-2yr", "2-3yr", "3-4yr", "4-5yr", "5-6yr", "6-7yr", "7-8yr", "8-9yr", "9-10yr", "10-15yr", "15-20yr", "20-30yr", "30yr+"),
                   include.lowest = TRUE)
)

# Split
sba_train <- sba[idx, ]
sba_test <- sba[-idx, ]

# Model
mod1 <- glm(PaidInFull ~ NewExist_f + LowDoc + IsRevLine + UrbanRural_f + NoEmp +
              log(DisbursementGross_num) + SBA_Portion + IsFranchise + Term +
              State + Recession + ApprovalFY + Term:SBA_Portion +
              HasJobs + log(GrAppv_num + 1) +
              log(DisbursementGross_num):SBA_Portion +
              GFC:Term + BankState + RealEstate:GFC + LongTerm +
              NewExist_f:GFC + LowDoc:GFC + IsRevLine:Term +
              log(SBA_Appv_num + 1) + LongTerm:GFC + UrbanRural_f:GFC +
              TermBucket + TermBucket:GFC + TermBucket:SBA_Portion +
              PostGFC + CreditBoom +
              CreditBoom:SBA_Portion + PostGFC:TermBucket +
              NAICS3 + SameBankState + Recession:SBA_Portion +
              Pre1989 + Peak90s + Late90s + ApprovalFY2 + ApprovalFY3 + ApprovalFY4 +
              HasJobs:TermBucket + HasJobs:GFC +
              DisbMonth + NewExist_f:TermBucket + LoanSizeRatio +
              LoanSizeRatio:GFC +
              HighSBA + HighSBA:GFC +
              Term2 + Term3 + Term4 +
              Term2:GFC + Term3:GFC +
              Recession:TermBucket +
              Pre1989:TermBucket,
            data = sba_train, family = "binomial")

# Predictions and evaluation (do not modify evaluate function — it lives in prepare.R)
preds_test <- predict(mod1, newdata = sba_test, type = "response")
evaluate(preds_test, sba_test$PaidInFull)

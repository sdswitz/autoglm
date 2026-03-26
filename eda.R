library(dplyr)

sba <- read.csv("sba_loans_50k.csv") %>% na.omit()

cat("\n=== Target Distribution ===\n")
print(table(sba$PaidInFull))
cat("Default rate:", mean(sba$PaidInFull == 0), "\n")

cat("\n=== Numeric Summaries ===\n")
num_cols <- c("Term", "NoEmp", "CreateJob", "RetainedJob", "DisbursementGross_num",
              "GrAppv_num", "SBA_Appv_num", "BalanceGross_num", "SBA_Portion", "ApprovalFY")
for (col in num_cols) {
  cat("\n---", col, "---\n")
  print(summary(as.numeric(as.character(sba[[col]]))))
}

cat("\n=== Collinearity (numeric predictors) ===\n")
sba_num <- sba %>% mutate(ApprovalFY = as.numeric(as.character(ApprovalFY))) %>%
  select(all_of(num_cols))
cor_mat <- cor(sba_num, use = "complete.obs")
cat("Pairs with |r| > 0.7:\n")
for (i in 1:(ncol(cor_mat)-1)) {
  for (j in (i+1):ncol(cor_mat)) {
    if (abs(cor_mat[i,j]) > 0.7) {
      cat(sprintf("  %s ~ %s: %.3f\n", colnames(cor_mat)[i], colnames(cor_mat)[j], cor_mat[i,j]))
    }
  }
}

cat("\n=== Factor Cardinality ===\n")
cat_cols <- c("State", "BankState", "NAICS_sector", "NewExist_f", "UrbanRural_f",
              "RevLineCr", "LowDoc", "IsFranchise")
for (col in cat_cols) {
  cat(sprintf("  %s: %d levels\n", col, length(unique(sba[[col]]))))
}
cat(sprintf("  NAICS (full): %d levels\n", length(unique(sba$NAICS))))
cat(sprintf("  NAICS3 (3-digit): %d levels\n", length(unique(substr(as.character(sba$NAICS), 1, 3)))))

cat("\n=== Default Rate by ApprovalFY ===\n")
sba$ApprovalFY_n <- as.numeric(as.character(sba$ApprovalFY))
yr_rates <- tapply(sba$PaidInFull, sba$ApprovalFY_n, function(x) c(mean(x), length(x)))
for (yr in sort(as.numeric(names(yr_rates)))) {
  v <- yr_rates[[as.character(yr)]]
  cat(sprintf("  %d: paid_rate=%.3f  n=%d\n", yr, v[1], v[2]))
}

cat("\n=== Default Rate by TermBucket ===\n")
sba$TermBucket <- cut(sba$Term, breaks = c(0, 60, 84, 120, 240, 360, Inf),
                      labels = c("0-5yr", "5-7yr", "7-10yr", "10-20yr", "20-30yr", "30yr+"),
                      include.lowest = TRUE)
print(tapply(sba$PaidInFull, sba$TermBucket, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Default Rate by RevLineCr ===\n")
print(tapply(sba$PaidInFull, sba$RevLineCr, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Default Rate by LowDoc ===\n")
print(tapply(sba$PaidInFull, sba$LowDoc, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Default Rate by NewExist_f ===\n")
print(tapply(sba$PaidInFull, sba$NewExist_f, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== NoEmp Distribution (skewness check) ===\n")
cat("Quantiles:\n")
print(quantile(sba$NoEmp, probs = c(0, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 1)))
cat("% zero:", mean(sba$NoEmp == 0), "\n")

cat("\n=== Unused columns worth investigating ===\n")
cat("PropPaid summary:\n")
print(summary(sba$PropPaid))
cat("% finite:", mean(is.finite(sba$PropPaid)), "\n")
cat("% equal to 1:", mean(sba$PropPaid == 1, na.rm=TRUE), "\n")
cat("Unique finite values (first 20):\n")
print(head(sort(unique(sba$PropPaid[is.finite(sba$PropPaid)])), 20))
cat("Default rate for PropPaid < 1 (finite):\n")
sub <- sba[is.finite(sba$PropPaid) & sba$PropPaid < 1, ]
cat(sprintf("  n=%d, paid_rate=%.3f\n", nrow(sub), mean(sub$PaidInFull)))
cat("Default rate for PropPaid == 1:\n")
sub2 <- sba[sba$PropPaid == 1, ]
cat(sprintf("  n=%d, paid_rate=%.3f\n", nrow(sub2), mean(sub2$PaidInFull)))

cat("\n=== Interaction check: TermBucket x CreditBoom ===\n")
sba$CreditBoom <- as.integer(sba$ApprovalFY_n >= 2004 & sba$ApprovalFY_n <= 2006)
print(tapply(sba$PaidInFull, list(sba$TermBucket, sba$CreditBoom), mean))

cat("\n=== Interaction check: TermBucket x RevLineCr ===\n")
print(tapply(sba$PaidInFull, list(sba$TermBucket, sba$RevLineCr), mean))

cat("\n=== RevLineCr detailed ===\n")
cat("Counts and paid rates by level:\n")
for (lev in sort(unique(sba$RevLineCr))) {
  sub <- sba[sba$RevLineCr == lev, ]
  cat(sprintf("  '%s': n=%d, paid_rate=%.3f\n", lev, nrow(sub), mean(sub$PaidInFull)))
}

cat("\n=== LowDoc detailed ===\n")
for (lev in sort(unique(sba$LowDoc))) {
  sub <- sba[sba$LowDoc == lev, ]
  cat(sprintf("  '%s': n=%d, paid_rate=%.3f\n", lev, nrow(sub), mean(sub$PaidInFull)))
}

cat("\n=== BalanceGross_num distribution ===\n")
print(quantile(sba$BalanceGross_num, probs = c(0, 0.25, 0.5, 0.75, 0.9, 0.99, 1)))
cat("% zero:", mean(sba$BalanceGross_num == 0), "\n")
cat("Default rate for BalanceGross==0:", mean(sba$PaidInFull[sba$BalanceGross_num == 0]), "\n")
cat("Default rate for BalanceGross>0:", mean(sba$PaidInFull[sba$BalanceGross_num > 0]), "\n")

cat("\n=== DisbursementDate parsing ===\n")
sba$DisbDate <- as.Date(sba$DisbursementDate, format="%d-%b-%y")
cat("Sample dates:\n")
print(head(sba$DisbDate, 10))
cat("\nDisbursement month distribution (paid rate):\n")
sba$DisbMonth <- as.integer(format(sba$DisbDate, "%m"))
print(tapply(sba$PaidInFull, sba$DisbMonth, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== HasJobs vs no jobs ===\n")
sba$HasJobs <- as.integer(sba$CreateJob + sba$RetainedJob > 0)
cat("HasJobs=0: paid_rate=", mean(sba$PaidInFull[sba$HasJobs == 0]),
    " n=", sum(sba$HasJobs == 0), "\n")
cat("HasJobs=1: paid_rate=", mean(sba$PaidInFull[sba$HasJobs == 1]),
    " n=", sum(sba$HasJobs == 1), "\n")

cat("\n=== DisbursementGross per employee ===\n")
sba$DisbPerEmp <- sba$DisbursementGross_num / (sba$NoEmp + 1)
q <- quantile(sba$DisbPerEmp, probs = seq(0, 1, 0.2))
sba$DisbPerEmpQ <- cut(sba$DisbPerEmp, breaks = q, include.lowest = TRUE)
print(tapply(sba$PaidInFull, sba$DisbPerEmpQ, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Interaction check: HasJobs x GFC ===\n")
sba$HasJobs <- as.integer(sba$CreateJob + sba$RetainedJob > 0)
sba$GFC <- as.integer(sba$ApprovalFY_n >= 2007 & sba$ApprovalFY_n <= 2009)
print(tapply(sba$PaidInFull, list(sba$HasJobs, sba$GFC), mean))

cat("\n=== Interaction check: SameBankState x GFC ===\n")
sba$SameBankState <- as.integer(sba$State == sba$BankState)
print(tapply(sba$PaidInFull, list(sba$SameBankState, sba$GFC), mean))

cat("\n=== Interaction check: IsRevLine x GFC ===\n")
sba$IsRevLine <- as.integer(sba$RevLineCr == "Y")
print(tapply(sba$PaidInFull, list(sba$IsRevLine, sba$GFC), mean))

cat("\n=== Interaction check: IsFranchise x TermBucket ===\n")
print(tapply(sba$PaidInFull, list(sba$IsFranchise, sba$TermBucket), mean))

cat("\n=== NoEmp binned default rates ===\n")
sba$NoEmpBin <- cut(sba$NoEmp, breaks = c(-1, 0, 2, 5, 10, 25, 50, Inf),
                    labels = c("0", "1-2", "3-5", "6-10", "11-25", "26-50", "50+"))
print(tapply(sba$PaidInFull, sba$NoEmpBin, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== SBA_Portion threshold effects ===\n")
sba$SBAbucket <- cut(sba$SBA_Portion, breaks = c(0, 0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 1.0),
                     include.lowest = TRUE)
print(tapply(sba$PaidInFull, sba$SBAbucket, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Interaction check: HighSBA x TermBucket ===\n")
sba$HighSBA <- as.integer(sba$SBA_Portion > 0.75)
print(tapply(sba$PaidInFull, list(sba$HighSBA, sba$TermBucket), mean))

cat("\n=== LoanSizeRatio distribution ===\n")
sba$LoanSizeRatio <- sba$GrAppv_num / pmax(sba$DisbursementGross_num, 1)
print(quantile(sba$LoanSizeRatio, probs = c(0, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 1)))
sba$LSRbucket <- cut(sba$LoanSizeRatio, breaks = c(0, 0.9, 0.95, 1.0, 1.05, 1.1, Inf), include.lowest = TRUE)
print(tapply(sba$PaidInFull, sba$LSRbucket, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Interaction check: LowDoc x NewExist_f ===\n")
print(tapply(sba$PaidInFull, list(sba$LowDoc, sba$NewExist_f), mean))

cat("\n=== Interaction check: IsFranchise x NewExist_f ===\n")
print(tapply(sba$PaidInFull, list(sba$IsFranchise, sba$NewExist_f), mean))

cat("\n=== Interaction check: SameBankState x TermBucket ===\n")
print(tapply(sba$PaidInFull, list(sba$SameBankState, sba$TermBucket), mean))

cat("\n=== log(DisbursementGross) binned default rates ===\n")
sba$LogDisbBin <- cut(log(sba$DisbursementGross_num), breaks = 8)
print(tapply(sba$PaidInFull, sba$LogDisbBin, function(x) c(mean=mean(x), n=length(x))))

cat("\n=== Interaction check: NAICS_sector x GFC (default rates) ===\n")
sba$GFC <- as.integer(sba$ApprovalFY_n >= 2007 & sba$ApprovalFY_n <= 2009)
print(tapply(sba$PaidInFull, list(sba$NAICS_sector, sba$GFC), mean))
cat("\nSector counts during GFC:\n")
print(table(sba$NAICS_sector, sba$GFC))

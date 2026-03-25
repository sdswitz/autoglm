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
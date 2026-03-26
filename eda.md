# EDA Guide

This file tells you how to do exploratory data analysis to motivate experiments. Don't guess — look at the data first.

## How to run EDA

Write analyses in `eda.R` and run them:

```
Rscript eda.R > eda.log 2>&1
```

Read the output with `cat eda.log` or `grep` for specific sections. Keep `eda.R` as a living script — add new analyses as questions come up during experimentation. Use `cat()` liberally to label output sections so they're easy to grep.

## What to investigate

### Before the first experiment

These checks prevent wasted iterations:

1. **Target distribution** — `table(sba$PaidInFull)`. Know the class balance before interpreting accuracy.
2. **Numeric summaries** — `summary()` on all numeric columns. Identifies skew (candidates for log transform), zero-inflation, and outliers.
3. **Factor cardinality** — `sapply(sba[cat_cols], function(x) length(unique(x)))`. High-cardinality factors are risky in interactions. Anything over ~50 levels should not be crossed with other categoricals.
4. **Factor level overlap** — For any factor you plan to use, check that all levels appear in both train and test. Missing levels cause prediction crashes.
5. **Collinearity** — Check correlations between numeric predictors (`cor(sba[num_cols])`). Near-collinear pairs (r > 0.9) destabilize coefficients and can hurt accuracy. Candidates: DisbursementGross_num, GrAppv_num, SBA_Appv_num are likely correlated.

### To motivate a specific experiment

Before adding a feature or interaction, look at the data to confirm the signal exists:

- **Default rate by group** — `tapply(sba$PaidInFull, sba$SomeVar, mean)`. If the rate doesn't vary across levels, the variable won't help.
- **Interaction signal** — To justify `A:B`, check that the effect of A changes across levels of B. A quick way: `tapply(PaidInFull, list(A, B), mean)` and look for non-parallel patterns.
- **Transform candidates** — Plot or tabulate a numeric variable against the target. If the relationship is non-linear, a transform (log, polynomial, bucketing) may help. Use `cut()` to bin and check.
- **Sparsity check** — Before adding an interaction like `Factor1:Factor2`, run `table(Factor1, Factor2)` and check for cells with 0 or very few observations. Sparse cells cause separation warnings and unstable estimates.

### When an experiment fails

If accuracy drops or the model crashes, use EDA to diagnose:

- **Separation** — `table()` the offending interaction. Look for zero cells.
- **Unexpected coefficient signs** — Check if collinearity with another predictor is flipping the sign.
- **Overfitting signal** — If train accuracy is much higher than test, the model is fitting noise. Simplify.

## Principles

- **EDA output stays out of your context window.** Write to eda.log, grep what you need. Don't dump raw R output into the conversation.
- **Label everything.** Use `cat("\n=== Section Name ===\n")` so you can grep for specific analyses later.
- **One question per analysis.** Don't write a 200-line EDA script. Ask a specific question, get the answer, move on.
- **EDA is not optional.** If you're about to add a feature because "it seems like it might help," stop and check the data first. 30 seconds of EDA saves 5 minutes of a wasted experiment run.

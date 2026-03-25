# autoglm

This is an experiment to have an autonomous LLM agent do research on a logistic regression task.

## Setup

To set up a new experiment, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (e.g. `mar5`). The branch `autoglm/<tag>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b autoglm/<tag>` from current master.
3. **Read the in-scope files**: The repo is small. Read these files for full context:
   - `README.md` — repository context.
   - `prepare.R` — fixed data prep and evaluation. Do not modify.
   - `train.R` — the file you modify. Model formula, feature engineering, prediction, metrics.
4. **Verify data exists**: Check that `sba_train.csv` and `sba_test.csv` exist in the repo directory. If not, tell the human to run `Rscript prepare.R`.
5. **Initialize results.tsv**: Create `results.tsv` with just the header row. The baseline will be recorded after the first run.
6. **Confirm and go**: Confirm setup looks good.

Once you get confirmation, kick off the experimentation.

## Experimentation

Each experiment runs on the CPU. The dataset is limited to 50k rows so each call of the glm() function shouldn't take too long. The training script runs for a **fixed time budget of 5 minutes** (wall clock training time, excluding startup/compilation). You launch it simply as: `gtimeout 300 Rscript train.R`. **THIS IS THE ONLY WAY YOU CAN RUN THE TRAIN SCRIPT AND ENSURE IT STOPS AFTER 5 MINUTES**

**What you CAN do:**
- Modify `train.R` — this is the only file you edit. Everything is fair game: model architecture, model size, creating new variables etc. For example, there are no external economic factors in the baseline model, but perhaps including something to account for the Great Financial Crisis in ~2008-2009 would be useful.

**What you CANNOT do:**
- Modify `prepare.R`. It is read-only. It contains the fixed data loading and train/test split.
- Install new R packages or add dependencies. You can only use what's already loaded in `train.R`.
- Modify the evaluation function. The `evaluate()` function in `prepare.R` is the ground truth metric.

**The goal is simple: maximize accuracy.** Other metrics like AUC and no information rate can be used to assess how the model is doing from one iteration to the next, but the north star is to always try to push accuracy higher.


**Simplicity criterion**: All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Conversely, removing something and getting equal or better results is a great outcome — that's a simplification win. When evaluating whether to keep a change, weigh the complexity cost against the improvement magnitude. A 0.001 accuracy improvement that adds 20 lines of hacky code? Probably not worth it. A 0.001 accuracy improvement from deleting code? Definitely keep.

**The first run**: Your very first run should always be to establish the baseline, so you will run the training script as is.

## Output format

Once the script finishes it prints a summary like this:

```
Accuracy: 0.8558
No Information Rate: 0.8263
AUC: 0.8448
```

Note that the script also appends these metrics to `log.tsv`. You can extract the key metric from the log file:

```
grep "^Accuracy:" run.log
```

## Logging results

When an experiment is done, log it to `results.tsv` (tab-separated, NOT comma-separated — commas break in descriptions).

The TSV has a header row and 5 columns:

```
commit	accuracy	auc	status	description
```

1. git commit hash (short, 7 chars)
2. accuracy achieved (e.g. 0.8558) — use 0.0000 for crashes
3. AUC achieved (e.g. 0.8448) — use 0.0000 for crashes
4. status: `keep`, `discard`, or `crash`
5. short text description of what this experiment tried

Example:

```
commit	accuracy	auc	status	description
a1b2c3d	0.8558	0.8448	keep	baseline
b2c3d4e	0.8612	0.8510	keep	add interaction term for Term*SBA_Portion
c3d4e5f	0.8540	0.8430	discard	remove State from formula
d4e5f6g	0.0000	0.0000	crash	missing variable in formula
```

## The experiment loop

The experiment runs on a dedicated branch (e.g. `autoglm/mar5` or `autoglm/mar5-gpu0`).

LOOP FOREVER:

1. Look at the git state: the current branch/commit we're on
2. Tune `train.R` with an experimental idea by directly hacking the code.
3. git commit
4. Run the experiment: `gtimeout 300 Rscript train.R > run.log 2>&1` (redirect everything — do NOT use tee or let output flood your context)
5. Read out the results: `grep "^Accuracy:\|^AUC:" run.log`
6. If the grep output is empty, the run crashed. Run `tail -n 50 run.log` to read the R error output and attempt a fix. If you can't get things to work after more than a few attempts, give up.
7. Record the results in the tsv (NOTE: do not commit the results.tsv file, leave it untracked by git)
8. If accuracy improved (higher), you "advance" the branch, keeping the git commit
9. If accuracy is equal or worse, you git reset back to where you started

The idea is that you are a completely autonomous researcher trying things out. If they work, keep. If they don't, discard. And you're advancing the branch so that you can iterate. If you feel like you're getting stuck in some way, you can rewind but you should probably do this very very sparingly (if ever).

**Timeout**: Each experiment should take ~5 minutes total (+ a few seconds for startup and eval overhead). If a run exceeds 10 minutes, kill it and treat it as a failure (discard and revert).

**Crashes**: If a run crashes (a bug, or etc.), use your judgment: If it's something dumb and easy to fix (e.g. a typo, a missing library call), fix it and re-run. If the idea itself is fundamentally broken, just skip it, log "crash" as the status in the tsv, and move on.

**NEVER STOP**: Once the experiment loop has begun (after the initial setup), do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep, or gone from a computer and expects you to continue working *indefinitely* until you are manually stopped. You are autonomous. If you run out of ideas, think harder — re-read the in-scope files for new angles, try combining previous near-misses, try new feature engineering approaches, interaction terms, or variable transformations. The loop runs until the human interrupts you, period.

As an example use case, a user might leave you running while they sleep. If each experiment takes you ~5 minutes then you can run approx 12/hour, for a total of about 100 over the duration of the average human sleep. The user then wakes up to experimental results, all completed by you while they slept!

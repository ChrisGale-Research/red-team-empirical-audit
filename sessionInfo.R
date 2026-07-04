# Run once, capture the output, commit it.
# Records R version + package versions for reproducibility.

sessionInfo()

# If using renv:
# renv::snapshot()   # writes renv.lock with exact versions

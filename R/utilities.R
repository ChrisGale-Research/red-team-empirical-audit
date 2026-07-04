# Utility functions for the red-team pipeline

install_required_packages <- function() {
  required <- c("tidyverse", "broom", "lme4", "mgcv")
  missing <- required[!required %in% rownames(installed.packages())]
  if (length(missing) > 0) install.packages(missing)
  invisible(required)
}

load_dependencies <- function() {
  library(tidyverse)
  library(broom)
}

ensure_output_dir <- function() {
  if (!dir.exists("output")) dir.create("output", showWarnings = FALSE)
}

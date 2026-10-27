
# ==============================================================================
# Project: From Metastatic Progression to Prognosis: Multi-Cohort Transcriptomic
#          Replication, Multi-Omics Prioritization, Single-Cell Localization,
#          and Pre-Specified External Validation of a Machine-Learning Model
#          in Cutaneous Melanoma
#
# Task: T5.4.3 - Develop and Internally Evaluate the Random Survival Forest Model
#
# Purpose:
#   Tune a Random Survival Forest using only the locked inner folds, then evaluate
#   it on the common outer folds and retain patient-level out-of-fold predictions.
#
# Input Files:
#   1. 261017_T5.1.2_TCGA_Development_Data_Results_Ameneh_Hashemzehi_Human.rds
#   2. 261018_T5.2.1_Progression_Features_Results_Ameneh_Hashemzehi_Human.rds
#   3. 261018_T5.2.2_Molecular_Scaling_Model_Ameneh_Hashemzehi_Human.rds
#   4. 261021_T5.3.1_Nested_CV_Lock_Results_Ameneh_Hashemzehi_Human.rds
#
# Output Files:
#   1. 261025_T5.4.3_Survival_Forest_Results_Narges_Omidian_Human.csv
#   2. 261025_T5.4.3_Survival_Forest_Results_Narges_Omidian_Human.rds
#   3. 261025_T5.4.3_Survival_Forest_Model_Narges_Omidian_Human.rds
#   4. 261025_T5.4.3_Survival_Forest_Table_RSF_Importance_Stability_Narges_Omidian_Human.csv
#   5. 261025_T5.4.3_Survival_Forest_Table_RSF_Importance_Stability_Narges_Omidian_Human.rds
#   6. 261025_T5.4.3_Survival_Forest_Table_OOF_Predictions_Narges_Omidian_Human.csv
#   7. 261025_T5.4.3_Survival_Forest_Table_Fold_Performance_Narges_Omidian_Human.csv
#   8. 261025_T5.4.3_Survival_Forest_Table_RSF_Tuning_Narges_Omidian_Human.csv
#   9. 261025_T5.4.3_Survival_Forest_Session_Info_Narges_Omidian_Human.txt
#  10. 261025_T5.4.3_Survival_Forest_Execution_Log_Narges_Omidian_Human.txt
#
# Author: Narges_Omidian
# Date: 2026-10-25
# R Version: 4.6.0
# ==============================================================================

# 0. Global safeguards ----------------------------------------------------------
required_r_version <- numeric_version("4.6.0");
if (getRversion() != required_r_version) {   stop("Incorrect R version. Required: 4.6.0; detected: ",        as.character(getRversion()), call. = FALSE) };
options(stringsAsFactors = FALSE, warn = 1, scipen = 999); set.seed(20260802)
# 1. Configuration --------------------------------------------------------------
# ---- 1.1 Task metadata ----
project_title <- paste(   "From Metastatic Progression to Prognosis:",   "Multi-Cohort Transcriptomic Replication, Multi-Omics Prioritization,",   "Single-Cell Localization, and Pre-Specified External Validation",   "of a Machine-Learning Model in Cutaneous Melanoma" );
task_id <- "T5.4.3"; task_title <- "Develop and Internally Evaluate the Random Survival Forest Model";
author_name <- "Narges_Omidian"; script_date <- "2026-10-25";
script_artifact_name <- "261025_T5.4.3_Survival_Forest_Script_Narges_Omidian_Human.R"
# ---- 1.2 Exact input file names ----
expected_input_files <- c(   development = "261017_T5.1.2_TCGA_Development_Data_Results_Ameneh_Hashemzehi_Human.rds",   features = "261018_T5.2.1_Progression_Features_Results_Ameneh_Hashemzehi_Human.rds",   scaling = "261018_T5.2.2_Molecular_Scaling_Model_Ameneh_Hashemzehi_Human.rds",   cv_lock = "261021_T5.3.1_Nested_CV_Lock_Results_Ameneh_Hashemzehi_Human.rds" )
# ---- 1.3 Exact generated output file names ----
output_files <- c(   results_csv = "261025_T5.4.3_Survival_Forest_Results_Narges_Omidian_Human.csv",   results_rds = "261025_T5.4.3_Survival_Forest_Results_Narges_Omidian_Human.rds",   model_rds = "261025_T5.4.3_Survival_Forest_Model_Narges_Omidian_Human.rds",   importance_csv = "261025_T5.4.3_Survival_Forest_Table_RSF_Importance_Stability_Narges_Omidian_Human.csv",   importance_rds = "261025_T5.4.3_Survival_Forest_Table_RSF_Importance_Stability_Narges_Omidian_Human.rds",   oof_csv = "261025_T5.4.3_Survival_Forest_Table_OOF_Predictions_Narges_Omidian_Human.csv", fold_csv = "261025_T5.4.3_Survival_Forest_Table_Fold_Performance_Narges_Omidian_Human.csv", tuning_csv = "261025_T5.4.3_Survival_Forest_Table_RSF_Tuning_Narges_Omidian_Human.csv", session_info = "261025_T5.4.3_Survival_Forest_Session_Info_Narges_Omidian_Human.txt",   execution_log = "261025_T5.4.3_Survival_Forest_Execution_Log_Narges_Omidian_Human.txt" )
# ---- 1.4 Required packages ----
required_packages <- c("randomForestSRC", "survival", "sessioninfo");
missing_packages <- required_packages[   !vapply(required_packages, requireNamespace, quietly = TRUE,           FUN.VALUE = logical(1)) ];
if (length(missing_packages)) {   stop("Missing required packages: ", paste(missing_packages, collapse = ", "),        ". Restore the project environment with renv::restore().", call. = FALSE) }
# 2. File-selection helpers -----------------------------------------------------
select_output_directory <- function() {
   selected <- NULL;
if (requireNamespace("rstudioapi", quietly = TRUE) &&       rstudioapi::isAvailable()) {
  
selected <- rstudioapi::selectDirectory(       caption = "Select the T5.4.3 output directory"     )   } else if (.Platform$OS.type == "windows") {     selected <- utils::choose.dir(caption = "Select the T5.4.3 output directory")   } else if (capabilities("tcltk")) {     selected <- as.character(tcltk::tk_choose.dir(       caption = "Select the T5.4.3 output directory"     ))   } else {
  
selected <- readline("Enter the T5.4.3 output directory path: ")   };
if (is.null(selected) || !nzchar(selected) || !dir.exists(selected)) {     stop("A valid output directory was not selected.", call. = FALSE)   };
normalizePath(selected, winslash = "/", mustWork = TRUE) }
# 3. Select input folder and output directory ----------------------------------
input_directory <- dirname(normalizePath(file.choose(), winslash = "/",                                          mustWork = TRUE));
actual_input_names <- list.files(input_directory, all.files = FALSE,                                  recursive = FALSE);
input_counts <- vapply(expected_input_files, function(nm) {
   sum(actual_input_names == nm) }, integer(1));
if (any(input_counts != 1L)) {
  missing <- names(input_counts)[input_counts == 0L]
  similar <- unlist(lapply(names(input_counts)[input_counts == 0L], function(k) {
    actual_input_names[tolower(actual_input_names) ==
      tolower(expected_input_files[[k]])]
  }), use.names = FALSE)
  detail <- if (length(similar)) {
    paste0(" Case/name variants: ", paste(similar, collapse = ", "))
  } else {
    ""
  }
  stop("Input folder lacks required exact files: ",
       paste(expected_input_files[missing], collapse = ", "), detail,
       call. = FALSE)
}
input_paths <- file.path(input_directory, expected_input_files);
names(input_paths) <- names(expected_input_files); output_dir <- select_output_directory();
output_paths <- file.path(output_dir, output_files); names(output_paths) <- names(output_files);
existing_outputs <- basename(output_paths[file.exists(output_paths)]);
if (length(existing_outputs)) {   stop("Output files already exist; select another output folder: ",        paste(existing_outputs, collapse = ", "), call. = FALSE) }
# 4. Reproducibility and logging helpers ---------------------------------------
warnings_collected <- character(0); error_message <- NULL; task_status <- "FAILED";
task_start_time <- Sys.time(); warning_context <- "input loading"; redact_text <- function(x) {
  
x <- gsub("(?i)[A-Z]:[/\\\\][^\\r\\n]*", "[LOCAL_PATH]", x, perl = TRUE);
x <- gsub("(?i)(/Users/|/home/)[^\\r\\n]*", "[LOCAL_PATH]", x,             perl = TRUE); x };
package_versions <- function() {
  
pkgs <- unique(c("base", "stats", "utils", "tools", required_packages,                    if (requireNamespace("renv", quietly = TRUE)) "renv",                    if (requireNamespace("rstudioapi", quietly = TRUE)) "rstudioapi",                    if (capabilities("tcltk")) "tcltk"));
vapply(pkgs, function(p) if (requireNamespace(p, quietly = TRUE))     as.character(utils::packageVersion(p)) else "not available", character(1)) };
write_session_report <- function(file_path, warnings = character(0), error = NULL) {
   report <- capture.output({
  
cat("PROJECT COMPUTATIONAL SESSION REPORT\n"); cat("====================================\n\n");
cat("Project:", project_title, "\n"); cat("Task:", task_id, "-", task_title, "\n");
cat("Author:", author_name, "\n"); cat("Script date:", script_date, "\n");
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n"); cat("R version:", R.version.string, "\n");
cat("Working directory:", getwd(), "\n"); cat("Output directory:", output_dir, "\n\n");
cat("INPUT FILES\n-----------\n");
for (nm in names(input_paths)) cat(nm, ": ", basename(input_paths[[nm]]), "\n", sep = "");
cat("\nOUTPUT FILES\n------------\n");
for (nm in names(output_paths)) cat(nm, ": ", basename(output_paths[[nm]]), "\n", sep = "");
cat("archived_script: ", script_artifact_name, "\n", sep = ""); cat("\nPACKAGE VERSIONS\n----------------\n");
pv <- package_versions(); for (nm in names(pv)) cat(nm, ": ", pv[[nm]], "\n", sep = "");
cat("\nRENV STATUS\n-----------\n");
if (requireNamespace("renv", quietly = TRUE)) {       rs <- capture.output(renv::status());
cat(if (length(rs)) rs else "renv::status() returned no text.", sep = "\n");
cat("\n")     } else cat("renv is not available in the active library.\n"); cat("\nWARNINGS\n--------\n");
if (!length(warnings)) cat("None recorded.\n") else       cat(paste0("- ", unique(warnings)), sep = "\n");
cat("\n\nERROR\n-----\n"); cat(if (is.null(error)) "None recorded.\n" else paste0(error, "\n"));
cat("\nSESSION INFORMATION\n-------------------\n"); print(sessioninfo::session_info())   });
writeLines(redact_text(report), file_path, useBytes = TRUE) };
write_execution_log <- function(file_path, status, start_time, end_time,                                 warnings = character(0), error = NULL) {
  
lines <- c(     paste0("Project: ", project_title), paste0("Task: ", task_id, " - ", task_title),     paste0("Author: ", author_name), paste0("Status: ", status),     paste0("Start time: ", format(start_time, "%Y-%m-%d %H:%M:%S %Z")),     paste0("End time: ", format(end_time, "%Y-%m-%d %H:%M:%S %Z")),     paste0("Elapsed seconds: ", round(as.numeric(difftime(end_time, start_time,                                                          units = "secs")), 2)),     "", "Warnings:", if (!length(warnings)) "None recorded." else       paste0("- ", unique(warnings)), "", "Error:",     if (is.null(error)) "None recorded." else error   );
writeLines(redact_text(lines), file_path, useBytes = TRUE) };
write_reproducibility_outputs <- function(session_file, log_file, status,                                           start_time, end_time, warnings, error) {
  
write_session_report(session_file, warnings, error);
write_execution_log(log_file, status, start_time, end_time, warnings, error) }
# 5. Input loading --------------------------------------------------------------
read_input_auto <- function(path) {
  
if (!identical(tolower(tools::file_ext(path)), "rds"))     stop("Unsupported input file extension: ", basename(path), call. = FALSE);
readRDS(path) }
# 6. Input validation and metric helpers ---------------------------------------
assert <- function(ok, text) if (!isTRUE(ok)) stop(text, call. = FALSE);
survival_at <- function(prediction, horizon, expected_n) {
  assert(length(expected_n) == 1L && is.finite(expected_n) && expected_n >= 0,
         "Expected prediction count is invalid.")
  if (is.null(prediction$survival) || is.null(prediction$time.interest)) return(rep(NA_real_, expected_n))
  ti <- prediction$time.interest; sm <- prediction$survival
  if (is.null(dim(sm)) || nrow(sm) != expected_n) stop("RSF survival matrix has an invalid patient dimension.", call. = FALSE)
  if (!length(ti) || any(!is.finite(ti)) || horizon > max(ti)) return(rep(NA_real_, expected_n))
  j <- which(ti <= horizon); if (!length(j)) return(rep(1, expected_n))
  as.numeric(sm[, max(j)])
}; km_censor <- function(time, event) {
  
sf <- survival::survfit(survival::Surv(time, 1 - event) ~ 1); list(time = sf$time, surv = sf$surv) };
g_value <- function(km, t, left = FALSE) {
   eligible <- if (left) km$time < t else km$time <= t;
if (!any(eligible)) return(1); val <- tail(km$surv[eligible], 1L);
if (length(val) != 1L || !is.finite(val) || val <= 0) return(NA_real_); as.numeric(val) };
metric_record <- function(metric, estimate = NA_real_, status = "NOT_ESTIMABLE",                           reason = "") {
  
data.frame(Metric = metric, Estimate = estimate, Status = status,              Reason = reason, stringsAsFactors = FALSE) };
uno_c <- function(time, event, risk, km, tau) {
  
if (any(!is.finite(time)) || any(!is.finite(event)) || any(!is.finite(risk)))     return(metric_record("Uno_C", reason = "One or more required observations have invalid values."));
numerator <- denominator <- 0;
for (i in which(event == 1 & time <= tau)) {     g <- g_value(km, time[i], left = TRUE);
if (!is.finite(g) || g <= 0)       return(metric_record("Uno_C", reason = "Censoring survival G(t-) is not positive and finite."));
js <- which(time > time[i]); if (!length(js)) next; w <- 1 / g^2;
numerator <- numerator + w * sum(ifelse(risk[i] > risk[js], 1,                                      ifelse(risk[i] == risk[js], 0.5, 0)));
denominator <- denominator + w * length(js)   };
if (denominator <= 0)     return(metric_record("Uno_C", reason = "No comparable event pairs through the horizon."));
metric_record("Uno_C", numerator / denominator, "ESTIMABLE", "") };
auc_ipcw <- function(time, event, risk, km, horizon) {
  cases <- which(event == 1 & time <= horizon)
  controls <- which(time > horizon)
  if (!length(cases) || !length(controls)) {
    return(metric_record("Time_Dependent_AUC", reason = "No cases or controls at horizon."))
  }
  wc <- vapply(cases, function(i) {
    g <- g_value(km, time[i], left = TRUE)
    if (!is.finite(g) || g <= 0) NA_real_ else 1 / g
  }, numeric(1))
  g0 <- g_value(km, horizon, left = FALSE)
  if (any(!is.finite(wc)) || !is.finite(g0) || g0 <= 0) {
    return(metric_record("Time_Dependent_AUC", reason = "Required IPCW censoring survival is invalid."))
  }
  w0 <- 1 / g0
  pair_w <- outer(wc, rep(w0, length(controls)))
  cmp <- outer(risk[cases], risk[controls], function(a, b) {
    ifelse(a > b, 1, ifelse(a == b, 0.5, 0))
  })
  metric_record("Time_Dependent_AUC", sum(pair_w * cmp) / sum(pair_w), "ESTIMABLE", "")
}
brier_ipcw <- function(time, event, survival_prob, km, horizon) {
  
usable_event <- which(event == 1 & time <= horizon); usable_control <- which(time > horizon);
censored_early <- which(event == 0 & time <= horizon); weights <- rep(NA_real_, length(time));
outcome <- rep(NA_real_, length(time)); for (i in usable_event) {     g <- g_value(km, time[i], left = TRUE);
if (!is.finite(g) || g <= 0)       return(metric_record("Brier", reason = "Required IPCW G(t-) is invalid."));
weights[i] <- 1 / g; outcome[i] <- 0   }; g0 <- g_value(km, horizon, left = FALSE);
if (length(usable_control) && (!is.finite(g0) || g0 <= 0))     return(metric_record("Brier", reason = "Required IPCW G(horizon) is invalid."));
if (length(usable_control)) {     weights[usable_control] <- 1 / g0; outcome[usable_control] <- 1   };
use <- c(usable_event, usable_control);
if (!length(use) || any(!is.finite(survival_prob[use])))     return(metric_record("Brier", reason = "No valid prediction support at horizon."));
metric_record("Brier", sum(weights[use] * (outcome[use] - survival_prob[use])^2) /                   length(time), "ESTIMABLE", "") };
performance_for <- function(dat, km, horizon, primary_tau) {
  
surv <- dat[[paste0("Predicted_Survival_", horizon)]]; risk <- 1 - surv;
if (any(!is.finite(surv))) {     out <- rbind(metric_record("Uno_C", reason = "Survival prediction unsupported at horizon."),       metric_record("Time_Dependent_AUC", reason = "Survival prediction unsupported at horizon."),       metric_record("Brier", reason = "Survival prediction unsupported at horizon."));
if (horizon == primary_tau) out$Metric[1L] <- "IPCW_Uno_C"; return(out)   };
rs <- list(uno_c(dat$OBS_Days, dat$Event, risk, km, horizon)); names(rs) <- "uno";
if (horizon == primary_tau) rs[[1L]]$Metric <- "IPCW_Uno_C";
auc <- auc_ipcw(dat$OBS_Days, dat$Event, risk, km, horizon); auc$Metric <- "Time_Dependent_AUC";
br <- brier_ipcw(dat$OBS_Days, dat$Event,                    dat[[paste0("Predicted_Survival_", horizon)]], km, horizon);
rbind(rs[[1L]], auc, br) }
# 7. Data cleaning and preparation ---------------------------------------------
# 8. Statistical analysis -------------------------------------------------------
# 9. Visualization --------------------------------------------------------------
# Figure generation was omitted as requested.
# 10. Export results ------------------------------------------------------------
# Task exports are written inside the protected execution block below.
# 11. Main execution and error handling -----------------------------------------
task_status <- "FAILED"; tryCatch(   withCallingHandlers({
   input_data <- lapply(input_paths, read_input_auto);
names(input_data) <- names(input_paths); development <- input_data$development; features <- input_data$features;
scaling <- input_data$scaling; cv <- input_data$cv_lock;
assert(is.list(development$provisional_candidate_data),            "Development input lacks provisional_candidate_data.");
expr <- development$provisional_candidate_data$expression_matrix;
meta <- development$provisional_candidate_data$metadata; feature_table <- features$feature_list;
assert(is.matrix(expr) && is.numeric(expr) && !is.null(rownames(expr)) &&              !is.null(colnames(expr)), "Expression matrix has invalid structure.");
req_meta <- c("Patient_ID", "Sample_ID", "Matrix_Column_ID", "Sample_Type",                   "OBS_Days", "Event", "QC_Status");
assert(all(req_meta %in% names(meta)), "Development metadata lacks required columns.");
assert(all(c("TCGA_Source_Feature_ID", "Gene_ID", "Gene_Symbol",                  "Locked_Order") %in% names(feature_table)),            "Progression feature table lacks required mapping columns.");
assert("Fully_Verified_Development_Eligibility" %in% names(feature_table),
       "Missing Fully_Verified_Development_Eligibility column.");
eligibility_values <- toupper(trimws(as.character(
  feature_table$Fully_Verified_Development_Eligibility)));
fully_verified <- !is.na(eligibility_values) & eligibility_values == "TRUE";
verification_status <- if (all(fully_verified)) "FULLY_VERIFIED" else
  if (any(fully_verified)) "PARTIALLY_VERIFIED" else "NOT_FULLY_VERIFIED";
assert(is.list(cv$splits) && is.list(cv$protocol),            "Nested CV lock lacks splits or protocol.");
sap <- development$statistical_analysis_plan; sap_fields <- c("endpoint", "event", "time_origin", "formula");
assert(is.list(sap) && all(sap_fields %in% names(sap)) &&       all(vapply(sap[sap_fields], function(v) is.character(v) &&         length(v) == 1L && nzchar(v), logical(1))),       "Development SAP lacks a complete endpoint or time-origin definition.");
protocol <- cv$protocol; rsf_spec <- protocol$Algorithms$Survival_Forest;
assert(identical(rsf_spec$engine, "randomForestSRC::rfsrc"),            "Locked Survival Forest engine is not randomForestSRC::rfsrc.");
assert(identical(as.integer(rsf_spec$ntree), 500L),            "Unexpected locked RSF tree count.");
assert(identical(as.integer(protocol$Seed), 20260802L),            "Unexpected locked seed.");
md5_now <- unname(tools::md5sum(input_paths)); names(md5_now) <- names(input_paths); lock_hashes <- cv$input_md5;
shared_names <- c(       expected_input_files[["development"]],       expected_input_files[["features"]],       expected_input_files[["scaling"]]     );
assert(is.character(lock_hashes) && !is.null(names(lock_hashes)) &&              all(shared_names %in% names(lock_hashes)),            "T5.3.1 lock lacks hashes for shared development, feature, or scaling inputs.");
input_hash_audit <- data.frame(       Input = names(input_paths), File = basename(input_paths),       MD5 = md5_now, Expected_MD5 = NA_character_, Hash_Match = NA,       stringsAsFactors = FALSE     );
for (nm in names(input_paths)) {       fn <- basename(input_paths[[nm]]);
if (fn %in% shared_names) {         input_hash_audit$Expected_MD5[input_hash_audit$Input == nm] <-           unname(lock_hashes[[fn]]);
input_hash_audit$Hash_Match[input_hash_audit$Input == nm] <-           identical(unname(md5_now[[nm]]), unname(lock_hashes[[fn]]))       }     };
assert(all(input_hash_audit$Hash_Match[!is.na(input_hash_audit$Hash_Match)]),            "A shared input MD5 does not match the T5.3.1 lock.");
ids <- feature_table$TCGA_Source_Feature_ID;
assert(length(ids) > 0L && !anyNA(ids) && !anyDuplicated(ids),            "Feature source IDs are missing or duplicated.");
assert(!anyNA(feature_table$Gene_ID) && !anyDuplicated(feature_table$Gene_ID),            "Gene identifiers in the progression feature list are missing or duplicated.");
assert(all(ids %in% rownames(expr)),            "One or more locked feature source IDs are absent from expression rows.");
assert(all(is.finite(expr[ids, , drop = FALSE])),            "Candidate expression contains NA, NaN, or infinite values.");
assert(!anyNA(meta$Patient_ID) && !anyDuplicated(meta$Patient_ID),            "Patient IDs are missing or duplicated in the development cohort.");
assert(!anyNA(meta$Sample_ID) && !anyDuplicated(meta$Sample_ID),            "Sample IDs are missing or duplicated in the development cohort.");
assert(all(startsWith(meta$Sample_ID, meta$Patient_ID)),            "Sample-to-patient identifiers are inconsistent.");
assert(!anyNA(meta$Matrix_Column_ID) && !anyDuplicated(meta$Matrix_Column_ID),            "Matrix_Column_ID values are missing or duplicated.");
assert(setequal(meta$Matrix_Column_ID, colnames(expr)),            "Expression columns do not map one-to-one to development metadata.");
meta <- meta[match(colnames(expr), meta$Matrix_Column_ID), , drop = FALSE];
assert(identical(meta$Matrix_Column_ID, colnames(expr)),            "Metadata alignment to expression columns failed.");
lock_count <- function(key) {
   v <- cv$summary$Value[match(key, cv$summary$Metric)];
if (length(v) != 1L || is.na(v) || !grepl("^[0-9]+$", v))         stop("T5.3.1 summary lacks valid count: ", key, call. = FALSE);
as.integer(v)     };
assert(nrow(meta) == lock_count("Patients") &&              sum(meta$Event == 1, na.rm = TRUE) == lock_count("Events") &&              sum(meta$Event == 0, na.rm = TRUE) == lock_count("Censored"),            "Development cohort counts differ from the supplied T5.3.1 cohort.");
assert(length(ids) == lock_count("Candidate_Genes"),            "Feature count differs from the T5.3.1 locked candidate count.");
assert(all(meta$QC_Status == "PASS"),            "Development cohort contains QC exclusions or review flags.");
assert(all(meta$Sample_Type == "Metastatic"),            "Development cohort contains a non-metastatic sample.");
assert(all(is.finite(meta$OBS_Days) & meta$OBS_Days > 0) &&              all(meta$Event %in% c(0, 1)), "Invalid OBS time or event coding.");
assert(identical(scaling$training_only, TRUE) &&              is.function(scaling$fit_on_training_fold) &&              is.function(scaling$apply_frozen_scaler),            "Training-only scaler interface is unavailable.");
minimum_sd <- as.numeric(formals(scaling$fit_on_training_fold)$minimum_sd);
assert(length(minimum_sd) == 1L && is.finite(minimum_sd) && minimum_sd > 0,            "Scaler minimum-SD rule is invalid.");
n_outer <- as.integer(protocol$Outer_Folds); n_repeats <- as.integer(protocol$Outer_Repeats); raw_horizons <- protocol$Horizons_Days
assert(is.numeric(raw_horizons) && length(raw_horizons) > 0L &&
       all(is.finite(raw_horizons)) && all(raw_horizons > 0) &&
       !anyDuplicated(raw_horizons) && all(raw_horizons <= max(meta$OBS_Days)),
       "Locked horizons must be positive, unique, finite, and within observed follow-up.")
horizons <- as.numeric(raw_horizons); tau <- as.numeric(protocol$Primary_Proposed_Tau_Days)
assert(length(n_outer) == 1L && n_outer > 1L &&
       length(n_repeats) == 1L && n_repeats >= 1L &&
       length(tau) == 1L && is.finite(tau) && tau > 0 && tau <= max(meta$OBS_Days) &&
       tau %in% horizons,
       "Invalid locked CV settings or primary horizon.")
assert(length(cv$splits) == n_outer * n_repeats,            "Number of stored outer splits differs from the protocol.");
min_events <- as.integer(protocol$Minimum_Events_Per_Partition);
min_censored <- as.integer(protocol$Minimum_Censored_Per_Partition);
assert(length(min_events) == 1L && is.finite(min_events) && min_events > 0L &&              length(min_censored) == 1L && is.finite(min_censored) && min_censored > 0L,            "T5.3.1 partition event/censor minima are invalid.");
patient_ids <- meta$Patient_ID; split_names <- names(cv$splits);
assert(!is.null(split_names) && !anyDuplicated(split_names) &&              all(grepl("^[0-9]+_[0-9]+$", split_names)),            "Outer split names are missing or duplicated.");
check_partition <- function(pids, label) {
   z <- meta[match(pids, meta$Patient_ID), , drop = FALSE];
ne <- sum(z$Event == 1); nc <- sum(z$Event == 0);
if (ne < min_events || nc < min_censored)         stop(label, " violates locked minimums: events=", ne,              ", censored=", nc, call. = FALSE)     };
fold_meta <- cv$metadata;
assert(all(c("Patient_ID", "Repeat", "Level", "Outer_Fold") %in%                  names(fold_meta)), "T5.3.1 fold metadata lacks required columns.");
for (sp_name in split_names) {       sp <- cv$splits[[sp_name]];
assert(all(c("outer_training", "outer_test", "inner") %in% names(sp)),              paste("Outer split is missing components:", sp_name));
tr <- sp$outer_training; te <- sp$outer_test; key <- as.integer(strsplit(sp_name, "_", fixed = TRUE)[[1]]);
assert(!anyDuplicated(tr) && !anyDuplicated(te) &&                !length(intersect(tr, te)) && setequal(c(tr, te), patient_ids),              paste("Outer patient partition is invalid:", sp_name));
fold_rows <- fold_meta[fold_meta$Repeat == key[1L] &                                fold_meta$Outer_Fold == key[2L], , drop = FALSE];
assert(nrow(fold_rows) > 0L,              paste("No matching rows in locked fold metadata:", sp_name));
level_sets <- split(fold_rows$Patient_ID, as.character(fold_rows$Level));
test_matches <- vapply(level_sets, function(z) setequal(unique(z), te),                              logical(1));
assert(sum(test_matches) == 1L,              paste("Could not uniquely map the locked test patients from fold metadata:",                    sp_name));
check_partition(tr, paste(sp_name, "outer training")); check_partition(te, paste(sp_name, "outer test"));
assert(length(sp$inner) >= 2L, paste("Too few inner folds:", sp_name));
for (j in seq_along(sp$inner)) {         inn <- sp$inner[[j]];
assert(all(c("training", "validation") %in% names(inn)),                paste("Inner split structure is invalid:", sp_name));
assert(!length(intersect(inn$training, inn$validation)) &&                  setequal(c(inn$training, inn$validation), tr),                paste("Inner patient partition is invalid:", sp_name));
check_partition(inn$training, paste(sp_name, "inner training", j));
check_partition(inn$validation, paste(sp_name, "inner validation", j))       }     };
repeat_ids <- vapply(strsplit(split_names, "_", fixed = TRUE), `[`,                          character(1), 1L);
for (rp in unique(repeat_ids)) {       ids_rp <- unlist(lapply(cv$splits[repeat_ids == rp], `[[`, "outer_test"),                        use.names = FALSE);
assert(!anyDuplicated(ids_rp) && setequal(ids_rp, patient_ids),              paste("Outer test folds do not partition patients in repeat", rp))     };
raw_nodesizes <- rsf_spec$nodesize; assert(is.numeric(raw_nodesizes) && length(raw_nodesizes) > 0L &&
       all(is.finite(raw_nodesizes)) && all(raw_nodesizes > 0) && all(raw_nodesizes <= .Machine$integer.max) &&
       all(raw_nodesizes == floor(raw_nodesizes)) && !anyDuplicated(raw_nodesizes),
       "Locked RSF node sizes must be nonempty, unique positive integers.")
ntree <- as.integer(rsf_spec$ntree); nodesizes <- as.integer(raw_nodesizes);
make_mtry <- function(p) unique(pmax(1L, pmin(p,       as.integer(floor(c(sqrt(p), p / 3))))));
count_training_features <- function(patient_ids) {
   ix <- match(patient_ids, meta$Patient_ID);
raw <- expr[ids, meta$Matrix_Column_ID[ix], drop = FALSE]; sdv <- apply(raw, 1L, stats::sd);
n <- sum(is.finite(sdv) & sdv > minimum_sd);
if (n < 2L) stop("Fewer than two variable genes in training partition.",                         call. = FALSE);
n     };
fit_rsf <- function(train_x, train_meta, mtry, nodesize, seed,                         compute_importance = FALSE) {
  
dat <- as.data.frame(t(train_x), check.names = FALSE); dat$OBS_Days <- train_meta$OBS_Days;
dat$Event <- as.integer(train_meta$Event);
rsf_formula <- stats::as.formula("Surv(OBS_Days, Event) ~ .", env = asNamespace("survival")); withCallingHandlers(randomForestSRC::rfsrc(formula = rsf_formula, data = dat, ntree = ntree, nodesize = nodesize, mtry = mtry, splitrule = "logrank", importance = if (compute_importance) "permute" else FALSE, forest = TRUE, seed = -abs(as.integer(seed))), warning = function(w) {
   warnings_collected <<- c(warnings_collected, paste0("[", warning_context, "] RSF fit warning: ", conditionMessage(w))); stop("RSF fit warning invalidates this candidate or fold: ", conditionMessage(w), call. = FALSE) })     };
predict_survival <- function(fit, test_x) {
   nd <- as.data.frame(t(test_x), check.names = FALSE);
pr <- predict(fit, newdata = nd);
assert(!is.null(pr$survival) && !is.null(pr$time.interest),              "RSF prediction lacks survival estimates or time grid.");
assert(nrow(pr$survival) == nrow(nd),              "RSF predictions do not match test patient order.");
list(object = pr, survival = pr$survival, times = pr$time.interest)     };
fit_scaled <- function(training_ids, prediction_ids, mtry, nodesize, seed,                            compute_importance = FALSE) {
  
ti <- match(training_ids, meta$Patient_ID); pi <- match(prediction_ids, meta$Patient_ID);
assert(!anyNA(ti) && !anyNA(pi), "Fold patient IDs do not map to metadata.");
train_raw <- expr[ids, meta$Matrix_Column_ID[ti], drop = FALSE];
pred_raw <- expr[ids, meta$Matrix_Column_ID[pi], drop = FALSE]; sds <- apply(train_raw, 1L, stats::sd);
usable <- ids[is.finite(sds) & sds > minimum_sd];
if (length(usable) < 2L) stop("Fewer than two variable genes in training fold.");
scaler <- scaling$fit_on_training_fold(train_raw, feature_ids = usable)
x_train <- scaling$apply_frozen_scaler(train_raw, scaler, cohort = "TCGA-SKCM")
x_pred <- scaling$apply_frozen_scaler(pred_raw, scaler, cohort = "TCGA-SKCM")
validate_scaled <- function(x, expected_samples, label) {
    assert(is.matrix(x) && is.numeric(x) && identical(dim(x), c(length(usable), length(expected_samples))),
           paste(label, "must have expected numeric dimensions."))
    assert(identical(rownames(x), usable) && identical(colnames(x), expected_samples),
           paste(label, "gene or patient names/order differ from fold inputs."))
    assert(all(is.finite(x)), paste(label, "contains NA, NaN, or infinite values.")); x
}
x_train <- validate_scaled(x_train, colnames(train_raw), "Scaled training data")
  x_pred <- validate_scaled(x_pred, colnames(pred_raw), "Scaled prediction data")
  fit <- fit_rsf(x_train, meta[ti, , drop = FALSE], mtry, nodesize, seed,
                 compute_importance)
list(fit = fit, scaler = scaler, train_x = x_train, pred_x = x_pred,            usable_features = usable, prediction = predict_survival(fit, x_pred))     };
inner_uno <- function(training_ids, validation_ids, seed, mtry, nodesize) {
  
z <- fit_scaled(training_ids, validation_ids, mtry, nodesize, seed);
vm <- meta[match(validation_ids, meta$Patient_ID), , drop = FALSE];
tm <- meta[match(training_ids, meta$Patient_ID), , drop = FALSE]; pred <- z$prediction$object;
s_tau <- survival_at(pred, tau, nrow(vm));
if (length(s_tau) != nrow(vm) || any(!is.finite(s_tau)))         return(metric_record("IPCW_Uno_C", reason = "Primary-horizon survival prediction is unsupported."));
km <- km_censor(tm$OBS_Days, tm$Event); uno_c(vm$OBS_Days, vm$Event, 1 - s_tau, km, tau)     };
tuning_rows <- list(); outer_models <- list(); oof_rows <- list(); fold_rows <- list();
importance_rows <- list(); warning_context <- "analysis";
for (sp_name in split_names) {       sp <- cv$splits[[sp_name]]; outer_training <- sp$outer_training;
outer_test <- sp$outer_test; n_inner <- length(sp$inner);
grid <- expand.grid(mtry_rule = c("sqrt_p", "p_div_3"), nodesize = nodesizes,                           KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE);
grid$ntree <- ntree; grid$Outer_Split <- sp_name; grid$Candidate_ID <- seq_len(nrow(grid));
grid$Mean_Inner_Uno_C <- NA_real_; grid$Valid_Inner_Folds <- 0L; grid$Inner_Folds <- n_inner;
grid$Candidate_Status <- "NOT_ESTIMABLE"; grid$Inner_Failure_Reasons <- ""; grid$Selected <- FALSE;
for (g in seq_len(nrow(grid))) {         vals <- rep(NA_real_, n_inner); reasons <- rep("", n_inner);
for (j in seq_len(n_inner)) {           warning_context <- paste("inner", sp_name, j, "candidate", g);
inn <- sp$inner[[j]]; seed <- as.integer(sp$inner_seed + 1000L * g + j);
p_inner <- count_training_features(inn$training); mtry_values <- make_mtry(p_inner);
mtry_index <- if (grid$mtry_rule[g] == "sqrt_p") 1L else 2L;
mtry_value <- mtry_values[min(mtry_index, length(mtry_values))];
got <- tryCatch(inner_uno(inn$training, inn$validation, seed,                                     mtry_value, grid$nodesize[g]),                           error = function(e) metric_record("IPCW_Uno_C",                             reason = paste("Fit/evaluation failed:", conditionMessage(e))));
if (identical(got$Status, "ESTIMABLE")) vals[j] <- got$Estimate; reasons[j] <- got$Reason;
tuning_rows[[length(tuning_rows) + 1L]] <- data.frame(             Outer_Split = sp_name, Candidate_ID = g, Inner_Fold = j,             Mtry_Rule = grid$mtry_rule[g], Mtry = mtry_value,             Node_Size = grid$nodesize[g], Ntree = ntree, Seed = seed,             Uno_C = got$Estimate, Metric_Status = got$Status,             Reason = got$Reason, Mean_Inner_Uno_C = NA_real_,             Valid_Inner_Folds = NA_integer_, Inner_Folds = n_inner,             Selected = NA, stringsAsFactors = FALSE           )         };
grid$Mean_Inner_Uno_C[g] <- if (all(is.finite(vals))) mean(vals) else NA_real_;
grid$Valid_Inner_Folds[g] <- sum(is.finite(vals)); grid$Inner_Folds <- n_inner;
grid$Candidate_Status[g] <- if (all(is.finite(vals))) "VALID" else "NOT_ESTIMABLE";
grid$Inner_Failure_Reasons[g] <- paste(unique(reasons[nzchar(reasons)]),                                                collapse = " | ")       };
valid_grid <- which(grid$Candidate_Status == "VALID" & is.finite(grid$Mean_Inner_Uno_C));
if (!length(valid_grid)) {
  reason_text <- paste(paste0(grid$mtry_rule, "/nodesize=", grid$nodesize,
                              ": ", grid$Inner_Failure_Reasons), collapse = " || ")
  stop("No valid inner-CV candidate for ", sp_name,
       ". Candidate diagnostics: ", reason_text, call. = FALSE)
}
rule_priority <- match(grid$mtry_rule, c("sqrt_p", "p_div_3"));
best <- valid_grid[order(-grid$Mean_Inner_Uno_C[valid_grid],                                -grid$nodesize[valid_grid],                                rule_priority[valid_grid])[1L]];
grid$Selected[best] <- TRUE; p_outer <- count_training_features(outer_training);
outer_mtrys <- make_mtry(p_outer);
outer_mtry <- outer_mtrys[min(         if (grid$mtry_rule[best] == "sqrt_p") 1L else 2L,         length(outer_mtrys)       )];
grid$Outer_Mtry <- NA_integer_; grid$Outer_Mtry[best] <- outer_mtry;
for (g in seq_len(nrow(grid))) {         tuning_rows[[length(tuning_rows) + 1L]] <- data.frame(           Outer_Split = sp_name, Candidate_ID = g, Inner_Fold = NA_integer_,           Mtry_Rule = grid$mtry_rule[g],           Mtry = if (g == best) outer_mtry else NA_integer_,           Node_Size = grid$nodesize[g], Ntree = ntree,           Seed = if (g == best) as.integer(sp$outer_seed) else NA_integer_,           Uno_C = grid$Mean_Inner_Uno_C[g], Metric_Status = grid$Candidate_Status[g],           Reason = if (grid$Selected[g]) "Selected by locked inner-CV rule" else             grid$Inner_Failure_Reasons[g], Mean_Inner_Uno_C = grid$Mean_Inner_Uno_C[g],           Valid_Inner_Folds = grid$Valid_Inner_Folds[g], Inner_Folds = n_inner,           Selected = grid$Selected[g],           stringsAsFactors = FALSE         )       };
warning_context <- paste("outer", sp_name, "selected model"); outer_seed <- as.integer(sp$outer_seed);
z <- fit_scaled(outer_training, outer_test, outer_mtry,                       grid$nodesize[best], outer_seed, compute_importance = TRUE);
tm <- meta[match(outer_training, meta$Patient_ID), , drop = FALSE];
vm <- meta[match(outer_test, meta$Patient_ID), , drop = FALSE]; km <- km_censor(tm$OBS_Days, tm$Event);
pred_obj <- z$prediction$object; surv_h <- lapply(horizons, function(h) survival_at(pred_obj, h, nrow(vm)));
names(surv_h) <- as.character(horizons); for (h in horizons) {         v <- surv_h[[as.character(h)]];
if (length(v) != nrow(vm)) stop("Prediction count mismatch in ", sp_name);
if (any(is.finite(v) & (v < 0 | v > 1)))           stop("Survival prediction outside [0,1] in ", sp_name)       };
risk_tau <- 1 - survival_at(pred_obj, tau, nrow(vm));
assert(length(risk_tau) == nrow(vm), paste("Risk score count mismatch in", sp_name));
pred_df <- data.frame(         Patient_ID = vm$Patient_ID, Sample_ID = vm$Sample_ID,         Outer_Split = sp_name,         Repeat = as.integer(strsplit(sp_name, "_", fixed = TRUE)[[1]][1]),         Outer_Fold = as.integer(strsplit(sp_name, "_", fixed = TRUE)[[1]][2]),         OBS_Days = vm$OBS_Days, Event = as.integer(vm$Event),         Risk_Score = risk_tau,         Risk_Score_Status = ifelse(is.finite(risk_tau), "ESTIMABLE", "NOT_ESTIMABLE"),         Risk_Score_Reason = ifelse(is.finite(risk_tau), "",           "Survival estimate unavailable at the locked primary horizon."),         stringsAsFactors = FALSE       );
for (h in horizons) pred_df[[paste0("Predicted_Survival_", h)]] <-         surv_h[[as.character(h)]];
oof_rows[[sp_name]] <- pred_df; for (h in horizons) {         perf <- performance_for(pred_df, km, h, tau);
for (r in seq_len(nrow(perf))) {           fold_rows[[length(fold_rows) + 1L]] <- data.frame(             Outer_Split = sp_name, Repeat = pred_df$Repeat[1L],             Outer_Fold = pred_df$Outer_Fold[1L], Horizon_Days = h,             Metric = perf$Metric[r], Estimate = perf$Estimate[r],             Metric_Status = perf$Status[r], Reason = perf$Reason[r],             Patients = nrow(vm), Events = sum(vm$Event == 1),             Censored = sum(vm$Event == 0), stringsAsFactors = FALSE           )         }       };
imp <- z$fit$importance;
if (is.matrix(imp)) {
  if (nrow(imp) == length(z$usable_features)) {
    bad_count <- rowSums(!is.finite(imp)); imp <- rowMeans(imp)
  } else if (ncol(imp) == length(z$usable_features)) {
    bad_count <- colSums(!is.finite(imp)); imp <- colMeans(imp)
  } else stop("RSF importance dimensions do not match fitted genes.");
} else {
  bad_count <- as.integer(!is.finite(imp)); names(bad_count) <- names(imp)
};
assert(length(imp) == length(z$usable_features) && !is.null(names(imp)) &&
       !anyDuplicated(names(imp)) && setequal(names(imp), z$usable_features),
       paste("Invalid RSF importance mapping:", sp_name));
imp <- imp[z$usable_features]; bad_count <- bad_count[z$usable_features];
assert(!anyNA(bad_count), "RSF invalid-importance counts are not mapped.");
imp[!is.finite(imp)] <- NA_real_;
mapped_gene_ids <- feature_table$Gene_ID[         match(names(imp), feature_table$TCGA_Source_Feature_ID)       ];
assert(!anyNA(mapped_gene_ids) && !anyDuplicated(mapped_gene_ids),              paste("Variable importance failed gene-ID mapping in", sp_name));
importance_rows[[sp_name]] <- data.frame(
  Outer_Split = sp_name, Gene_ID = mapped_gene_ids,
  Importance = as.numeric(imp),
  Importance_Status = ifelse(is.finite(imp), "ESTIMABLE", "NOT_ESTIMABLE"),
  Invalid_Components = as.integer(bad_count), stringsAsFactors = FALSE);
outer_models[[sp_name]] <- list(         fit = z$fit, scaler = z$scaler, selected_features = z$usable_features,         selected_hyperparameters = grid[best, , drop = FALSE],         training_patient_ids = outer_training, test_patient_ids = outer_test,         censoring_km = km, seed = outer_seed       )     }
oof <- do.call(rbind, oof_rows); rownames(oof) <- NULL; fold_performance <- do.call(rbind, fold_rows);
tuning_table <- do.call(rbind, tuning_rows); importance_fold <- do.call(rbind, importance_rows);
imp_genes <- feature_table$Gene_ID; imp_expanded <- do.call(rbind, lapply(imp_genes, function(g) {
  
vals <- ranks <- numeric(0);
for (f in split_names) {         ff <- importance_fold[importance_fold$Outer_Split == f, , drop = FALSE];
hit <- match(g, ff$Gene_ID); if (!is.na(hit)) {           vals <- c(vals, ff$Importance[hit]);
ranks <- c(ranks, rank(-ff$Importance, ties.method = "average", na.last = "keep")[hit])         }       };
data.frame(Gene_ID = g,         Mean_Importance = if (length(vals)) mean(vals) else NA_real_,         SD_Importance = if (length(vals) > 1L) stats::sd(vals) else NA_real_,         Positive_Fold_Fraction = if (length(vals)) mean(vals > 0) else NA_real_,         Folds_Ranked = length(vals),         Mean_Importance_Rank = if (length(ranks)) mean(ranks) else NA_real_,         stringsAsFactors = FALSE)     }));
imp_expanded <- merge(feature_table[, c("Gene_ID", "Gene_Symbol", "Locked_Order")],                           imp_expanded, by = "Gene_ID", all.y = TRUE, sort = FALSE);
imp_expanded$Invalid_Folds <- vapply(imp_expanded$Gene_ID, function(g) sum(importance_fold$Gene_ID == g & importance_fold$Importance_Status == "NOT_ESTIMABLE"), integer(1));
imp_expanded$Fully_Verified_Development_Eligibility <- fully_verified[match(imp_expanded$Gene_ID, feature_table$Gene_ID)];
metric_rows <- fold_performance[fold_performance$Metric == "IPCW_Uno_C" &                                       fold_performance$Horizon_Days == tau, , drop = FALSE];
valid_primary <- metric_rows$Estimate[metric_rows$Metric_Status == "ESTIMABLE" &                                             is.finite(metric_rows$Estimate)];
primary_all_valid <- length(valid_primary) == n_outer * n_repeats;
result_summary <- data.frame(       Metric = c("Patients", "Events", "Censored", "Candidate_Genes",                  "Outer_Folds", "Outer_Repeats", "Primary_Metric",                  "Primary_Horizon_Days", "Mean_Fold_IPCW_Uno_C",                  "Primary_Metric_Status", "Primary_Folds_Estimable",                  "Endpoint", "Event_Definition", "Time_Origin", "OBS_Formula",                  "Endpoint_Source_Status",                  "External_Evaluation_Status", "Feature_Annotation_Status",                  "Scaling_Reference_Status", "Development_Source_Model_Ready",                  "Development_Source_Review_Status", "Uncertainty_Limitation"),       Value = NA_character_, stringsAsFactors = FALSE     );
result_summary$Value <- c(       nrow(meta), sum(meta$Event == 1), sum(meta$Event == 0), length(ids),       n_outer, n_repeats, "IPCW Uno C", tau,       if (primary_all_valid) mean(valid_primary) else NA_real_,       if (primary_all_valid) "ESTIMABLE" else "NOT_ESTIMABLE",       length(valid_primary),       sap$endpoint, sap$event, sap$time_origin, sap$formula,       development$primary_endpoint$status,       "NOT_PERFORMED; requires compatible external predictors and endpoint/time origin",       verification_status,       scaling$reference_status, development$model_ready,       development$scientific_review_status,       "Bootstrap intervals use fixed OOF predictions and do not include model refitting."     );
set.seed(as.integer(protocol$Seed)); fold_ids <- unique(oof$Outer_Split);
metric_keys <- unique(fold_performance[, c("Metric", "Horizon_Days")]); bootstrap_rows <- list();
for (k in seq_len(nrow(metric_keys))) {       metric <- metric_keys$Metric[k];
horizon <- metric_keys$Horizon_Days[k];
original <- fold_performance[fold_performance$Metric == metric &         fold_performance$Horizon_Days == horizon, , drop = FALSE];
all_folds_valid <- nrow(original) == length(fold_ids) &&         all(original$Metric_Status == "ESTIMABLE" & is.finite(original$Estimate));
boot <- rep(NA_real_, 1000L); for (b in if (all_folds_valid) seq_len(1000L) else integer(0)) {
  
fold_est <- numeric(0); for (f in fold_ids) {           fd <- oof[oof$Outer_Split == f, , drop = FALSE];
ix <- sample(seq_len(nrow(fd)), nrow(fd), replace = TRUE);
met <- performance_for(fd[ix, , drop = FALSE],             outer_models[[f]]$censoring_km, horizon, tau);
hit <- which(met$Metric == metric);
if (length(hit) == 1L && identical(met$Status[hit], "ESTIMABLE") && is.finite(met$Estimate[hit])) fold_est <- c(fold_est, met$Estimate[hit])         };
if (length(fold_est) == length(fold_ids)) boot[b] <- mean(fold_est)       }; bv <- boot[is.finite(boot)];
ci <- if (length(bv) >= 950L) stats::quantile(bv, c(.025, .975), names = FALSE) else c(NA, NA);
bootstrap_rows[[k]] <- data.frame(         Metric = metric, Horizon_Days = horizon, Replicates = 1000L,         Valid = length(bv), Invalid = 1000L - length(bv),         CI_Method = "Patient bootstrap within outer fold; fixed OOF predictions",         CI_Lower = if (all_folds_valid) ci[1L] else NA_real_,         CI_Upper = if (all_folds_valid) ci[2L] else NA_real_,         Status = if (all_folds_valid && length(bv) >= 950L) "ESTIMABLE" else "NOT_ESTIMABLE",         stringsAsFactors = FALSE       )     };
bootstrap_summary <- do.call(rbind, bootstrap_rows);
for (k in seq_len(nrow(metric_keys))) {       key <- metric_keys$Metric[k]; hz <- metric_keys$Horizon_Days[k];
ff <- fold_performance[fold_performance$Metric == key &         fold_performance$Horizon_Days == hz, , drop = FALSE];
valid <- ff$Metric_Status == "ESTIMABLE" & is.finite(ff$Estimate);
all_valid <- nrow(ff) == length(fold_ids) && all(valid); bs <- bootstrap_summary[k, ];
nm <- paste0("Fold_Mean_", key, "_Horizon_", hz);
add <- data.frame(Metric = c(nm, paste0(nm, "_Status"),         paste0(nm, "_Valid_Folds"), paste0(nm, "_CI_Lower"),         paste0(nm, "_CI_Upper"), paste0(nm, "_Bootstrap_Valid")),         Value = c(if (all_valid) mean(ff$Estimate) else NA_real_,           if (all_valid) "ESTIMABLE" else "NOT_ESTIMABLE", sum(valid),           bs$CI_Lower, bs$CI_Upper, bs$Valid), stringsAsFactors = FALSE);
result_summary <- rbind(result_summary, add)     };
result_rds <- list(       task_id = task_id, status = "SUCCESS", summary = result_summary,       endpoint = sap[sap_fields],       bootstrap = bootstrap_summary, fold_performance = fold_performance,       oof_predictions = oof, hyperparameter_tuning = tuning_table,       importance_fold = importance_fold, importance_stability = imp_expanded,       feature_verification = data.frame(Gene_ID = feature_table$Gene_ID, Fully_Verified_Development_Eligibility = fully_verified), input_md5 = md5_now, input_hash_audit = input_hash_audit, protocol = protocol[c("Seed", "Outer_Folds",         "Outer_Repeats", "Horizons_Days", "Primary_Metric",         "Primary_Proposed_Tau_Days", "Algorithms", "Mtry_Rule", "Uncertainty")],       limitations = c("External evaluation was not performed in this task.",         "Fold-wise metrics are the primary interpretation; risk scores may differ in scale across fitted forests.",         "Variable importance may be unstable among correlated genes.",         "Feature annotation eligibility in the supplied source remains provisional.",         paste("Development source readiness:", development$model_ready,               development$scientific_review_status))     );
utils::write.csv(result_summary, output_paths[["results_csv"]], row.names = FALSE, na = "");
saveRDS(result_rds, output_paths[["results_rds"]], compress = "xz");
saveRDS(list(outer_models = outer_models, tuning = tuning_table,                  protocol = result_rds$protocol, input_md5 = md5_now,                  endpoint = result_rds$endpoint),             output_paths[["model_rds"]], compress = "xz");
utils::write.csv(imp_expanded, output_paths[["importance_csv"]], row.names = FALSE, na = "");
saveRDS(imp_expanded, output_paths[["importance_rds"]], compress = "xz");
utils::write.csv(oof, output_paths[["oof_csv"]], row.names = FALSE, na = "");
utils::write.csv(fold_performance, output_paths[["fold_csv"]], row.names = FALSE, na = "");
utils::write.csv(tuning_table, output_paths[["tuning_csv"]], row.names = FALSE, na = "");
data_paths <- output_paths[!names(output_paths) %in% c("session_info", "execution_log")]
assert(all(file.exists(data_paths)) && all(file.info(data_paths)$size > 0),
       "One or more data outputs were not written or are empty.")
invisible(utils::read.csv(output_paths[["results_csv"]], check.names = FALSE))
invisible(readRDS(output_paths[["results_rds"]]))
invisible(readRDS(output_paths[["model_rds"]]))
invisible(utils::read.csv(output_paths[["importance_csv"]], check.names = FALSE))
invisible(readRDS(output_paths[["importance_rds"]]))
invisible(utils::read.csv(output_paths[["oof_csv"]], check.names = FALSE))
invisible(utils::read.csv(output_paths[["fold_csv"]], check.names = FALSE))
invisible(utils::read.csv(output_paths[["tuning_csv"]], check.names = FALSE))
task_status <- "SUCCESS"
  }, warning = function(w) {
  
warnings_collected <<- c(warnings_collected,                              paste0("[", warning_context, "] ", conditionMessage(w)));
invokeRestart("muffleWarning")   }),   error = function(e) {
   task_status <<- "FAILED";
error_message <<- redact_text(conditionMessage(e)); message("Task failed: ", error_message)   },   finally = {
  
task_end_time <- Sys.time();
tryCatch(write_reproducibility_outputs(       output_paths[["session_info"]], output_paths[["execution_log"]],       task_status, task_start_time, task_end_time,       warnings_collected, error_message     ), error = function(e) {
  
task_status <<- "FAILED"; error_message <<- redact_text(paste(error_message, conditionMessage(e)));
try(write_execution_log(output_paths[["execution_log"]], "FAILED",         task_start_time, Sys.time(), warnings_collected, error_message), silent = TRUE)     })   } );if (identical(task_status, "SUCCESS")) {   report_ok <- all(file.exists(output_paths)) &&     all(file.info(output_paths)$size > 0) &&     any(grepl("^Status: SUCCESS$",       readLines(output_paths[["execution_log"]], warn = FALSE)));
if (!report_ok) {     task_status <- "FAILED";
error_message <- "Post-write verification failed for one or more outputs.";
try(write_reproducibility_outputs(output_paths[["session_info"]],       output_paths[["execution_log"]], task_status, task_start_time, Sys.time(),       warnings_collected, error_message), silent = TRUE)   } };if (!identical(task_status, "SUCCESS")) {   stop("Task execution failed. Review the Session_Info and Execution_Log.",        call. = FALSE) };
message("AUDIT_COMPLETED")
message("Warnings recorded: ", length(unique(warnings_collected)))
message("Session_Info: ", basename(output_paths[["session_info"]]))
message("Execution_Log: ", basename(output_paths[["execution_log"]]))
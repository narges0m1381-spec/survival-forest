# ==============================================================================
# Project:

From Metastatic Progression to Prognosis: Multi-Cohort Transcriptomic Replication, Multi-Omics Prioritization, Single-Cell Localization, and Pre-Specified External Validation of a Machine-Learning Model in Cutaneous Melanoma

# Task:

T5.4.3 — Develop and Internally Evaluate the Random Survival Forest Model 

## Input Files

1. `261017_T5.1.2_TCGA_Development_Data_Results_Ameneh_Hashemzehi_Human.rds`
2. `261018_T5.2.1_Progression_Features_Results_Ameneh_Hashemzehi_Human.rds`
3. `261018_T5.2.2_Molecular_Scaling_Model_Ameneh_Hashemzehi_Human.rds`
4. `261021_T5.3.1_Nested_CV_Lock_Results_Ameneh_Hashemzehi_Human.rds`

## Output Files

1. `261025_T5.4.3_Survival_Forest_Results_Narges_Omidian_Human.csv`
2. `261025_T5.4.3_Survival_Forest_Results_Narges_Omidian_Human.rds`
3. `261025_T5.4.3_Survival_Forest_Model_Narges_Omidian_Human.rds`
4. `261025_T5.4.3_Survival_Forest_Table_RSF_Importance_Stability_Narges_Omidian_Human.csv`
5. `261025_T5.4.3_Survival_Forest_Table_RSF_Importance_Stability_Narges_Omidian_Human.rds`
6. `261025_T5.4.3_Survival_Forest_Table_OOF_Predictions_Narges_Omidian_Human.csv`
7. `261025_T5.4.3_Survival_Forest_Table_Fold_Performance_Narges_Omidian_Human.csv`
8. `261025_T5.4.3_Survival_Forest_Table_RSF_Tuning_Narges_Omidian_Human.csv`
9. `261025_T5.4.3_Survival_Forest_Session_Info_Narges_Omidian_Human.txt`
10. `261025_T5.4.3_Survival_Forest_Execution_Log_Narges_Omidian_Human.txt`
11. `261025_T5.4.3_Survival_Forest_Script_Narges_Omidian_Human.R`
12. `261025_T5.4.3_Survival_Forest_README_Narges_Omidian_Human.md`

# File Storage and Availability:

**Milestone folder:** `05_Survival_Data_Preparation_Feature_Selection_and_Prognostic_Model_Development`

**Zenodo:** [Open milestone folder](https://zenodo.org/uploads/21855729)

# Author:

Narges Omidian  

# Date:

 2026-10-25

# ==============================================================================

## Methods

A Random Survival Forest was fitted to 337 metastatic TCGA-SKCM patients (179 events and 158 censored) using 325 progression-associated candidate genes.

The analysis followed five locked outer folds and nested inner cross-validation. Gene filtering and scaling were fitted within training partitions. Inner folds evaluated `sqrt(p)` and `p/3` mtry rules with minimum node sizes of 5 and 15. Forests used 500 trees, log-rank splitting and seed `20260802`.

Patient-level out-of-fold (OOF) predictions were evaluated using IPCW Uno's C, time-dependent AUC and Brier score at 365.25, 1,095.75 and 1,826.25 days. The primary metric was IPCW Uno's C at 1,095.75 days. Permutation-based variable importance was summarized across outer folds.

## Results

All 337 patients received one OOF prediction. Four outer folds selected `sqrt(p)` with `mtry = 18`; one selected `p/3` with `mtry = 108`. All five selected a node size of 15.

**Internal cross-validation performance**

| Horizon (days) | Uno's C (95% CI) | AUC (95% CI) | Brier (95% CI) |
|---|---|---|---|
| 365.25 | 0.651 (0.587–0.708) | 0.681 (0.614–0.743) | 0.182 (0.161–0.201) |
| 1,095.75 | **0.633 (0.587–0.683)** | 0.664 (0.593–0.735) | 0.230 (0.205–0.258) |
| 1,826.25 | 0.637 (0.594–0.683) | 0.676 (0.585–0.764) | 0.216 (0.178–0.257) |

Values are means across the five outer folds. Confidence intervals are percentile intervals from within-fold patient bootstrap resampling of fixed OOF predictions.

## Quality Control

- All 337 patient IDs matched the locked cohort and outer test partitions, without duplicates or training–test overlap.
- All four input MD5 hashes matched the recorded values.
- OOF survival probabilities were finite, within [0, 1], and non-increasing across evaluation horizons.
- All 45 fold-level performance estimates were estimable.
- All nine bootstrap intervals used 1,000 valid resamples.
- Variable importance covered all 325 genes, with no invalid fold-level estimates.
- CSV outputs matched their corresponding RDS data after explicit CSV column-type handling.
- Execution completed successfully in **664.23 seconds**, with no recorded warnings or errors. The session report recorded R 4.6.0 and `randomForestSRC` 3.6.2.

## Limitations

The development cohort retains a pending scientific-approval status for its endpoint, and its model-readiness flag is `FALSE`. All 325 candidate genes have `Fully_Verified_Development_Eligibility = FALSE`; their annotation eligibility remains provisional. The scaling reference is also marked as provisional QC.

Variable importance may be unstable among correlated genes. Bootstrap confidence intervals reflect uncertainty in the fixed OOF predictions rather than uncertainty from refitting the forests.

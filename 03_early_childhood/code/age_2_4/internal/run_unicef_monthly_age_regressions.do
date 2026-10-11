version 18.0
clear all
set more off
set varabbrev off


local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local master_dir "`project_root'/age 2-4 mechanism/master do files"
local unicef_root "`project_root'/age 2-4 mechanism/UNICEF Development"
local sample_dta "`master_dir'/age2_4_regression_sample.dta"
local all_outcomes_dta "`master_dir'/age2_4_all_outcomes_sample.dta"
local engine "`c(pwd)'/03_early_childhood/code/age_2_4/internal/run_family_ols_rdd.do"
local article_exporter "`master_dir'/00_export_article_style_word_table.do"
local family_exporter "`master_dir'/00_export_family_word_table.do"

capture log close unicef_monthly
log using "`master_dir'/04_run_unicef_monthly_age_regressions.log", ///
    text replace name(unicef_monthly)

local task_dir "`unicef_root'/1 UNICEF on-track dummy"
use "`sample_dta'", clear
do "`engine'" "unicef_ontrack" ///
    "`task_dir'/unicef_ontrack_monthly_age_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`article_exporter'" ///
    "`task_dir'/unicef_ontrack_monthly_age_rdd_results.dta" ///
    "`task_dir'/unicef_ontrack_monthly_age_rdd_table_bw4_8.docx" ///
    "1M" ///
    "Reduced-Form Effects on UNICEF Age-Specific Developmentally On-Track Status: Monthly Child-Age Controls" ///
    "ontrack" "monthly"

local task_dir "`unicef_root'/2 Total development score"
use "`sample_dta'", clear
do "`engine'" "score_total_20" ///
    "`task_dir'/total_score_monthly_age_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`article_exporter'" ///
    "`task_dir'/total_score_monthly_age_rdd_results.dta" ///
    "`task_dir'/total_score_monthly_age_rdd_table_bw4_8.docx" ///
    "2M" ///
    "Reduced-Form Effects on the Total Development Score: Monthly Child-Age Controls" ///
    "total" "monthly"

local task_dir "`unicef_root'/3 Development domain scores"
local outcomes domain_health domain_learning domain_psychosocial
use "`all_outcomes_dta'", clear
do "`engine'" "`outcomes'" ///
    "`task_dir'/domain_scores_monthly_age_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`family_exporter'" ///
    "`task_dir'/domain_scores_monthly_age_rdd_results.dta" ///
    "`task_dir'/domain_scores_monthly_age_rdd_table_bw4_8.docx" ///
    "3M" ///
    "Reduced Form Effects on Development Domain Scores: Monthly Child-Age Controls" ///
    "Higher domain scores indicate more favourable development."

log close unicef_monthly
display as result "Additional UNICEF monthly-age regressions completed."
clear

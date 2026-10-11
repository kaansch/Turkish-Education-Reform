version 18.0
clear all
set more off
set varabbrev off

args age_tag

local root "C:/Users/Kaan Cil/Desktop/microdata/0-5-6 age"
local age_num = substr("`age_tag'", 3, 1)
local sample "`root'/`age_tag' age/Reference microdata/regression_sample_age0_`age_num'.dta"
local engine "`c(pwd)'/03_early_childhood/code/age_0_6/internal/run_family_ols_rdd.do"
local exporter "`root'/do files/00_export_family_word_table.do"
local output_root "`root'/`age_tag' age"
capture log close
log using "`output_root'/run_regressions.log", text replace

local task "`output_root'/WHO Anthropometric Development/14 Height and weight"
local outcomes weight_kg_all height_cm_all
use "`sample'", clear
do "`engine'" "`outcomes'" "`task'/height_weight_rdd_results.dta" "monthly" "child_weight" "6"
do "`exporter'" "`task'/height_weight_rdd_results.dta" ///
    "`task'/height_weight_rdd_table_bw4_8.docx" "14" ///
    "Reduced Form Effects on Weight and Height for Ages `age_tag'" ///
    "The child cohort is based on complete birth dates on 16 December 2022. Reported KILO and BOY are in their original units."

local task "`output_root'/WHO Anthropometric Development/15 WHO anthropometrics clinical"
local outcomes who_haz who_waz who_whz who_bmiz who_stunted ///
    who_underweight who_wasted who_overweight who_obese who_ciaf ///
    who_below_bmiz who_bmi_overweight_5plus who_bmi_obese_5plus ///
    who_bmi_thin_5plus
use "`sample'", clear
do "`engine'" "`outcomes'" "`task'/who_clinical_rdd_results.dta" "monthly" "child_weight" "6"
do "`exporter'" "`task'/who_clinical_rdd_results.dta" ///
    "`task'/who_clinical_rdd_table_bw4_8.docx" "15" ///
    "Reduced Form Effects on WHO Anthropometric Outcomes for Ages `age_tag'" ///
    "WHO 2006 covers months 0-60 and WHO 2007 covers months 61 onward. Weight-for-length/height and related classifications are available through month 60 only."

local task "`output_root'/Nutrition Frequency/9 Nutrition weekly"
local outcomes nutrition_weekly_fruit nutrition_weekly_vegetables ///
    nutrition_weekly_meatfish nutrition_weekly_legumes ///
    nutrition_weekly_animalprod nutrition_weekly_sweets ///
    nutrition_weekly_snacks nutrition_weekly_softdrink ///
    nutrition_weekly_grains nutrition_ever_breastfed
use "`sample'", clear
do "`engine'" "`outcomes'" "`task'/nutrition_weekly_rdd_results.dta" "monthly" "child_weight" "6"
do "`exporter'" "`task'/nutrition_weekly_rdd_results.dta" ///
    "`task'/nutrition_weekly_rdd_table_bw4_8.docx" "9" ///
    "Reduced Form Effects on Weekly Nutrition for Ages `age_tag'" ///
    "Food outcomes require an age above six months and recorded codes 1-9. Ever breastfed uses recorded codes 1 and 2."

local task "`output_root'/Nutrition Frequency/10 Nutrition strict frequency"
local outcomes nutrition_strict_fruit nutrition_strict_vegetables ///
    nutrition_strict_meatfish nutrition_strict_legumes ///
    nutrition_strict_animalprod nutrition_strict_sweets ///
    nutrition_strict_snacks nutrition_strict_softdrink ///
    nutrition_strict_grains
use "`sample'", clear
do "`engine'" "`outcomes'" "`task'/nutrition_strict_rdd_results.dta" "monthly" "child_weight" "6"
do "`exporter'" "`task'/nutrition_strict_rdd_results.dta" ///
    "`task'/nutrition_strict_rdd_table_bw4_8.docx" "10" ///
    "Reduced Form Effects on Frequent Nutrition for Ages `age_tag'" ///
    "Food outcomes require an age above six months and recorded codes 1-9. Codes 1-2 indicate daily or several times weekly consumption."

display as result "Completed mechanism regression tables for `age_tag'."
log close
clear

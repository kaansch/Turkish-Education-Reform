version 18.0
clear all
set more off
set varabbrev off

local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local regression_root "`project_root'/age 2-4 mechanism/master do files"
local archive "`c(pwd)'/03_early_childhood/code/age_2_4/internal"

do "`archive'/prepare_age_2_4_regression_data.do"
do "`archive'/unicef_development/01_unicef_ontrack_regressions.do"
do "`archive'/unicef_development/02_total_score_regressions.do"
do "`archive'/prepare_all_additional_outcomes.do"
do "`archive'/run_all_additional_regressions.do"

display as result "All pooled age-2-4 regressions completed."

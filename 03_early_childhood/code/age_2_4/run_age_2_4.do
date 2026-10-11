version 18.0
clear all
set more off
set varabbrev off

local repo_root "`c(pwd)'"
local internal "`repo_root'/03_early_childhood/code/age_2_4/internal"

do "`internal'/run_all_age_2_4_regressions.do"

display as result "Age 2-4 main mechanism analyses completed."

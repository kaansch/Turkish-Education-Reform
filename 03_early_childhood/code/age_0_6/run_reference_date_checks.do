version 18.0
clear all
set more off
set varabbrev off

local scripts "`c(pwd)'/03_early_childhood/code/age_0_6/internal"
do "`scripts'/run_reference_date_who_regressions.do"
do "`scripts'/run_oldest_child_who_regressions.do"

version 18.0
clear all
set more off
set varabbrev off

local scripts "`c(pwd)'/03_early_childhood/code/age_0_6/internal"
do "`scripts'/run_regressions.do" "0-6"
do "`scripts'/run_rdd_graphs.do" "0-6"
do "`scripts'/run_supplementary_who.do" "0-6"

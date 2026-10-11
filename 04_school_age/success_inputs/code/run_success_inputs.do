version 18.0
clear all
set more off
set varabbrev off

local repo_root "`c(pwd)'"
local internal "`repo_root'/04_school_age/success_inputs/code/internal"
do "`internal'/run_input_regressions.do"
do "`internal'/primary_school_regressions.do"
do "`internal'/plot_input_rdd.do"

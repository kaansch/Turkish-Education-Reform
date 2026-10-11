version 18.0
clear all
set more off
set varabbrev off

local internal "`c(pwd)'/02_sample_selection/code/internal"
do "`internal'/run_systematic_parent_selection.do" "all" "2" "4" "end" "any"

display as result "Any-child sample-selection checks completed."

version 18.0
clear all
set more off
set varabbrev off

args data_root
do "`c(pwd)'/04_school_age/school_success/code/internal/run_success_jobs.do" "`data_root'"

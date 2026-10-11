version 18.0
clear all
set more off
set varabbrev off

args data_root
do "`c(pwd)'/04_school_age/who_anthropometrics/code/internal/run_who_anthropometrics.do" "`data_root'"

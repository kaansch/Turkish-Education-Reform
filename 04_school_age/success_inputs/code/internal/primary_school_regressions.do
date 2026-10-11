version 18.0
clear all
set more off
set varabbrev off
set processors 1

local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local sample_root "`project_root'/school success/Primary school/Reference microdata"
local output_root "`project_root'/age7plus_mechanisms/primary_school_regressions"
local engine "`c(pwd)'/04_school_age/school_success/code/internal/run_family_ols_rdd.do"
local exporter "`project_root'/0-5-6 age/do files/00_export_family_word_table.do"
capture mkdir "`output_root'"
capture log close
log using "`output_root'/run.log", text replace

foreach selection in youngest oldest {
    use "`sample_root'/regression_sample_`selection'.dta", clear

    foreach v of varlist FIILI_SAAT_EVIS HAFTAICI_EGITIM_SAAT HAFTASONU_EGITIM_SAAT {
        capture confirm string variable `v'
        if !_rc destring `v', generate(__n_`v') dpcomma force
        else generate double __n_`v' = `v'
    }

    generate byte __all_household_tasks_no = 1
    foreach v of varlist EVIS_ALISVERIS EVIS_YEMEK EVIS_BULASIK EVIS_CAMASIR ///
        EVIS_COCUK EVIS_YASLI EVIS_SUTASIMA EVIS_YAKACAK EVIS_BASKA {
        replace __all_household_tasks_no = 0 if `v' != "2"
    }
    generate double household_work_hours = __n_FIILI_SAAT_EVIS
    replace household_work_hours = 0 if missing(household_work_hours) & __all_household_tasks_no
    label variable household_work_hours "Weekly household work hours"

    generate double education_hours = __n_HAFTAICI_EGITIM_SAAT + __n_HAFTASONU_EGITIM_SAAT
    label variable education_hours "Weekday plus weekend educational hours"

    local result "`output_root'/primary_school_`selection'_rdd_results.dta"
    local table "`output_root'/primary_school_`selection'_rdd_table.docx"

    do "`engine'" "household_work_hours education_hours" "`result'" "monthly" "child_weight" "6"
    do "`exporter'" "`result'" "`table'" "Primary" ///
        "Reduced Form Effects on Primary School Household Work and Educational Hours" ///
        "The sample contains currently enrolled primary-school children. Household-work hours are coded as zero only when all nine household-task questions are answered no. Educational hours equal weekday plus weekend hours."
}

display as result "Primary-school regression tables complete."
log close
clear

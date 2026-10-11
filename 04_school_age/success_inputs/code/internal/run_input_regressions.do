version 18.0
clear all
set more off
set varabbrev off
set processors 1

args requested_level requested_selection
local levels "Primary Middle High"
local selections "youngest oldest"
if inlist("`requested_level'", "Primary", "Middle", "High") local levels "`requested_level'"
if inlist("`requested_selection'", "youngest", "oldest") local selections "`requested_selection'"

local root "C:/Users/Kaan Cil/Desktop/microdata"
local success "`root'/school success"
local engine "`c(pwd)'/04_school_age/school_success/code/internal/run_family_ols_rdd.do"
local exporter "`root'/0-5-6 age/do files/00_export_family_word_table.do"
local output "`root'/age7plus_mechanisms/school_input_regressions"
capture mkdir "`output'"
capture log close
local logtag "all"
if "`requested_level'" != "" local logtag "`requested_level'_`requested_selection'"
log using "`output'/run_school_input_regressions_`logtag'.log", text replace

foreach level of local levels {
    foreach selection of local selections {
        local level_label = lower("`level'")
        local sample "`success'/`level' school/Reference microdata/regression_sample_`selection'.dta"
        use "`sample'", clear

        foreach v in EGITIM_HARCAMA HAFTAICI_EGITIM_SAAT HAFTASONU_EGITIM_SAAT FIILI_SAAT_EVIS ///
            EVIS_ALISVERIS EVIS_YEMEK EVIS_BULASIK EVIS_CAMASIR EVIS_COCUK EVIS_YASLI ///
            EVIS_SUTASIMA EVIS_YAKACAK EVIS_BASKA {
            capture drop n_`v'
            capture destring `v', generate(n_`v') dpcomma force
        }

        capture drop education_hours household_work_hours education_spending
        generate double education_hours = n_HAFTAICI_EGITIM_SAAT + n_HAFTASONU_EGITIM_SAAT ///
            if !missing(n_HAFTAICI_EGITIM_SAAT, n_HAFTASONU_EGITIM_SAAT)
        generate double education_spending = n_EGITIM_HARCAMA if !missing(n_EGITIM_HARCAMA)
        label variable education_hours "Out-of-school education hours per week"
        label variable education_spending "Previous-school-year education spending (TL, level)"

        generate double household_work_hours = n_FIILI_SAAT_EVIS
        replace household_work_hours = 0 if missing(household_work_hours) & ///
            !missing(n_EVIS_ALISVERIS, n_EVIS_YEMEK, n_EVIS_BULASIK, n_EVIS_CAMASIR, ///
                n_EVIS_COCUK, n_EVIS_YASLI, n_EVIS_SUTASIMA, n_EVIS_YAKACAK, n_EVIS_BASKA)
        label variable household_work_hours "Hours spent on household work"

        local outcomes household_work_hours education_hours education_spending
        local outbase "`output'/`level_label'_`selection'_school_inputs"
        do "`engine'" "`outcomes'" "`outbase'_rdd_results.dta" "monthly" "child_weight" "6"
        do "`exporter'" "`outbase'_rdd_results.dta" "`outbase'_rdd_table.docx" "17" ///
            "School-age input outcomes: `level_label' school - `selection' child" ///
            "Education spending is EGITIM_HARCAMA in Turkish-lira levels. Education hours combine weekday and weekend study; household work uses FIILI_SAAT_EVIS where reported."
    }
}

display as result "School input RDD analyses complete; spending remains in levels."
log close

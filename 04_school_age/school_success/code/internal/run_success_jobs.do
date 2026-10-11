version 18.0
clear all
set more off
set varabbrev off

args data_root
local analysis "`data_root'/school success"
local engine "`c(pwd)'/04_school_age/school_success/code/internal/run_family_ols_rdd.do"

foreach level in Primary Middle High {
    local level_code = cond("`level'" == "Primary", 2, ///
        cond("`level'" == "Middle", 3, 4))
    foreach selection in youngest oldest {
        local sample "`analysis'/`level' school/Reference microdata/regression_sample_`selection'.dta"
        foreach family in very_successful successful reverse_score {
            local prefix = cond("`family'" == "very_successful", "v", ///
                cond("`family'" == "successful", "g", "s"))
            local outcomes "`prefix'_turkish `prefix'_social `prefix'_math `prefix'_science `prefix'_language `prefix'_arts `prefix'_vocational"
            local result "`analysis'/`level' school/`selection'/`family'/school_success_rdd_results.dta"
            display as text "Estimating `level' / `selection' / `family'"
            use "`sample'", clear
            do "`engine'" "`outcomes'" "`result'" "monthly" "child_weight" "6"
            generate byte school_level = `level_code'
            generate str8 child_selection = "`selection'"
            generate str20 family = "`family'"
            generate str10 reference_date = "2022-12-16"
            save "`result'", replace
        }
    }
}

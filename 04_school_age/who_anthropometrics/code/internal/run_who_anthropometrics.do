version 18.0
clear all
set more off
set varabbrev off

args data_root
local analysis "`data_root'/school WHO anthropometrics"
local engine "`c(pwd)'/04_school_age/school_success/code/internal/run_family_ols_rdd.do"

foreach level in Primary Middle High {
    local level_code = cond("`level'" == "Primary", 2, ///
        cond("`level'" == "Middle", 3, 4))
    foreach selection in youngest oldest {
        local sample "`analysis'/`level' school/`selection'/who_sample.dta"
        foreach family in base supplementary {
            if "`family'" == "base" {
                local outcomes "who_haz who_waz who_bmiz who_stunted who_underweight who_bmi_thin who_bmi_overweight who_bmi_obese"
                if "`level'" == "High" {
                    local outcomes "who_haz who_bmiz who_stunted who_bmi_thin who_bmi_overweight who_bmi_obese"
                }
            }
            else {
                local outcomes "who_not_stunted who_not_underweight who_neither_bmiz who_normal_haz who_normal_waz who_normal_bmiz who_above_haz who_above_waz who_above_bmiz"
                if "`level'" == "High" {
                    local outcomes "who_not_stunted who_neither_bmiz who_normal_haz who_normal_bmiz who_above_haz who_above_bmiz"
                }
            }
            local result "`analysis'/`level' school/`selection'/`family'/who_results.dta"
            display as text "Estimating WHO `level' / `selection' / `family'"
            use "`sample'", clear
            do "`engine'" "`outcomes'" "`result'" "monthly" "child_weight" "6"
            generate byte school_level = `level_code'
            generate str8 child_selection = "`selection'"
            generate str16 family = "`family'"
            save "`result'", replace
        }
    }
}

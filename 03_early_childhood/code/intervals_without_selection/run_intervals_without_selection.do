version 18.0
clear all
set more off
set varabbrev off

args data_root requested_date
if "`requested_date'" == "" local requested_date "all"
local analysis "`data_root'/selected age intervals"
local engine "`c(pwd)'/03_early_childhood/code/intervals_without_selection/internal/run_family_ols_rdd.do"

foreach reference in beginning middle end {
    if "`requested_date'" == "all" | "`requested_date'" == "`reference'" {
        if "`reference'" == "beginning" {
            local date "2022-10-10"
            local folder "Beginning - 10 October 2022"
        }
        else if "`reference'" == "middle" {
            local date "2022-11-12"
            local folder "Middle - 12 November 2022"
        }
        else {
            local date "2022-12-16"
            local folder "End - 16 December 2022"
        }
        foreach age in 0-2 1-3 0-3 {
            local age_min = real(substr("`age'", 1, 1))
            local age_max = real(substr("`age'", 3, 1))
            local age_file = subinstr("`age'", "-", "_", .)
            local cell "`analysis'/`folder'/`age' age"
            foreach selection in youngest oldest {
                foreach family in height_weight who_clinical nutrition_weekly nutrition_strict who_supplementary {
                    local suffix ""
                    if "`family'" == "height_weight" {
                        local outcomes "weight_kg_all height_cm_all"
                        local family_dir "WHO Anthropometric Development/14 Height and weight"
                    }
                    else if "`family'" == "who_clinical" {
                        local outcomes "who_haz who_waz who_whz who_bmiz who_stunted who_underweight who_wasted who_overweight who_obese who_ciaf who_below_bmiz"
                        local family_dir "WHO Anthropometric Development/15 WHO anthropometrics clinical"
                    }
                    else if "`family'" == "nutrition_weekly" {
                        local outcomes "nutrition_weekly_fruit nutrition_weekly_vegetables nutrition_weekly_meatfish nutrition_weekly_legumes nutrition_weekly_animalprod nutrition_weekly_sweets nutrition_weekly_snacks nutrition_weekly_softdrink nutrition_weekly_grains nutrition_ever_breastfed"
                        local family_dir "Nutrition Frequency/9 Nutrition weekly"
                    }
                    else if "`family'" == "nutrition_strict" {
                        local outcomes "nutrition_strict_fruit nutrition_strict_vegetables nutrition_strict_meatfish nutrition_strict_legumes nutrition_strict_animalprod nutrition_strict_sweets nutrition_strict_snacks nutrition_strict_softdrink nutrition_strict_grains"
                        local family_dir "Nutrition Frequency/10 Nutrition strict frequency"
                    }
                    else {
                        local outcomes "who_not_stunted who_not_underweight who_neither_whz who_neither_bmiz who_normal_haz who_normal_waz who_normal_whz who_normal_bmiz who_above_haz who_above_waz who_above_whz who_above_bmiz"
                        local family_dir "WHO Anthropometric Development/16 WHO anthropometrics supplementary"
                        local suffix "_supplementary"
                    }
                    local sample "`cell'/Reference microdata/regression_sample_`selection'_age`age_file'`suffix'.dta"
                    local result "`cell'/`selection'/`family_dir'/`family'_rdd_results.dta"
                    display as text "Estimating `date' / age `age' / `selection' / `family'"
                    use "`sample'", clear
                    do "`engine'" "`outcomes'" "`result'" "monthly" "child_weight" "6"
                    generate str10 reference_date = "`date'"
                    generate str9 reference_point = "`reference'"
                    generate byte age_min = `age_min'
                    generate byte age_max = `age_max'
                    generate str8 child_selection = "`selection'"
                    generate str20 family = "`family'"
                    save "`result'", replace
                }
            }
        }
    }
}

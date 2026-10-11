version 18.0
clear all
set more off
set varabbrev off

local root "C:/Users/Kaan Cil/Desktop/microdata"
local who_root "`root'/age 2-4 mechanism/WHO Anthropometric Development"
local master "`root'/age 2-4 mechanism/master do files"
local unicef "`root'/age 2-4 mechanism/UNICEF Development/1 UNICEF on-track dummy + 2 Total development score +3 Development domain scores/do files"
local input_dta "`master'/age2_4_all_outcomes_sample.dta"
local archive "`c(pwd)'/03_early_childhood/code/age_2_4/internal"
local engine "`archive'/run_family_ols_rdd.do"
local aid_engine "`archive'/unicef_development/00_run_aid_control_models.do"
local aid_builder "`archive'/unicef_development/00_prepare_aid_control_sample.do"
local exporter "`unicef'/00_export_family_with_aid.do"

tempfile aid_sample baseline_results aid_results
do "`aid_builder'" "`aid_sample'"

foreach family in 14 15 {
    if `family' == 14 {
        local task_dir "`who_root'/14 Height and weight"
        local outcomes weight_kg_all height_cm_all
        local prefix height_weight
        local title "Reduced Form Effects on Weight and Height With UNICEF Age Controls"
        local note "KILO and BOY are reported in their original units without WHO plausibility or other outcome-value restrictions. Child age is based on 16 December 2022."
        local n_outcomes 2
    }
    else {
        local task_dir "`who_root'/15 WHO anthropometrics clinical"
        local outcomes who_haz who_waz who_whz who_bmiz who_stunted ///
            who_underweight who_wasted who_overweight who_obese who_ciaf ///
            who_below_bmiz
        local prefix who_clinical
        local title "Reduced Form Effects on WHO Anthropometric Outcomes With UNICEF Age Controls"
        local note "Continuous z scores and prespecified adverse clinical classifications exclude WHO-flagged measurements. Child age is based on 16 December 2022."
        local n_outcomes 11
    }

    use "`input_dta'", clear
    isid BIRIMNO
    do "`engine'" `"`outcomes'"' `"`baseline_results'"' ///
        "unicef" "child_weight" "4"

    use `aid_sample', clear
    do "`aid_engine'" `"`outcomes'"' `"`aid_results'"' ///
        "unicef" "child_weight"

    use `baseline_results', clear
    append using `aid_results'
    isid outcome parent version bandwidth specification
    local expected = `n_outcomes' * 2 * 2 * 5 * 6
    sort outcome_order parent specification version bandwidth
    local results_dta "`task_dir'/`prefix'_unicef_age_controls_rdd_results.dta"
    local output_docx "`task_dir'/`prefix'_unicef_age_controls_rdd_table_bw4_8.docx"
    save "`results_dta'", replace

    do "`exporter'" `"`results_dta'"' `"`output_docx'"' ///
        "`family'" `"`title'"' `"`note'"'
    display as result "Saved default UNICEF age-control WHO table: `output_docx'"
}
clear

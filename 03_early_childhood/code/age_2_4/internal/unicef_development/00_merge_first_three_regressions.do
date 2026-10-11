version 18.0
clear all
set more off
set varabbrev off


local root "C:/Users/Kaan Cil/Desktop/microdata"
local master "`root'/age 2-4 mechanism/master do files"
local unicef "`root'/age 2-4 mechanism/UNICEF Development"
local archive "`c(pwd)'/03_early_childhood/code/age_2_4/internal"
local destination "`unicef'/1 UNICEF on-track dummy"
local full_sample "`master'/age2_4_all_outcomes_sample.dta"
local outcomes unicef_ontrack score_total_20 domain_health ///
    domain_learning domain_psychosocial

tempfile aid_sample baseline_results aid_results
do "`archive'/unicef_development/00_prepare_aid_control_sample.do" `"`aid_sample'"'

foreach age_control in unicef monthly {
    use "`full_sample'", clear
    do "`archive'/run_family_ols_rdd.do" `"`outcomes'"' ///
        `"`baseline_results'"' "`age_control'" "child_weight" "4"

    use `aid_sample', clear
    do "`archive'/unicef_development/00_run_aid_control_models.do" `"`outcomes'"' ///
        `"`aid_results'"' "`age_control'" "child_weight"

    use `baseline_results', clear
    append using `aid_results'
    isid outcome parent version bandwidth specification
    sort outcome_order parent specification version bandwidth

    local suffix ""
    local number "1-3"
    local title "Reduced Form Effects on UNICEF Development Outcomes"
    if "`age_control'" == "monthly" {
        local suffix "_monthly_age"
        local number "1-3M"
        local title "Reduced Form Effects on UNICEF Development Outcomes: Monthly Child-Age Controls"
    }
    local results "`destination'/unicef_merged`suffix'_rdd_results.dta"
    local document "`destination'/unicef_merged`suffix'_rdd_table_bw4_8.docx"
    save "`results'", replace

    do "`unicef'/00_export_family_with_aid.do" ///
        `"`results'"' `"`document'"' "`number'" `"`title'"' ///
        "The table combines on-track status with the total score and the three development-domain scores."
    display as result "Merged UNICEF table saved: `document'"
}

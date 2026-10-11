version 18.0
clear all
set more off
set varabbrev off

local root "C:/Users/Kaan Cil/Desktop/microdata"
local who_root "`root'/age 2-4 mechanism/WHO Anthropometric Development"
local scripts "`c(pwd)'/03_early_childhood/code/age_2_4/internal/who_anthropometrics"
local unicef_root "`root'/age 2-4 mechanism/UNICEF Development/1 UNICEF on-track dummy + 2 Total development score +3 Development domain scores"
local master "`root'/age 2-4 mechanism/master do files"
local engine "`c(pwd)'/03_early_childhood/code/age_2_4/internal/run_family_ols_rdd.do"
local aid_engine "`c(pwd)'/03_early_childhood/code/age_2_4/internal/unicef_development/00_run_aid_control_models.do"
local aid_sample_builder "`c(pwd)'/03_early_childhood/code/age_2_4/internal/unicef_development/12_prepare_capped_aid_sample.do"
local exporter "`who_root'/do files/01_export_capped_who_tables.do"

foreach case in october midpoint {
    if "`case'" == "october" {
        local date_text "10 October 2022"
        local case_folder "Reference 10 October 2022"
    }
    else {
        local date_text "12 November 2022"
        local case_folder "Reference 12 November 2022"
    }
    local shared_root "`who_root'/do files/work"
    local shared_dir "`shared_root'/`case_folder'"
    capture mkdir "`shared_root'"
    capture mkdir "`shared_dir'"

    local reference_dta "`unicef_root'/`case_folder'/work/all_development_respondents_reference.dta"
    local sample_dta "`unicef_root'/`case_folder'/work/capped_regression_sample.dta"
    local who_scores_dta "`shared_dir'/who_lms_scores_monthly_age2_4.dta"
    local all_outcomes_dta "`shared_dir'/who_all_outcomes_sample.dta"
    local aid_sample_dta "`shared_dir'/who_aid_sample.dta"

    do "`scripts'/00_score_capped_who_reference.do" ///
        "`reference_dta'" "`shared_dir'"

    use "`sample_dta'", clear
    isid BIRIMNO FERTNO
    destring KILO BOY, replace
    clonevar weight_kg_all = KILO
    clonevar height_cm_all = BOY
    label variable weight_kg_all "Weight in kg for all children"
    label variable height_cm_all "Height in cm for all children"

    preserve
        use "`who_scores_dta'", clear
        keep BIRIMNO FERTNO haz_monthly waz_monthly whz_monthly ///
            bmiz_monthly domain_haz_monthly domain_waz_monthly ///
            domain_whz_monthly domain_bmiz_monthly flag_haz_monthly ///
            flag_waz_monthly flag_whz_monthly flag_bmiz_monthly
        isid BIRIMNO FERTNO
        tempfile who_scores
        save `who_scores'
    restore
    merge 1:1 BIRIMNO FERTNO using `who_scores', ///
        keep(master match) generate(_merge_who)
    drop _merge_who

    generate double who_haz = haz_monthly ///
        if domain_haz_monthly == 0 & flag_haz_monthly == 0
    generate double who_waz = waz_monthly ///
        if domain_waz_monthly == 0 & flag_waz_monthly == 0
    generate double who_whz = whz_monthly ///
        if domain_whz_monthly == 0 & flag_whz_monthly == 0
    generate double who_bmiz = bmiz_monthly ///
        if domain_bmiz_monthly == 0 & flag_bmiz_monthly == 0
    label variable who_haz "WHO height-for-age z score"
    label variable who_waz "WHO weight-for-age z score"
    label variable who_whz "WHO weight-for-height z score"
    label variable who_bmiz "WHO BMI-for-age z score"
    generate byte who_stunted = (who_haz < -2) if !missing(who_haz)
    generate byte who_underweight = (who_waz < -2) if !missing(who_waz)
    generate byte who_wasted = (who_whz < -2) if !missing(who_whz)
    generate byte who_overweight = (who_whz > 2) if !missing(who_whz)
    generate byte who_obese = (who_whz > 3) if !missing(who_whz)
    generate byte who_ciaf = (who_haz < -2 | who_waz < -2 | who_whz < -2) ///
        if !missing(who_haz, who_waz, who_whz)
    generate byte who_below_bmiz = (who_bmiz < -2) if !missing(who_bmiz)
    label variable who_stunted "Stunted HAZ below -2"
    label variable who_underweight "Underweight WAZ below -2"
    label variable who_wasted "Wasted WHZ below -2"
    label variable who_overweight "Overweight WHZ above +2"
    label variable who_obese "Obese WHZ above +3"
    label variable who_ciaf "CIAF any stunting underweight or wasting"
    label variable who_below_bmiz "Below-normal BMI-for-age BMIZ below -2"
    save "`all_outcomes_dta'", replace

    do "`aid_sample_builder'" "`aid_sample_dta'" "`all_outcomes_dta'"

    foreach family in 14 15 {
        if `family' == 14 {
            local family_dir "`who_root'/14 Height and weight"
            local outcomes weight_kg_all height_cm_all
            local title_subject "Weight and Height"
            local family_note "KILO and BOY are reported in their original units without WHO plausibility or other outcome-value restrictions. Child age is calculated on `date_text' and capped at 24 and 59 months."
            local prefix height_weight
            local n_outcomes 2
        }
        else {
            local family_dir "`who_root'/15 WHO anthropometrics clinical"
            local outcomes who_haz who_waz who_whz who_bmiz who_stunted ///
                who_underweight who_wasted who_overweight who_obese ///
                who_ciaf who_below_bmiz
            local title_subject "WHO Anthropometric Outcomes"
            local family_note "Continuous z scores and prespecified adverse clinical classifications exclude WHO-flagged measurements. Child age is calculated on `date_text' and capped at 24 and 59 months."
            local prefix who_clinical
            local n_outcomes 11
        }
        local case_dir "`family_dir'/`case_folder'"
        local work_dir "`case_dir'/work"
        capture mkdir "`case_dir'"
        capture mkdir "`work_dir'"

        foreach age_control in unicef monthly {
            tempfile baseline_results aid_results
            use "`all_outcomes_dta'", clear
            do "`engine'" `"`outcomes'"' `"`baseline_results'"' ///
                "`age_control'" "child_weight" "4"

            use "`aid_sample_dta'", clear
            do "`aid_engine'" `"`outcomes'"' `"`aid_results'"' ///
                "`age_control'" "child_weight"

            use `baseline_results', clear
            append using `aid_results'
            isid outcome parent version bandwidth specification
            local expected = `n_outcomes' * 2 * 2 * 5 * 6
            sort outcome_order parent specification version bandwidth
            local results_dta "`work_dir'/`prefix'_`age_control'_rdd_results.dta"
            save "`results_dta'", replace

            if "`age_control'" == "unicef" {
                local title "Reduced Form Effects on `title_subject' Using `date_text' Child Age"
                local output_docx "`case_dir'/unicef_age_controls_regressions.docx"
            }
            else {
                local title "Reduced Form Effects on `title_subject' With Monthly Child Age Controls Using `date_text' Child Age"
                local output_docx "`case_dir'/monthly_age_controls_regressions.docx"
            }
            do "`exporter'" `"`results_dta'"' `"`output_docx'"' ///
                "`family'" `"`title'"' `"`family_note'"'
        }
    }
    display as result "Completed WHO reference-date regressions: `date_text'"
}
clear

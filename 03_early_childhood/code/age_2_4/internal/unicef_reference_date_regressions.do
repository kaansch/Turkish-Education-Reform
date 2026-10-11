version 18.0
clear all
set more off
set varabbrev off

local root "C:/Users/Kaan Cil/Desktop/microdata"
local target "`root'/age 2-4 mechanism/UNICEF Development/1 UNICEF on-track dummy + 2 Total development score +3 Development domain scores"
local scripts "`c(pwd)'/03_early_childhood/code/age_2_4/internal/unicef_development"
local master "`root'/age 2-4 mechanism/master do files"
local engine "`c(pwd)'/03_early_childhood/code/age_2_4/internal/run_family_ols_rdd.do"
local aid_engine "`scripts'/00_run_aid_control_models.do"
local exporter "`target'/do files/13_export_capped_reference_tables.do"
local outcomes unicef_ontrack score_total_20 domain_health ///
    domain_learning domain_psychosocial

foreach case in october midpoint {
    if "`case'" == "october" {
        local ref_date "2022-10-10"
        local date_text "10 October 2022"
        local case_dir "`target'/Reference 10 October 2022"
    }
    else {
        local ref_date "2022-11-12"
        local date_text "12 November 2022"
        local case_dir "`target'/Reference 12 November 2022"
    }
    capture mkdir "`case_dir'"
    local work_dir "`case_dir'/work"
    capture mkdir "`work_dir'"

    local reference_dta "`work_dir'/all_development_respondents_reference.dta"
    local sample_dta "`work_dir'/capped_regression_sample.dta"
    local all_outcomes_dta "`work_dir'/capped_all_outcomes_sample.dta"
    local aid_sample_dta "`work_dir'/capped_aid_sample.dta"

    do "`scripts'/10_build_all_development_reference.do" ///
        "`ref_date'" "`work_dir'"
    do "`scripts'/11_prepare_capped_unicef_sample.do" ///
        "`reference_dta'" "`sample_dta'"

    use "`sample_dta'", clear
    isid BIRIMNO
    local dev_health point_ENGEBEDE_YURUME point_ZIPLAMA ///
        point_GIYINME point_DUGME_ILIKLEME
    local dev_learning point_KELIME_SOYLEME point_UC_KELIMELIK_CUMLE ///
        point_BES_KELIMELIK_CUMLE point_ZAMIR_KULLANMA ///
        point_NESNE_ISMI_BILME point_ALFABE_BES_HARF point_ISMINI_YAZMA ///
        point_BIRDEN_BESE_SAYMA point_SAYILI_NESNE point_HATASIZ_SAYMA ///
        point_BOYA_YAPMA
    local dev_psychosocial point_BASKALARINI_SORMA point_YARDIM_TEKLIF ///
        point_IYI_GECINME point_UZGUN_MUTSUZ point_ISIRMA_VURMA
    egen byte domain_health = rowtotal(`dev_health'), missing
    egen byte domain_learning = rowtotal(`dev_learning'), missing
    egen byte domain_psychosocial = rowtotal(`dev_psychosocial'), missing
    label variable domain_health "Health development score 0 to 4"
    label variable domain_learning "Learning development score 0 to 11"
    label variable domain_psychosocial "Psychosocial well-being score 0 to 5"
    save "`all_outcomes_dta'", replace

    do "`scripts'/12_prepare_capped_aid_sample.do" ///
        "`aid_sample_dta'" "`all_outcomes_dta'"

    tempfile baseline_results aid_results
    foreach age_control in unicef monthly {
        use "`all_outcomes_dta'", clear
        do "`engine'" `"`outcomes'"' `"`baseline_results'"' ///
            "`age_control'" "child_weight" "4"

        use "`aid_sample_dta'", clear
        do "`aid_engine'" `"`outcomes'"' `"`aid_results'"' ///
            "`age_control'" "child_weight"

        use `baseline_results', clear
        append using `aid_results'
        isid outcome parent version bandwidth specification
        sort outcome_order parent specification version bandwidth
        local results_dta "`work_dir'/unicef_merged_`age_control'_rdd_results.dta"
        save "`results_dta'", replace

        if "`age_control'" == "unicef" {
            local title "Reduced Form Effects on UNICEF Development Outcomes Using 10 October 2022 Child Age"
            local output_docx "`case_dir'/unicef_age_controls_regressions.docx"
            if "`case'" == "midpoint" {
                local title "Reduced Form Effects on UNICEF Development Outcomes Using 12 November 2022 Child Age"
            }
        }
        else {
            local title "Reduced Form Effects on UNICEF Development Outcomes With Monthly Child Age Controls Using 10 October 2022 Child Age"
            local output_docx "`case_dir'/monthly_age_controls_regressions.docx"
            if "`case'" == "midpoint" {
                local title "Reduced Form Effects on UNICEF Development Outcomes With Monthly Child Age Controls Using 12 November 2022 Child Age"
            }
        }
        local family_note "Child age is calculated on `date_text'. All development respondents with complete DOB are eligible; analysis ages below 24 map to 24 and above 59 map to 59."
        do "`exporter'" `"`results_dta'"' `"`output_docx'"' ///
            "1-3" `"`title'"' `"`family_note'"'
    }
    display as result "Completed reference-date regressions: `date_text'"
}
clear

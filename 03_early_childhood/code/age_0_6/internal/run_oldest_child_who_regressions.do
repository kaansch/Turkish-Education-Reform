version 18.0
clear all
set more off
set varabbrev off

local root "C:/Users/Kaan Cil/Desktop/microdata/0-5-6 age"
local scripts "`root'/do files"
local engine "`c(pwd)'/03_early_childhood/code/age_0_6/internal/run_family_ols_rdd.do"
local exporter "`scripts'/00_export_family_word_table.do"
local work_root "`scripts'/oldest child work"
capture mkdir "`work_root'"

foreach age_tag in 0-5 0-6 {
    local age_num = substr("`age_tag'", 3, 1)
    local upper = cond("`age_tag'" == "0-5", 71, 83)
    local age_folder "`root'/`age_tag' age"
    foreach case in october midpoint december {
        if "`case'" == "october" local date_text "10 October 2022"
        else if "`case'" == "midpoint" local date_text "12 November 2022"
        else local date_text "16 December 2022"
        local case_folder "Reference `date_text'"

        if "`case'" == "december" {
            local full "`age_folder'/Reference microdata/child_age0_`age_num'_linked_who.dta"
        }
        else {
            local full "`scripts'/reference date work/`case_folder'/`age_tag'/child_age0_`age_num'_linked_who.dta"
        }

        local case_work "`work_root'/`case_folder'"
        local sample_dir "`case_work'/`age_tag'"
        capture mkdir "`case_work'"
        capture mkdir "`sample_dir'"
        local sample "`sample_dir'/regression_sample_age0_`age_num'_oldest.dta"

        use "`full'", clear
        isid BIRIMNO FERTNO
        bysort BIRIMNO: egen double __oldest_dob = min(child_dob)
        generate double __fertno_order = real(strtrim(FERTNO))
        gsort BIRIMNO child_dob __fertno_order
        by BIRIMNO: keep if _n == 1
        isid BIRIMNO
        drop __oldest_dob __fertno_order
        save "`sample'", replace
        display as result "Oldest-child `age_tag' sample on `date_text': " _N " households"

        foreach family in 14 15 {
            if `family' == 14 {
                local family_dir "`age_folder'/WHO Anthropometric Development/14 Height and weight"
                local outcomes weight_kg_all height_cm_all
                local prefix height_weight
                local title "Reduced Form Effects on Weight and Height for the Oldest Eligible Child Ages `age_tag' Using `date_text' Child Age"
                local note "The earliest-born eligible child in each household is selected within completed ages 0 to `upper' months on `date_text'. Ages outside this range are excluded. KILO and BOY are in their original units."
                local n_outcomes 2
            }
            else {
                local family_dir "`age_folder'/WHO Anthropometric Development/15 WHO anthropometrics clinical"
                local outcomes who_haz who_waz who_whz who_bmiz who_stunted ///
                    who_underweight who_wasted who_overweight who_obese ///
                    who_ciaf who_below_bmiz who_bmi_overweight_5plus ///
                    who_bmi_obese_5plus who_bmi_thin_5plus
                local prefix who_clinical
                local title "Reduced Form Effects on WHO Anthropometric Outcomes for the Oldest Eligible Child Ages `age_tag' Using `date_text' Child Age"
                local note "The earliest-born eligible child in each household is selected within completed ages 0 to `upper' months on `date_text'. Ages outside this range are excluded. WHO 2006 covers months 0-60 and WHO 2007 covers months 61 onward. Weight-for-length/height classifications apply through month 60."
                local n_outcomes 14
            }
            local oldest_dir "`family_dir'/Oldest child"
            local output_dir "`oldest_dir'/`case_folder'"
            local results_dir "`output_dir'/work"
            capture mkdir "`oldest_dir'"
            capture mkdir "`output_dir'"
            capture mkdir "`results_dir'"
            local results "`results_dir'/`prefix'_rdd_results.dta"
            local docx "`output_dir'/`prefix'_rdd_table_bw4_8.docx"

            use "`sample'", clear
            do "`engine'" `"`outcomes'"' `"`results'"' ///
                "monthly" "child_weight" "6"
            local expected = `n_outcomes' * 2 * 2 * 5 * 6
            do "`exporter'" `"`results'"' `"`docx'"' ///
                "`family'" `"`title'"' `"`note'"' "oldest"
            display as result "Saved oldest-child WHO regression table: `docx'"
        }
    }
}
clear

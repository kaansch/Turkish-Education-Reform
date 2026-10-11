version 18.0
clear all
set more off
set varabbrev off

local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local input_dta "`project_root'/0-17 linked microdata/child017_linked.dta"
local output_dir "`project_root'/age7plus_mechanisms/school_level_rdd_graphs/outputs"
capture mkdir "`output_dir'"
capture log close
log using "`output_dir'/graph_run_inputs.log", text replace

use "`input_dta'", clear

foreach v of varlist OKUL_YILI_DEVAM OKUL_YILI_SEVIYE_DEVAM FAKTOR_FERT ///
    FIILI_SAAT_EVIS HAFTAICI_EGITIM_SAAT HAFTASONU_EGITIM_SAAT ///
    EGITIM_HARCAMA ///
    BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL {
    capture confirm string variable `v'
    if !_rc {
        destring `v', generate(n_`v') dpcomma force
    }
    else {
        generate double n_`v' = `v'
    }
}

gen double __w = n_FAKTOR_FERT
gen int __run_father = (n_BABA_DOGUM_TARIH_YIL - 1987) * 12 + (n_BABA_DOGUM_TARIH_AY - 1)
replace __run_father = . if missing(n_BABA_DOGUM_TARIH_YIL) | !inrange(n_BABA_DOGUM_TARIH_AY,1,12)
gen int __run_mother = (n_ANNE_DOGUM_TARIH_YIL - 1987) * 12 + (n_ANNE_DOGUM_TARIH_AY - 1)
replace __run_mother = . if missing(n_ANNE_DOGUM_TARIH_YIL) | !inrange(n_ANNE_DOGUM_TARIH_AY,1,12)

gen byte __all_household_tasks_no = 1
foreach v of varlist EVIS_ALISVERIS EVIS_YEMEK EVIS_BULASIK EVIS_CAMASIR ///
    EVIS_COCUK EVIS_YASLI EVIS_SUTASIMA EVIS_YAKACAK EVIS_BASKA {
    replace __all_household_tasks_no = 0 if `v' != "2"
}
gen double __house_hours = n_FIILI_SAAT_EVIS
replace __house_hours = 0 if missing(__house_hours) & __all_household_tasks_no
gen double __study_hours = n_HAFTAICI_EGITIM_SAAT + n_HAFTASONU_EGITIM_SAAT
gen double __education_spending = n_EGITIM_HARCAMA
label variable __education_spending "Previous-school-year education spending (TL, level)"

capture program drop __export_rd_pair
program define __export_rd_pair
    version 18.0
    syntax varname(numeric), FILEBase(string) TITLE(string) YTITLE(string) OUTDir(string)
    local y `varlist'
    foreach parent in father mother {
        local x = cond("`parent'" == "father", "__run_father", "__run_mother")
        local parent_text = cond("`parent'" == "father", "Father birth month", "Mother birth month")
        local parent_plural = cond("`parent'" == "father", "Fathers", "Mothers")
        foreach version in nodonut donut12 {
            preserve
            keep if OKUL_YILI_DEVAM == "1" & inlist(n_OKUL_YILI_SEVIYE_DEVAM,2,3,4)
            keep if !missing(`y', `x', __w) & __w > 0
            keep if inrange(`x', -96, 95)
            local donut_text "No donut hole"
            if "`version'" == "donut12" {
                drop if inrange(`x', -12, 11)
                local donut_text "12-month donut on each side"
            }
            quietly count if `x' < 0
            local n_left = r(N)
            quietly count if `x' >= 0
            local n_right = r(N)
            di as text "`filebase' | `parent' | `version' | left=`n_left' right=`n_right'"

            tempvar bin_id bin_center weighted_y bin_weight bin_weighted_y bin_mean bin_tag
            generate long `bin_id' = floor(`x' / 3)
            generate double `bin_center' = `bin_id' * 3 + 1
            generate double `weighted_y' = `y' * __w
            bysort `bin_id': egen double `bin_weight' = total(__w)
            bysort `bin_id': egen double `bin_weighted_y' = total(`weighted_y')
            generate double `bin_mean' = `bin_weighted_y' / `bin_weight'
            bysort `bin_id': generate byte `bin_tag' = (_n == 1)
            local left_fit "`x' < 0"
            local right_fit "`x' >= 0"
            if "`version'" == "donut12" {
                local left_fit "`x' < -12"
                local right_fit "`x' > 11"
            }
            tempname graph_name
            twoway ///
                (lfitci `y' `x' if `left_fit' [pw=__w], level(95) ciplot(rline) ///
                    range(-96 0) clcolor(black) clwidth(thick) ///
                    alcolor(black) alpattern(dash) alwidth(medthin)) ///
                (lfitci `y' `x' if `right_fit' [pw=__w], level(95) ciplot(rline) ///
                    range(0 96) clcolor(black) clwidth(thick) ///
                    alcolor(black) alpattern(dash) alwidth(medthin)) ///
                (scatter `bin_mean' `bin_center' if `bin_tag', ///
                    msymbol(O) msize(small) mcolor(black)), ///
                title("`title'", color(black) size(medlarge)) ///
                subtitle("`parent_text'; `donut_text'; +/- 96 months", size(medsmall)) ///
                ytitle("`ytitle'", size(medsmall)) ///
                xtitle("Months around the January 1987 cutoff", size(medsmall)) ///
                xline(0, lcolor(black)) xlabel(-96(12)96) xscale(range(-96 96)) ///
                legend(off) ///
                note("`parent_plural': left = `n_left'; right = `n_right'. Weighted three-month means; dashed lines are 95% CIs." ///
                    "Current reported school level; no child age restriction. FAKTOR_FERT weights." ///
                    "`ytitle'.", size(tiny)) ///
                scheme(s1mono) name(`graph_name', replace) ///
                graphregion(color(white)) plotregion(margin(medlarge))
            graph export "`outdir'/`filebase'_`parent'_bw96_`version'.png", as(png) width(2400) replace
            graph drop `graph_name'
            restore
        }
    }
end

foreach school in primary middle high {
    local level = cond("`school'" == "primary",2,cond("`school'" == "middle",3,4))
    local label = cond("`school'" == "primary","Primary school",cond("`school'" == "middle","Middle school","High school"))
    preserve
    keep if OKUL_YILI_DEVAM == "1" & n_OKUL_YILI_SEVIYE_DEVAM == `level'
    quietly count
    di as result "SCHOOL SAMPLE | `label' | enrolled child records=`r(N)'"
    restore
    preserve
    keep if n_OKUL_YILI_SEVIYE_DEVAM == `level'
    __export_rd_pair __house_hours, filebase("FIILI_SAAT_EVIS_`school'") ///
        title("Weekly household work hours: `label'") ///
        ytitle("Hours in the previous week") outdir("`output_dir'")
    restore
}

foreach school in primary middle high {
    local level = cond("`school'" == "primary",2,cond("`school'" == "middle",3,4))
    local label = cond("`school'" == "primary","Primary school",cond("`school'" == "middle","Middle school","High school"))
    preserve
    keep if n_OKUL_YILI_SEVIYE_DEVAM == `level'
    __export_rd_pair __study_hours, filebase("OUT_OF_SCHOOL_EDUCATION_HOURS_`school'") ///
        title("Out-of-school education hours: `label'") ///
        ytitle("Weekday plus weekend hours") outdir("`output_dir'")
    __export_rd_pair __education_spending, filebase("EGITIM_HARCAMA_`school'") ///
        title("Previous-school-year education spending: `label'") ///
        ytitle("Spending (Turkish lira, level)") outdir("`output_dir'")
    restore
}

display as result "ALL REQUESTED SCHOOL-LEVEL RDD GRAPH SETS COMPLETE"
log close

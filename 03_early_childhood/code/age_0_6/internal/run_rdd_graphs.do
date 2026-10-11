version 18.0
clear all
set more off
set varabbrev off

args age_tag

local root "C:/Users/Kaan Cil/Desktop/microdata/0-5-6 age"
local age_num = substr("`age_tag'", 3, 1)
local input "`root'/`age_tag' age/Reference microdata/child_age0_`age_num'_linked_who.dta"
local output_root "`root'/`age_tag' age"
local age_file "age0_`age_num'"

capture log close
log using "`output_root'/run_rdd_graphs.log", text replace
use "`input'", clear
isid BIRIMNO FERTNO

capture program drop __graph_pair
program define __graph_pair
    version 18.0
    syntax varname(numeric), FILEBase(string) TITLE(string) YTITLE(string) ///
        OUTDIR(string) AGETAG(string) AGELABEL(string) DOMAINNOTE(string) [BINARY]
    local y `varlist'
    foreach parent in father mother {
        local x = cond("`parent'" == "father", "run_father", "run_mother")
        local parent_text = cond("`parent'" == "father", "Father birth month", "Mother birth month")
        local destination "`outdir'"
        if "`parent'" == "mother" local destination "`outdir'/mother"
        foreach version in nodonut donut12 {
            preserve
            keep if !missing(`y', `x', child_weight) & child_weight > 0
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

            tempvar bin_id bin_center weighted_y bin_weight bin_weighted_y bin_mean bin_tag
            generate long `bin_id' = floor(`x' / 3)
            generate double `bin_center' = `bin_id' * 3 + 1
            generate double `weighted_y' = `y' * child_weight
            bysort `bin_id': egen double `bin_weight' = total(child_weight)
            bysort `bin_id': egen double `bin_weighted_y' = total(`weighted_y')
            generate double `bin_mean' = `bin_weighted_y' / `bin_weight'
            bysort `bin_id': generate byte `bin_tag' = (_n == 1)
            local left_fit "`x' < 0"
            local right_fit "`x' >= 0"
            if "`version'" == "donut12" {
                local left_fit "`x' < -12"
                local right_fit "`x' > 11"
            }

            local yscale_option "ylabel(, angle(0) format(%9.1f))"
            if "`binary'" != "" local yscale_option "ylabel(0(.1)1, angle(0) format(%3.1f)) yscale(range(0 1))"
            tempname graph_name
            twoway ///
                (lfitci `y' `x' if `left_fit' [pw=child_weight], level(95) ///
                    ciplot(rline) range(-96 0) clcolor(black) clwidth(thick) ///
                    alcolor(black) alpattern(dash) alwidth(medthin)) ///
                (lfitci `y' `x' if `right_fit' [pw=child_weight], level(95) ///
                    ciplot(rline) range(0 96) clcolor(black) clwidth(thick) ///
                    alcolor(black) alpattern(dash) alwidth(medthin)) ///
                (scatter `bin_mean' `bin_center' if `bin_tag', ///
                    msymbol(O) msize(small) mcolor(black)), ///
                title("`title': `agelabel'", color(black) size(medlarge)) ///
                subtitle("`parent_text'; `donut_text'; +/- 96 months", size(medsmall)) ///
                ytitle("`ytitle' and 95% CI", size(medsmall)) ///
                xtitle("Months around the January 1987 Cutoff", size(medsmall)) ///
                xline(0, lcolor(black)) xlabel(-96(32)96) xscale(range(-96 96)) ///
                `yscale_option' legend(off) ///
                note("Children: left = `n_left'; right = `n_right'. Weighted three-month means; dashed lines are 95% CIs." ///
                    "Ages are completed months on 16 Dec 2022. `domainnote'", size(tiny)) ///
                scheme(s1mono) name(`graph_name', replace) ///
                graphregion(color(white)) plotregion(margin(medlarge))
            graph export "`destination'/`filebase'_`agetag'_`parent'_bw96_`version'.png", ///
                as(png) width(2400) replace
            graph drop `graph_name'
            restore
        }
    }
end

local hw "`output_root'/WHO Anthropometric Development/14 Height and weight/RDD Graphs"
__graph_pair weight_kg_all, filebase("KILO") title("Child weight") ///
    ytitle("Weight in kg") outdir("`hw'") agetag("`age_file'") ///
    agelabel("age `age_tag'") domainnote("Reported weight in original units.")
__graph_pair height_cm_all, filebase("BOY") title("Child length or height") ///
    ytitle("Length or height in cm") outdir("`hw'") agetag("`age_file'") ///
    agelabel("age `age_tag'") domainnote("Reported BOY in original units.")

local clinical "`output_root'/WHO Anthropometric Development/15 WHO anthropometrics clinical/RDD Graphs"
foreach pair in who_haz who_waz who_whz who_bmiz {
    local title "WHO length/height-for-age z score"
    local filebase "HAZ_monthly"
    local domain "WHO 2006 through month 60; WHO 2007 from month 61."
    if "`pair'" == "who_waz" {
        local title "WHO weight-for-age z score"
        local filebase "WAZ_monthly"
    }
    if "`pair'" == "who_whz" {
        local title "WHO weight-for-length/height z score"
        local filebase "WHZ_monthly"
        local domain "Available through month 60 only."
    }
    if "`pair'" == "who_bmiz" {
        local title "WHO BMI-for-age z score"
        local filebase "BMIZ_monthly"
    }
    __graph_pair `pair', filebase("`filebase'") title("`title'") ///
        ytitle("WHO z score") outdir("`clinical'") agetag("`age_file'") ///
        agelabel("age `age_tag'") domainnote("`domain'")
}

local weekly "`output_root'/Nutrition Frequency/9 Nutrition weekly/RDD Graphs"
local strict "`output_root'/Nutrition Frequency/10 Nutrition strict frequency/RDD Graphs"
foreach food in fruit vegetables meatfish legumes animalprod sweets snacks softdrink grains {
    __graph_pair nutrition_weekly_`food', filebase("`food'_codes1_3") ///
        title("`food' at least weekly") ytitle("Weighted probability") ///
        outdir("`weekly'") agetag("`age_file'") agelabel("age `age_tag'") ///
        domainnote("Food question applies after six months; source codes 1-9 only.") binary
    __graph_pair nutrition_strict_`food', filebase("`food'_codes1_2") ///
        title("`food' daily or several times weekly") ytitle("Weighted probability") ///
        outdir("`strict'") agetag("`age_file'") agelabel("age `age_tag'") ///
        domainnote("Food question applies after six months; source codes 1-9 only.") binary
}
__graph_pair nutrition_ever_breastfed, filebase("ANNE_SUTU") ///
    title("Ever breastfed") ytitle("Weighted probability") ///
    outdir("`weekly'") agetag("`age_file'") agelabel("age `age_tag'") ///
    domainnote("Only recorded response codes 1 and 2 enter this outcome.") binary

display as result "Completed RDD graphs for `age_tag'."
log close
clear

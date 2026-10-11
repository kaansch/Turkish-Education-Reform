version 18.0
clear all
set more off

local input_dta  "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Reference microdata/child_age2_4_reference.dta"
local output_root "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Nutrition/outputs"
local output_dir_code2 "`output_root'/code1-2/age2-4"
local output_dir_code3 "`output_root'/code1-3/age2-4"

capture mkdir "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Nutrition"
capture mkdir "`output_root'"

capture mkdir "`output_root'/code1-2"
capture mkdir "`output_root'/code1-3"
capture mkdir "`output_dir_code2'"
capture mkdir "`output_dir_code3'"

capture log close
log using "`output_root'/plot_nutrition_frequency.log", text replace

use "`input_dta'", clear

isid BIRIMNO FERTNO
display as result "REFERENCE COHORT: " _N " children; actual months 24-62; analysis months 24-59."

local foods MEYVE_YEME SEBZE_YEME ET_TAVUK_BALIK_YEME ///
    BAKLIYAT_YEME HAYVAN_URUNU_YEME TATLI_YEME ///
    ATISTIRMALIK_YEME ALKOLSUZ_ICECEK_ICME TAHIL_YEME

destring DOGUM_TARIH_GUN DOGUM_TARIH_AY DOGUM_TARIH_YIL ///
    BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL ///
    `foods', replace

gen double __w = real(subinstr(strtrim(FAKTOR_FERT), ",", ".", .))
clonevar __child_dob = child_dob
gen int __child_age_y = floor(child_months_analysis / 12)

gen int __run_father = (BABA_DOGUM_TARIH_YIL - 1987) * 12 + (BABA_DOGUM_TARIH_AY - 1)
replace __run_father = . if missing(BABA_DOGUM_TARIH_YIL) | !inrange(BABA_DOGUM_TARIH_AY, 1, 12)
gen int __run_mother = (ANNE_DOGUM_TARIH_YIL - 1987) * 12 + (ANNE_DOGUM_TARIH_AY - 1)
replace __run_mother = . if missing(ANNE_DOGUM_TARIH_YIL) | !inrange(ANNE_DOGUM_TARIH_AY, 1, 12)

capture program drop __export_rd_pair
program define __export_rd_pair
    version 18.0
    syntax varname(numeric), FILEBase(string) TITle(string) ///
        AGETag(string) AGETExt(string) YLOGic(string) OUTDir(string)
    local y `varlist'
    local x_tick 32
    foreach parent in father mother {
        local x = cond("`parent'" == "father", "__run_father", "__run_mother")
        local parent_text = cond("`parent'" == "father", "Father birth month", "Mother birth month")
        local parent_plural = cond("`parent'" == "father", "Fathers", "Mothers")
        foreach version in nodonut donut12 {
            preserve
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
                ytitle("Weighted Probability and 95% CI", size(medsmall)) ///
                xtitle("Months around the January 1987 Cutoff", size(medsmall)) ///
                xline(0, lcolor(black)) xlabel(-96(`x_tick')96) xscale(range(-96 96)) ///
                ylabel(0(.1)1, format(%3.1f) angle(0)) yscale(range(0 1)) ///
                legend(off) ///
                note("`parent_plural': left = `n_left'; right = `n_right'. Weighted three-month means; dashed lines are 95% CIs." ///
                    "`ylogic'" "Reference cohort: raw ages 24-62 months; analysis ages 60-62 set to 59.", size(tiny)) ///
                scheme(s1mono) name(`graph_name', replace) ///
                graphregion(color(white)) plotregion(margin(medlarge))
            graph export "`outdir'/`filebase'_`agetag'_`parent'_bw96_`version'.png", ///
                as(png) width(2400) replace
            graph drop `graph_name'
            restore
        }
    }
end

tempvar y
foreach v of local foods {
    gen byte `y' = inlist(`v', 1, 2) if ///
        !missing(`v') & inrange(__child_age_y, 2, 4)
    __export_rd_pair `y', filebase("`v'_codes1_2") ///
        title("`v' (kod 1-2)") ///
        agetag("age2_4") agetext("age 2-4") ///
        ylogic("Binary: 1=codes 1-2 (daily/several times weekly); 0=every other recorded response; blanks excluded.") ///
        outdir("`output_dir_code2'")
    drop `y'

    gen byte `y' = inrange(`v', 1, 3) if ///
        !missing(`v') & inrange(__child_age_y, 2, 4)
    __export_rd_pair `y', filebase("`v'_codes1_3") ///
        title("`v' (kod 1-3)") ///
        agetag("age2_4") agetext("age 2-4") ///
        ylogic("Binary: 1=codes 1-3 (at least weekly); 0=every other recorded response; blanks excluded.") ///
        outdir("`output_dir_code3'")
    drop `y'
}

display as result "07_beslenme codes1-2 and codes1-3 age2-4 completed."
display as result "Codes 1-2 PNG files: `output_dir_code2'"
display as result "Codes 1-3 PNG files: `output_dir_code3'"
log close
clear

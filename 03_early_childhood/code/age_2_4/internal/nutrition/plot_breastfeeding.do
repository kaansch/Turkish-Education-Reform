version 18.0
clear all
set more off
set varabbrev off


local input_dta  "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Reference microdata/child_age2_4_reference.dta"
local output_dir "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Nutrition/outputs/breastfeeding/age2-4"

capture mkdir "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Nutrition/outputs/breastfeeding"
capture mkdir "`output_dir'"
capture log close
log using "`output_dir'/plot_breastfeeding.log", text replace

use "`input_dta'", clear

isid BIRIMNO FERTNO

local required ANNE_SUTU FAKTOR_FERT ///
    BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL

destring ANNE_SUTU ///
    BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL, replace

generate double __w = real(subinstr(strtrim(FAKTOR_FERT), ",", ".", .))
generate int __run_father = (BABA_DOGUM_TARIH_YIL - 1987) * 12 + ///
    (BABA_DOGUM_TARIH_AY - 1)
replace __run_father = . if missing(BABA_DOGUM_TARIH_YIL) | ///
    !inrange(BABA_DOGUM_TARIH_AY, 1, 12)
generate int __run_mother = (ANNE_DOGUM_TARIH_YIL - 1987) * 12 + ///
    (ANNE_DOGUM_TARIH_AY - 1)
replace __run_mother = . if missing(ANNE_DOGUM_TARIH_YIL) | ///
    !inrange(ANNE_DOGUM_TARIH_AY, 1, 12)

capture program drop __export_rd_pair
program define __export_rd_pair
    version 18.0
    syntax varname(numeric), FILEBase(string) TITle(string) YLOGic(string) OUTDir(string)

    local y `varlist'
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
                xline(0, lcolor(black)) xlabel(-96(32)96) xscale(range(-96 96)) ///
                ylabel(0(.1)1, format(%3.1f) angle(0)) yscale(range(0 1)) ///
                legend(off) ///
                note("`parent_plural': left = `n_left'; right = `n_right'. Weighted three-month means; dashed lines are 95% CIs." ///
                    "`ylogic'" "Reference cohort: raw months 24-62; analysis months 24-59.", size(tiny)) ///
                scheme(s1mono) name(`graph_name', replace) ///
                graphregion(color(white)) plotregion(margin(medlarge))

            graph export "`outdir'/`filebase'_age2_4_`parent'_bw96_`version'.png", ///
                as(png) width(2400) replace
            graph drop `graph_name'
            restore
        }
    }
end

tempvar y
generate byte `y' = ANNE_SUTU == 1 if !missing(ANNE_SUTU)
__export_rd_pair `y', filebase("ANNE_SUTU") title("ANNE_SUTU") ///
    ylogic("Binary: 1=Ever breastfed; 0=every other recorded response, including 99; blanks excluded.") ///
    outdir("`output_dir'")
drop `y'

display as result "Breastfeeding plots completed. PNG files: `output_dir'"
log close
clear

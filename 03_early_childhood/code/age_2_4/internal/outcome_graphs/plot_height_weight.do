version 18.0
clear all
set more off

local input_dta  "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Reference microdata/child_age2_4_reference.dta"
local output_dir "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 intervals/Height and weight/outputs"
local rd_window_months 96

capture mkdir "`output_dir'"
capture log close
log using "`output_dir'/plot_height_weight.log", text replace

use "`input_dta'", clear

isid BIRIMNO FERTNO
display as result "REFERENCE COHORT: " _N " children; actual months 24-62; analysis months 24-59."

destring KILO BOY DOGUM_TARIH_GUN DOGUM_TARIH_AY DOGUM_TARIH_YIL  ///
    BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL                      ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL, replace

clonevar __child_dob = child_dob
clonevar __survey_date = reference_date
clonevar __child_age_d = child_age_days
clonevar __child_age_m = child_months_analysis

generate double __w = real(subinstr(strtrim(FAKTOR_FERT), ",", ".", .))

generate int __run_father = (BABA_DOGUM_TARIH_YIL - 1987) * 12      ///
    + (BABA_DOGUM_TARIH_AY - 1)
replace __run_father = . if missing(BABA_DOGUM_TARIH_YIL)           ///
    | !inrange(BABA_DOGUM_TARIH_AY, 1, 12)

generate int __run_mother = (ANNE_DOGUM_TARIH_YIL - 1987) * 12      ///
    + (ANNE_DOGUM_TARIH_AY - 1)
replace __run_mother = . if missing(ANNE_DOGUM_TARIH_YIL)           ///
    | !inrange(ANNE_DOGUM_TARIH_AY, 1, 12)

capture program drop __export_continuous_rd_pair
program define __export_continuous_rd_pair
    version 18.0
    syntax varname(numeric), FILEBase(string) TITle(string)          ///
        YTITle(string) UNITText(string) OUTDir(string) WINDOW(integer)

    local y `varlist'
    local x_left = -`window'
    local x_right_data = `window' - 1
    local x_tick = max(1, floor(`window' / 3))

    foreach parent in father mother {
        local x = cond("`parent'" == "father", "__run_father", "__run_mother")
        local parent_text = cond("`parent'" == "father",             ///
            "Father birth month", "Mother birth month")
        local parent_plural = cond("`parent'" == "father",          ///
            "Fathers", "Mothers")

        foreach version in nodonut donut12 {
            preserve
            keep if inrange(__child_age_m, 24, 59)
            keep if !missing(`y', `x', __w) & __w > 0
            keep if inrange(`x', `x_left', `x_right_data')

            local donut_text "No donut hole"
            if "`version'" == "donut12" {
                drop if inrange(`x', -12, 11)
                local donut_text "12-month donut on each side"
            }

            quietly count if `x' < 0
            local n_left = r(N)
            quietly count if `x' >= 0
            local n_right = r(N)

            tempvar bin_id bin_center weighted_y bin_weight             ///
                bin_weighted_y bin_mean bin_tag
            generate long `bin_id' = floor(`x' / 3)
            generate double `bin_center' = `bin_id' * 3 + 1
            generate double `weighted_y' = `y' * __w
            bysort `bin_id': egen double `bin_weight' = total(__w)
            bysort `bin_id': egen double `bin_weighted_y' =            ///
                total(`weighted_y')
            generate double `bin_mean' = `bin_weighted_y' / `bin_weight'
            bysort `bin_id': generate byte `bin_tag' = (_n == 1)

            local left_fit "`x' < 0"
            local right_fit "`x' >= 0"
            if "`version'" == "donut12" {
                local left_fit "`x' < -12"
                local right_fit "`x' > 11"
            }

            tempname graph_name
            twoway                                      ///
                (lfitci `y' `x' if `left_fit' [pw=__w], level(95)       ///
                    ciplot(rline) range(`x_left' 0) clcolor(black)       ///
                    clwidth(thick) alcolor(black) alpattern(dash)        ///
                    alwidth(medthin))                                    ///
                (lfitci `y' `x' if `right_fit' [pw=__w], level(95)      ///
                    ciplot(rline) range(0 `window') clcolor(black)       ///
                    clwidth(thick) alcolor(black) alpattern(dash)        ///
                    alwidth(medthin))                                    ///
                (scatter `bin_mean' `bin_center' if `bin_tag',          ///
                    msymbol(O) msize(small) mcolor(black)),              ///
                title("`title': age 2-4", color(black) size(medlarge)) ///
                subtitle("`parent_text'; `donut_text'; +/- `window' months", ///
                    size(medsmall))                                      ///
                ytitle("`ytitle' and 95% CI", size(medsmall))          ///
                xtitle("Months around the January 1987 Cutoff",        ///
                    size(medsmall))                                      ///
                xline(0, lcolor(black))                                 ///
                xlabel(`x_left'(`x_tick')`window')                      ///
                xscale(range(`x_left' `window'))                        ///
                ylabel(, angle(0) format(%9.1f))                        ///
                legend(off)                                             ///
                note("`parent_plural': left = `n_left'; right = `n_right'. Weighted three-month means; dashed lines are 95% CIs." ///
                    "Outcome is the child's reported `unittext'."       ///
                    "Reference cohort: actual ages 24-62 months on 16 Dec 2022; analysis ages 60-62 set to 59.", size(tiny)) ///
                scheme(s1mono) name(`graph_name', replace)              ///
                graphregion(color(white)) plotregion(margin(medlarge))

            graph export "`outdir'/`filebase'_age2_4_`parent'_bw`window'_`version'.png", ///
                as(png) width(2400) replace
            graph drop `graph_name'
            restore
        }
    }
end

__export_continuous_rd_pair KILO, filebase("KILO")                     ///
    title("Child weight") ytitle("Weighted weight (kg)")              ///
    unittext("weight in kilograms") outdir("`output_dir'")             ///
    window(`rd_window_months')

__export_continuous_rd_pair BOY, filebase("BOY")                       ///
    title("Child height") ytitle("Weighted height (cm)")              ///
    unittext("height in centimeters") outdir("`output_dir'")           ///
    window(`rd_window_months')

display as result                                                       ///
    "Height/weight task completed. PNG files are in: `output_dir'"
log close
clear

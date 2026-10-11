version 18.0
clear all
set more off
args input_dta output_dir

local who_dir    "C:/Users/Kaan Cil/Desktop/microdata/age 2-4 rdd graphs/WHO Tables"
local rd_window_months 96
local donut_months 12

capture mkdir "`output_dir'"
capture log close
log using "`output_dir'/00_score_capped_who_reference.log", text replace

tempfile hfa_boys_m hfa_m wfa_boys_m wfa_m bmi_boys_m bmi_m wfh_boys_m wfh_m

import excel using "`who_dir'/hfa_boys_2_5_zscores.xlsx", firstrow case(lower) clear
rename month __age_m
keep __age_m l m s
generate byte __sex = 1
rename (l m s) (l_haz_m m_haz_m s_haz_m)
save `hfa_boys_m'

import excel using "`who_dir'/hfa_girls_2_5_zscores.xlsx", firstrow case(lower) clear
rename month __age_m
keep __age_m l m s
generate byte __sex = 2
rename (l m s) (l_haz_m m_haz_m s_haz_m)
append using `hfa_boys_m'
isid __sex __age_m
save `hfa_m'

import excel using "`who_dir'/wfa_boys_0_5_zscores.xlsx", firstrow case(lower) clear
rename month __age_m
keep __age_m l m s
generate byte __sex = 1
rename (l m s) (l_waz_m m_waz_m s_waz_m)
save `wfa_boys_m'

import excel using "`who_dir'/wfa_girls_0_5_zscores.xlsx", firstrow case(lower) clear
rename month __age_m
keep __age_m l m s
generate byte __sex = 2
rename (l m s) (l_waz_m m_waz_m s_waz_m)
append using `wfa_boys_m'
isid __sex __age_m
save `wfa_m'

import excel using "`who_dir'/bmi_boys_2_5_zscores.xlsx", firstrow case(lower) clear
rename month __age_m
keep __age_m l m s
generate byte __sex = 1
rename (l m s) (l_bmiz_m m_bmiz_m s_bmiz_m)
save `bmi_boys_m'

import excel using "`who_dir'/bmi_girls_2_5_zscores.xlsx", firstrow case(lower) clear
rename month __age_m
keep __age_m l m s
generate byte __sex = 2
rename (l m s) (l_bmiz_m m_bmiz_m s_bmiz_m)
append using `bmi_boys_m'
isid __sex __age_m
save `bmi_m'

import excel using "`who_dir'/wfh_boys_2_5_zscores.xlsx", firstrow case(lower) clear
generate int __height2 = round(height * 2)
keep __height2 l m s
generate byte __sex = 1
rename (l m s) (l_whz_m m_whz_m s_whz_m)
save `wfh_boys_m'

import excel using "`who_dir'/wfh_girls_2_5_zscores.xlsx", firstrow case(lower) clear
generate int __height2 = round(height * 2)
keep __height2 l m s
generate byte __sex = 2
rename (l m s) (l_whz_m m_whz_m s_whz_m)
append using `wfh_boys_m'
isid __sex __height2
save `wfh_m'

use "`input_dta'", clear

isid BIRIMNO FERTNO
display as result "REFERENCE COHORT: " _N " children; actual months 24-62; analysis months 24-59."

foreach v in KILO BOY CINSIYET DOGUM_TARIH_GUN DOGUM_TARIH_AY              ///
    DOGUM_TARIH_YIL BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL              ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL {
    capture confirm numeric variable `v'
    if _rc destring `v', replace
}

clonevar __child_dob = child_dob
clonevar __survey_date = reference_date
clonevar __age_d = child_age_days
clonevar __age_m = child_months_analysis

generate byte __sex = CINSIYET
replace __sex = . if !inlist(__sex, 1, 2)
label define __sex_lbl 1 "Boy" 2 "Girl"
label values __sex __sex_lbl

generate double __weight = KILO
generate double __height = BOY
generate double __bmi = __weight / ((__height / 100)^2)                 ///
    if __weight > 0 & __height > 0

generate int __height2  = round(__height * 2)

capture confirm numeric variable FAKTOR_FERT
if !_rc generate double __w = FAKTOR_FERT
else generate double __w = real(subinstr(strtrim(FAKTOR_FERT), ",", ".", .))

generate int __run_father = (BABA_DOGUM_TARIH_YIL - 1987) * 12 +       ///
    (BABA_DOGUM_TARIH_AY - 1)
replace __run_father = . if missing(BABA_DOGUM_TARIH_YIL) |             ///
    !inrange(BABA_DOGUM_TARIH_AY, 1, 12)

generate int __run_mother = (ANNE_DOGUM_TARIH_YIL - 1987) * 12 +       ///
    (ANNE_DOGUM_TARIH_AY - 1)
replace __run_mother = . if missing(ANNE_DOGUM_TARIH_YIL) |             ///
    !inrange(ANNE_DOGUM_TARIH_AY, 1, 12)

keep if inlist(__sex, 1, 2)

merge m:1 __sex __age_m using `hfa_m', keep(master match) gen(__merge_haz_m)
merge m:1 __sex __age_m using `wfa_m', keep(master match) gen(__merge_waz_m)
merge m:1 __sex __age_m using `bmi_m', keep(master match) gen(__merge_bmiz_m)
merge m:1 __sex __height2 using `wfh_m', keep(master match) gen(__merge_whz_m)

capture program drop __who_lms_score
program define __who_lms_score
    version 18.0
    syntax, X(varname numeric) L(varname numeric) M(varname numeric)       ///
        S(varname numeric) GENerate(name)

    tempvar zraw c3 c2 cn3 cn2
    generate double `zraw' = ((`x' / `m')^`l' - 1) / (`l' * `s')       ///
        if !missing(`x', `l', `m', `s') & `x' > 0 & `m' > 0 & `l' != 0
    replace `zraw' = ln(`x' / `m') / `s'                               ///
        if !missing(`x', `l', `m', `s') & `x' > 0 & `m' > 0 & `l' == 0

    generate double `c3'  = `m' * (1 + `l' * `s' * 3)^(1 / `l')       ///
        if !missing(`l', `m', `s') & `l' != 0
    generate double `c2'  = `m' * (1 + `l' * `s' * 2)^(1 / `l')       ///
        if !missing(`l', `m', `s') & `l' != 0
    generate double `cn3' = `m' * (1 - `l' * `s' * 3)^(1 / `l')       ///
        if !missing(`l', `m', `s') & `l' != 0
    generate double `cn2' = `m' * (1 - `l' * `s' * 2)^(1 / `l')       ///
        if !missing(`l', `m', `s') & `l' != 0

    replace `c3'  = `m' * exp(`s' * 3)  if !missing(`m', `s') & `l' == 0
    replace `c2'  = `m' * exp(`s' * 2)  if !missing(`m', `s') & `l' == 0
    replace `cn3' = `m' * exp(-`s' * 3) if !missing(`m', `s') & `l' == 0
    replace `cn2' = `m' * exp(-`s' * 2) if !missing(`m', `s') & `l' == 0

    generate double `generate' = `zraw'
    replace `generate' = 3 + (`x' - `c3') / (`c3' - `c2')             ///
        if `zraw' > 3 & !missing(`zraw', `c3', `c2')
    replace `generate' = -3 + (`x' - `cn3') / (`cn2' - `cn3')         ///
        if `zraw' < -3 & !missing(`zraw', `cn3', `cn2')
end

generate byte domain_haz_monthly = (__merge_haz_m != 3) |              ///
    missing(__height) | __height <= 0
__who_lms_score, x(__height) l(l_haz_m) m(m_haz_m) s(s_haz_m)          ///
    generate(haz_monthly)
replace domain_haz_monthly = 1 if missing(haz_monthly)

generate byte domain_waz_monthly = (__merge_waz_m != 3) |              ///
    missing(__weight) | __weight <= 0
__who_lms_score, x(__weight) l(l_waz_m) m(m_waz_m) s(s_waz_m)          ///
    generate(waz_monthly)
replace domain_waz_monthly = 1 if missing(waz_monthly)

generate byte domain_bmiz_monthly = (__merge_bmiz_m != 3) |            ///
    missing(__bmi) | __bmi <= 0
__who_lms_score, x(__bmi) l(l_bmiz_m) m(m_bmiz_m) s(s_bmiz_m)          ///
    generate(bmiz_monthly)
replace domain_bmiz_monthly = 1 if missing(bmiz_monthly)

generate byte domain_whz_monthly = (__merge_whz_m != 3) |              ///
    missing(__weight) | __weight <= 0
__who_lms_score, x(__weight) l(l_whz_m) m(m_whz_m) s(s_whz_m)          ///
    generate(whz_monthly)
replace domain_whz_monthly = 1 if missing(whz_monthly)

generate byte flag_haz_monthly  = (haz_monthly  < -6 | haz_monthly  > 6) if !domain_haz_monthly
generate byte flag_waz_monthly  = (waz_monthly  < -6 | waz_monthly  > 5) if !domain_waz_monthly
generate byte flag_whz_monthly  = (whz_monthly  < -5 | whz_monthly  > 5) if !domain_whz_monthly
generate byte flag_bmiz_monthly = (bmiz_monthly < -5 | bmiz_monthly > 5) if !domain_bmiz_monthly

label variable haz_monthly  "WHO height-for-age z score, reference analysis-month LMS"
label variable waz_monthly  "WHO weight-for-age z score, reference analysis-month LMS"
label variable whz_monthly  "WHO weight-for-height z score, 0.5-cm LMS grid"
label variable bmiz_monthly "WHO BMI-for-age z score, reference analysis-month LMS"

drop __merge_*
compress
save "`output_dir'/who_lms_scores_monthly_age2_4.dta", replace

display as result "WHO LMS scores saved for capped reference: `output_dir'"
log close
clear

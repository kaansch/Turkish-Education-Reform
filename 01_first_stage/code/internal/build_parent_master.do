version 18.0
clear all
set more off
set varabbrev off

args parent linked_dta output_file
local prefix = cond("`parent'" == "father", "baba", "anne")
local sex = cond("`parent'" == "father", 1, 2)

use "`linked_dta'", clear
rename *, lower

foreach variable in birimno fertno `prefix'_birimno `prefix'_fertno      ///
    `prefix'_fertno_es {
    replace `variable' = strtrim(`variable')
}
isid birimno fertno
keep if `prefix'_birimno != "" & !inlist(`prefix'_fertno, "", "99")

foreach variable in faktor_hane `prefix'_cinsiyet                       ///
    `prefix'_dogum_tarih_gun `prefix'_dogum_tarih_ay                      ///
    `prefix'_dogum_tarih_yil `prefix'_medeni_durum `prefix'_fertno_es     ///
    `prefix'_okul_durum `prefix'_egitim_seviye                             ///
    `prefix'_seviye_bitirme_durum `prefix'_okur_yazar {
    bysort `prefix'_birimno `prefix'_fertno: assert `variable' == `variable'[1]
}
bysort `prefix'_birimno `prefix'_fertno: generate int n_linked_children = _N
bysort `prefix'_birimno `prefix'_fertno: keep if _n == 1
isid `prefix'_birimno `prefix'_fertno

keep `prefix'_birimno `prefix'_fertno n_linked_children faktor_hane     ///
    `prefix'_cinsiyet `prefix'_dogum_tarih_gun `prefix'_dogum_tarih_ay   ///
    `prefix'_dogum_tarih_yil `prefix'_medeni_durum `prefix'_fertno_es    ///
    `prefix'_okul_durum `prefix'_egitim_seviye                            ///
    `prefix'_seviye_bitirme_durum `prefix'_okur_yazar

rename `prefix'_birimno birimno
rename `prefix'_fertno `parent'_fertno
rename `prefix'_cinsiyet `parent'_cinsiyet
rename `prefix'_dogum_tarih_gun `parent'_birth_day
rename `prefix'_dogum_tarih_ay `parent'_birth_month
rename `prefix'_dogum_tarih_yil `parent'_birth_year
rename `prefix'_medeni_durum `parent'_marital_status
rename `prefix'_fertno_es `parent'_spouse_fertno
rename `prefix'_okul_durum `parent'_school_attendance
rename `prefix'_egitim_seviye `parent'_education_level
rename `prefix'_seviye_bitirme_durum `parent'_highest_level_completed
rename `prefix'_okur_yazar `parent'_literate

replace faktor_hane = subinstr(strtrim(faktor_hane), ",", ".", .)
destring faktor_hane, replace
foreach variable in `parent'_cinsiyet `parent'_birth_day                 ///
    `parent'_birth_month `parent'_birth_year `parent'_marital_status     ///
    `parent'_school_attendance `parent'_education_level                  ///
    `parent'_highest_level_completed `parent'_literate {
    replace `variable' = strtrim(`variable')
    destring `variable', replace
}
isid birimno `parent'_fertno

generate int `parent'_birth_ym = ym(`parent'_birth_year,                ///
    `parent'_birth_month) if !missing(`parent'_birth_year)                ///
    & inrange(`parent'_birth_month, 1, 12)
format `parent'_birth_ym %tm
generate double `parent'_birth_date = mdy(`parent'_birth_month,         ///
    `parent'_birth_day, `parent'_birth_year) if !missing(                 ///
    `parent'_birth_year, `parent'_birth_month, `parent'_birth_day)
format `parent'_birth_date %td
generate int run_month = `parent'_birth_ym - ym(1987, 1)
generate byte reform_exposed = (run_month >= 0) if !missing(run_month)

generate byte middle8_complete = .
replace middle8_complete = 0 if missing(`parent'_education_level)      ///
    & `parent'_school_attendance == 2
replace middle8_complete = 0 if inlist(`parent'_education_level, 0, 2)
replace middle8_complete = 0 if `parent'_education_level == 3           ///
    & `parent'_highest_level_completed == 2
replace middle8_complete = 1 if `parent'_education_level == 3           ///
    & `parent'_highest_level_completed == 1
replace middle8_complete = 1 if inlist(`parent'_education_level,        ///
    4, 511, 512, 521, 522, 53)
replace middle8_complete = . if `parent'_education_level == 99

label define yes_no 0 "No" 1 "Yes", replace
label values middle8_complete yes_no
label values reform_exposed yes_no
label variable run_month "Months from January 1987 cutoff"
label variable middle8_complete "Completed at least eight years of schooling"
label variable faktor_hane "Household estimation weight"
drop `parent'_school_attendance
order birimno `parent'_fertno n_linked_children faktor_hane             ///
    `parent'_birth_date `parent'_birth_ym run_month reform_exposed       ///
    middle8_complete
sort run_month birimno `parent'_fertno
compress
save "`output_file'", replace
display as result "Saved unique `parent' master: `output_file'"

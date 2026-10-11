version 18.0
clear all
set more off
set varabbrev off
args reference_dta output_dta eligibility_mode


local project_root    "C:/Users/Kaan Cil/Desktop/microdata"
local regression_root "`project_root'/age 2-4 mechanism/master do files"
local household_csv   "`project_root'/micro data/TCA_Hane_Mikroveri.csv"

capture mkdir "`regression_root'"
capture log close prep_age24
log using "`output_dta'.log", ///
    text replace name(prep_age24)

tempfile household_income

import delimited using "`household_csv'", delimiter(";") varnames(1) ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear

keep BIRIMNO GELIR_HANE HH_BUYUKLUK FAKTOR_HANE
replace BIRIMNO = strtrim(BIRIMNO)
replace GELIR_HANE = strtrim(GELIR_HANE)
replace HH_BUYUKLUK = strtrim(HH_BUYUKLUK)
replace FAKTOR_HANE = strtrim(FAKTOR_HANE)
destring GELIR_HANE HH_BUYUKLUK FAKTOR_HANE, replace dpcomma
isid BIRIMNO
label variable GELIR_HANE "Average monthly net household income (2022 TL)"
label variable HH_BUYUKLUK "Household size"
label variable FAKTOR_HANE "Household survey weight"
generate double income_per_person = GELIR_HANE / HH_BUYUKLUK

bysort GELIR_HANE (BIRIMNO): generate byte income_value_tag = (_n == 1)
sort GELIR_HANE BIRIMNO
generate long household_income_value_rank = sum(income_value_tag)
quietly count if income_value_tag
local n_income_values = r(N)
generate byte income5 = ///
    floor(5*(household_income_value_rank - 1)/`n_income_values') + 1
drop income_value_tag household_income_value_rank

bysort income_per_person (BIRIMNO): generate byte per_person_value_tag = (_n == 1)
sort income_per_person BIRIMNO
generate long income_per_person_value_rank = sum(per_person_value_tag)
quietly count if per_person_value_tag
local n_per_person_values = r(N)
generate byte income_per_person5 = ///
    floor(5*(income_per_person_value_rank - 1)/`n_per_person_values') + 1
drop per_person_value_tag income_per_person_value_rank

label variable income5 "Five groups of distinct household income values"
label variable income_per_person5 "Five groups of distinct income/person values"
save `household_income'

use "`reference_dta'", clear
isid BIRIMNO FERTNO
if "`eligibility_mode'" == "strict" keep if inrange(child_months_raw, 24, 59)

capture drop FAKTOR_HANE

merge m:1 BIRIMNO using `household_income', keep(master match) ///
    generate(_merge_income)
drop _merge_income

local health ENGEBEDE_YURUME ZIPLAMA GIYINME DUGME_ILIKLEME
local learning KELIME_SOYLEME UC_KELIMELIK_CUMLE BES_KELIMELIK_CUMLE ///
    ZAMIR_KULLANMA NESNE_ISMI_BILME ALFABE_BES_HARF ISMINI_YAZMA ///
    BIRDEN_BESE_SAYMA SAYILI_NESNE HATASIZ_SAYMA BOYA_YAPMA
local psychosocial_yesno BASKALARINI_SORMA YARDIM_TEKLIF IYI_GECINME
local direct_yesno `health' `learning' `psychosocial_yesno'
local all_items `health' `learning' `psychosocial_yesno' ///
    UZGUN_MUTSUZ ISIRMA_VURMA
local n_items : word count `all_items'

destring `all_items' CINSIYET BABA_DOGUM_TARIH_AY ///
    BABA_DOGUM_TARIH_YIL ANNE_DOGUM_TARIH_AY ///
    ANNE_DOGUM_TARIH_YIL, replace

local point_items
foreach v of local direct_yesno {
    generate byte point_`v' = (`v' == 1) if !missing(`v')
    local point_items `point_items' point_`v'
}

replace point_BES_KELIMELIK_CUMLE = 0 if ///
    missing(BES_KELIMELIK_CUMLE) & UC_KELIMELIK_CUMLE == 2

generate byte point_UZGUN_MUTSUZ = inlist(UZGUN_MUTSUZ, 5, 6, 9) ///
    if !missing(UZGUN_MUTSUZ)
generate byte point_ISIRMA_VURMA = inlist(ISIRMA_VURMA, 0, 1, 4) ///
    if !missing(ISIRMA_VURMA)
local point_items `point_items' point_UZGUN_MUTSUZ point_ISIRMA_VURMA

egen byte score_total_20 = rowtotal(`point_items'), missing
egen byte answered_total_20 = rownonmiss(`point_items')

generate byte unicef_age_group = .
replace unicef_age_group = 1 if inrange(child_months_analysis, 24, 29)
replace unicef_age_group = 2 if inrange(child_months_analysis, 30, 35)
replace unicef_age_group = 3 if inrange(child_months_analysis, 36, 41)
replace unicef_age_group = 4 if inrange(child_months_analysis, 42, 47)
replace unicef_age_group = 5 if inrange(child_months_analysis, 48, 59)

label define unicef_age_lbl 1 "24-29" 2 "30-35" 3 "36-41" ///
    4 "42-47" 5 "48-59", replace
label values unicef_age_group unicef_age_lbl

generate byte unicef_cutoff = .
replace unicef_cutoff = 7  if unicef_age_group == 1
replace unicef_cutoff = 9  if unicef_age_group == 2
replace unicef_cutoff = 11 if unicef_age_group == 3
replace unicef_cutoff = 13 if unicef_age_group == 4
replace unicef_cutoff = 15 if unicef_age_group == 5

generate byte unicef_ontrack = (score_total_20 >= unicef_cutoff)

generate byte female = (CINSIYET == 2)
generate double ln_household_income = ln(GELIR_HANE)

clonevar child_age_month = child_months_analysis

capture confirm numeric variable FAKTOR_FERT
if !_rc {
    generate double child_weight = FAKTOR_FERT
}
else {
    generate double child_weight = ///
        real(subinstr(strtrim(FAKTOR_FERT), ",", ".", .))
}

generate double household_weight = FAKTOR_HANE

generate int father_birth_ym = ym(BABA_DOGUM_TARIH_YIL, ///
    BABA_DOGUM_TARIH_AY) if inrange(BABA_DOGUM_TARIH_AY, 1, 12)
generate int mother_birth_ym = ym(ANNE_DOGUM_TARIH_YIL, ///
    ANNE_DOGUM_TARIH_AY) if inrange(ANNE_DOGUM_TARIH_AY, 1, 12)
format father_birth_ym mother_birth_ym %tm

generate int run_father = father_birth_ym - ym(1987, 1)
generate int run_mother = mother_birth_ym - ym(1987, 1)
generate byte eligible_father = (run_father >= 0) if !missing(run_father)
generate byte eligible_mother = (run_mother >= 0) if !missing(run_mother)

generate double __fertno_order = real(strtrim(FERTNO))
local n_initial = _N

gsort BIRIMNO FERTNO_OZ_ANNE child_dob __fertno_order
by BIRIMNO FERTNO_OZ_ANNE: generate byte __first_for_mother = (_n == 1)
keep if strtrim(FERTNO_OZ_ANNE) == "" | __first_for_mother
local n_after_mother = _N

gsort BIRIMNO child_dob __fertno_order
by BIRIMNO: keep if _n == 1
local n_primary = _N
isid BIRIMNO
drop __fertno_order __first_for_mother

label variable score_total_20 "Total favourable development items (0-20)"
label variable answered_total_20 "Development items scored"
label variable unicef_age_group "UNICEF child-age interval (months)"
label variable unicef_cutoff "UNICEF age-specific on-track cut score"
label variable unicef_ontrack "UNICEF age-specific developmentally on track"
label variable female "Child is female"
label variable child_age_month "Child analysis age in completed months"
label variable ln_household_income "Log average monthly net household income"
label variable child_weight "Child survey weight (FAKTOR_FERT)"
label variable household_weight "Household survey weight (FAKTOR_HANE)"
label variable run_father "Father birth month relative to January 1987"
label variable run_mother "Mother birth month relative to January 1987"
label variable eligible_father "Father born January 1987 or later"
label variable eligible_mother "Mother born January 1987 or later"

order BIRIMNO FERTNO child_dob child_months_raw child_months_analysis ///
    age_adjusted_60_62 unicef_age_group unicef_cutoff score_total_20 ///
    unicef_ontrack child_age_month female GELIR_HANE ln_household_income ///
    income5 income_per_person5 ///
    child_weight household_weight ///
    father_birth_ym run_father eligible_father mother_birth_ym ///
    run_mother eligible_mother
sort BIRIMNO

notes _dta: Primary age-2-4 regression sample: earliest-born eligible child per mother, then earliest-born eligible child per household; lowest numeric FERTNO resolves DOB ties.
if "`eligibility_mode'" == "capped" notes _dta: All development respondents with complete DOB are retained; raw ages below 24 map to 24 and above 59 map to 59.
if "`eligibility_mode'" == "strict" notes _dta: Only development respondents aged 24-59 completed months on the reference date are retained.
notes _dta: New non-UNICEF outcome families control for exact child analysis-month fixed effects; UNICEF intervals are retained only for the UNICEF composites and development-domain scores.
notes _dta: Child outcomes use FAKTOR_FERT. Household-income outcomes use one household record and FAKTOR_HANE.
compress
save "`output_dta'", replace

display as result "Prepared regression sample: `output_dta'"
display as result "Children: `n_initial' -> `n_after_mother' after mother rule -> `n_primary' after household rule."
tabulate unicef_age_group
summarize score_total_20 unicef_ontrack GELIR_HANE ln_household_income, detail
log close prep_age24
clear

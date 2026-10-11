version 18.0
clear all
set more off
args ref_date output_dir


local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local child_csv    "`project_root'/micro data/TCA_Fert_0-17_Mikroveri.csv"
local roster_csv   "`project_root'/micro data/TCA_Fertliste_Mikroveri.csv"
local hane_csv     "`project_root'/micro data/TCA_Hane_Mikroveri.csv"
local output_dta   "`output_dir'/all_development_respondents_reference.dta"

capture mkdir "`output_dir'"
capture log close
log using "`output_dir'/01_build_all_development_reference.log", text replace

tempfile child_base child_links father_block mother_block household_weight

import delimited using `"`child_csv'"', delimiter(";") varnames(1)           ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear

foreach id in BIRIMNO FERTNO {
    replace `id' = strtrim(`id')
}

isid BIRIMNO FERTNO


unab child_fields : _all
local child_field_count : word count `child_fields'

quietly count
local child_count = r(N)
save `child_base'

import delimited using `"`roster_csv'"', delimiter(";") varnames(1)          ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear

local roster_fields                                                        ///
    BIRIMNO FERTNO CINSIYET DOGUM_TARIH_GUN DOGUM_TARIH_AY                ///
    DOGUM_TARIH_YIL YAS_BITIRILEN YAS_YIL YAS_AY YAS_GUN                  ///
    YAKINLIK MEDENI_DURUM FERTNO_ES                                       ///
    OZ_ANNE_HAYATTA OZ_ANNE_BU_EVDE FERTNO_OZ_ANNE                        ///
    OZ_BABA_HAYATTA OZ_BABA_BU_EVDE FERTNO_OZ_BABA                        ///
    TEMEL_BAKIM GUNDUZ_BAKIM GUNDUZ_BAKIM_YAKINLIK HANE_DISINDAN          ///
    OKUL_DURUM EGITIM_SEVIYE SEVIYE_BITIRME_DURUM OKUR_YAZAR FAAL_DURUM

local roster_field_count : word count `roster_fields'

foreach v in BIRIMNO FERTNO FERTNO_OZ_BABA FERTNO_OZ_ANNE {
    replace `v' = strtrim(`v')
}
isid BIRIMNO FERTNO

preserve
    keep BIRIMNO FERTNO DOGUM_TARIH_GUN DOGUM_TARIH_AY                    ///
        DOGUM_TARIH_YIL FERTNO_OZ_BABA FERTNO_OZ_ANNE
    save `child_links'
restore

local father_fields                                                        ///
    BABA_BIRIMNO BABA_FERTNO BABA_CINSIYET BABA_DOGUM_TARIH_GUN          ///
    BABA_DOGUM_TARIH_AY BABA_DOGUM_TARIH_YIL BABA_YAS_BITIRILEN          ///
    BABA_YAS_YIL BABA_YAS_AY BABA_YAS_GUN BABA_YAKINLIK                  ///
    BABA_MEDENI_DURUM BABA_FERTNO_ES                                     ///
    BABA_OZ_ANNE_HAYATTA BABA_OZ_ANNE_BU_EVDE                            ///
    BABA_FERTNO_OZ_ANNE BABA_OZ_BABA_HAYATTA                             ///
    BABA_OZ_BABA_BU_EVDE BABA_FERTNO_OZ_BABA BABA_TEMEL_BAKIM            ///
    BABA_GUNDUZ_BAKIM BABA_GUNDUZ_BAKIM_YAKINLIK BABA_HANE_DISINDAN      ///
    BABA_OKUL_DURUM BABA_EGITIM_SEVIYE BABA_SEVIYE_BITIRME_DURUM         ///
    BABA_OKUR_YAZAR BABA_FAAL_DURUM

preserve
    keep `roster_fields'
    gen strL BABA_BIRIMNO = BIRIMNO
    gen strL BABA_FERTNO = FERTNO
    rename CINSIYET BABA_CINSIYET
    rename DOGUM_TARIH_GUN BABA_DOGUM_TARIH_GUN
    rename DOGUM_TARIH_AY BABA_DOGUM_TARIH_AY
    rename DOGUM_TARIH_YIL BABA_DOGUM_TARIH_YIL
    rename YAS_BITIRILEN BABA_YAS_BITIRILEN
    rename YAS_YIL BABA_YAS_YIL
    rename YAS_AY BABA_YAS_AY
    rename YAS_GUN BABA_YAS_GUN
    rename YAKINLIK BABA_YAKINLIK
    rename MEDENI_DURUM BABA_MEDENI_DURUM
    rename FERTNO_ES BABA_FERTNO_ES
    rename OZ_ANNE_HAYATTA BABA_OZ_ANNE_HAYATTA
    rename OZ_ANNE_BU_EVDE BABA_OZ_ANNE_BU_EVDE
    rename FERTNO_OZ_ANNE BABA_FERTNO_OZ_ANNE
    rename OZ_BABA_HAYATTA BABA_OZ_BABA_HAYATTA
    rename OZ_BABA_BU_EVDE BABA_OZ_BABA_BU_EVDE
    rename FERTNO_OZ_BABA BABA_FERTNO_OZ_BABA
    rename TEMEL_BAKIM BABA_TEMEL_BAKIM
    rename GUNDUZ_BAKIM BABA_GUNDUZ_BAKIM
    rename GUNDUZ_BAKIM_YAKINLIK BABA_GUNDUZ_BAKIM_YAKINLIK
    rename HANE_DISINDAN BABA_HANE_DISINDAN
    rename OKUL_DURUM BABA_OKUL_DURUM
    rename EGITIM_SEVIYE BABA_EGITIM_SEVIYE
    rename SEVIYE_BITIRME_DURUM BABA_SEVIYE_BITIRME_DURUM
    rename OKUR_YAZAR BABA_OKUR_YAZAR
    rename FAAL_DURUM BABA_FAAL_DURUM
    rename FERTNO FERTNO_OZ_BABA
    order BIRIMNO FERTNO_OZ_BABA `father_fields'
    isid BIRIMNO FERTNO_OZ_BABA
    save `father_block'
restore

local mother_fields                                                        ///
    ANNE_BIRIMNO ANNE_FERTNO ANNE_CINSIYET ANNE_DOGUM_TARIH_GUN          ///
    ANNE_DOGUM_TARIH_AY ANNE_DOGUM_TARIH_YIL ANNE_YAS_BITIRILEN          ///
    ANNE_YAS_YIL ANNE_YAS_AY ANNE_YAS_GUN ANNE_YAKINLIK                  ///
    ANNE_MEDENI_DURUM ANNE_FERTNO_ES                                     ///
    ANNE_OZ_ANNE_HAYATTA ANNE_OZ_ANNE_BU_EVDE                            ///
    ANNE_FERTNO_OZ_ANNE ANNE_OZ_BABA_HAYATTA                             ///
    ANNE_OZ_BABA_BU_EVDE ANNE_FERTNO_OZ_BABA ANNE_TEMEL_BAKIM            ///
    ANNE_GUNDUZ_BAKIM ANNE_GUNDUZ_BAKIM_YAKINLIK ANNE_HANE_DISINDAN      ///
    ANNE_OKUL_DURUM ANNE_EGITIM_SEVIYE ANNE_SEVIYE_BITIRME_DURUM         ///
    ANNE_OKUR_YAZAR ANNE_FAAL_DURUM

keep `roster_fields'
gen strL ANNE_BIRIMNO = BIRIMNO
gen strL ANNE_FERTNO = FERTNO
rename CINSIYET ANNE_CINSIYET
rename DOGUM_TARIH_GUN ANNE_DOGUM_TARIH_GUN
rename DOGUM_TARIH_AY ANNE_DOGUM_TARIH_AY
rename DOGUM_TARIH_YIL ANNE_DOGUM_TARIH_YIL
rename YAS_BITIRILEN ANNE_YAS_BITIRILEN
rename YAS_YIL ANNE_YAS_YIL
rename YAS_AY ANNE_YAS_AY
rename YAS_GUN ANNE_YAS_GUN
rename YAKINLIK ANNE_YAKINLIK
rename MEDENI_DURUM ANNE_MEDENI_DURUM
rename FERTNO_ES ANNE_FERTNO_ES
rename OZ_ANNE_HAYATTA ANNE_OZ_ANNE_HAYATTA
rename OZ_ANNE_BU_EVDE ANNE_OZ_ANNE_BU_EVDE
rename FERTNO_OZ_ANNE ANNE_FERTNO_OZ_ANNE
rename OZ_BABA_HAYATTA ANNE_OZ_BABA_HAYATTA
rename OZ_BABA_BU_EVDE ANNE_OZ_BABA_BU_EVDE
rename FERTNO_OZ_BABA ANNE_FERTNO_OZ_BABA
rename TEMEL_BAKIM ANNE_TEMEL_BAKIM
rename GUNDUZ_BAKIM ANNE_GUNDUZ_BAKIM
rename GUNDUZ_BAKIM_YAKINLIK ANNE_GUNDUZ_BAKIM_YAKINLIK
rename HANE_DISINDAN ANNE_HANE_DISINDAN
rename OKUL_DURUM ANNE_OKUL_DURUM
rename EGITIM_SEVIYE ANNE_EGITIM_SEVIYE
rename SEVIYE_BITIRME_DURUM ANNE_SEVIYE_BITIRME_DURUM
rename OKUR_YAZAR ANNE_OKUR_YAZAR
rename FAAL_DURUM ANNE_FAAL_DURUM
rename FERTNO FERTNO_OZ_ANNE
order BIRIMNO FERTNO_OZ_ANNE `mother_fields'
isid BIRIMNO FERTNO_OZ_ANNE
save `mother_block'

import delimited using `"`hane_csv'"', delimiter(";") varnames(1)            ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear

keep BIRIMNO FAKTOR_HANE
replace BIRIMNO = strtrim(BIRIMNO)
isid BIRIMNO
save `household_weight'

use `child_base', clear

merge 1:1 BIRIMNO FERTNO using `child_links', keep(master match)           ///
    gen(_merge_child_link)
drop _merge_child_link

merge m:1 BIRIMNO FERTNO_OZ_BABA using `father_block', keep(master match)  ///
    gen(_merge_father)
quietly count if _merge_father == 3
local father_matches_raw = r(N)
generate byte father_linked = (_merge_father == 3)

merge m:1 BIRIMNO FERTNO_OZ_ANNE using `mother_block', keep(master match)  ///
    gen(_merge_mother)
quietly count if _merge_mother == 3
local mother_matches_raw = r(N)
generate byte mother_linked = (_merge_mother == 3)

drop _merge_father _merge_mother

merge m:1 BIRIMNO using `household_weight', keep(master match)             ///
    gen(_merge_household)
drop _merge_household

local development_items ENGEBEDE_YURUME ZIPLAMA GIYINME DUGME_ILIKLEME ///
    KELIME_SOYLEME UC_KELIMELIK_CUMLE BES_KELIMELIK_CUMLE ZAMIR_KULLANMA ///
    NESNE_ISMI_BILME ALFABE_BES_HARF ISMINI_YAZMA BIRDEN_BESE_SAYMA ///
    SAYILI_NESNE HATASIZ_SAYMA BOYA_YAPMA BASKALARINI_SORMA YARDIM_TEKLIF ///
    IYI_GECINME UZGUN_MUTSUZ ISIRMA_VURMA
local n_development_items : word count `development_items'
generate byte ecdi_items_answered = 0
foreach v of local development_items {
    replace ecdi_items_answered = ecdi_items_answered + (strtrim(`v') != "")
}
quietly count if ecdi_items_answered > 0
generate double reference_date = date("`ref_date'", "YMD")
generate double child_dob = mdy(real(DOGUM_TARIH_AY), ///
    real(DOGUM_TARIH_GUN), real(DOGUM_TARIH_YIL))
generate int child_age_days = reference_date - child_dob
generate int child_months_raw = ///
    (year(reference_date)-real(DOGUM_TARIH_YIL))*12 + ///
    month(reference_date)-real(DOGUM_TARIH_AY)
replace child_months_raw = child_months_raw - 1 if ///
    real(DOGUM_TARIH_GUN) > day(reference_date)
replace child_months_raw = . if missing(child_dob) | child_age_days < 0
quietly count if ecdi_items_answered > 0 & missing(child_months_raw)
keep if ecdi_items_answered > 0 & !missing(child_months_raw)
generate byte in_original_24_59 = inrange(child_months_raw, 24, 59)
generate byte age_adjusted_60_62 = inrange(child_months_raw, 60, 62)
generate int child_months_analysis = ///
    max(24, min(child_months_raw, 59))
generate double father_dob = mdy(real(BABA_DOGUM_TARIH_AY), ///
    real(BABA_DOGUM_TARIH_GUN), real(BABA_DOGUM_TARIH_YIL))
generate double mother_dob = mdy(real(ANNE_DOGUM_TARIH_AY), ///
    real(ANNE_DOGUM_TARIH_GUN), real(ANNE_DOGUM_TARIH_YIL))
format reference_date child_dob father_dob mother_dob %tdCCYY-NN-DD

order `child_fields' `father_fields' `mother_fields' FAKTOR_HANE
order DOGUM_TARIH_GUN DOGUM_TARIH_AY DOGUM_TARIH_YIL, before(YAS_YIL)
order child_dob reference_date child_age_days child_months_raw child_months_analysis ///
    age_adjusted_60_62 in_original_24_59 ecdi_items_answered, after(DOGUM_TARIH_YIL)
order FERTNO_OZ_BABA FERTNO_OZ_ANNE father_linked mother_linked, before(BABA_BIRIMNO)
order father_dob, after(BABA_DOGUM_TARIH_YIL)
order mother_dob, after(ANNE_DOGUM_TARIH_YIL)
unab final_fields : _all
local final_field_count : word count `final_fields'
sort BIRIMNO FERTNO

label data "All development respondents with complete DOB; age capped 24 to 59"
label variable child_months_raw "DOB-based completed months at scenario reference date"
label variable child_months_analysis "Analysis age; raw below 24 set to 24 and above 59 set to 59"
label variable age_adjusted_60_62 "Raw age is 60 to 62 months"
label variable in_original_24_59 "Raw age is 24 to 59 months"
label variable ecdi_items_answered "Recorded development items out of 20"
label variable reference_date "Scenario child-age reference date"
label variable child_dob "Complete child DOB from FertListe"
label variable child_age_days "Days from child DOB to reference date"
label variable father_linked "Biological father matched within household"
label variable mother_linked "Biological mother matched within household"
label variable FERTNO_OZ_BABA "Child roster pointer to biological father"
label variable FERTNO_OZ_ANNE "Child roster pointer to biological mother"
label variable father_dob "Full DOB from matched father record"
label variable mother_dob "Full DOB from matched mother record"
notes _dta: All 2322 development-module respondents with complete DOB are retained regardless of raw calculated age; four incomplete-DOB respondents are excluded by user instruction.
notes _dta: Below 24 months maps to analysis month 24 and above 59 months maps to analysis month 59; original DOB and raw age are preserved.
compress
save `"`output_dta'"', replace
display as result "Reference date: `ref_date'; respondents with complete DOB: " _N
tabulate child_months_raw if child_months_raw < 24 | child_months_raw > 59
tabulate ecdi_items_answered
log close
clear

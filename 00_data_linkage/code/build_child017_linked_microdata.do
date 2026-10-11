version 18.0
clear all
set more off

local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local child_csv    "`project_root'/micro data/TCA_Fert_0-17_Mikroveri.csv"
local roster_csv   "`project_root'/micro data/TCA_Fertliste_Mikroveri.csv"
local hane_csv     "`project_root'/micro data/TCA_Hane_Mikroveri.csv"
local output_dir   "`project_root'/0-17 linked microdata"
local output_dta   "`output_dir'/child017_linked.dta"

capture mkdir "`project_root'/0-17 linked microdata"
capture mkdir "`output_dir'"

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
assert _merge_child_link == 3
drop _merge_child_link

merge m:1 BIRIMNO FERTNO_OZ_BABA using `father_block', keep(master match)  ///
    gen(_merge_father)
quietly count if _merge_father == 3
local father_matches = r(N)

merge m:1 BIRIMNO FERTNO_OZ_ANNE using `mother_block', keep(master match)  ///
    gen(_merge_mother)
quietly count if _merge_mother == 3
local mother_matches = r(N)

drop FERTNO_OZ_BABA FERTNO_OZ_ANNE _merge_father _merge_mother

merge m:1 BIRIMNO using `household_weight', keep(master match)             ///
    gen(_merge_household)
assert _merge_household == 3
drop _merge_household

order `child_fields' `father_fields' `mother_fields' FAKTOR_HANE
order DOGUM_TARIH_GUN DOGUM_TARIH_AY DOGUM_TARIH_YIL, before(YAS_YIL)
isid BIRIMNO FERTNO

unab final_fields : _all
local final_field_count : word count `final_fields'

compress
save `"`output_dta'"', replace

di as result "Original 0-17 child records retained: " %12.0fc `child_count'
di as result "Original child fields retained: " %9.0fc `child_field_count'
di as result "Child FertListe birth-date fields added: " %9.0fc 3
di as result "Children linked to a biological-father record: "           ///
    %12.0fc `father_matches'
di as result "Children linked to a biological-mother record: "           ///
    %12.0fc `mother_matches'
di as result "Final field count: " %9.0fc `final_field_count'
di as text "Saved main linked base: `output_dta'"

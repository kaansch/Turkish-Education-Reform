version 18.0
clear all
set more off
set varabbrev off


local project_root    "C:/Users/Kaan Cil/Desktop/microdata"
local regression_root "`project_root'/age 2-4 mechanism/master do files"
local input_dta       "`regression_root'/age2_4_regression_sample.dta"
local who_dta         "`project_root'/age 2-4 rdd graphs/WHO LMS RDD/outputs/who_lms_scores_monthly_age2_4.dta"
local output_dta      "`regression_root'/age2_4_all_outcomes_sample.dta"

capture log close prep_outcomes
log using "`regression_root'/02_prepare_all_additional_outcomes.log", ///
    text replace name(prep_outcomes)

use "`input_dta'", clear
isid BIRIMNO

local home KENDI_ODA COCUK_KITAP
local activities BIRLIKTE_KITAP_OKUMA BIRLIKTE_HIKAYE ///
    BIRLIKTE_SARKI BIRLIKTE_DISARI BIRLIKTE_OYNAMA BIRLIKTE_CIZME
local partners KIMLE_KITAP_OKUMA KIMLE_HIKAYE KIMLE_SARKI ///
    KIMLE_DISARI KIMLE_OYNAMA KIMLE_CIZME
local hygiene DIS_FIRCALAMA DIS_HEKIMI EL_YIKAMA_SABAH ///
    EL_YIKAMA_GELINCE EL_YIKAMA_YEMEK_ONCESI ///
    EL_YIKAMA_YEMEK_SONRASI EL_YIKAMA_TUVALET BANYO_DUS
local foods MEYVE_YEME SEBZE_YEME ET_TAVUK_BALIK_YEME ///
    BAKLIYAT_YEME HAYVAN_URUNU_YEME TATLI_YEME ///
    ATISTIRMALIK_YEME ALKOLSUZ_ICECEK_ICME TAHIL_YEME
local discipline DISIPLIN_AYRICALIK DISIPLIN_DAVRANIS_YANLIS ///
    DISIPLIN_SARSMA DISIPLIN_BAGIRMA DISIPLIN_BIRSEY_VERME ///
    DISIPLIN_SEVMEME DISIPLIN_VURMA DISIPLIN_SERT_VURMA ///
    DISIPLIN_HAKIR_GORME DISIPLIN_TOKAT ///
    DISIPLIN_EL_KOL_BACAK_VURMA DISIPLIN_SIDDETLI_DOVME ///
    DISIPLIN_KUCUK_DUSURME DISIPLIN_GORMEZDEN_GELME ///
    DISIPLIN_ARKADAS_GORUSTURMEME DISIPLIN_HARCLIK_KESME
local other ANNE_SUTU YAKINLIK_BAKIM_VEREN KILO BOY

destring `home' `activities' `partners' `hygiene' `foods' ///
    `discipline' `other', replace


generate byte home_own_room = (KENDI_ODA == 1) if inlist(KENDI_ODA, 1, 2)
generate byte home_books_ge3 = (COCUK_KITAP >= 3) if !missing(COCUK_KITAP)
generate byte home_books_ge10 = (COCUK_KITAP >= 10) if !missing(COCUK_KITAP)

label variable home_own_room "Child has own room"
label variable home_books_ge3 "At least 3 children's books"
label variable home_books_ge10 "At least 10 children's books"


local activity_suffixes kitap_okuma hikaye sarki disari oynama cizme
local activity_sources  BIRLIKTE_KITAP_OKUMA BIRLIKTE_HIKAYE ///
    BIRLIKTE_SARKI BIRLIKTE_DISARI BIRLIKTE_OYNAMA BIRLIKTE_CIZME

forvalues j = 1/6 {
    local suffix : word `j' of `activity_suffixes'
    local source : word `j' of `activity_sources'
    generate byte activity_`suffix' = (`source' == 1) if inlist(`source', 1, 2)
}
label variable activity_kitap_okuma "Read books with an adult household member"
label variable activity_hikaye "Told stories with an adult household member"
label variable activity_sarki "Sang songs with an adult household member"
label variable activity_disari "Went outside with an adult household member"
label variable activity_oynama "Played with an adult household member"
label variable activity_cizme "Drew or painted with an adult household member"


local partner_sources KIMLE_KITAP_OKUMA KIMLE_HIKAYE KIMLE_SARKI ///
    KIMLE_DISARI KIMLE_OYNAMA KIMLE_CIZME

forvalues j = 1/6 {
    local suffix : word `j' of `activity_suffixes'
    local activity_source : word `j' of `activity_sources'
    local partner_source : word `j' of `partner_sources'

    generate byte partner_father_`suffix' = ///
        (`activity_source' == 1 & `partner_source' == 2) ///
        if inlist(`activity_source', 1, 2)
    generate byte partner_mother_`suffix' = ///
        (`activity_source' == 1 & `partner_source' == 1) ///
        if inlist(`activity_source', 1, 2)

}
label variable partner_father_kitap_okuma "Read books with father"
label variable partner_mother_kitap_okuma "Read books with mother"
label variable partner_father_hikaye "Told stories with father"
label variable partner_mother_hikaye "Told stories with mother"
label variable partner_father_sarki "Sang songs with father"
label variable partner_mother_sarki "Sang songs with mother"
label variable partner_father_disari "Went outside with father"
label variable partner_mother_disari "Went outside with mother"
label variable partner_father_oynama "Played with father"
label variable partner_mother_oynama "Played with mother"
label variable partner_father_cizme "Drew or painted with father"
label variable partner_mother_cizme "Drew or painted with mother"


local dev_health point_ENGEBEDE_YURUME point_ZIPLAMA ///
    point_GIYINME point_DUGME_ILIKLEME
local dev_learning point_KELIME_SOYLEME point_UC_KELIMELIK_CUMLE ///
    point_BES_KELIMELIK_CUMLE point_ZAMIR_KULLANMA ///
    point_NESNE_ISMI_BILME point_ALFABE_BES_HARF point_ISMINI_YAZMA ///
    point_BIRDEN_BESE_SAYMA point_SAYILI_NESNE point_HATASIZ_SAYMA ///
    point_BOYA_YAPMA
local dev_psychosocial point_BASKALARINI_SORMA point_YARDIM_TEKLIF ///
    point_IYI_GECINME point_UZGUN_MUTSUZ point_ISIRMA_VURMA

egen byte domain_health = rowtotal(`dev_health'), missing
egen byte domain_learning = rowtotal(`dev_learning'), missing
egen byte domain_psychosocial = rowtotal(`dev_psychosocial'), missing
label variable domain_health "Health development score 0 to 4"
label variable domain_learning "Learning development score 0 to 11"
label variable domain_psychosocial "Psychosocial well-being score 0 to 5"

label variable point_ENGEBEDE_YURUME "Walks on uneven ground"
label variable point_ZIPLAMA "Jumps with both feet"
label variable point_GIYINME "Dresses independently"
label variable point_DUGME_ILIKLEME "Fastens buttons"
label variable point_KELIME_SOYLEME "Says recognizable words"
label variable point_UC_KELIMELIK_CUMLE "Uses sentences of at least three words"
label variable point_BES_KELIMELIK_CUMLE "Uses sentences of at least five words"
label variable point_ZAMIR_KULLANMA "Uses personal pronouns correctly"
label variable point_NESNE_ISMI_BILME "Names familiar objects"
label variable point_ALFABE_BES_HARF "Recognizes at least five letters"
label variable point_ISMINI_YAZMA "Writes own name"
label variable point_BIRDEN_BESE_SAYMA "Counts from one to five"
label variable point_SAYILI_NESNE "Gives a requested number of objects"
label variable point_HATASIZ_SAYMA "Counts objects accurately"
label variable point_BOYA_YAPMA "Draws or paints"
label variable point_BASKALARINI_SORMA "Shows interest in other people"
label variable point_YARDIM_TEKLIF "Offers to help"
label variable point_IYI_GECINME "Gets along with other children"
label variable point_UZGUN_MUTSUZ "Rarely or never seems sad or unhappy"
label variable point_ISIRMA_VURMA "Does not bite or hit more than peers"


generate byte hygiene_brush_daily = inlist(DIS_FIRCALAMA, 16, 17) ///
    if !missing(DIS_FIRCALAMA) & DIS_FIRCALAMA != 99
generate byte hygiene_dentist_year = (DIS_HEKIMI == 1) ///
    if inlist(DIS_HEKIMI, 1, 2)
generate byte hygiene_wash_morning = (EL_YIKAMA_SABAH == 1) ///
    if inlist(EL_YIKAMA_SABAH, 1, 2)
generate byte hygiene_wash_return = (EL_YIKAMA_GELINCE == 1) ///
    if inlist(EL_YIKAMA_GELINCE, 1, 2)
generate byte hygiene_wash_before_meal = (EL_YIKAMA_YEMEK_ONCESI == 1) ///
    if inlist(EL_YIKAMA_YEMEK_ONCESI, 1, 2)
generate byte hygiene_wash_after_meal = (EL_YIKAMA_YEMEK_SONRASI == 1) ///
    if inlist(EL_YIKAMA_YEMEK_SONRASI, 1, 2)
generate byte hygiene_wash_toilet = (EL_YIKAMA_TUVALET == 1) ///
    if inlist(EL_YIKAMA_TUVALET, 1, 2)
generate byte hygiene_bath_frequent = inlist(BANYO_DUS, 21, 26, 27) ///
    if !missing(BANYO_DUS) & BANYO_DUS != 99

label variable hygiene_brush_daily "Brushes teeth daily or more often"
label variable hygiene_dentist_year "Visited a dentist in the past year"
label variable hygiene_wash_morning "Washes hands in the morning"
label variable hygiene_wash_return "Washes hands after returning home"
label variable hygiene_wash_before_meal "Washes hands before meals"
label variable hygiene_wash_after_meal "Washes hands after meals"
label variable hygiene_wash_toilet "Washes hands after toilet use"
label variable hygiene_bath_frequent "Bathes at least twice per week"


local food_suffixes fruit vegetables meatfish legumes ///
    animalprod sweets snacks softdrink grains

forvalues j = 1/9 {
    local source : word `j' of `foods'
    local suffix : word `j' of `food_suffixes'
    generate byte nutrition_weekly_`suffix' = inrange(`source', 1, 3) ///
        if inrange(`source', 1, 9)
    generate byte nutrition_strict_`suffix' = inrange(`source', 1, 2) ///
        if inrange(`source', 1, 9)
}

label variable nutrition_weekly_fruit "Fruit consumed at least weekly"
label variable nutrition_weekly_vegetables "Vegetables consumed at least weekly"
label variable nutrition_weekly_meatfish "Meat fish or poultry consumed at least weekly"
label variable nutrition_weekly_legumes "Legumes consumed at least weekly"
label variable nutrition_weekly_animalprod "Animal products consumed at least weekly"
label variable nutrition_weekly_sweets "Sweets consumed at least weekly"
label variable nutrition_weekly_snacks "Snack foods consumed at least weekly"
label variable nutrition_weekly_softdrink "Packaged soft drinks consumed at least weekly"
label variable nutrition_weekly_grains "Grains consumed at least weekly"
label variable nutrition_strict_fruit "Fruit consumed daily or several times weekly"
label variable nutrition_strict_vegetables "Vegetables consumed daily or several times weekly"
label variable nutrition_strict_meatfish "Meat fish or poultry consumed daily or several times weekly"
label variable nutrition_strict_legumes "Legumes consumed daily or several times weekly"
label variable nutrition_strict_animalprod "Animal products consumed daily or several times weekly"
label variable nutrition_strict_sweets "Sweets consumed daily or several times weekly"
label variable nutrition_strict_snacks "Snack foods consumed daily or several times weekly"
label variable nutrition_strict_softdrink "Packaged soft drinks consumed daily or several times weekly"
label variable nutrition_strict_grains "Grains consumed daily or several times weekly"

generate byte nutrition_ever_breastfed = (ANNE_SUTU == 1) ///
    if inlist(ANNE_SUTU, 1, 2)
label variable nutrition_ever_breastfed "Child was ever breastfed"


local disc_suffixes privilege explain shake shout distract withhold_love ///
    hit_bottom hit_object demean slap_face hit_limbs beat_hard humiliate ///
    ignore prevent_friends cut_allowance

forvalues j = 1/16 {
    local source : word `j' of `discipline'
    local suffix : word `j' of `disc_suffixes'
    generate byte discipline_`suffix' = (`source' == 1) ///
        if inlist(`source', 1, 2)
}

label variable discipline_privilege "Removed privileges or restricted activity"
label variable discipline_explain "Explained why behaviour was wrong"
label variable discipline_shake "Shook the child"
label variable discipline_shout "Shouted or yelled at the child"
label variable discipline_distract "Redirected the child with something else"
label variable discipline_withhold_love "Withheld affection from the child"
label variable discipline_hit_bottom "Hit the child on the bottom with a bare hand"
label variable discipline_hit_object "Hit the child with a hard object"
label variable discipline_demean "Called the child dumb lazy or similar"
label variable discipline_slap_face "Hit face head or ears or pulled ears"
label variable discipline_hit_limbs "Hit or slapped hand arm or leg"
label variable discipline_beat_hard "Beat the child hard and repeatedly"
label variable discipline_humiliate "Insulted humiliated or shamed the child"
label variable discipline_ignore "Ignored the child or refused to speak"
label variable discipline_prevent_friends "Prevented the child from seeing friends"
label variable discipline_cut_allowance "Cut allowance or refused requested purchases"

egen byte discipline_nonviolent = rowmax(discipline_privilege ///
    discipline_explain discipline_distract)
egen byte discipline_psychological = rowmax(discipline_shout ///
    discipline_withhold_love discipline_demean discipline_humiliate ///
    discipline_ignore)
egen byte discipline_physical = rowmax(discipline_shake ///
    discipline_hit_bottom discipline_hit_object discipline_slap_face ///
    discipline_hit_limbs discipline_beat_hard)
egen byte discipline_severe = rowmax(discipline_slap_face ///
    discipline_beat_hard)
egen byte discipline_any_violent = rowmax(discipline_psychological ///
    discipline_physical)

label variable discipline_nonviolent "Any nonviolent discipline method"
label variable discipline_psychological "Any psychological aggression"
label variable discipline_physical "Any physical punishment"
label variable discipline_severe "Any severe physical punishment"
label variable discipline_any_violent "Any violent discipline"


generate byte caregiver_father = (YAKINLIK_BAKIM_VEREN == 2) ///
    if inlist(YAKINLIK_BAKIM_VEREN, 1, 2, 6, 7)
generate byte caregiver_mother = (YAKINLIK_BAKIM_VEREN == 1) ///
    if inlist(YAKINLIK_BAKIM_VEREN, 1, 2, 6, 7)
generate byte caregiver_nonmother = (YAKINLIK_BAKIM_VEREN != 1) ///
    if inlist(YAKINLIK_BAKIM_VEREN, 1, 2, 6, 7)
label variable caregiver_father "Father is the primary caregiver"
label variable caregiver_mother "Mother is the primary caregiver"
label variable caregiver_nonmother "Primary caregiver is not the mother"


generate double income_level = GELIR_HANE
generate double income_log = ln_household_income
quietly _pctile GELIR_HANE, p(1 99)
local income_p1 = r(r1)
local income_p99 = r(r2)
generate double income_level_trim1 = GELIR_HANE ///
    if inrange(GELIR_HANE, `income_p1', `income_p99')
label variable income_level "Monthly net household income in 2022 TL"
label variable income_log "Log monthly net household income"
label variable income_level_trim1 "Monthly household income trimmed at 1st and 99th percentiles"


clonevar weight_kg_all = KILO
clonevar height_cm_all = BOY
label variable weight_kg_all "Weight in kg for all children"
label variable height_cm_all "Height in cm for all children"


preserve
use "`who_dta'", clear
keep BIRIMNO FERTNO haz_monthly waz_monthly whz_monthly bmiz_monthly ///
    domain_haz_monthly domain_waz_monthly domain_whz_monthly ///
    domain_bmiz_monthly flag_haz_monthly flag_waz_monthly ///
    flag_whz_monthly flag_bmiz_monthly
isid BIRIMNO FERTNO
tempfile who_scores
save `who_scores'
restore

merge 1:1 BIRIMNO FERTNO using `who_scores', keep(master match) ///
    generate(_merge_who)
drop _merge_who

generate double who_haz = haz_monthly ///
    if domain_haz_monthly == 0 & flag_haz_monthly == 0
generate double who_waz = waz_monthly ///
    if domain_waz_monthly == 0 & flag_waz_monthly == 0
generate double who_whz = whz_monthly ///
    if domain_whz_monthly == 0 & flag_whz_monthly == 0
generate double who_bmiz = bmiz_monthly ///
    if domain_bmiz_monthly == 0 & flag_bmiz_monthly == 0

label variable who_haz "WHO height-for-age z score"
label variable who_waz "WHO weight-for-age z score"
label variable who_whz "WHO weight-for-height z score"
label variable who_bmiz "WHO BMI-for-age z score"

generate byte who_stunted = (who_haz < -2) if !missing(who_haz)
generate byte who_underweight = (who_waz < -2) if !missing(who_waz)
generate byte who_wasted = (who_whz < -2) if !missing(who_whz)
generate byte who_overweight = (who_whz > 2) if !missing(who_whz)
generate byte who_obese = (who_whz > 3) if !missing(who_whz)
generate byte who_ciaf = (who_haz < -2 | who_waz < -2 | who_whz < -2) ///
    if !missing(who_haz, who_waz, who_whz)
generate byte who_below_bmiz = (who_bmiz < -2) if !missing(who_bmiz)

label variable who_stunted "Stunted HAZ below -2"
label variable who_underweight "Underweight WAZ below -2"
label variable who_wasted "Wasted WHZ below -2"
label variable who_overweight "Overweight WHZ above +2"
label variable who_obese "Obese WHZ above +3"
label variable who_ciaf "CIAF any stunting underweight or wasting"
label variable who_below_bmiz "Below-normal BMI-for-age BMIZ below -2"

generate byte who_not_stunted = (who_haz >= -2) if !missing(who_haz)
generate byte who_not_underweight = (who_waz >= -2) if !missing(who_waz)
generate byte who_neither_whz = inrange(who_whz, -2, 2) if !missing(who_whz)
generate byte who_neither_bmiz = inrange(who_bmiz, -2, 2) if !missing(who_bmiz)
generate byte who_normal_haz = inrange(who_haz, -2, 3) if !missing(who_haz)
generate byte who_normal_waz = inrange(who_waz, -2, 1) if !missing(who_waz)
generate byte who_normal_whz = inrange(who_whz, -2, 1) if !missing(who_whz)
generate byte who_normal_bmiz = inrange(who_bmiz, -2, 1) if !missing(who_bmiz)
generate byte who_above_haz = (who_haz > 3) if !missing(who_haz)
generate byte who_above_waz = (who_waz > 1) if !missing(who_waz)
generate byte who_above_whz = (who_whz > 1) if !missing(who_whz)
generate byte who_above_bmiz = (who_bmiz > 1) if !missing(who_bmiz)

label variable who_not_stunted "Not stunted HAZ at least -2"
label variable who_not_underweight "Not underweight WAZ at least -2"
label variable who_neither_whz "Neither wasted nor overweight WHZ -2 to +2"
label variable who_neither_bmiz "Neither low nor high BMIZ -2 to +2"
label variable who_normal_haz "Strict normal HAZ -2 to +3"
label variable who_normal_waz "Strict normal WAZ -2 to +1"
label variable who_normal_whz "Strict normal WHZ -2 to +1"
label variable who_normal_bmiz "Strict normal BMIZ -2 to +1"
label variable who_above_haz "Above-normal height HAZ above +3"
label variable who_above_waz "Above-normal weight WAZ above +1"
label variable who_above_whz "Above-normal WHZ above +1"
label variable who_above_bmiz "Above-normal BMIZ above +1"


ds home_* activity_* partner_* point_* hygiene_* nutrition_* discipline_* ///
    caregiver_* who_* , has(type numeric)
local constructed `r(varlist)'
foreach v of local constructed {
    quietly count if !missing(`v') & !inlist(`v', 0, 1)
    if !inlist("`v'", "who_haz", "who_waz", "who_whz", "who_bmiz") & ///
        !inlist("`v'", "domain_health", "domain_learning", ///
        "domain_psychosocial") {
    }
}

isid BIRIMNO
sort BIRIMNO
notes _dta: All new non-domain outcomes use exact child_age_month fixed effects in the RDD regressions.
notes _dta: The three development-domain scores use UNICEF age-interval controls by explicit design choice.
notes _dta: Activity-partner indicators are unconditional; no activity is coded zero rather than excluded.
notes _dta: Raw KILO and BOY outcomes have no WHO plausibility or outcome-value restrictions; WHO-derived outcomes retain WHO domains and flags.
compress
save "`output_dta'", replace

display as result "Prepared all-outcome regression sample: `output_dta'"
display as result "Observations: " _N
summarize domain_health domain_learning domain_psychosocial ///
    height_cm_all weight_kg_all who_haz who_waz who_whz who_bmiz
tabulate caregiver_father
tabulate discipline_severe

log close prep_outcomes
clear

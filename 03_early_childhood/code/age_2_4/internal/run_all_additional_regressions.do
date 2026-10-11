version 18.0
clear all
set more off
set varabbrev off


local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local regression_root "`project_root'/age 2-4 mechanism/master do files"
local input_dta "`regression_root'/age2_4_all_outcomes_sample.dta"
local engine "`c(pwd)'/03_early_childhood/code/age_2_4/internal/run_family_ols_rdd.do"
local exporter "`regression_root'/00_export_family_word_table.do"

capture log close all_additional
log using "`regression_root'/03_run_all_additional_regressions.log", ///
    text replace name(all_additional)


local task_dir "`project_root'/age 2-4 mechanism/UNICEF Development/3 Development domain scores"
capture mkdir "`task_dir'"
local outcomes domain_health domain_learning domain_psychosocial
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/domain_scores_rdd_results.dta" ///
    "unicef" "child_weight" "4"
do "`exporter'" "`task_dir'/domain_scores_rdd_results.dta" ///
    "`task_dir'/domain_scores_rdd_table_bw4_8.docx" "3" ///
    "Reduced Form Effects on Development Domain Scores" ///
    "Higher domain scores indicate more favourable development."


local task_dir "`project_root'/age 2-4 mechanism/UNICEF Development/4 Individual development items"
capture mkdir "`task_dir'"
local outcomes point_ENGEBEDE_YURUME point_ZIPLAMA point_GIYINME ///
    point_DUGME_ILIKLEME point_KELIME_SOYLEME ///
    point_UC_KELIMELIK_CUMLE point_BES_KELIMELIK_CUMLE ///
    point_ZAMIR_KULLANMA point_NESNE_ISMI_BILME ///
    point_ALFABE_BES_HARF point_ISMINI_YAZMA ///
    point_BIRDEN_BESE_SAYMA point_SAYILI_NESNE ///
    point_HATASIZ_SAYMA point_BOYA_YAPMA ///
    point_BASKALARINI_SORMA point_YARDIM_TEKLIF point_IYI_GECINME ///
    point_UZGUN_MUTSUZ point_ISIRMA_VURMA
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/development_items_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/development_items_rdd_results.dta" ///
    "`task_dir'/development_items_rdd_table_bw4_8.docx" "4" ///
    "Reduced Form Effects on Individual Development Items" ///
    "Every indicator is oriented so that one means favourable development."


local task_dir "`project_root'/age 2-4 mechanism/UNICEF Development/5 Home environment"
capture mkdir "`task_dir'"
local outcomes home_own_room home_books_ge3 home_books_ge10
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/home_environment_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/home_environment_rdd_results.dta" ///
    "`task_dir'/home_environment_rdd_table_bw4_8.docx" "5" ///
    "Reduced Form Effects on the Home Environment" ///
    "Each dependent variable is a zero-one indicator defined in the outcome column."


local task_dir "`project_root'/age 2-4 mechanism/Others/6 Activities together"
capture mkdir "`task_dir'"
capture mkdir "`task_dir'/outputs"
local outcomes activity_kitap_okuma activity_hikaye activity_sarki ///
    activity_disari activity_oynama activity_cizme
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/outputs/activities_rdd_results.dta" ///
    "monthly" "child_weight" "3"
do "`exporter'" "`task_dir'/outputs/activities_rdd_results.dta" ///
    "`task_dir'/outputs/activities_rdd_table_bw4_8.docx" "6" ///
    "Reduced Form Effects on Activities with Children" ///
    "Outcomes indicate whether any eligible adult household member did the activity with the child."


local task_dir "`project_root'/age 2-4 mechanism/Others/7 Activity partner"
capture mkdir "`task_dir'"
capture mkdir "`task_dir'/outputs"
local outcomes partner_father_kitap_okuma partner_mother_kitap_okuma ///
    partner_father_hikaye partner_mother_hikaye ///
    partner_father_sarki partner_mother_sarki ///
    partner_father_disari partner_mother_disari ///
    partner_father_oynama partner_mother_oynama ///
    partner_father_cizme partner_mother_cizme
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/outputs/activity_partner_rdd_results.dta" ///
    "monthly" "child_weight" "3"
do "`exporter'" "`task_dir'/outputs/activity_partner_rdd_results.dta" ///
    "`task_dir'/outputs/activity_partner_rdd_table_bw4_8.docx" "7" ///
    "Reduced Form Effects on Parent Specific Activities" ///
    "Indicators are unconditional: no activity or an activity with another person is coded zero."


local task_dir "`project_root'/age 2-4 mechanism/Others/8 Hygiene"
capture mkdir "`task_dir'"
capture mkdir "`task_dir'/outputs"
local outcomes hygiene_brush_daily hygiene_dentist_year ///
    hygiene_wash_morning hygiene_wash_return ///
    hygiene_wash_before_meal hygiene_wash_after_meal ///
    hygiene_wash_toilet hygiene_bath_frequent
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/outputs/hygiene_rdd_results.dta" ///
    "monthly" "child_weight" "3"
do "`exporter'" "`task_dir'/outputs/hygiene_rdd_results.dta" ///
    "`task_dir'/outputs/hygiene_rdd_table_bw4_8.docx" "8" ///
    "Reduced Form Effects on Hygiene" ///
    "Structurally unasked hygiene questions and unknown responses remain missing rather than zero."


local task_dir "`project_root'/age 2-4 mechanism/Nutrition Frequency/9 Nutrition weekly"
capture mkdir "`task_dir'"
local outcomes nutrition_weekly_fruit nutrition_weekly_vegetables ///
    nutrition_weekly_meatfish nutrition_weekly_legumes ///
    nutrition_weekly_animalprod nutrition_weekly_sweets ///
    nutrition_weekly_snacks nutrition_weekly_softdrink ///
    nutrition_weekly_grains nutrition_ever_breastfed
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/nutrition_weekly_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/nutrition_weekly_rdd_results.dta" ///
    "`task_dir'/nutrition_weekly_rdd_table_bw4_8.docx" "9" ///
    "Reduced Form Effects on Weekly Nutrition" ///
    "Food indicators equal one for consumption at least weekly; frequent sweets snacks and soft drinks are adverse outcomes."


local task_dir "`project_root'/age 2-4 mechanism/Nutrition Frequency/10 Nutrition strict frequency"
capture mkdir "`task_dir'"
local outcomes nutrition_strict_fruit nutrition_strict_vegetables ///
    nutrition_strict_meatfish nutrition_strict_legumes ///
    nutrition_strict_animalprod nutrition_strict_sweets ///
    nutrition_strict_snacks nutrition_strict_softdrink ///
    nutrition_strict_grains
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/nutrition_strict_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/nutrition_strict_rdd_results.dta" ///
    "`task_dir'/nutrition_strict_rdd_table_bw4_8.docx" "10" ///
    "Reduced Form Effects on Frequent Nutrition" ///
    "Food indicators equal one for consumption daily or several times per week and form a stricter sensitivity analysis."


local task_dir "`project_root'/age 2-4 mechanism/Others/11 Discipline"
capture mkdir "`task_dir'"
capture mkdir "`task_dir'/outputs"
local outcomes discipline_nonviolent discipline_psychological ///
    discipline_physical discipline_severe discipline_any_violent ///
    discipline_privilege discipline_explain discipline_shake ///
    discipline_shout discipline_distract discipline_withhold_love ///
    discipline_hit_bottom discipline_hit_object discipline_demean ///
    discipline_slap_face discipline_hit_limbs discipline_beat_hard ///
    discipline_humiliate discipline_ignore discipline_prevent_friends ///
    discipline_cut_allowance
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/outputs/discipline_rdd_results.dta" ///
    "monthly" "child_weight" "3"
do "`exporter'" "`task_dir'/outputs/discipline_rdd_results.dta" ///
    "`task_dir'/outputs/discipline_rdd_table_bw4_8.docx" "11" ///
    "Reduced Form Effects on Child Discipline" ///
    "One indicates use of the named method; code 3 for allowance restriction is treated as not applicable and missing."


local task_dir "`project_root'/age 2-4 mechanism/Others/12 Caregiver"
capture mkdir "`task_dir'"
capture mkdir "`task_dir'/outputs"
local outcomes caregiver_father caregiver_mother caregiver_nonmother
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/outputs/caregiver_rdd_results.dta" ///
    "monthly" "child_weight" "3"
do "`exporter'" "`task_dir'/outputs/caregiver_rdd_results.dta" ///
    "`task_dir'/outputs/caregiver_rdd_table_bw4_8.docx" "12" ///
    "Reduced Form Effects on Primary Caregiver Identity" ///
    "The father-specific outcome has few positive observations and is exploratory."


local task_dir "`project_root'/age 2-4 mechanism/Others/13 Household income"
capture mkdir "`task_dir'"
capture mkdir "`task_dir'/outputs"
local outcomes income_log income_level income_level_trim1
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/outputs/household_income_rdd_results.dta" ///
    "monthly" "household_weight" "2"
do "`exporter'" "`task_dir'/outputs/household_income_rdd_results.dta" ///
    "`task_dir'/outputs/household_income_rdd_table_bw4_8.docx" "13" ///
    "Reduced Form Effects on Household Income" ///
    "The unit is the household; log income is primary and level outcomes are sensitivities."


local task_dir "`project_root'/age 2-4 mechanism/WHO Anthropometric Development/14 Height and weight"
capture mkdir "`task_dir'"
local outcomes weight_kg_all height_cm_all
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/height_weight_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/height_weight_rdd_results.dta" ///
    "`task_dir'/height_weight_rdd_table_bw4_8.docx" "14" ///
    "Reduced Form Effects on Weight and Height" ///
    "KILO and BOY are reported in their original units without WHO plausibility or other outcome-value restrictions."


local task_dir "`project_root'/age 2-4 mechanism/WHO Anthropometric Development/15 WHO anthropometrics clinical"
capture mkdir "`task_dir'"
local outcomes who_haz who_waz who_whz who_bmiz who_stunted ///
    who_underweight who_wasted who_overweight who_obese who_ciaf ///
    who_below_bmiz
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/who_clinical_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/who_clinical_rdd_results.dta" ///
    "`task_dir'/who_clinical_rdd_table_bw4_8.docx" "15" ///
    "Reduced Form Effects on WHO Anthropometric Outcomes" ///
    "Continuous z scores and prespecified adverse clinical classifications exclude WHO-flagged measurements."


local task_dir "`project_root'/age 2-4 mechanism/WHO Anthropometric Development/16 WHO anthropometrics supplementary"
capture mkdir "`task_dir'"
local outcomes who_not_stunted who_not_underweight who_neither_whz ///
    who_neither_bmiz who_normal_haz who_normal_waz who_normal_whz ///
    who_normal_bmiz who_above_haz who_above_waz who_above_whz ///
    who_above_bmiz
use "`input_dta'", clear
do "`engine'" "`outcomes'" "`task_dir'/who_supplementary_rdd_results.dta" ///
    "monthly" "child_weight" "4"
do "`exporter'" "`task_dir'/who_supplementary_rdd_results.dta" ///
    "`task_dir'/who_supplementary_rdd_table_bw4_8.docx" "16" ///
    "Supplementary Reduced Form Effects on WHO Classifications" ///
    "These outcomes reproduce alternative normal and above-normal graph definitions and are not independent clinical hypotheses."

log close all_additional
display as result "All additional pooled age-2-4 regressions and Word tables completed."
clear

version 18.0
clear all
set more off
set varabbrev off

args requested_age
local root "C:/Users/Kaan Cil/Desktop/microdata"
local engine "`c(pwd)'/03_early_childhood/code/age_0_6/internal/run_family_ols_rdd.do"
local exporter "`root'/0-5-6 age/do files/00_export_family_word_table.do"
local graph_do "`c(pwd)'/03_early_childhood/code/age_0_6/internal/run_supplementary_who_simple_graphs.do"

capture log close
log using "`root'/run_supplementary_who_current_3.log", text replace

local ages "0-5 0-6"
if "`requested_age'" != "" local ages "`requested_age'"
foreach age_tag of local ages {
    local age_file = subinstr("`age_tag'", "-", "_", .)
    local sample "`root'/0-5-6 age/`age_tag' age/Reference microdata/regression_sample_age`age_file'.dta"
    local linked "`root'/0-5-6 age/`age_tag' age/Reference microdata/child_age`age_file'_linked_who.dta"
    local outdir "`root'/0-5-6 age/`age_tag' age/WHO Anthropometric Development/16 WHO anthropometrics supplementary"
    capture mkdir "`outdir'"
    capture mkdir "`outdir'/RDD Graphs"
    capture mkdir "`outdir'/RDD Graphs/mother"

    use "`sample'", clear
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

    local outcomes who_not_stunted who_not_underweight who_neither_whz ///
        who_neither_bmiz who_normal_haz who_normal_waz who_normal_whz ///
        who_normal_bmiz who_above_haz who_above_waz who_above_whz ///
        who_above_bmiz
    do "`engine'" "`outcomes'" "`outdir'/who_supplementary_rdd_results.dta" ///
        "monthly" "child_weight" "6"
    do "`exporter'" "`outdir'/who_supplementary_rdd_results.dta" ///
        "`outdir'/who_supplementary_rdd_table_bw4_8.docx" "16" ///
        "Supplementary Reduced Form Effects on WHO Classifications for Ages `age_tag'" ///
        "WHO binary classifications are derived from WHO z scores; missing scores remain missing."

    do "`graph_do'" "`age_tag'"
}

display as result "0-5 and 0-6 WHO supplementary analyses complete."
log close

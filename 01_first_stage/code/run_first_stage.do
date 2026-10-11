version 18.0
clear all
set more off
set varabbrev off

args data_root
local repo_root "`c(pwd)'"
local scripts "`repo_root'/01_first_stage/code/internal"
local linked "`data_root'/0-17 linked microdata/child017_linked.dta"
local roster "`data_root'/micro data/TCA_Fertliste_Mikroveri.csv"
local working "`data_root'/first stage/outputs"
local graphs "`repo_root'/01_first_stage/outputs/RDD Graphs"
capture mkdir "`working'"
capture mkdir "`graphs'"
capture mkdir "`graphs'/mother"

foreach parent in father mother {
    local master "`working'/`parent'_master.dta"
    local spouse "`working'/`parent'_spouse.dta"
    do "`scripts'/build_parent_master.do" "`parent'" "`linked'" "`master'"
    do "`scripts'/build_spouse_outcome.do" "`parent'" "`master'" ///
        "`linked'" "`roster'" "`spouse'"
    local label = cond("`parent'" == "father", "Fathers", "Mothers")
    local graph_dir "`graphs'"
    if "`parent'" == "mother" local graph_dir "`graphs'/mother"
    do "`scripts'/plot_first_stage.do" "`master'" "middle8_complete" ///
        "`graph_dir'/`parent'_first_stage_bw96" ///
        "`label': middle school completion" "`parent'"
    do "`scripts'/plot_first_stage.do" "`spouse'" "spouse_middle8_complete" ///
        "`graph_dir'/`parent'_spouse_first_stage_bw96" ///
        "`label' spouses: middle school completion" "`parent'"
}
do "`scripts'/estimate_first_stage.do" "`working'" ///
    "`repo_root'/01_first_stage/outputs/first_stage_no_controls.docx"

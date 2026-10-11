version 18.0
clear all
set more off
set varabbrev off

local project_root "C:/Users/Kaan Cil/Desktop/microdata"
local run_mode "single"
local age_min 2
local age_max 4
local reference_point "end"
local child_rule "any"

args mode_arg lower_arg upper_arg reference_arg rule_arg
if "`mode_arg'" != "" local run_mode "`mode_arg'"
if "`lower_arg'" != "" local age_min = real("`lower_arg'")
if "`upper_arg'" != "" local age_max = real("`upper_arg'")
if "`reference_arg'" != "" local reference_point "`reference_arg'"
if "`rule_arg'" != "" local child_rule "`rule_arg'"

local task_dir "`project_root'/sample selection"
local scripts "`c(pwd)'/02_sample_selection/code/internal"
local work_dir "`task_dir'/systematic work"
capture mkdir "`work_dir'"
capture log close _all
log using "`work_dir'/04_run_systematic_`run_mode'.log", text replace

local references beginning middle end
local rules any
local widths 3 4 5
if "`run_mode'" == "single" {
    local references "`reference_point'"
    local rules "`child_rule'"
    local widths = `age_max' - `age_min' + 1
}

local analyses = 0
foreach ref of local references {
    if "`ref'" == "beginning" {
        local date_iso "2022-10-10"
        local date_text "10 October 2022"
        local reference_folder "Beginning - 10 October 2022"
    }
    else if "`ref'" == "middle" {
        local date_iso "2022-11-12"
        local date_text "12 November 2022"
        local reference_folder "Middle - 12 November 2022"
    }
    else {
        local date_iso "2022-12-16"
        local date_text "16 December 2022"
        local reference_folder "End - 16 December 2022"
    }
    local reference_dir "`task_dir'/`reference_folder'"
    capture mkdir "`reference_dir'"
    local parent_dta "`work_dir'/parent_selection_`date_iso'.dta"

    do "`scripts'/build_systematic_parent_sample.do" ///
        "`project_root'" "`date_iso'" "`parent_dta'"

    foreach rule of local rules {
        local rule_dir "`reference_dir'/`rule'"
        capture mkdir "`rule_dir'"
        foreach width of local widths {
            local width_dir "`rule_dir'/`width'-year intervals"
            capture mkdir "`width_dir'"
            local first = 0
            local last = 18 - `width'
            if "`run_mode'" == "single" {
                local first = `age_min'
                local last = `age_min'
            }
            forvalues lower = `first'/`last' {
                local upper = `lower' + `width' - 1
                local age_dir "`width_dir'/age_`lower'_`upper'"
                capture mkdir "`age_dir'"
                display as result "RUN: `date_text'; `rule'; ages `lower'-`upper'"
                do "`scripts'/run_systematic_age_interval.do" ///
                    "`parent_dta'" "`age_dir'" "`rule'" ///
                    "`lower'" "`upper'" "`date_iso'"
                local ++analyses
            }
        }
    }
}
display as result "Completed `analyses' analyses; " `analyses'*60 " model estimates."
display as result "Run 07_export_systematic_word_tables.py to export and audit the Word tables."
log close

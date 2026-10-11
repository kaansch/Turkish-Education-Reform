version 18.0
clear all
set more off
set varabbrev off


local project_root    "C:/Users/Kaan Cil/Desktop/microdata"
local regression_root "`project_root'/age 2-4 mechanism/master do files"
local input_dta       "`regression_root'/age2_4_regression_sample.dta"
local task_dir        "`project_root'/age 2-4 mechanism/UNICEF Development/1 UNICEF on-track dummy"
local output_dir      "`task_dir'/outputs"
local bandwidths      96 84 72 60 48
local graph_window    96
local donut           12

capture mkdir "`task_dir'"
capture mkdir "`output_dir'"
capture log close ontrack_reg
log using "`task_dir'/01_unicef_ontrack_regressions.log", ///
    text replace name(ontrack_reg)

use "`input_dta'", clear
isid BIRIMNO

tempfile results
tempname results_post
postfile `results_post' str24 outcome str6 parent str8 version ///
    int bandwidth byte specification ///
    double reform_b reform_se reform_p female_b female_se female_p ///
    outcome_mean N clusters r2 ///
    using `results', replace

foreach parent in father mother {
    local run      run_`parent'
    local eligible eligible_`parent'
    local cluster  `parent'_birth_ym

    foreach bandwidth of local bandwidths {
        foreach version in nodonut donut12 {
            preserve
            keep if inrange(`run', -`bandwidth', `bandwidth' - 1)
            keep if !missing(unicef_ontrack, `run', `eligible', `cluster', ///
                unicef_age_group, female, child_weight)
            keep if child_weight > 0
            if "`version'" == "donut12" {
                drop if inrange(`run', -`donut', `donut' - 1)
            }
            generate double run_right = `run' * `eligible'

            forvalues specification = 1/4 {
                local controls "ib1.unicef_age_group"
                if `specification' >= 2 {
                    local controls "`controls' female"
                }
                if `specification' == 3 {
                    local controls "`controls' ib1.income5"
                }
                if `specification' == 4 {
                    local controls "`controls' ib1.income_per_person5"
                }

                quietly regress unicef_ontrack `eligible' `run' run_right ///
                    `controls' [pw=child_weight], vce(cluster `cluster')

            local reform_b  = _b[`eligible']
            local reform_se = _se[`eligible']
            local reform_p  = 2 * ttail(e(df_r), abs(`reform_b' / `reform_se'))
            local n_model   = e(N)
            local n_cluster = e(N_clust)
            local model_r2  = e(r2)

            local female_b  = .
            local female_se = .
            local female_p  = .
            if `specification' >= 2 {
                local female_b  = _b[female]
                local female_se = _se[female]
                local female_p  = 2 * ttail(e(df_r), ///
                    abs(`female_b' / `female_se'))
            }

            quietly summarize unicef_ontrack [aw=child_weight] if e(sample), meanonly
            local outcome_mean = r(mean)

                post `results_post' ("UNICEF on-track") ("`parent'") ///
                    ("`version'") (`bandwidth') (`specification') ///
                    (`reform_b') (`reform_se') (`reform_p') ///
                    (`female_b') (`female_se') (`female_p') ///
                    (`outcome_mean') (`n_model') (`n_cluster') (`model_r2')
            }
            restore
        }
    }
}

postclose `results_post'
use `results', clear
label variable version "RDD donut-hole specification"
label variable bandwidth "RDD outer bandwidth in months"
label variable specification "Alternative income-control specification"
label variable reform_b "RDD eligibility coefficient"
label variable reform_se "Clustered standard error"
label variable reform_p "Two-sided p-value"
sort parent specification bandwidth version
save "`task_dir'/unicef_ontrack_rdd_results.dta", replace

do "`regression_root'/00_export_article_style_word_table.do" ///
    "`task_dir'/unicef_ontrack_rdd_results.dta" ///
    "`task_dir'/unicef_ontrack_rdd_table_bw4_8.docx" ///
    "1" ///
    "Reduced-Form Effects on UNICEF Age-Specific Developmentally On-Track Status" ///
    "ontrack"

use "`input_dta'", clear
foreach parent in father mother {
    local run run_`parent'
    local parent_title = proper("`parent'")

    foreach version in nodonut donut12 {
        preserve
        keep if inrange(`run', -`graph_window', `graph_window' - 1)
        keep if !missing(unicef_ontrack, `run', child_weight) & child_weight > 0

        local donut_text "No donut hole"
        if "`version'" == "donut12" {
            drop if inrange(`run', -`donut', `donut' - 1)
            local donut_text "12-month donut on each side"
        }

        quietly count if `run' < 0
        local n_left = r(N)
        quietly count if `run' >= 0
        local n_right = r(N)

        tempvar bin_id bin_center weighted_y bin_weight bin_weighted_y bin_mean bin_tag
        generate long `bin_id' = floor(`run' / 3)
        generate double `bin_center' = `bin_id' * 3 + 1
        generate double `weighted_y' = unicef_ontrack * child_weight
        bysort `bin_id': egen double `bin_weight' = total(child_weight)
        bysort `bin_id': egen double `bin_weighted_y' = total(`weighted_y')
        generate double `bin_mean' = `bin_weighted_y' / `bin_weight'
        bysort `bin_id': generate byte `bin_tag' = (_n == 1)

        twoway ///
            (lfitci unicef_ontrack `run' if `run' < 0 [pw=child_weight], ///
                level(95) ciplot(rline) range(-`graph_window' 0) ///
                clcolor(black) clwidth(thick) alcolor(black) ///
                alpattern(dash) alwidth(medthin)) ///
            (lfitci unicef_ontrack `run' if `run' >= 0 [pw=child_weight], ///
                level(95) ciplot(rline) range(0 `graph_window') ///
                clcolor(black) clwidth(thick) alcolor(black) ///
                alpattern(dash) alwidth(medthin)) ///
            (scatter `bin_mean' `bin_center' if `bin_tag', ///
                msymbol(O) msize(small) mcolor(black)), ///
            title("UNICEF age-specific developmentally on track", size(medlarge)) ///
            subtitle("`parent_title' birth month; `donut_text'; +/- `graph_window' months", size(medsmall)) ///
            ytitle("Weighted on-track proportion and 95% CI", size(medsmall)) ///
            xtitle("Months around the January 1987 cutoff", size(medsmall)) ///
            xline(0, lcolor(black)) xlabel(-96(32)96) xscale(range(-96 96)) ///
            ylabel(0(.1)1, angle(0) format(%3.1f)) yscale(range(0 1)) ///
            legend(off) scheme(s1mono) name(ontrack_`parent'_`version', replace) ///
            note("Primary sample: one latest-born child per household; left=`n_left', right=`n_right'." ///
                "Dots are FAKTOR_FERT-weighted three-month means; dashed lines are 95% CIs.", size(tiny)) ///
            graphregion(color(white)) plotregion(margin(medlarge))

        graph export "`output_dir'/unicef_ontrack_`parent'_bw96_`version'.png", ///
            as(png) width(2400) replace
        graph drop ontrack_`parent'_`version'
        restore
    }
}

display as result "UNICEF on-track regressions and graphs completed: `output_dir'"
log close ontrack_reg
clear

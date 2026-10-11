version 18.0
clear all
set more off
set varabbrev off


local project_root    "C:/Users/Kaan Cil/Desktop/microdata"
local regression_root "`project_root'/age 2-4 mechanism/master do files"
local input_dta       "`regression_root'/age2_4_regression_sample.dta"
local task_dir        "`project_root'/age 2-4 mechanism/UNICEF Development/2 Total development score"
local output_dir      "`task_dir'/outputs"
local bandwidths      96 84 72 60 48
local graph_window    96
local donut           12

capture mkdir "`task_dir'"
capture mkdir "`output_dir'"
capture log close total_reg
log using "`task_dir'/02_total_score_regressions.log", ///
    text replace name(total_reg)

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
            keep if !missing(score_total_20, `run', `eligible', `cluster', ///
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

                quietly regress score_total_20 `eligible' `run' run_right ///
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

            quietly summarize score_total_20 [aw=child_weight] if e(sample), meanonly
            local outcome_mean = r(mean)

                post `results_post' ("Total score 0-20") ("`parent'") ///
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
save "`task_dir'/total_score_rdd_results.dta", replace

do "`regression_root'/00_export_article_style_word_table.do" ///
    "`task_dir'/total_score_rdd_results.dta" ///
    "`task_dir'/total_score_rdd_table_bw4_8.docx" ///
    "2" ///
    "Reduced-Form Effects on the Total Development Score" ///
    "total"

use "`input_dta'", clear
foreach parent in father mother {
    local run run_`parent'
    local parent_title = proper("`parent'")

    foreach version in nodonut donut12 {
        preserve
        keep if inrange(`run', -`graph_window', `graph_window' - 1)
        keep if !missing(score_total_20, `run', child_weight) & child_weight > 0

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
        generate double `weighted_y' = score_total_20 * child_weight
        bysort `bin_id': egen double `bin_weight' = total(child_weight)
        bysort `bin_id': egen double `bin_weighted_y' = total(`weighted_y')
        generate double `bin_mean' = `bin_weighted_y' / `bin_weight'
        bysort `bin_id': generate byte `bin_tag' = (_n == 1)

        twoway ///
            (lfitci score_total_20 `run' if `run' < 0 [pw=child_weight], ///
                level(95) ciplot(rline) range(-`graph_window' 0) ///
                clcolor(black) clwidth(thick) alcolor(black) ///
                alpattern(dash) alwidth(medthin)) ///
            (lfitci score_total_20 `run' if `run' >= 0 [pw=child_weight], ///
                level(95) ciplot(rline) range(0 `graph_window') ///
                clcolor(black) clwidth(thick) alcolor(black) ///
                alpattern(dash) alwidth(medthin)) ///
            (scatter `bin_mean' `bin_center' if `bin_tag', ///
                msymbol(O) msize(small) mcolor(black)), ///
            title("Total development score (0-20)", size(medlarge)) ///
            subtitle("`parent_title' birth month; `donut_text'; +/- `graph_window' months", size(medsmall)) ///
            ytitle("Weighted mean total score and 95% CI", size(medsmall)) ///
            xtitle("Months around the January 1987 cutoff", size(medsmall)) ///
            xline(0, lcolor(black)) xlabel(-96(32)96) xscale(range(-96 96)) ///
            ylabel(0(2)20, angle(0)) yscale(range(0 20)) ///
            legend(off) scheme(s1mono) name(total_`parent'_`version', replace) ///
            note("Primary sample: one latest-born child per household; left=`n_left', right=`n_right'." ///
                "Dots are FAKTOR_FERT-weighted three-month means; dashed lines are 95% CIs.", size(tiny)) ///
            graphregion(color(white)) plotregion(margin(medlarge))

        graph export "`output_dir'/total_score_`parent'_bw96_`version'.png", ///
            as(png) width(2400) replace
        graph drop total_`parent'_`version'
        restore
    }
}

use "`input_dta'", clear
keep if !missing(child_months_analysis, score_total_20, child_weight) ///
    & child_weight > 0
generate double weighted_score = score_total_20 * child_weight
collapse (sum) cell_weight=child_weight cell_weighted_score=weighted_score, ///
    by(child_months_analysis score_total_20 unicef_cutoff)
bysort child_months_analysis: egen double month_weight = total(cell_weight)
bysort child_months_analysis: egen double month_weighted_score = ///
    total(cell_weighted_score)
generate double cell_percent = 100 * cell_weight / month_weight
generate double month_mean = month_weighted_score / month_weight
bysort child_months_analysis: generate byte month_tag = (_n == 1)

twoway ///
    (scatter score_total_20 child_months_analysis [aw=cell_percent], ///
        msymbol(O) mcolor(gs10%55) mlcolor(gs7) mlwidth(vthin)) ///
    (line month_mean child_months_analysis if month_tag, ///
        sort lcolor(black) lwidth(thick)) ///
    (line unicef_cutoff child_months_analysis if month_tag, ///
        sort lcolor(black) lpattern(dash) lwidth(medthick)), ///
    title("Distribution of total development scores by child age", size(medlarge)) ///
    subtitle("Primary sample; FAKTOR_FERT-weighted", size(medsmall)) ///
    xtitle("Child age in completed months") ///
    ytitle("Total favourable items (0-20)") ///
    xlabel(24(3)57 59) xscale(range(24 59)) ///
    ylabel(0(2)20, angle(0)) yscale(range(0 20)) ///
    legend(order(1 "Weighted score distribution" 2 "Weighted monthly mean" ///
        3 "UNICEF cutoff") rows(1) size(small)) ///
    note("Bubble area represents the weighted percentage at each age-score cell." ///
        "Raw ages 60-62 are plotted at analysis month 59.", size(tiny)) ///
    scheme(s1mono) name(total_distribution, replace) ///
    graphregion(color(white)) plotregion(margin(medlarge))

graph export "`output_dir'/total_score_distribution_by_month_24_59.png", ///
    as(png) width(2600) replace
graph drop total_distribution

display as result "Total-score regressions and graphs completed: `output_dir'"
log close total_reg
clear

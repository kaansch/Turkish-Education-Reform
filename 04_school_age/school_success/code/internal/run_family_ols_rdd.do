version 18.0
set more off
set varabbrev off


args outcomes results_dta age_control weight_var max_spec

local bandwidths 96 84 72 60 48
local donut 12
tempname results_post
tempfile results_temp

postfile `results_post' int outcome_order str32 outcome ///
    str120 outcome_label str6 parent str8 version int bandwidth ///
    byte specification str8 age_control str20 weight_variable ///
    double reform_b reform_se reform_p outcome_mean ///
    long N clusters positive_cases byte binary_outcome int return_code str18 fit_status ///
    using "`results_temp'", replace

local outcome_order = 0
foreach y of local outcomes {
    local ++outcome_order
    local y_label : variable label `y'
    if `"`y_label'"' == "" local y_label "`y'"

    quietly count if !missing(`y') & !inlist(`y', 0, 1)
    local binary_outcome = (r(N) == 0)

    foreach parent in father mother {
        local run run_`parent'
        local eligible eligible_`parent'
        local cluster `parent'_birth_ym

        foreach bandwidth of local bandwidths {
            foreach version in nodonut donut12 {
                forvalues specification = 1/`max_spec' {
                    preserve

                    keep if !missing(`y', `run', `eligible', `cluster', ///
                        `weight_var') & `weight_var' > 0
                    keep if inrange(`run', -`bandwidth', `bandwidth' - 1)
                    if "`version'" == "donut12" {
                        drop if inrange(`run', -`donut', `donut' - 1)
                    }

                    local controls
                    if "`age_control'" == "monthly" {
                        keep if !missing(child_age_month)
                        local controls "i.child_age_month"
                    }
                    else {
                        keep if !missing(unicef_age_group)
                        local controls "i.unicef_age_group"
                    }
                    if `specification' >= 2 {
                        keep if !missing(female)
                        local controls "`controls' female"
                    }
                    if `max_spec' == 3 & `specification' == 3 {
                        keep if !missing(ln_household_income)
                        local controls "`controls' c.ln_household_income"
                    }
                    if inlist(`max_spec', 4, 6) & `specification' == 3 {
                        keep if !missing(income5)
                        local controls "`controls' ib1.income5"
                    }
                    if inlist(`max_spec', 4, 6) & `specification' == 4 {
                        keep if !missing(income_per_person5)
                        local controls "`controls' ib1.income_per_person5"
                    }
                    if `specification' >= 5 {
                        keep if !missing(aid_count, aid_any)
                        if `specification' == 5 {
                            local controls "`controls' ib0.aid_count"
                        }
                        else {
                            local controls "`controls' aid_any"
                        }
                    }

                    generate double __run_right = `eligible' * `run'

                    capture quietly regress `y' `eligible' `run' ///
                        __run_right `controls' [pw=`weight_var'], ///
                        vce(cluster `cluster')
                    local model_rc = _rc

                    if `model_rc' {
                        quietly count
                        local n_model = r(N)
                        post `results_post' (`outcome_order') ("`y'") ///
                            (`"`y_label'"') ("`parent'") ("`version'") ///
                            (`bandwidth') (`specification') ///
                            ("`age_control'") ("`weight_var'") ///
                            (.) (.) (.) (.) (`n_model') (.) (.) ///
                            (`binary_outcome') (`model_rc') ("failed")
                        restore
                        continue
                    }

                    local reform_b = _b[`eligible']
                    local reform_se = _se[`eligible']
                    local reform_p = .
                    if `reform_se' > 0 & `reform_se' < . {
                        local reform_p = 2 * ttail(e(df_r), ///
                            abs(`reform_b' / `reform_se'))
                    }
                    local n_model = e(N)
                    local n_clusters = e(N_clust)

                    quietly summarize `y' [aw=`weight_var'] if e(sample), meanonly
                    local outcome_mean = r(mean)

                    local positive_cases = .
                    if `binary_outcome' {
                        quietly count if `y' == 1 & e(sample)
                        local positive_cases = r(N)
                    }

                    post `results_post' (`outcome_order') ("`y'") ///
                        (`"`y_label'"') ("`parent'") ("`version'") ///
                        (`bandwidth') (`specification') ///
                        ("`age_control'") ("`weight_var'") ///
                        (`reform_b') (`reform_se') (`reform_p') ///
                        (`outcome_mean') (`n_model') (`n_clusters') ///
                        (`positive_cases') (`binary_outcome') (0) ///
                        (cond(`reform_se' == 0, "zero_se", "ok"))

                    restore
                }
            }
        }
    }
}

postclose `results_post'
use "`results_temp'", clear
sort outcome_order parent specification version bandwidth
isid outcome parent version bandwidth specification
compress
save `"`results_dta'"', replace

display as result "Saved family RDD results: `results_dta'"
display as result "Outcomes: `outcome_order'; result rows: " _N

version 18.0
args parent_dta output_dir rule lower upper date_iso
clear
set more off
set varabbrev off

local lower = real("`lower'")
local upper = real("`upper'")
local group "`lower'_`upper'"
local width = `upper' - `lower' + 1

use "`parent_dta'", clear
isid parent birimno parent_fertno

capture confirm variable `rule'_a`group'
if _rc {
    generate byte outcome = inrange(`rule'_months, 12*`lower', 12*(`upper'+1)-1)
}
else generate byte outcome = `rule'_a`group'

preserve
keep parent birimno parent_fertno reference_date parent_dob birth_ym ///
    run_month exposed faktor_hane n_linked_children youngest_months oldest_months ///
    income5 income_per_person5 outcome
label variable outcome "`rule' child rule: completed ages `lower'-`upper'"
save "`output_dir'/parent_interval_sample.dta", replace
restore

tempfile result_temp
tempname result_post
postfile `result_post' str10 reference_date str8 child_rule ///
    byte age_min age_max interval_years str8 age_group str6 parent str8 version ///
    int bandwidth str20 model double jump se p ci_low ci_high outcome_mean ///
    long N N_left N_right N_positive N_clusters byte n_income_categories ///
    str24 fit_status int return_code using `result_temp', replace

foreach parent_type in father mother {
    foreach bandwidth in 96 84 72 60 48 {
        foreach version in nodonut donut12 {
            preserve
            keep if parent == "`parent_type'" & inrange(run_month, -`bandwidth', `bandwidth'-1)
            if "`version'" == "donut12" drop if inrange(run_month, -12, 11)
            quietly count if run_month < 0
            local n_left = r(N)
            quietly count if run_month >= 0
            local n_right = r(N)
            generate double run_right = exposed * run_month
            foreach model in none hh_income_5 pc_income_5 {
                local controls ""
                local category_var ""
                if "`model'" == "hh_income_5" {
                    local controls "ib1.income5"
                    local category_var "income5"
                }
                if "`model'" == "pc_income_5" {
                    local controls "ib1.income_per_person5"
                    local category_var "income_per_person5"
                }
                quietly regress outcome exposed run_month run_right ///
                    `controls' [pw=faktor_hane], vce(cluster birth_ym)
                local jump = _b[exposed]
                local se = _se[exposed]
                local p = .
                local ci_low = .
                local ci_high = .
                local status "ok"
                if `se' > 0 & `se' < . {
                    local critical = invttail(e(df_r), 0.025)
                    local p = 2*ttail(e(df_r), abs(`jump'/`se'))
                    local ci_low = `jump' - `critical'*`se'
                    local ci_high = `jump' + `critical'*`se'
                }
                else local status "zero_standard_error"
                local n_model = e(N)
                local n_clusters = e(N_clust)
                quietly count if e(sample) & run_month < 0
                local n_left_model = r(N)
                quietly count if e(sample) & run_month >= 0
                local n_right_model = r(N)
                quietly count if e(sample) & outcome == 1
                local n_positive = r(N)
                quietly summarize outcome [aw=faktor_hane] if e(sample), meanonly
                local outcome_mean = r(mean)
                local n_categories = .
                if "`category_var'" != "" {
                    quietly levelsof `category_var' if e(sample), local(levels)
                    local n_categories : word count `levels'
                }
                post `result_post' ("`date_iso'") ("`rule'") ///
                    (`lower') (`upper') (`width') ("`group'") ///
                    ("`parent_type'") ("`version'") (`bandwidth') ("`model'") ///
                    (`jump') (`se') (`p') (`ci_low') (`ci_high') (`outcome_mean') ///
                    (`n_model') (`n_left_model') (`n_right_model') ///
                    (`n_positive') (`n_clusters') (`n_categories') ("`status'") (0)
            }
            restore
        }
    }
}
postclose `result_post'
use `result_temp', clear
generate double jump_pp = 100*jump
generate double ci_low_pp = 100*ci_low
generate double ci_high_pp = 100*ci_high
generate double outcome_mean_pct = 100*outcome_mean
sort parent bandwidth version model
isid parent bandwidth version model
save "`output_dir'/selection_rdd_results_age`group'.dta", replace

foreach numeric of varlist jump se p ci_low ci_high outcome_mean ///
    jump_pp ci_low_pp ci_high_pp outcome_mean_pct {
    generate str32 `numeric'_csv = strtrim(string(`numeric', "%24.16g")) if !missing(`numeric')
    replace `numeric'_csv = "0" + `numeric'_csv if substr(`numeric'_csv, 1, 1) == "."
    replace `numeric'_csv = "-0" + substr(`numeric'_csv, 2, strlen(`numeric'_csv)) ///
        if substr(`numeric'_csv, 1, 2) == "-."
    replace `numeric'_csv = subinstr(`numeric'_csv, ".", ",", .)
    drop `numeric'
    rename `numeric'_csv `numeric'
}
export delimited using "`output_dir'/selection_rdd_results_age`group'.csv", delimiter(";") replace

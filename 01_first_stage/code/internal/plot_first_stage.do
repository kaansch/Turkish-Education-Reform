version 18.0
set more off
set varabbrev off

args input_dta outcome graph_stub graph_title parent
local bandwidth 96
local bin_width 3
local tick = `bandwidth' / 3
local parent_label = cond("`parent'" == "father", "Father", "Mother")

use "`input_dta'", clear

foreach donut in 0 1 {
    preserve
    keep if inrange(run_month, -`bandwidth', `bandwidth' - 1)
    keep if !missing(run_month, `outcome', faktor_hane)
    local left "run_month < 0"
    local right "run_month >= 0"
    local suffix ""
    local subtitle "No donut hole"
    if `donut' {
        drop if inrange(run_month, -12, 11)
        local left "run_month < -12"
        local right "run_month > 11"
        local suffix "_donut"
        local subtitle "12-month donut hole"
    }
    quietly count if `left'
    local n_left = r(N)
    quietly count if `right'
    local n_right = r(N)

    tempvar bin_id bin_center weighted_y bin_weight bin_weighted_y bin_mean bin_tag
    generate long `bin_id' = floor(run_month / `bin_width')
    generate double `bin_center' = `bin_id' * `bin_width' + (`bin_width' - 1) / 2
    generate double `weighted_y' = `outcome' * faktor_hane
    bysort `bin_id': egen double `bin_weight' = total(faktor_hane)
    bysort `bin_id': egen double `bin_weighted_y' = total(`weighted_y')
    generate double `bin_mean' = `bin_weighted_y' / `bin_weight'
    bysort `bin_id': generate byte `bin_tag' = (_n == 1)

    twoway                                                               ///
        (lfitci `outcome' run_month if `left' [pw=faktor_hane],           ///
            level(95) ciplot(rline) range(-`bandwidth' 0)               ///
            clcolor(black) clwidth(thick) alcolor(black)                ///
            alpattern(dash) alwidth(medthin))                            ///
        (lfitci `outcome' run_month if `right' [pw=faktor_hane],          ///
            level(95) ciplot(rline) range(0 `bandwidth')                ///
            clcolor(black) clwidth(thick) alcolor(black)                ///
            alpattern(dash) alwidth(medthin))                            ///
        (scatter `bin_mean' `bin_center' if `bin_tag',                   ///
            msymbol(O) msize(small) mcolor(black)),                      ///
        title("`graph_title'", size(medlarge))                            ///
        subtitle("`subtitle'; +/- `bandwidth' months", size(medsmall))  ///
        ytitle("Weighted fraction completed and 95% CI")                ///
        xtitle("`parent_label' birth months around January 1987")       ///
        xline(0, lcolor(black))                                          ///
        xlabel(-`bandwidth'(`tick')`bandwidth')                          ///
        xscale(range(-`bandwidth' `bandwidth'))                          ///
        ylabel(0(0.1)1, format(%3.1f) angle(0))                          ///
        yscale(range(0 1)) legend(off) scheme(s1mono)                   ///
        note("Left: `n_left'; right: `n_right'. Points are weighted three-month means; dashed lines are 95% CIs.", size(vsmall)) ///
        graphregion(color(white)) plotregion(margin(medlarge))
    graph export "`graph_stub'`suffix'.png", replace width(2400)
    restore
}

version 18.0
clear all
set more off
set varabbrev off
set processors 1
args age_tag
local root "C:/Users/Kaan Cil/Desktop/microdata"
local age_file = subinstr("`age_tag'", "-", "_", .)
local input "`root'/0-5-6 age/`age_tag' age/Reference microdata/child_age`age_file'_linked_who.dta"
local out "`root'/0-5-6 age/`age_tag' age/WHO Anthropometric Development/16 WHO anthropometrics supplementary/RDD Graphs"
capture mkdir "`out'"
capture log close
log using "`out'/simple_graphs.log", text replace

local outcomes who_not_stunted who_not_underweight who_neither_whz who_neither_bmiz ///
    who_normal_haz who_normal_waz who_normal_whz who_normal_bmiz ///
    who_above_haz who_above_waz who_above_whz who_above_bmiz
foreach parent in father mother {
    local x run_`parent'
    foreach version in nodonut donut12 {
        foreach y of local outcomes {
            use "`input'", clear
            generate byte `y' = .
            if "`y'" == "who_not_stunted" replace `y' = who_haz >= -2 if !missing(who_haz)
            if "`y'" == "who_not_underweight" replace `y' = who_waz >= -2 if !missing(who_waz)
            if "`y'" == "who_neither_whz" replace `y' = inrange(who_whz,-2,2) if !missing(who_whz)
            if "`y'" == "who_neither_bmiz" replace `y' = inrange(who_bmiz,-2,2) if !missing(who_bmiz)
            if "`y'" == "who_normal_haz" replace `y' = inrange(who_haz,-2,3) if !missing(who_haz)
            if "`y'" == "who_normal_waz" replace `y' = inrange(who_waz,-2,1) if !missing(who_waz)
            if "`y'" == "who_normal_whz" replace `y' = inrange(who_whz,-2,1) if !missing(who_whz)
            if "`y'" == "who_normal_bmiz" replace `y' = inrange(who_bmiz,-2,1) if !missing(who_bmiz)
            if "`y'" == "who_above_haz" replace `y' = who_haz > 3 if !missing(who_haz)
            if "`y'" == "who_above_waz" replace `y' = who_waz > 1 if !missing(who_waz)
            if "`y'" == "who_above_whz" replace `y' = who_whz > 1 if !missing(who_whz)
            if "`y'" == "who_above_bmiz" replace `y' = who_bmiz > 1 if !missing(who_bmiz)
            keep if !missing(`y', `x', child_weight) & child_weight > 0 & inrange(`x',-96,95)
            if "`version'" == "donut12" drop if inrange(`x',-12,11)
            quietly count if `x' < 0
            local nleft = r(N)
            quietly count if `x' >= 0
            local nright = r(N)
            if `nleft' >= 5 & `nright' >= 5 {
                generate int bin = floor(`x'/3)*3
                generate double wy = `y' * child_weight
                bysort bin: egen double sw = total(child_weight)
                bysort bin: egen double swy = total(wy)
                generate double mean = swy/sw
                bysort bin: keep if _n == 1
                twoway (scatter mean bin, msize(vsmall) mcolor(black)) ///
                    (lfit mean bin if bin < 0, lcolor(navy)) ///
                    (lfit mean bin if bin >= 0, lcolor(maroon)), ///
                    xline(0) legend(off) graphregion(color(white)) ///
                    title("WHO `y' - age `age_tag' - `parent' - `version'") ///
                    xtitle("Months around January 1987 cutoff") ytitle("Classification")
                capture noisily graph export "`out'/age`age_file'_`parent'_`y'_`version'.png", replace width(1600)
            }
        }
    }
}
display as result "WHO supplementary simple graphs complete for `age_tag'."
log close

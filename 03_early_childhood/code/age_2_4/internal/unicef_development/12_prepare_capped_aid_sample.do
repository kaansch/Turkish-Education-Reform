version 18.0
set more off
set varabbrev off

args output_dta outcomes_dta

local root "C:/Users/Kaan Cil/Desktop/microdata"
local household_csv "`root'/micro data/TCA_Hane_Mikroveri.csv"
local aid_fields AILE_YARDIM BARINMA_YARDIM SAGLIK_YARDIM ///
    ENGELLI_YARDIM EGITIM_YARDIM BASKA_YARDIM

tempfile aid_households
import delimited using "`household_csv'", delimiter(";") varnames(1) ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear
keep BIRIMNO `aid_fields'
replace BIRIMNO = strtrim(BIRIMNO)
isid BIRIMNO

local aid_indicators
foreach field of local aid_fields {
    replace `field' = strtrim(`field')
    generate byte aid_`field' = .
    replace aid_`field' = 1 if `field' == "1"
    replace aid_`field' = 0 if `field' == "2"
    local aid_indicators `aid_indicators' aid_`field'
}

egen byte aid_answers = rownonmiss(`aid_indicators')
quietly count if aid_answers != 6
display as result "Households excluded for blank or non-yes/no aid answers: " r(N)
keep if aid_answers == 6
egen byte aid_count = rowtotal(`aid_indicators')
generate byte aid_any = (aid_count > 0)
label variable aid_count "Number of six aid types received (0-6)"
label variable aid_any "Household received at least one aid type"
label define aid_count_lbl 0 "0 aids" 1 "1 aid" 2 "2 aids" ///
    3 "3 aids" 4 "4 aids" 5 "5 aids" 6 "6 aids", replace
label values aid_count aid_count_lbl
keep BIRIMNO `aid_indicators' aid_count aid_any
save `aid_households'

use "`outcomes_dta'", clear
isid BIRIMNO
merge 1:1 BIRIMNO using `aid_households', keep(master match) ///
    generate(_merge_aid)
quietly count if _merge_aid == 1
display as result "Analysis households excluded for incomplete aid answers: " r(N)
keep if _merge_aid == 3
drop _merge_aid
isid BIRIMNO
tabulate aid_count
compress
save `"`output_dta'"', replace
display as result "Complete-case aid analysis sample: " _N

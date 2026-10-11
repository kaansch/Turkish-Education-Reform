version 18.0
clear all
set more off
set varabbrev off

args parent parent_master linked_dta roster_csv output_file
local spouse_prefix = cond("`parent'" == "father", "anne", "baba")
tempfile linked_spouse roster_spouse

use "`linked_dta'", clear
rename *, lower
replace `spouse_prefix'_birimno = strtrim(`spouse_prefix'_birimno)
replace `spouse_prefix'_fertno = strtrim(`spouse_prefix'_fertno)
keep if `spouse_prefix'_birimno != "" & !inlist(`spouse_prefix'_fertno, "", "99")
foreach variable in `spouse_prefix'_okul_durum                           ///
    `spouse_prefix'_egitim_seviye `spouse_prefix'_seviye_bitirme_durum {
    bysort `spouse_prefix'_birimno `spouse_prefix'_fertno: ///
        assert `variable' == `variable'[1]
}
bysort `spouse_prefix'_birimno `spouse_prefix'_fertno: keep if _n == 1
keep `spouse_prefix'_birimno `spouse_prefix'_fertno                       ///
    `spouse_prefix'_okul_durum `spouse_prefix'_egitim_seviye              ///
    `spouse_prefix'_seviye_bitirme_durum
rename `spouse_prefix'_birimno birimno
rename `spouse_prefix'_fertno `parent'_spouse_fertno
rename `spouse_prefix'_okul_durum linked_school
rename `spouse_prefix'_egitim_seviye linked_level
rename `spouse_prefix'_seviye_bitirme_durum linked_completed
foreach variable in linked_school linked_level linked_completed {
    destring `variable', replace
}
isid birimno `parent'_spouse_fertno
save "`linked_spouse'"

import delimited using "`roster_csv'", delimiter(";") varnames(1)      ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear
rename *, lower
keep birimno fertno okul_durum egitim_seviye seviye_bitirme_durum
replace birimno = strtrim(birimno)
replace fertno = strtrim(fertno)
rename fertno `parent'_spouse_fertno
rename okul_durum roster_school
rename egitim_seviye roster_level
rename seviye_bitirme_durum roster_completed
foreach variable in roster_school roster_level roster_completed {
    destring `variable', replace
}
isid birimno `parent'_spouse_fertno
save "`roster_spouse'"

use "`parent_master'", clear
replace birimno = strtrim(birimno)
replace `parent'_spouse_fertno = strtrim(`parent'_spouse_fertno)
isid birimno `parent'_fertno
merge m:1 birimno `parent'_spouse_fertno using "`linked_spouse'",    ///
    keep(master match) generate(linked_merge)
merge m:1 birimno `parent'_spouse_fertno using "`roster_spouse'",    ///
    keep(master match) generate(roster_merge)

assert linked_school == roster_school if linked_merge == 3 & ///
    roster_merge == 3 & !missing(linked_school, roster_school)
assert linked_level == roster_level if linked_merge == 3 & ///
    roster_merge == 3 & !missing(linked_level, roster_level)
assert linked_completed == roster_completed if linked_merge == 3 & ///
    roster_merge == 3 & !missing(linked_completed, roster_completed)

generate byte spouse_source = .
replace spouse_source = 1 if !inlist(`parent'_spouse_fertno, "", "99") ///
    & linked_merge == 3
replace spouse_source = 2 if !inlist(`parent'_spouse_fertno, "", "99") ///
    & linked_merge == 1 & roster_merge == 3
generate double spouse_school_attendance = .
generate double spouse_education_level = .
generate double spouse_highest_level_completed = .
replace spouse_school_attendance = linked_school if spouse_source == 1
replace spouse_education_level = linked_level if spouse_source == 1
replace spouse_highest_level_completed = linked_completed if spouse_source == 1
replace spouse_school_attendance = roster_school if spouse_source == 2
replace spouse_education_level = roster_level if spouse_source == 2
replace spouse_highest_level_completed = roster_completed if spouse_source == 2
generate byte spouse_record_matched = inlist(spouse_source, 1, 2)

generate byte spouse_middle8_complete = .
replace spouse_middle8_complete = 0 if spouse_record_matched           ///
    & spouse_school_attendance == 2
replace spouse_middle8_complete = 0 if spouse_record_matched           ///
    & spouse_school_attendance == 1 & inlist(spouse_education_level, 0, 2)
replace spouse_middle8_complete = 0 if spouse_record_matched           ///
    & spouse_school_attendance == 1 & spouse_education_level == 3        ///
    & spouse_highest_level_completed == 2
replace spouse_middle8_complete = 1 if spouse_record_matched           ///
    & spouse_school_attendance == 1 & spouse_education_level == 3        ///
    & spouse_highest_level_completed == 1
replace spouse_middle8_complete = 1 if spouse_record_matched           ///
    & spouse_school_attendance == 1 & inlist(spouse_education_level,     ///
    4, 511, 512, 521, 522, 53)
replace spouse_middle8_complete = . if spouse_record_matched           ///
    & spouse_education_level == 99
label define yes_no 0 "No" 1 "Yes", replace
label values spouse_middle8_complete yes_no
label variable spouse_middle8_complete "Spouse completed at least eight years of schooling"
isid birimno `parent'_fertno
drop linked_merge roster_merge linked_school linked_level              ///
    linked_completed roster_school roster_level roster_completed
save "`output_file'", replace
display as result "Saved `parent' spouse outcome: `output_file'"

version 18.0
args project_root date_iso output_dta
clear
set more off
set varabbrev off

local refdate = daily("`date_iso'", "YMD")
local refyear = year(`refdate')
local refmonth = month(`refdate')
local refday = day(`refdate')
local linked_dta "`project_root'/0-17 linked microdata/child017_linked.dta"
local household_csv "`project_root'/micro data/TCA_Hane_Mikroveri.csv"
tempfile households father_rows mother_rows

import delimited using "`household_csv'", delimiter(";") varnames(1) ///
    stringcols(_all) encoding("UTF-8") case(preserve) clear
keep BIRIMNO GELIR_HANE HH_BUYUKLUK FAKTOR_HANE
rename *, lower
replace birimno = strtrim(birimno)
isid birimno
generate double household_income = real(subinstr(strtrim(gelir_hane), ",", ".", .))
generate double household_size = real(subinstr(strtrim(hh_buyukluk), ",", ".", .))
generate double faktor_hane_num = real(subinstr(strtrim(faktor_hane), ",", ".", .))
generate double income_per_person = household_income / household_size

bysort household_income (birimno): generate byte income_value_tag = (_n == 1)
sort household_income birimno
generate long household_income_value_rank = sum(income_value_tag)
quietly count if income_value_tag
local n_income_values = r(N)
generate byte income5 = floor(5*(household_income_value_rank - 1)/`n_income_values') + 1

bysort income_per_person (birimno): generate byte per_person_value_tag = (_n == 1)
sort income_per_person birimno
generate long income_per_person_value_rank = sum(per_person_value_tag)
quietly count if per_person_value_tag
local n_per_person_values = r(N)
generate byte income_per_person5 = floor(5*(income_per_person_value_rank - 1)/`n_per_person_values') + 1
keep birimno household_income household_size income_per_person ///
    household_income_value_rank income_per_person_value_rank ///
    income5 income_per_person5 faktor_hane_num
save `households'

use "`linked_dta'", clear
rename *, lower
foreach id in birimno fertno baba_birimno baba_fertno anne_birimno anne_fertno {
    replace `id' = strtrim(`id')
}
isid birimno fertno
generate double child_dob = mdy(real(dogum_tarih_ay), ///
    real(dogum_tarih_gun), real(dogum_tarih_yil))
quietly count
local n_source = r(N)
keep if !missing(child_dob) & child_dob <= `refdate'
generate int child_months = (`refyear' - real(dogum_tarih_yil))*12 + ///
    `refmonth' - real(dogum_tarih_ay) - (real(dogum_tarih_gun) > `refday')
quietly count
display as result "`date_iso': valid born children " r(N) " of `n_source' source rows."

foreach parent in father mother {
    preserve
    if "`parent'" == "father" {
        local prefix baba
        local sex 1
    }
    else {
        local prefix anne
        local sex 2
    }
    keep if `prefix'_birimno != "" & !inlist(`prefix'_fertno, "", "99")
    generate str16 parent_fertno = `prefix'_fertno
    generate int birth_year = real(`prefix'_dogum_tarih_yil)
    generate byte birth_month = real(`prefix'_dogum_tarih_ay)
    generate byte birth_day = real(`prefix'_dogum_tarih_gun)
    generate str6 parent = "`parent'"
    generate double parent_dob = mdy(birth_month, birth_day, birth_year)
    keep if !missing(parent_dob) & parent_dob <= `refdate'
    generate double linked_hh_weight = real(subinstr(strtrim(faktor_hane), ",", ".", .))
    bysort birimno parent_fertno: generate int n_linked_children = _N
    bysort birimno parent_fertno: egen int youngest_months = min(child_months)
    bysort birimno parent_fertno: egen int oldest_months = max(child_months)

    forvalues lower = 0/17 {
        forvalues upper = `lower'/17 {
            generate byte child_flag = inrange(child_months, 12*`lower', 12*(`upper'+1)-1)
            bysort birimno parent_fertno: egen byte any_a`lower'_`upper' = max(child_flag)
            drop child_flag
        }
    }
    bysort birimno parent_fertno: keep if _n == 1
    isid birimno parent_fertno
    generate int birth_ym = mofd(parent_dob)
    generate int run_month = birth_ym - ym(1987,1)
    generate byte exposed = (run_month >= 0)
    format parent_dob %td
    format birth_ym %tm
    keep parent birimno parent_fertno parent_dob birth_year birth_month ///
        birth_day birth_ym run_month exposed linked_hh_weight ///
        n_linked_children youngest_months oldest_months any_a*
    save ``parent'_rows'
    quietly count
    display as result "`date_iso': `parent' denominator = " r(N)
    restore
}

use `father_rows', clear
append using `mother_rows'
isid parent birimno parent_fertno
merge m:1 birimno using `households', keep(master match) generate(_household_merge)
drop _household_merge linked_hh_weight
rename faktor_hane_num faktor_hane
generate double reference_date = `refdate'
format reference_date %td
foreach width in 3 4 5 {
    local last = 18 - `width'
    forvalues lower = 0/`last' {
        local upper = `lower' + `width' - 1
        foreach rule in youngest oldest {
            generate byte `rule'_a`lower'_`upper' = inrange(`rule'_months, 12*`lower', 12*(`upper'+1)-1)
        }
    }
}
notes _dta: One row per linked father or mother with valid DOB; all retained parents are denominators.
notes _dta: Child ages are strict completed ages on reference_date; no 60-62-month extensions or age caps.
notes _dta: Youngest and oldest refer to valid-DOB children linked to that parent in child017_linked.dta, before interval testing.
notes _dta: Adult children absent from the linked 0-17 source cannot be identified; household children linked to another parent are not substituted.
sort parent birth_ym birimno parent_fertno
compress
save "`output_dta'", replace

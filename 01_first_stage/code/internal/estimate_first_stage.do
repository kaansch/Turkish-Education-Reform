version 18.0
set more off

args master_dir output_docx
tempfile estimates
tempname handle
postfile `handle' str6 parent str6 outcome str10 donut str16 model ///
    double estimate se p long N using "`estimates'", replace

foreach parent in father mother {
    foreach target in parent spouse {
        local input "`master_dir'/`parent'_master.dta"
        local y middle8_complete
        if "`target'" == "spouse" {
            local input "`master_dir'/`parent'_spouse.dta"
            local y spouse_middle8_complete
        }

        use "`input'", clear
        keep if inrange(run_month, -96, 95) & ///
            !missing(`y', run_month, reform_exposed, faktor_hane) & faktor_hane > 0

        foreach hole in 0 12 {
            preserve
            if `hole' == 12 drop if inrange(run_month, -12, 11)
            local donut = cond(`hole' == 12, "12 months", "none")

            quietly regress `y' i.reform_exposed [pw=faktor_hane], vce(robust)
            post `handle' ("`parent'") ("`target'") ("`donut'") ///
                ("Raw difference") (_b[1.reform_exposed]) ///
                (_se[1.reform_exposed]) ///
                (2*ttail(e(df_r), abs(_b[1.reform_exposed] / ///
                    _se[1.reform_exposed]))) (e(N))

            quietly regress `y' i.reform_exposed##c.run_month ///
                [pw=faktor_hane], vce(robust)
            post `handle' ("`parent'") ("`target'") ("`donut'") ///
                ("Local linear") (_b[1.reform_exposed]) ///
                (_se[1.reform_exposed]) ///
                (2*ttail(e(df_r), abs(_b[1.reform_exposed] / ///
                    _se[1.reform_exposed]))) (e(N))
            restore
        }
    }
}
postclose `handle'

use "`estimates'", clear

putdocx begin, pagesize(letter) font("Times New Roman", 9, black) ///
    margin(top, .55in) margin(bottom, .55in) ///
    margin(left, .75in) margin(right, .75in)

putdocx paragraph, halign(left) spacing(after, 5pt)
putdocx text ("Table 1."), bold font("Times New Roman", 11, black)
putdocx text (" First-stage effects on eight-year schooling completion"), ///
    font("Times New Roman", 11, black)

putdocx table firststage = (16, 5), width(100%) indent(.02in) ///
    layout(fixed) headerrow(2) ///
    cellmargin(top, .025in) cellmargin(bottom, .025in) ///
    cellmargin(left, .055in) cellmargin(right, .055in) ///
    border(all, nil)
putdocx table firststage(., 1), width(2.65in) halign(left)
forvalues column = 2/5 {
    putdocx table firststage(., `column'), width(.95in) halign(center)
}
putdocx table firststage(., .), font("Times New Roman", 8.7, black) ///
    valign(center)

putdocx table firststage(1, 1) = ("Specification"), bold
putdocx table firststage(1, 4) = ("Local linear RDD"), colspan(2) ///
    bold halign(center)
putdocx table firststage(1, 2) = ("Raw difference"), colspan(2) ///
    bold halign(center)
putdocx table firststage(2, 1) = ("Outcome"), italic
putdocx table firststage(2, 2) = ("No donut"), italic halign(center)
putdocx table firststage(2, 3) = ("12-month donut"), italic halign(center)
putdocx table firststage(2, 4) = ("No donut"), italic halign(center)
putdocx table firststage(2, 5) = ("12-month donut"), italic halign(center)

putdocx table firststage(3, 1) = ("A  Father cutoff"), colspan(5) bold
putdocx table firststage(10, 1) = ("B  Mother cutoff"), colspan(5) bold

foreach parent in father mother {
    local first_outcome_row = cond("`parent'" == "father", 4, 11)
    local outcome_number = 0
    foreach target in parent spouse {
        local coefficient_row = `first_outcome_row' + 3*`outcome_number'
        local se_row = `coefficient_row' + 1
        local n_row = `coefficient_row' + 2
        local outcome_label = cond("`target'" == "parent", ///
            "Cutoff parent's completion", "Spouse's completion")
        putdocx table firststage(`coefficient_row', 1) = ///
            ("`outcome_label'")
        putdocx table firststage(`se_row', 1) = ("Robust standard error"), ///
            italic font("Times New Roman", 8.2, black)
        putdocx table firststage(`n_row', 1) = ("Observations"), ///
            font("Times New Roman", 8.2, black)

        local column = 1
        foreach model in "Raw difference" "Local linear" {
            foreach donut in none "12 months" {
                local ++column
                quietly summarize estimate if parent == "`parent'" & ///
                    outcome == "`target'" & model == "`model'" & ///
                    donut == "`donut'", meanonly
                local coefficient = r(mean)
                quietly summarize se if parent == "`parent'" & ///
                    outcome == "`target'" & model == "`model'" & ///
                    donut == "`donut'", meanonly
                local standard_error = r(mean)
                quietly summarize p if parent == "`parent'" & ///
                    outcome == "`target'" & model == "`model'" & ///
                    donut == "`donut'", meanonly
                local p_value = r(mean)
                quietly summarize N if parent == "`parent'" & ///
                    outcome == "`target'" & model == "`model'" & ///
                    donut == "`donut'", meanonly
                local observations = r(mean)

                local stars ""
                if `p_value' < .10 local stars "*"
                if `p_value' < .05 local stars "**"
                if `p_value' < .01 local stars "***"
                local coefficient_text : display %6.3f `coefficient'
                local coefficient_text = strtrim("`coefficient_text'") + "`stars'"
                local se_text : display %6.3f `standard_error'
                local se_text = "[" + strtrim("`se_text'") + "]"
                local n_text : display %9.0fc `observations'
                local n_text = strtrim("`n_text'")

                putdocx table firststage(`coefficient_row', `column') = ///
                    ("`coefficient_text'"), halign(center)
                putdocx table firststage(`se_row', `column') = ///
                    ("`se_text'"), halign(center) ///
                    font("Times New Roman", 8.2, black)
                putdocx table firststage(`n_row', `column') = ///
                    ("`n_text'"), halign(center) ///
                    font("Times New Roman", 8.2, black)
                if `p_value' < .10 {
                    putdocx table firststage(`coefficient_row', `column'), bold
                }
            }
        }
        local ++outcome_number
    }
}

putdocx table firststage(1, .), border(top, single, black, 1pt)
putdocx table firststage(2, .), border(bottom, single, black, .5pt)
putdocx table firststage(3, .), border(bottom, single, black, .5pt)
putdocx table firststage(9, .), border(bottom, single, black, .5pt)
putdocx table firststage(10, .), border(bottom, single, black, .5pt)
putdocx table firststage(16, .), border(bottom, single, black, 1pt)
foreach row in 7 14 {
    putdocx table firststage(`row', .), border(top, single, black, .25pt)
}

putdocx paragraph, halign(left) spacing(before, 5pt) spacing(after, 0pt)
putdocx text ("Notes: "), italic font("Times New Roman", 7.8, black)
putdocx text ("The dependent variable equals one when the indicated adult completed at least eight years of schooling. All estimates use a symmetric 8-year bandwidth around January 1987 and FAKTOR_HANE weights. Raw differences compare observations on either side of the cutoff. Local linear RDD estimates allow separate slopes on the two sides. Donut estimates exclude birth months -12 through +11. No additional covariates are included. Robust standard errors are in brackets. Significant coefficients are bold. *** p<0.01, ** p<0.05, * p<0.10."), ///
    font("Times New Roman", 7.8, black)

putdocx save "`output_docx'", replace nomsg

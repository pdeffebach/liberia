
cap program drop summary_table_diff
program define summary_table_diff
    
    clear mata 
    set matsize 10000
    syntax varlist [if], FILENAME(name) SUBSET(varlist) DIFFVAR(varlist) COVARIATES(varlist) ZEROSTRING(string) ONESTRING(string)


    mat means = J(`:word count `varlist'', 3, .)
    mat regress_diff = J(`:word count `varlist'', 2, .)
    mat regress_diff_stars = J(`:word count `varlist'', 2,0)

    mat rownames means = `varlist'
    mat rownames regress_diff = `varlist'


    local i = 1
foreach var in `varlist' {
    qui sum  `var' if `subset' == 1
    if r(N) != 0 {
    qui summarize `var' if `subset' == 1
    mat means[`i', 1] = r(mean)

    qui summarize `var' if `subset' == 1 & `diffvar' == 0 , detail
    mat means[`i', 2] = r(mean)

    qui summarize `var' if `subset' == 1 & `diffvar' == 1, detail
    mat means[`i', 3] = r(mean)



    svy: regress `var' `diffvar' `covariates' if `subset' == 1
    mat regress_diff[`i',1] = _b[`diffvar']
    
    local p = (2 * ttail(e(df_r), abs(_b[`diffvar']/_se[`diffvar'])))
    mat regress_diff[`i',2] = `p'
    * Use p-value to make stars ********************************************
        if (`p' < .1)   mat regress_diff_stars[`i',2] = 1 // less than 10%?
        if (`p' < .05)  mat regress_diff_stars[`i',2] = 2 // less than 5%?
        if (`p' < .01)  mat regress_diff_stars[`i',2] = 3 // less than 1%?
    }
    local ++i
}

frmttable, statmat(means) varlabels 
frmttable, statmat(regress_diff) annotate(regress_diff_stars) asymbol(*,**,***) merge varlabels 
frmttable using out/tables/`filename', ctitle( ///
"", "\uline{\hfill Mean \hfill}", "", "", "\uline{\hfill Regression difference \hfill}", "" \ ///
"Baseline covariate", "All", "`zerostring'", "`onestring'", "Coeff.", "p-value" \ ///
"", "(1)", "(2)", "(3)", "(4)", "(5)" ///
) ///
multicol(1,2,3;1,5,2) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace

end
***
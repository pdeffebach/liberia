
cap program drop summary_table_diff
program define summary_table_diff
    
    clear mata 
    set matsize 10000
    syntax varlist [if], FILENAME(name) SUBSET(varlist) DIFFVAR(varlist) COVARIATES(varlist)


    mat means = J(`:word count `varlist'', 2, .)
    mat medians = J(`:word count `varlist'', 2, .)
    mat sds = J(`:word count `varlist'', 2, .)
    mat regress_diff = J(`:word count `varlist'', 2, .)
    mat regress_diff_stars = J(`:word count `varlist'', 2,0)

    mat rownames means = `varlist'
    mat rownames medians = `varlist'
    mat rownames sds = `varlist'
    mat rownames regress_diff = `varlist'


    local i = 1
    foreach var in `varlist' {

    qui summarize `var' if `subset' == 1 & `diffvar' == 0 , detail

    mat means[`i', 1] = r(mean)
    mat sds[`i', 1] = r(sd)
    mat medians[`i', 1] = r(p50)

    qui summarize `var' if `subset' == 1 & `diffvar' == 1, detail

    mat means[`i', 2] = r(mean)
    mat sds[`i', 2] = r(sd)
    mat medians[`i', 2] = r(p50)


    svy: regress `var' `diffvar' district1-district14 if `subset' == 1
    mat regress_diff[`i',1] = _b[`diffvar']
    mat regress_diff[`i',2] = _se[`diffvar']
    
    local p = (2 * ttail(e(df_r), abs(_b[`diffvar']/_se[`diffvar'])))
    * Use p-value to make stars ********************************************
        if (`p' < .1)   mat regress_diff_stars[`i',2] = 1 // less than 10%?
        if (`p' < .05)  mat regress_diff_stars[`i',2] = 2 // less than 5%?
        if (`p' < .01)  mat regress_diff_stars[`i',2] = 3 // less than 1%?
    
    local ++i
}

frmttable, statmat(means) varlabels 
frmttable, statmat(medians) varlabels merge
frmttable, statmat(sds) varlabels merge
frmttable, statmat(regress_diff) annotate(regress_diff_stars) asymbol(*,**,***) merge varlabels substat(1)
frmttable using out/tables/`filename', ctitle( ///
"", "\uline{\hfill Mean \hfill}", "", "\uline{\hfill Median \hfill}", "", "\uline{\hfill Std. dev. \hfill}", "", "Effect of" \ ///
"Baseline covariate", "Kept", "Dropped", "Kept", "Dropped", "Kept", "Dropped", "Dropping" ///
) ///
multicol(1,2,2;1,4,2;1,6,2) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace

end
***
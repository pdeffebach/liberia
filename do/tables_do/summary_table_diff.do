
cap program drop summary_table_diff
program define summary_table_diff
    
    clear mata 
    set matsize 10000
    syntax varlist [if], FILENAME(name) SUBSET(varlist) DIFFVAR(varlist) COVARIATES(varlist)


    mat stats = J(`:word count `varlist'', 6, .)
    mat regress_diff = J(`:word count `varlist'', 2, .)
    mat regress_diff_stars = J(`:word count `varlist'', 2,0)

    mat rownames stats = `varlist'
    mat rownames regress_diff = `varlist'


    local i = 1
    foreach var in `varlist' {

    qui summarize `var' if `subset' == 1 & `diffvar' == 0 , detail

    mat stats[`i', 1] = r(mean)
    mat stats[`i', 2] = r(sd)
    mat stats[`i', 3] = r(p50)

    qui summarize `var' if `subset' == 1 & `diffvar' == 1, detail

    mat stats[`i', 4] = r(mean)
    mat stats[`i', 5] = r(sd)
    mat stats[`i', 6] = r(p50)


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

frmttable, statmat(stats) varlabels 
frmttable, statmat(regress_diff) annotate(regress_diff_stars) asymbol(*,**,***) merge varlabels substat(1)
frmttable using out/tables/`filename', ctitle( ///
"", "\uline{\hfill Non-dropped communities \hfill}", "", "", "\uline{\hfill Dropped communities \hfill}", "", "", "Effect of" \ ///
"Baseline covariate", "Mean", "SD", "Median", "Mean", "SD", "Median", "Dropping" ///
) ///
multicol(1,2,3;1,5,3) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace

end
***
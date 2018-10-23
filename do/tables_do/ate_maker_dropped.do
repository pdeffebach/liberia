cap program drop ate_maker_dropped
program define ate_maker_dropped 
syntax varlist, TREAT(varlist) COVARIATES(varlist) SUBSET(varlist) FILENAME(name) ///
    DROPPED(varlist)

local dep_vars `varlist' 
local number_dep_vars    `:word count `dep_vars'' 

mat control_mean = J(`number_dep_vars', 1, .)
mat reg_main        = J(`number_dep_vars',6,.)
mat stars          = J(`number_dep_vars',6,0)
mat reg_pct_control= J(`number_dep_vars',3,.)

mat rownames control_mean = `dep_vars'
mat rownames reg_main = `dep_vars'
mat rownames reg_pct_control = `dep_vars'

local regressors `treat' `dropped' `covariates'

local y_counter = 1 
foreach y in `dep_vars'{ 
    qui sum `y' if `subset' == 1
    if r(N) != 0 {
    * Run the regression ***************************************************

    * Input the betas and the standard errors ******************************
    qui svyset commcode [pweight=weight_e1_e2], strata(county) 
    qui svy: reg `y' `treat' `covariates' if (`subset' == 1) 
    mat reg_main[`y_counter',1] = _b[`treat'] // put in beta estimate
    mat reg_main[`y_counter',2] = _se[`treat'] // put in standard error estimate
    local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
        if (`p' < .1)   mat stars[`y_counter',2] = 1 // less than 10%?
        if (`p' < .05)  mat stars[`y_counter',2] = 2 // less than 5%?
        if (`p' < .01)  mat stars[`y_counter',2] = 3 // less than 1%?
    local beta_treat_all = _b[`treat']

    qui svyset commcode [pweight=dropping_weight_ec2], strata(county) 
    qui svy: reg `y' `treat' `covariates' if (`subset' == 1) & `dropped' == 0 
    mat reg_main[`y_counter',3] = _b[`treat'] // put in beta estimate
    mat reg_main[`y_counter',4] = _se[`treat'] // put in standard error estimate
    local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
        if (`p' < .1)   mat stars[`y_counter',4] = 1 // less than 10%?
        if (`p' < .05)  mat stars[`y_counter',4] = 2 // less than 5%?
        if (`p' < .01)  mat stars[`y_counter',4] = 3 // less than 1%?
    local beta_treat_e2 = _b[`treat']

    qui svyset commcode [pweight=weight_e1_e2], strata(county) 
    qui svy: reg `y' `treat' `dropped' `covariates' if (`subset' == 1) 
    mat reg_main[`y_counter', 5] = _b[`dropped']
    mat reg_main[`y_counter', 6] = _se[`dropped']
    local p = (2 * ttail(e(df_r), abs(_b[`dropped']/_se[`dropped'])))
        if (`p' < .1)   mat stars[`y_counter',6] = 1 // less than 10%?
        if (`p' < .05)  mat stars[`y_counter',6] = 2 // less than 5%?
        if (`p' < .01)  mat stars[`y_counter',6] = 3 // less than 1%?
    local beta_dropped = _b[`dropped']


    * Get the control means *************************************************
    // normal
    qui svyset commcode [pweight=weight_e1_e2], strata(county) 
    qui svy: mean `y' if (`treat' == 0 & `subset' == 1) 
    mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
    local temp_mean = mean_mat[1, 1]
    mat control_mean[`y_counter', 1] = e(b)
    mat reg_pct_control[`y_counter', 1] = 100 * `beta_treat_all' / `temp_mean'

    // non-dropped
    qui svyset commcode [pweight=dropping_weight_ec2], strata(county) 
    qui svy: mean `y' if (`treat' == 0 & `subset' == 1) & `dropped' == 0  
    mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
    local temp_mean = mean_mat[1, 1]
    mat reg_pct_control[`y_counter', 2] = 100 * `beta_treat_e2' / `temp_mean'

    // dropped 
    qui svyset commcode [pweight=weight_e1_e2], strata(county) 
    qui svy: mean `y' if (`treat' == 0 & `subset' == 1) & `dropped' == 1  
    mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
    local temp_mean = mean_mat[1, 1]
    mat reg_pct_control[`y_counter', 3] = 100 * `beta_dropped' / `temp_mean'
    
    } // end if r(N) != 0 (for new blank variables that are labels)
    * Increment the counters ***********************************************
    loc ++y_counter
}

qui frmttable, statmat(control_mean) sdec(3) varlabels
qui frmttable, statmat(reg_main) merge substat(1) sdec(3) varlabels annotate(stars) asymbol(*,**,***) squarebrack
qui frmttable, statmat(reg_pct_control) merge  varlabels

frmttable using out/tables/`filename', ctitle( ///
"", "", "", "", "", "Effect as \%", "", "" \ ///
"", "Mean", "\uline{\hfill Effect of Treatment \hfill}", "", "Effect", "\uline{\hfill of control mean \hfill}" \ ///
"", "full" "Full", "Reduced", "of", "Full", "Reduced", "" \ ///
"", "sample", "sample", "sample", "Dropping", "sample", "sample", "Dropping" \ ///
"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)" ///
) ///
multicol(1,6,3; 2,3,2; 2,6,3) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace



end


***
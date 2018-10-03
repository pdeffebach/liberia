cap program drop ate_maker_dropped
program define ate_maker_dropped 
syntax varlist, TREAT(varlist) COVARIATES(varlist) SUBSET(varlist) FILENAME(name) ///
    DROPPED(varlist)

local dep_vars `varlist' 
local number_dep_vars    `:word count `dep_vars'' 

mat reg_count       = J(`number_dep_vars',1,.)

mat control_means    = J(`number_dep_vars',2,.)
mat reg_main        = J(`number_dep_vars',4,.)
mat stars          = J(`number_dep_vars',4,0)
mat reg_pct_control= J(`number_dep_vars',2,.)


mat rownames reg_count = `dep_vars'

mat rownames control_means = `dep_vars'
mat rownames reg_main = `dep_vars'
mat rownames reg_pct_control = `dep_vars'

local regressors `treat' `dropped' `covariates'

local y_counter = 1 
foreach y in `dep_vars'{ 
    qui sum `y' if `subset' == 1
    if r(N) != 0 {
    * Run the regression ***************************************************
    qui svy: reg `y' `regressors' if (`subset' == 1) & `dropped' == 0 
    
    * Input number of obs. in regression ***********************************
    mat reg_count[`y_counter',1] = e(N) // put in number of observations used in regression
    
    * Input the betas and the standard errors ******************************
    mat reg_main[`y_counter',1] = _b[`treat'] // put in beta estimate
    mat reg_main[`y_counter',2] = _se[`treat'] // put in standard error estimate
    local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
        if (`p' < .1)   mat stars[`y_counter',2] = 1 // less than 10%?
        if (`p' < .05)  mat stars[`y_counter',2] = 2 // less than 5%?
        if (`p' < .01)  mat stars[`y_counter',2] = 3 // less than 1%?
    local beta_treat = _b[`treat']

    qui svy: reg `y' `regressors' if (`subset' == 1) 
    mat reg_main[`y_counter', 3] = _b[`dropped']
    mat reg_main[`y_counter', 4] = _se[`dropped']
    local p = (2 * ttail(e(df_r), abs(_b[`dropped']/_se[`dropped'])))
        if (`p' < .1)   mat stars[`y_counter',2] = 1 // less than 10%?
        if (`p' < .05)  mat stars[`y_counter',2] = 2 // less than 5%?
        if (`p' < .01)  mat stars[`y_counter',2] = 3 // less than 1%?
    local beta_dropped = _b[`dropped']


    * Get the control means *************************************************
    // non-dropped
    qui svy: mean `y' if (`treat' == 0 & `subset' == 1) & `dropped' == 0  
    mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
    mat control_means[`y_counter',1] = mean_mat[1, 1] // put in control mean 
    local temp_mean = mean_mat[1, 1]
    mat reg_pct_control[`y_counter', 1] = 100 * `beta_treat' / `temp_mean'
    // dropped 
    qui svy: mean `y' if (`treat' == 0 & `subset' == 1) & `dropped' == 1  
    mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
    mat control_means[`y_counter',2] = mean_mat[1, 1] // put in control mean 
    local temp_mean = mean_mat[1, 1]
    mat reg_pct_control[`y_counter', 2] = 100 * `beta_dropped' / `temp_mean'
    
    } // end if r(N) != 0 (for new blank variables that are labels)
    * Increment the counters ***********************************************
    loc ++y_counter
}

qui frmttable, statmat(reg_count) varlabels sdec(0)
qui frmttable, statmat(control_means) merge varlabels 
qui frmttable, statmat(reg_main) merge substat(1) sdec(3) varlabels annotate(stars) asymbol(*,**,***)
qui frmttable, statmat(reg_pct_control) merge  varlabels

frmttable using out/tables/`filename', ctitle( ///
"", "", "", "", "", "", "Effect as pct", "" \ ///
"", "", "", "", "", "", "\uline{\hfill of control \hfill}", "" \ ///
"", "", "\uline{\hfill Control mean in full sample \hfill}", "", "Effect of", "Effect of", "Treatment", "Dropping" \ ///
"Dependent variable", "N", "Not dropped", "Dropped", "Treatment (no drops)", "Dropping (full sample)", "(no drops)", "(full sample)" \ ///
"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)") ///
multicol(1,7,2; 2,7,2; 3,3,2;) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace



end


***
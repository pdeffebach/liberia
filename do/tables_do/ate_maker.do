

cap program drop ate_maker
program define ate_maker
clear mata 
syntax varlist, TREAT(varlist) COVARIATES(varlist) SUBSET(varlist) FILENAME(name) [omitpct] ///
	[ADJUSTVARS(varlist) NSIMS(integer 0)] [EXTRAADJUSTVARS(varlist)]

qui do do/tables_do/adjust_p_values
local dep_vars `varlist' // creating a local for dep. variables
local number_dep_vars = `:word count `dep_vars''

/* making longer local for regression because reg takes only one local */
local regressors `treat' `covariates'
// Initializing all the matices 
/* 	we have to have separate matrices for each number format we want, I 
	think. We can't store control means and counts in the same matrix 
	because obviously we don't want counts to have decimal places, but 
	we do want decimal places for means. */

mat control_mean 	= J(`number_dep_vars',1,.)
mat reg_count		= J(`number_dep_vars',1,.)
mat reg_main 		= J(`number_dep_vars',2,.)
mat stars			= J(`number_dep_vars',2,0)
mat reg_pct_control = J(`number_dep_vars',1,.)
mat estimated_ps 	= J(`number_dep_vars',1,.)
mat adjusted_ps 	= J(`number_dep_vars',2,.)
mat adjusted_ps_syms = J(`number_dep_vars',2,0)

// Initializing row names.
mat rownames control_mean = `dep_vars'
mat rownames reg_count = `dep_vars'
mat rownames reg_main = `dep_vars'
mat rownames reg_pct_control = `dep_vars'
mat rownames estimated_ps = `dep_vars'
mat rownames adjusted_ps = `dep_vars'

loc y_counter = 1
foreach y in `dep_vars'{ 
	qui sum `y' if `subset' == 1
	if r(N) != 0 {
	* Run the regression ***************************************************
	qui svy: reg `y' `regressors' if (`subset' == 1)
	
	* Input number of obs. in regression ***********************************
	mat reg_count[`y_counter',1] = e(N) // put in number of observations used in regression
	
	* Calculate the p-value of treatment ***********************************
	local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
	mat estimated_ps[`y_counter',1] = `p'
	* Use p-value to make stars ********************************************
		if (`p' < .1) 	mat stars[`y_counter',2] = 1 // less than 10%?
		if (`p' < .05) 	mat stars[`y_counter',2] = 2 // less than 5%?
		if (`p' < .01) 	mat stars[`y_counter',2] = 3 // less than 1%?
	
	* Input the betas and the standard errors ******************************
	mat reg_main[`y_counter',1] = _b[`treat'] // put in beta estimate
	mat reg_main[`y_counter',2] = _se[`treat'] // put in standard error estimate
	
	* Save the beta for use in calculating beta / control mean 
	/* 	The command svy: mean overwrites the beta matrix that was created 
		in the regression. 
	*/
	local beta = _b[`treat']
	
	* Get the control mean *************************************************
	qui svy: mean `y' if (`treat' == 0 & `subset' == 1) // get summary stats for control mean
	mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
	mat control_mean[`y_counter',1] = mean_mat[1, 1] // put in control mean 
	local temp_mean = mean_mat[1, 1]
	mat reg_pct_control[`y_counter', 1] = 100 * `beta' / `temp_mean'
	} // end if r(N) != 0 (for new blank variables that are labels)
	
	* Increment the counters ***********************************************
	loc ++y_counter
}

if "`adjustvars'" != "" {
	adjust_p_values, adjustvars(`adjustvars') adjustvarsmat(adjusted_ps) controls(`covariates') treat(`treat') nsims(`nsims') strata(district_bl) group(`subset')
	foreach y in `adjustvars' {
		local t = rownumb(adjusted_ps, "`y'")
		mat adjusted_ps_syms[`t', 1] = 1 
	}
}

if "`extraadjustvars'" != "" {
	adjust_p_values, adjustvars(`extraadjustvars') adjustvarsmat(adjusted_ps) controls(`covariates') treat(`treat') nsims(`nsims') strata(district_bl) group(`subset')
	foreach y in `extraadjustvars' {
		local t = rownumb(adjusted_ps, "`y'")
		mat adjusted_ps_syms[`t', 1] = 2 
	}
}

if "`adjustvars'" == "" {
	if "`omitpct'" == "" {
	********************************************************************************
	* Merge matrices to form our larger, final matrix. *****************************
	********************************************************************************
		qui frmttable, statmat(reg_count) sdec(0) varlabels 
		qui frmttable, statmat(control_mean) sdec(3) varlabels merge
		qui frmttable, statmat(reg_main) sdec(3) annotate(stars) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
		qui frmttable, statmat(reg_pct_control) sdec(1) varlabels merge
		frmttable using out/tables/`filename', ///
		ctitle( ///
		"", "", "", "", "ITT /" \ ///
		"", "", "Control", "", "control", \ ///
		"Dependent Variable", "N", "mean", "ITT", "mean (\%)" \ ///
		"", "(1)", "(2)", "(3)", "(4)") ///
		tex ///
		fragment ///
		varlabels ///
		nocenter ///
		replace
	}
	else {
		qui frmttable, statmat(reg_count) sdec(0) varlabels 
		qui frmttable, statmat(control_mean) sdec(3) varlabels merge
		qui frmttable, statmat(reg_main) sdec(3) annotate(stars) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
		frmttable using out/tables/`filename', ///
		ctitle( ///
		"", "", "", "" \ ///
		"", "", "Control", "" \ ///
		"Dependent Variable", "N", "mean", "ITT" \ ///
		"", "(1)", "(2)", "(3)") ///
		tex ///
		fragment ///
		varlabels ///
		nocenter ///
		replace
	}
}
if "`adjustvars'" != "" {
	if "`omitpct'" == "" {
	********************************************************************************
	* Merge matrices to form our larger, final matrix. *****************************
	********************************************************************************
		qui frmttable, statmat(reg_count) sdec(0) varlabels 
		qui frmttable, statmat(control_mean) sdec(3) varlabels merge
		qui frmttable, statmat(reg_main) sdec(3) annotate(stars) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
		qui frmttable, statmat(reg_pct_control) sdec(1) varlabels merge
		qui frmttable, statmat(estimated_ps) sdec(3) varlabels merge 
		qui frmttable, statmat(adjusted_ps) sdec(3) asymbol(\textsuperscript{a},\textsuperscript{b}) merge squarebrack varlabels
		frmttable using out/tables/`filename', ///
		ctitle( ///
		"", "", "", "", "ITT /", "", "", "" \ ///
		"", "", "Control", "", "control", "Est.", "WY. adj.", "Holms adj." \ ///
		"Dependent Variable", "N", "mean", "ITT", "mean (\%)", "p-val", "p-val", "p-val" \ ///
		"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)") ///
		tex ///
		fragment ///
		varlabels ///
		nocenter ///
		replace
	}
	else {
		qui frmttable, statmat(reg_count) sdec(0) varlabels 
		qui frmttable, statmat(control_mean) sdec(3) varlabels merge
		qui frmttable, statmat(reg_main) sdec(3) annotate(stars) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
		qui frmttable, statmat(estimated_ps) sdec(3) varlabels merge 
		qui frmttable, statmat(adjusted_ps) sdec(3) asymbol(\textsuperscript{a},\textsuperscript{b}) merge squarebrack varlabels
		frmttable using out/tables/`filename', ///
		ctitle( ///
		"", "", "", "", "", "" \ ///
		"", "", "Control", "", "Est.", "Wy adj.", "Holms adj." \ ///
		"Dependent Variable", "N", "mean", "ITT","p-val", "p-val", "p-val" \ ///
		"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)") ///
		tex ///
		fragment ///
		varlabels ///
		nocenter ///
		replace
	}
}

end 



///
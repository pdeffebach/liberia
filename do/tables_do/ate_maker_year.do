cap program drop ate_maker_year
program define ate_maker_year
	clear mata 
	set matsize 10000

	set more off 
	syntax varlist, TREAT(varlist) GROUP1(varlist) GROUP2(varlist) CONTROLS1(varlist) CONTROLS2(varlist) FILENAME(name) [ADJUSTVARSG1(varlist) ADJUSTVARSG2(varlist) NSIMS(integer 0)] [EXTRAADJUSTVARSG1(varlist) EXTRAADJUSTVARSG2(varlist)]

	local dep_vars `varlist' // creating a local for dep. variables
	local M = `:word count `dep_vars''

	/* making longer local for regression because reg takes only one local */
	local regressors1 		`treat' `controls1'
	local regressors2 		`treat' `controls2'
	

	// Initializing all the matices 
	/* 	we have to have separate matrices for each number format we want, I 
		think. We can't store control means and counts in the same matrix 
		because obviously we don't want counts to have decimal places, but 
		we do want decimal places for means. */
	mat control_mean_g1		= J(`M',2,.)
	mat control_mean_g2 	= J(`M',2,.)

	mat reg_g1 			= J(`M',2,.)
	mat stars_g1 		= J(`M',2,0)
	mat ate_pct_g1		= J(`M',1,.)
	mat estimated_ps_g1 = J(`M',1,.)
	mat adjusted_ps_g1 	= J(`M',2,.)
	mat adjusted_ps_syms_g1 = J(`M',2,0)


	mat reg_g2 			= J(`M',2,.)
	mat stars_g2		= J(`M',2,0)
	mat ate_pct_g2		= J(`M',1,.)
	mat estimated_ps_g2 = J(`M',1,.)
	mat adjusted_ps_g2 	= J(`M',2,.)
	mat adjusted_ps_syms_g2 = J(`M',2,0)

	// Initializing row names.
	mat rownames control_mean_g1 = `dep_vars'
	mat rownames control_mean_g2 = `dep_vars'
	mat rownames estimated_ps_g1 = `dep_vars'
	mat rownames adjusted_ps_g1 = `dep_vars'
	mat rownames ate_pct_g1 = `dep_vars'
	mat rownames ate_pct_g2 = `dep_vars'
	mat rownames reg_g1 = `dep_vars'
	mat rownames reg_g2 = `dep_vars'
	mat rownames estimated_ps_g2 = `dep_vars'
	mat rownames adjusted_ps_g2 = `dep_vars'
	mat rownames adjusted_ps_syms_g1 = `dep_vars'
	mat rownames adjusted_ps_syms_g2 = `dep_vars'

	mat colnames adjusted_ps_g1 = "WY" "Holms"
	mat colnames adjusted_ps_g2 = "WY" "Holms"

	/* 	This upcoming for loop does the following: 
		1)	For each dependent variable it runs a regression of y on treat and 
			the covariates. 
		2) 	Calculates the p-values and significance levels of the coefficients
		3) 	Inputs the estimates for beta (on treat only), into the matrix. It 
			inputs beta hat in one column and SE hat in another. 
		
		In order to understand why I generate stars the way I do, please see 
		this link: https://www.pdx.edu/econ/sites/www.pdx.edu.econ/files/frmttable_sj.pdf
		frmttable adds stars to estimates based on a matrix that here i call 
		stars. If stars(i,j) = 3, for example, than cell (i,j) will get 3 stars. 
		I set the first column of stars all to zero because we want stars to 
		go next to the standard errors, not the beta estimates. 
	*/

	loc m = 1
	foreach y in `dep_vars'{ 
		
		************************************************************************
		* Year 1 regression  ***************************************************
		************************************************************************

		* Check to make sure we have observations of that variable 
		qui sum `y' if `group1' == 1
		if r(N) != 0 {

			qui svyset [pweight=s_weight2], psu(commcode) strata(county)	// Set survey data specific to each dataset

			qui svy: reg `y' `regressors1' if (`group1'== 1 & !missing(`y'))
			mat control_mean_g1[`m',2] = e(N) // put in the N of the regression

			local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
			mat estimated_ps_g1[`m',1] = `p'

			mat stars_g1[`m', 1] = 0 // make the first column of stars 0
				if (`p' < .1) 		mat stars_g1[`m',2] = 1 // less than 10%?
					else mat stars_g1[`m',2] = 0 // if not, no stars
				if (`p' < .05) 	mat stars_g1[`m',2] = 2 // less than 5%?
				if (`p' < .01) 	mat stars_g1[`m',2] = 3 // less than 1%?
	
			mat reg_g1[`m',1] = _b[`treat'] // put in beta estimate
			mat reg_g1[`m',2] = _se[`treat'] // put in standard error estimate

			local beta = _b[`treat']
	
			* Get the control mean *************************************************
			qui svy: mean `y' if (`treat' == 0 & `group1' == 1) // get summary stats for control mean
			mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
			mat control_mean_g1[`m',1] = mean_mat[1, 1] // put in control mean 
			local temp_mean = mean_mat[1, 1]
			qui sum `y' if `group1' == 1 
			// put in the control mean, but only if its not an index variable
			if abs(r(mean)) > .01 & r(min) >= 0 { 
				mat ate_pct_g1[`m', 1] = 100 * `beta' / `temp_mean'
			}
		}



		************************************************************************
		* Year 2 regression ****************************************************
		************************************************************************
		* Check to make sure we have observations of that variable 
		qui sum `y' if `group2' == 1
		if r(N) != 0 {		
		qui qui svyset commcode [pweight=weight_e1_e2], strata(county)	// Set survey data specific to each dataset
		qui svy: reg `y' `regressors2' if (`group2' == 1 & !missing(`y'))
		
		mat control_mean_g2[`m',2] = e(N) // impute the N used in the regression


		local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
		mat estimated_ps_g2[`m',1] = `p'

		mat stars_g2[`m', 1] = 0 // make the first column of stars 0
			if (`p' < .1) 		mat stars_g2[`m',2] = 1 // less than 10%?
				else mat stars_g2[`m',2] = 0 // if not, no stars
			if (`p' < .05) 	mat stars_g2[`m',2] = 2 // less than 5%?
			if (`p' < .01) 	mat stars_g2[`m',2] = 3 // less than 1%?
	
		mat reg_g2[`m',1] = _b[`treat'] // put in beta estimate
		mat reg_g2[`m',2] = _se[`treat'] // put in standard error estimate
		
		local beta = _b[`treat']

		* Get the control mean *************************************************
		qui svy: mean `y' if (`treat' == 0 & `group2' == 1) // get summary stats for control mean
		mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
		mat control_mean_g2[`m',1] = mean_mat[1, 1] // put in control mean 
		local temp_mean = mean_mat[1, 1]
		
		qui sum `y' if `group2' == 1
		if !(abs(r(mean)) > .01 | r(min) >= 0) { 
			mat ate_pct_g2[`m', 1] = 100 * `beta' / `temp_mean'
		}
		}
		************************************************************************
		local ++m 	
	}

********************************************************************************
* Adjust p values **************************************************************
********************************************************************************
if "`adjustvarsg1'" != "" {
// group 1
qui svyset [pweight=s_weight2], psu(commcode) strata(county)
adjust_p_values, adjustvars(`adjustvarsg1') adjustvarsmat(adjusted_ps_g1) controls(`controls1') treat(`treat') nsims(`nsims') strata(district_bl) group(`group1')
// group 2
qui qui svyset commcode [pweight=weight_e1_e2], strata(county)
adjust_p_values, adjustvars(`adjustvarsg2') adjustvarsmat(adjusted_ps_g2) controls(`controls2') treat(`treat') nsims(`nsims') strata(district_bl) group(`group2')

foreach y in `adjustvarsg1' {
	local t = rownumb(adjusted_ps_g1, "`y'")
	mat adjusted_ps_syms_g1[`t', 1] = 1 
}

foreach y in `adjustvarsg2' {
	local t = rownumb(adjusted_ps_g2, "`y'")
	mat adjusted_ps_syms_g2[`t', 1] = 1 
}

if "`extraadjustvarsg1'" != "" {
	// group 1
	qui svyset [pweight=s_weight2], psu(commcode) strata(county)
	adjust_p_values, adjustvars(`extraadjustvarsg1') adjustvarsmat(adjusted_ps_g1) controls(`controls1') treat(`treat') nsims(`nsims') strata(district_bl) group(`group1')
	// group 2
	qui qui svyset commcode [pweight=weight_e1_e2], strata(county)
	adjust_p_values, adjustvars(`extraadjustvarsg2') adjustvarsmat(adjusted_ps_g2) controls(`controls2') treat(`treat') nsims(`nsims') strata(district_bl) group(`group2')
	
	foreach y in `extraadjustvarsg1' {
		local t = rownumb(adjusted_ps_g1, "`y'")
		mat adjusted_ps_syms_g1[`t', 1] = 2 
	}
	
	foreach y in `extraadjustvarsg2' {
		local t = rownumb(adjusted_ps_g2, "`y'")
		mat adjusted_ps_syms_g2[`t', 1] = 2 
	}
}

********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
	
	* First Matrix: Comparing 2012 and 2017 ************************************
	qui frmttable, statmat(control_mean_g1) sdec(3, 0) varlabels 
	qui frmttable, statmat(reg_g1) sdec(3) substat(1) annotate(stars_g1) asymbol(*,**,***) varlabels merge  squarebrack
	qui frmttable, statmat(ate_pct_g1) sdec(1, 0) varlabels merge 
	qui frmttable, statmat(estimated_ps_g1) sdec(3) varlabels merge 
	qui frmttable, statmat(adjusted_ps_g1) sdec(3) varlabels annotate(adjusted_ps_syms_g1) asymbol(\textsuperscript{a},\textsuperscript{c}) merge squarebrack

	qui frmttable, statmat(control_mean_g2) sdec(3, 0) varlabels merge 	
	qui frmttable, statmat(reg_g2) sdec(3) substat(1) annotate(stars_g2) asymbol(*,**,***)  varlabels merge squarebrack 
	qui frmttable, statmat(ate_pct_g2) sdec(1, 0) varlabels merge 
	qui frmttable, statmat(estimated_ps_g2) sdec(3) varlabels merge 
	qui frmttable, statmat(adjusted_ps_g2) sdec(3) varlabels merge annotate(adjusted_ps_syms_g2) asymbol(\textsuperscript{b},\textsuperscript{d}) squarebrack

	frmttable using out/tables/`filename'_year, ///
	ctitle("", "\uline{\hfill 1-year endline \hfill}", "", "", "", "", "", "", "\uline{\hfill 3-year endline \hfill}", "", "", "", "", ""  \ ///
	"", "", "", "", "ITT /", , "", "", "", "",, "", "", "ITT /", "", "",  \ ///
	"", "Control", "", "", "control", "Est.", "WY Adj.", "Holms Adj" "Control", "", "", "control", "Est.", "WY Adj.", "Holms Adj"  \ ///
	"Dependent Variable", "mean", "N", "ITT", "mean (\%)", "p-val", "p-val", "p-val", "mean", "N", "ITT", "mean (\%)", "p-val", "p-val", "p-val" \ ///
	"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)", "(8)", "(9)", "(10)", "(11)", "(12)", "(13)", "(14)") ///
	tex ///
	fragment ///
	varlabels ///
	replace ///
	multicol(1,2,7; 1,9,7) ///
	nocenter 
	
}
else {
	* First Matrix: Comparing 2012 and 2017 ************************************
	qui frmttable, statmat(control_mean_g1) sdec(3, 0) varlabels 
	qui frmttable, statmat(reg_g1) sdec(3) substat(1) annotate(stars_g1) asymbol(*,**,***) varlabels merge squarebrack
	qui frmttable, statmat(ate_pct_g1) sdec(1, 0) varlabels merge 

	qui frmttable, statmat(control_mean_g2) sdec(3, 0) varlabels merge 	
	qui frmttable, statmat(reg_g2) sdec(3) substat(1) annotate(stars_g2) asymbol(*,**,***) varlabels merge  squarebrack
	qui frmttable, statmat(ate_pct_g2) sdec(1, 0) varlabels merge 

	frmttable using out/tables/`filename'_year, ///
	ctitle("", "\uline{\hfill 1-year endline \hfill}", "", "", "", "\uline{\hfill 3-year endline \hfill}", "", "", "" \ ///
	"", "", "", "", "ITT / ", "", "", "", "ITT /" \ ///	
	"", "Control", "", "", "control", "Control", "", "", "control" \ ///
	"Dependent Variable", "mean", "N", "ITT", "mean (\%)" "mean", "N", "ITT", "mean (\%)" \ ///
	"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)", "(8)") ///
	tex ///
	fragment ///
	varlabels ///
	replace ///
	multicol(1,2,4; 1,6,4) ///
	nocenter 
}
end 

cap program drop construct_treatments
program define construct_treatments
syntax
merge m:1 commcode using data/simulated_treatments
end 


***

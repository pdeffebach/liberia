cap program drop IV_maker_year
program define IV_maker_year
	clear mata 
	set matsize 10000

	set more off 
	syntax varlist, EXOGENOUS(varlist) ENDOGENOUS(varlist) GROUP1(varlist) GROUP2(varlist) CONTROLS1(varlist) CONTROLS2(varlist) FILENAME(name)

	local dep_vars `varlist' // creating a local for dep. variables
	local M = `:word count `dep_vars''
	
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

	mat reg_g2 			= J(`M',2,.)
	mat stars_g2		= J(`M',2,0)
	mat ate_pct_g2		= J(`M',1,.)

	// Initializing row names.
	mat rownames control_mean_g1 = `dep_vars'
	mat rownames control_mean_g2 = `dep_vars'


	mat rownames reg_g1 = `dep_vars'

	mat rownames reg_g2 = `dep_vars'

	// Make a variable that represents the control with many exogenous regressors
	/*	This is for making the control mean. We want some variable that 
		is 0 if all of the binary exogenous variables are 0. So we initialize 
		it at 0, and replace if 1 if any of the exogenous dummies are equal to 1. 
	*/
	cap drop zz_control_variable
	gen zz_control_variable = 0 if (`group1' == 1 | `group2' == 1)
	foreach var in `exogenous' {
		replace zz_control_variable = 1 if `var' == 1
	}

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
	qui sum `y' if `group1' == 1 
	if r(N) != 0 {
		************************************************************************
		* Year 1 regression  ***************************************************
		************************************************************************

		* Check to make sure we have observations of that variable 
		qui sum `y' if `group1' == 1
		if r(N) != 0 {

			qui svyset [pweight=s_weight2], psu(commcode) strata(county)	// Set survey data specific to each dataset

			qui svy: ivregress 2sls `y' `covariates1' trainee (`endogenous' = `exogenous') if (`group1'== 1 & !missing(`y') & assigned_ever == 1)
			mat control_mean_g1[`m',2] = e(N) // put in the N of the regression

			local p = (2 * ttail(e(df_r), abs(_b[`endogenous']/_se[`endogenous'])))
	
			mat stars_g1[`m', 1] = 0 // make the first column of stars 0
				if (`p' < .1) 		mat stars_g1[`m',2] = 1 // less than 10%?
					else mat stars_g1[`m',2] = 0 // if not, no stars
				if (`p' < .05) 	mat stars_g1[`m',2] = 2 // less than 5%?
				if (`p' < .01) 	mat stars_g1[`m',2] = 3 // less than 1%?
	
			mat reg_g1[`m',1] = _b[`endogenous'] // put in beta estimate
			mat reg_g1[`m',2] = _se[`endogenous'] // put in standard error estimate

		local beta = _b[`endogenous']

		* Get the control mean *************************************************
		qui svy: mean `y' if (zz_control_variable == 0 & `group1' == 1) // get summary stats for control mean
		mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
		mat control_mean_g1[`m',1] = mean_mat[1, 1] // put in control mean 
		local temp_mean = mean_mat[1, 1]
		
		mat ate_pct_g1[`m', 1] = 100 * `beta' / `temp_mean'

		}
		} // if all missing observations in group 1 

		************************************************************************
		* Year 2 regression ****************************************************
		************************************************************************
		qui sum `y' if `group2' == 1 
		if r(N) != 0 {
		qui svyset commcode [pweight=weight_e1_e2], strata(county)	// Set survey data specific to each dataset

		qui svy: ivregress 2sls `y' `covariates2' (`endogenous' = `exogenous') if (`group2'== 1 & !missing(`y') & assigned_ever == 1)
		
		mat control_mean_g2[`m',2] = e(N) // impute the N used in the regression
		local p = (2 * ttail(e(df_r), abs(_b[`endogenous']/_se[`endogenous'])))
		mat stars_g2[`m', 1] = 0 // make the first column of stars 0
			if (`p' < .1) 		mat stars_g2[`m',2] = 1 // less than 10%?
				else mat stars_g2[`m',2] = 0 // if not, no stars
			if (`p' < .05) 	mat stars_g2[`m',2] = 2 // less than 5%?
			if (`p' < .01) 	mat stars_g2[`m',2] = 3 // less than 1%?
	
		mat reg_g2[`m',1] = _b[`endogenous'] // put in beta estimate
		mat reg_g2[`m',2] = _se[`endogenous'] // put in standard error estimate
		
		local beta = _b[`endogenous']

		* Get the control mean *************************************************
		qui svy: mean `y' if (zz_control_variable == 0 & `group2' == 1) // get summary stats for control mean
		mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
		mat control_mean_g2[`m',1] = mean_mat[1, 1] // put in control mean 
		local temp_mean = mean_mat[1, 1]
		
		mat ate_pct_g2[`m', 1] = 100 * `beta' / `temp_mean'
		} // if all missing observations in group 2  

		************************************************************************
		local ++m 	
	}


********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
	
	* First Matrix: Comparing 2012 and 2017 ************************************
	qui frmttable, statmat(control_mean_g1) sdec(3, 0) varlabels 
	qui frmttable, statmat(reg_g1) sdec(3) annotate(stars_g1) asymbol(*,**,***) varlabels merge 
	qui frmttable, statmat(ate_pct_g1) sdec(1, 0) varlabels merge 

	qui frmttable, statmat(control_mean_g2) sdec(3, 0) varlabels merge 	
	qui frmttable, statmat(reg_g2) sdec(3) annotate(stars_g2) asymbol(*,**,***) varlabels merge  
	qui frmttable, statmat(ate_pct_g2) sdec(1, 0) varlabels merge 


	frmttable using out/tables/`filename'_iv, ///
	ctitle("", "\uline{\hfill Endline 1 \hfill}", "", "", "", "", "\uline{\hfill Endline 2 \hfill}", "", "", "", "" \ ///
	"Dependent Variable", "Control mean", "N", "IV est.","SE", "ITT / control mean" "Control mean", "N", "IV est." "SE", "ITT / control mean" \ ///
	"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)", "(8)", "(9)", "(10)") ///
	tex ///
	fragment ///
	varlabels ///
	replace ///
	multicol(1,2,5; 1,7,5) ///
	nocenter 

	cap drop zz_control_variable

end 

///

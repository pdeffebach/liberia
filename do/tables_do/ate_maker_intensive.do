

cap program drop ate_maker_intensive
program define ate_maker_intensive
	clear mata 
	set matsize 10000
	syntax varlist, TREATMAIN(varlist) TREATINTENSE(varlist) CONTROLS1(varlist) CONTROLS2(varlist) FILENAME(name) GROUP1(varlist) GROUP2(varlist)

	set more off

	local dep_vars `varlist' // creating a local for dep. variables
	local M = `:word count `dep_vars''

	/* making longer local for regression because reg takes only one local */
	local regressors1 		`treatmain' `treatintense' `controls1'
	local regressors2 		`treatmain' `treatintense' `controls2'
	

	// Initializing all the matices 
	mat reg_e1 = J(`M', 6, .)
	mat reg_e2 = J(`M', 6, .)

	mat stars_e1 = J(`M', 6, 0)
	mat stars_e2 = J(`M', 6, 0)

	// Initializing row names
	mat rownames reg_e1 = `dep_vars'
	mat rownames reg_e2 = `dep_vars'
	
	/* 	This upcoming for loop does the following: 
		1)	For each dependent variable it runs a regression of y on treat1, 
			treat2, and 
			the covariates. 
		2) 	Calculates the p-values and significance levels of the coefficients
		3) 	Inputs the estimates for beta (on treat1 only), into the matrix. It 
			inputs beta hat in one column and SE hat in another. 

		It does this for both year 1 and year 2. 
		
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
			
			mat reg_e1[`m',1] = _b[`treatmain'] // put in beta estimate
			mat reg_e1[`m',2] = _se[`treatmain'] // put in standard error estimate

			local p_main = (2 * ttail(e(df_r), abs(_b[`treatmain']/_se[`treatmain'])))
			if (`p_main' < .1) 		mat stars_e1[`m',2] = 1 // less than 10%?
			if (`p_main' < .05) 	mat stars_e1[`m',2] = 2 // less than 5%?
			if (`p_main' < .01) 	mat stars_e1[`m',2] = 3 // less than 1%?
		
			mat reg_e1[`m', 3] = _b[`treatintense']
			mat reg_e1[`m', 4] = _se[`treatintense']
			
			local p_intense = (2 * ttail(e(df_r), abs(_b[`treatintense']/_se[`treatintense'])))
			if (`p_intense' < .1) 		mat stars_e1[`m',4] = 1 // less than 10%?
			if (`p_intense' < .05) 		mat stars_e1[`m',4] = 2 // less than 5%?
			if (`p_intense' < .01) 		mat stars_e1[`m',4] = 3 // less than 1%?

			qui lincom `treatmain' + `treatintense'
			mat reg_e1[`m', 5] = r(estimate)
			mat reg_e1[`m', 6] = r(se)

			local p_sum = (2 * ttail(e(df_r), abs(r(estimate))/r(se)))
			if (`p_sum' < .1) 		mat stars_e1[`m',6] = 1 // less than 10%?
			if (`p_sum' < .05) 		mat stars_e1[`m',6] = 2 // less than 5%?
			if (`p_sum' < .01) 		mat stars_e1[`m',6] = 3 // less than 1%?

	}

		************************************************************************
		* Year 2 regression  ***************************************************
		************************************************************************

		* Check to make sure we have observations of that variable 
		qui sum `y' if `group2' == 1
		if r(N) != 0 {

			qui svyset [pweight=s_weight2], psu(commcode) strata(county)	// Set survey data specific to each dataset
			qui svy: reg `y' `regressors2' if (`group2'== 1 & !missing(`y'))
			
			mat reg_e2[`m',1] = _b[`treatmain'] // put in beta estimate
			mat reg_e2[`m',2] = _se[`treatmain'] // put in standard error estimate
			
			local p_main = (2 * ttail(e(df_r), abs(_b[`treatmain']/_se[`treatmain'])))
			if (`p_main' < .1) 		mat stars_e2[`m',2] = 1 // less than 10%?
			if (`p_main' < .05) 	mat stars_e2[`m',2] = 2 // less than 5%?
			if (`p_main' < .01) 	mat stars_e2[`m',2] = 3 // less than 1%?
		
			mat reg_e2[`m', 3] = _b[`treatintense']
			mat reg_e2[`m', 4] = _se[`treatintense']
			
			local p_intense = (2 * ttail(e(df_r), abs(_b[`treatintense']/_se[`treatintense'])))
			if (`p_intense' < .1) 		mat stars_e2[`m',4] = 1 // less than 10%?
			if (`p_intense' < .05) 		mat stars_e2[`m',4] = 2 // less than 5%?
			if (`p_intense' < .01) 		mat stars_e2[`m',4] = 3 // less than 1%?

			qui lincom `treatmain' + `treatintense'
			mat reg_e2[`m', 5] = r(estimate)
			mat reg_e2[`m', 6] = r(se)

			local p_sum = (2 * ttail(e(df_r), abs(r(estimate))/r(se)))
			if (`p_sum' < .1) 		mat stars_e2[`m',6] = 1 // less than 10%?
			if (`p_sum' < .05) 		mat stars_e2[`m',6] = 2 // less than 5%?
			if (`p_sum' < .01) 		mat stars_e2[`m',6] = 3 // less than 1%?
	}

	local m = `m' + 1
}

********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
	
	qui frmttable, statmat(reg_e1) varlabels substat(1) annotate(stars_e1) asymbol(*,**,***) sdec(3) squarebrack
	qui frmttable, statmat(reg_e2) varlabels substat(1) merge annotate(stars_e2) asymbol(*,**,***) sdec(3) squarebrack

	frmttable using out/tables/`filename', ///
	ctitle("", "\uline{\hfill Endline 1 \hfill}", "", "", "\uline{\hfill Endline 2 \hfill}", "", "" \ ///
	"", "Normal", "Intensive", "", "Normal", "Intensive", "", \ ///
	"", "treatment", "treatment", "Sum", "treatment", "treatment", "Sum") ///
	multicol(1,2,3; 1,5,3) ///
	tex ///
	fragment ///
	varlabels ///
	nocenter ///
	replace 
end 

///
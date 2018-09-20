

cap program drop ate_maker_res_leader
program define ate_maker_res_leader
	clear mata 
	set matsize 10000
	syntax varlist, TREAT(varlist) COVARIATESRES(varlist) COVARIATESLEADER(varlist) FILENAME(name) RESGROUP(varlist) LEADERGROUP(varlist)

	local dep_vars `varlist' // creating a local for dep. variables
	local M = `:word count `dep_vars''

	/* making longer local for regression because reg takes only one local */
	local regressors_res `treat' `covariatesres'
	local regressors_leader `treat' `covariatesleader'
	

	// Initializing all the matices 
	/* 	we have to have separate matrices for each number format we want, I 
		think. We can't store control means and counts in the same matrix 
		because obviously we don't want counts to have decimal places, but 
		we do want decimal places for means. */
	mat control_mean_res 	= J(`M',1,.)
	mat reg_count_res		= J(`M',1,.)
	mat reg_res 			= J(`M',2,.)
	mat p_res 				= J(`M',1,.)
	mat stars_res			= J(`M',2,.)

	mat control_mean_leader 	= J(`M',1,.)
	mat reg_count_leader		= J(`M',1,.)
	mat reg_leader 				= J(`M',2,.)
	mat p_leader 				= J(`M',1,.)
	mat stars_leader			= J(`M',2,.)

	mat rownames control_mean_res 		= `dep_vars'
	mat rownames reg_count_res			= `dep_vars'
	mat rownames reg_res 				= `dep_vars'
	mat rownames p_res 					= `dep_vars'

	mat rownames control_mean_leader 	= `dep_vars'
	mat rownames reg_count_leader		= `dep_vars'
	mat rownames reg_leader 			= `dep_vars'
	mat rownames p_leader				= `dep_vars'


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
		* Residents ***************************************************
		************************************************************************
		
		* Run the regression ***************************************************
		qui svy: reg `y' `regressors_res' if (`resgroup' == 1)
		
		* Input number of obs. in regression ***********************************
		mat reg_count_res[`m',1] = e(N) // put in number of observations used in regression

		* Calculate the p-value of treatment ***********************************
		local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
		mat p_res[`m', 1] = `p'

		* Use p-value to make stars ********************************************
		mat stars_res[`m', 1] = 0 // make the first column of stars 0
			if (`p' < .1) 		mat stars_res[`m',2] = 1 // less than 10%?
				else mat stars_res[`m',2] = 0 // if not, no stars
			if (`p' < .05) 	mat stars_res[`m',2] = 2 // less than 5%?
			if (`p' < .01) 	mat stars_res[`m',2] = 3 // less than 1%?

		* Input the betas and the standard errors ******************************
		mat reg_res[`m',1] = _b[`treat'] // put in beta estimate
		mat reg_res[`m',2] = _se[`treat'] // put in standard error estimate

		* Save the beta for use in calculating beta / control mean 
		/* 	The command svy: mean overwrites the beta matrix that was created 
			in the regression. 
		*/
		
		* Get the control mean *************************************************
		qui svy: mean `y' if (`treat' == 0 & `resgroup' == 1) // get summary stats for control mean
		mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
		mat control_mean_res[`m',1] = mean_mat[1,1] // put in control mean 

		/* 	TODO: fix the above confusion with mean_mat. It isn't necessary when
			we aren't computing the ITT / control mean
		*/




		************************************************************************
		* Leaders **************************************************************
		************************************************************************
		
		* Run the regression ***************************************************
		qui svy: reg `y' `regressors_leader' if (`leadergroup' == 1)
		
		* Input number of obs. in regression ***********************************
		mat reg_count_leader[`m',1] = e(N) // put in number of observations used in regression

		* Calculate the p-value of treatment ***********************************
		local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
		mat p_leader[`m', 1] = `p'
		* Use p-value to make stars ********************************************
		mat stars_leader[`m', 1] = 0 // make the first column of stars 0
			if (`p' < .1) 		mat stars_leader[`m',2] = 1 // less than 10%?
				else mat stars_leader[`m',2] = 0 // if not, no stars
			if (`p' < .05) 	mat stars_leader[`m',2] = 2 // less than 5%?
			if (`p' < .01) 	mat stars_leader[`m',2] = 3 // less than 1%?

		* Input the betas and the standard errors ******************************
		mat reg_leader[`m',1] = _b[`treat'] // put in beta estimate
		mat reg_leader[`m',2] = _se[`treat'] // put in standard error estimate

		* Save the beta for use in calculating beta / control mean 
		/* 	The command svy: mean overwrites the beta matrix that was created 
			in the regression. 
		*/

		* Get the control mean *************************************************
		qui svy: mean `y' if (`treat' == 0 & `leadergroup' == 1) // get summary stats for control mean
		mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
		mat control_mean_leader[`m',1] = mean_mat[1,1] // put in control mean 




		* Increment the counter ************************************************
		loc ++m
	}



********************************************************************************
* Perform the Holm method for multiple hypothesis correction *******************
********************************************************************************

* Residents ********************************************************************

	* Temporary matrix of names to keep track of their order *******************
	mat nametemp = J(`M', 1, .)
	forvalues m = 1/`M' {
		mat nametemp[`m', 1] = `m'
	}

	* Short bubble sort to get the observed p-values in order ******************
	local swapped = 1
	local t = `M' - 1
	while `swapped' == 1 {	
		local swapped = 0
		
		forvalues m = 1/`t' {

			local first = p_res[`m', 1]
			local second = p_res[`m' + 1, 1]

			local namefirst = nametemp[`m', 1] 		// keep track of names order
			local namesecond = nametemp[`m' + 1, 1] // keep track of names order			

			if `second' < `first' {
				mat p_res[`m', 1 ] = `second'
				mat p_res[`m' + 1, 1] = `first'

				mat nametemp[`m', 1 ] = `namesecond'
				mat nametemp[`m' + 1, 1] = `namefirst'

				local swapped = 1
			}
		}
	}

	* Make a local macro of row names for the ordered p matrix *****************
	local names
	forvalues m = 1/`M' {
		local t = nametemp[`m', 1] // the new ordering we made above
		local names `names' `:word `t' of `dep_vars'' // construct the macro
	}

	mat rownames p_res = `names' // make new rownames for the sorted p values


	* Perform the adjustment ***************************************************
/*
	* 	For P_i multiply by (M - 1 + i)
	* 	If a p-value, once multiplied, is lower than the one before it, make it 
		the one before it.
	* Taken from here: http://www.pmean.com/05/MultipleComparisons.asp

	TODO: Make this more consistent with better literature. 
*/
	local t = p_res[1,1] * `M'
		mat p_res[1, 1] = `t'
	
		forvalues m = 2/`M' { 
			local t = p_res[`m', 1] * (`M' - `m' + 1)

			if `t' < 1 {
			mat p_res[`m', 1] = `t'
			}
			else {
				mat p_res[`m', 1] = 1
			}

			local m_before = p_res[`m' - 1,1]
			local m_current = p_res[`m', 1]
			if `m_current' < `m_before' {
				mat	p_res[`m', 1] = `m_before'
			}
		}

* Leaders **********************************************************************

	* Temporary matrix of names to keep track of their order *******************
	mat nametemp = J(`M', 1, .)
	forvalues m = 1/`M' {
		mat nametemp[`m', 1] = `m'
	}

	* Short bubble sort to get the observed p-values in order ******************
	local swapped = 1
	local t = `M' - 1
	while `swapped' == 1 {	
		local swapped = 0
		
		forvalues m = 1/`t' {

			local first = p_leader[`m', 1]
			local second = p_leader[`m' + 1, 1]

			local namefirst = nametemp[`m', 1] 		// keep track of names order
			local namesecond = nametemp[`m' + 1, 1] // keep track of names order			

			if `second' < `first' {
				mat p_leader[`m', 1 ] = `second'
				mat p_leader[`m' + 1, 1] = `first'

				mat nametemp[`m', 1 ] = `namesecond'
				mat nametemp[`m' + 1, 1] = `namefirst'

				local swapped = 1
			}
		}
	}

	* Make a local macro of row names for the ordered p matrix *****************
	local names
	forvalues m = 1/`M' {
		local t = nametemp[`m', 1] // the new ordering we made above
		local names `names' `:word `t' of `dep_vars'' // construct the macro
	}

	mat rownames p_leader = `names' // make new rownames for the sorted p values


	* Perform the adjustment ***************************************************
/*
	* 	For P_i multiply by (M - 1 + i)
	* 	If a p-value, once multiplied, is lower than the one before it, make it 
		the one before it.
	* Taken from here: http://www.pmean.com/05/MultipleComparisons.asp

	TODO: Make this more consistent with better literature. 
*/
	local t = p_leader[1,1] * `M'
		mat p_leader[1, 1] = `t'
	
		forvalues m = 2/`M' { 
			local t = p_leader[`m', 1] * (`M' - `m' + 1)

			if `t' < 1 {
			mat p_leader[`m', 1] = `t'
			}
			else {
				mat p_leader[`m', 1] = 1
			}

			local m_before = p_leader[`m' - 1,1]
			local m_current = p_leader[`m', 1]
			if `m_current' < `m_before' {
				mat	p_leader[`m', 1] = `m_before'
			}
		}


********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
	
	cap frmttable, statmat(reg_count_res) sdec(0) varlabels 
	cap frmttable, statmat(control_mean_res) sdec(3) varlabels merge
	cap frmttable, statmat(reg_res) sdec(3) annotate(stars_res) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
	cap frmttable, statmat(p_res) sdec(3) varlabels merge 

	cap frmttable, statmat(reg_count_leader) sdec(0) varlabels merge
	cap frmttable, statmat(control_mean_leader) sdec(3) varlabels merge
	cap frmttable, statmat(reg_leader) sdec(3) annotate(stars_leader) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
		frmttable, statmat(p_leader) sdec(3) varlabels merge 	





	frmttable using out/tables/`filename', ///
	ctitle("", "\uline{\hfill Residents \hfill}", "", "", "", "\uline{\hfill Leaders \hfill}", "", "", "" \ ///
	"Dependent Variable", "N", "Control Mean", "ITT", "P-value", "N", "Control Mean", "ITT", "P-value" \ ///
	"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)") ///
	multicol(1,2,4;1,6,4) ///
	tex ///
	fragment ///
	varlabels ///
	nocenter ///
	replace


	frmttable using out/rtf_tables/`filename', ///
	ctitle("", "\uline{\hfill Residents \hfill}", "", "", "", "\uline{\hfill Leaders \hfill}", "", "", "", \ ///
	"Dependent Variable", "N", "Control Mean", "ITT", " Adj. P-value", "N", "Control Mean", "ITT", "Adj. P-value" \ ///
	"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)") ///
	varlabels ///
	replace

*/

*/
end 

///
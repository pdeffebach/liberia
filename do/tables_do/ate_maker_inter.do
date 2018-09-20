

cap program drop ate_maker_inter
program define ate_maker_inter
	clear mata 
	set matsize 10000
	syntax varlist, TREAT(varlist) COVARIATES(varlist) INTERACTIONS(varlist) FILENAME(name) SUBSET(varlist) ///
	INTER1(string) INTER2(string) INTER3(string)

	local dep_vars `varlist' // creating a local for dep. variables
	local M = `:word count `dep_vars''

	/* making longer local for regression because reg takes only one local */
	local regressors `treat' `covariates'
	
	local K `:word count `interactions''

	// Initializing all the matices 
	/* 	we have to have separate matrices for each number format we want, I 
		think. We can't store control means and counts in the same matrix 
		because obviously we don't want counts to have decimal places, but 
		we do want decimal places for means. */

	mat reg_inter 		= J(`M', 6 * `K',.)
	mat stars			= J(`M', 6 * `K',0)


	mat rownames reg_inter = `dep_vars'
	mat colnames reg_inter = "Treatment" "" "Interaction" "" "Sum" ""


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

	foreach inter_var in `interactions' {
		cap drop a_`inter_var'
		gen a_`inter_var' = `inter_var' * `treat' 
		local lab: var lab `inter_var'
		label var a_`inter_var' "Assigned x `lab'"
	}

	loc m = 1
	foreach y in `dep_vars'{ 
		
		loc k = 1
		foreach inter_var in `interactions' {

		/* 	We don't have to worry about having the variable we are interacting
		with in the list of covariates, beacause stata is smart enough to omit
		the second appearance of that variable from the regression. As long as
		the interactions come first we are good. 
		*/	
		local regressors `treat' `inter_var' a_`inter_var' `covariates'

		* Run the regression ***************************************************
		qui svy: reg `y' `regressors' if (`subset' == 1)

		* Input the betas and the standard errors for treatment ****************
		mat reg_inter[`m',6*`k' - 5] = _b[`treat'] // put in beta estimate
		mat reg_inter[`m',6*`k' - 4] = _se[`treat'] // put in standard error estimate

		* Input the betas and standard errors for the interaction term *********
		mat reg_inter[`m', 6*`k' -3] = _b[a_`inter_var']
		mat reg_inter[`m', 6*`k' -2] = _se[a_`inter_var']

		* Input the betas and standard errors for the net effect ***************
		qui lincom assigned_ever + a_`inter_var'

		mat reg_inter[`m', 6*`k' - 1] = r(estimate)
		mat reg_inter[`m', 6 *`k'   ] = r(se)

		* Calculate the p-value of treatment ***********************************
		local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))

		if (`p' < .1) 	mat stars[`m',6*`k' - 4] = 1 // less than 10%?
		if (`p' < .05) 	mat stars[`m',6*`k' - 4] = 2 // less than 5%?
		if (`p' < .01) 	mat stars[`m',6*`k' - 4] = 3 // less than 1%?

		* calculate p-value of the interaction *********************************
		local p = (2 * ttail(e(df_r), abs(_b[a_`inter_var']/_se[a_`inter_var'])))
		if (`p' < .1) 	mat stars[`m',6*`k' - 2] = 1 // less than 10%?
		if (`p' < .05) 	mat stars[`m',6*`k' - 2] = 2 // less than 5%?
		if (`p' < .01) 	mat stars[`m',6*`k' - 2] = 3 // less than 1%?

		* calculate p-value of linear combination ******************************
		local p = (2 * ttail(e(df_r), abs(r(estimate))/r(se)))

		* Use p-value to make stars ********************************************
		if (`p' < .1) 	mat stars[`m',6*`k'] = 1 // less than 10%?
		if (`p' < .05) 	mat stars[`m',6*`k'] = 2 // less than 5%?
		if (`p' < .01) 	mat stars[`m',6*`k'] = 3 // less than 1%?

		local ++k
		}
	local ++m	
	}

********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
	cap frmttable, statmat(reg_inter) sdec(3) substat(1) annotate(stars) asymbol(*,**,***) varlabels squarebrack 
	
	//local title_row1 = "Political Connectedness"

	//local title_row2  "Treatment", "Interaction", "Sum",
	frmttable using out/tables/`filename', ///
	ctitle("", "\uline{\hfill `inter1' \hfill}", "","", "\uline{\hfill `inter2' \hfill}", "","", "\uline{\hfill `inter3' \hfill}","","" \  ///
	"", "", "Coeff. on", "", "", "Coeff. on", "", "", "Coeff. on", "" \ /// 
	"", "", "treatment-", "Net", "", "treatment-", "Net", "", "treatment-", "Net" \ /// 
	"", "Coeff. on", "covariate", "effect", "Coeff. on", "covariate", "effect", "Coeff. on", "covariate", "effect"  \ /// 
	"Dependent variable", "treatment", "interaction", "(sum)", "treatment", "interaction", "(sum)", "treatment", "interaction", "(sum)") ///
	multicol(1, 2, 3; 1, 5,3; 1,8,3) ///
	tex ///
	fragment ///
	varlabels ///
	nocenter ///
	replace 
end 

///
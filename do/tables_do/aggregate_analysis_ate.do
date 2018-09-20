cap program drop aggregate_analysis_ate
program define aggregate_analysis_ate
	clear mata 
	set matsize 10000

	set more off 
	syntax varlist, TREAT(varlist) GROUP1(varlist) GROUP2(varlist) CONTROLS1(varlist) CONTROLS2(varlist) FILENAME(name)
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
	mat ate_g1 			= J(`M', 1, .)
	mat ate_g2 			= J(`M', 1, .)

	mat pop_g1 			= J(`M', 1, .)
	mat pop_g2 			= J(`M', 1, .)

	mat net_g1 			= J(`M', 1, .)
	mat net_g2 			= J(`M', 1, .)

	mat net_all 		= J(`M', 1, .)


	// Initializing row names.
	mat rownames ate_g1 	= `dep_vars'
	mat rownames ate_g2 	= `dep_vars'

	mat rownames net_g1 	= `dep_vars'
	mat rownames net_g2 	= `dep_vars'
	mat rownames net_all	= `dep_vars'




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
		if r(N) == 0 {
		display as error "Variable is all missing in Year 1"
		exit 
		}	
		
		qui svy: reg `y' `regressors1' if (`group1'== 1 & !missing(`y'))
		mat ate_g1[`m', 1] = _b[`treat']



		************************************************************************
		* Year 2 regression ****************************************************
		************************************************************************
		* Check to make sure we have observations of that variable 
		qui sum `y' if `group2' == 1
		if r(N) == 0 {
		display as error "Variable is all missing in Year 2"
		exit 
		}	
		
		qui svy: reg `y' `regressors2' if (`group2'== 1 & !missing(`y'))
		mat ate_g2[`m', 1] = _b[`treat']
		local ++m 	
	}

********************************************************************************
* Fill in the rest of the matrix ***********************************************
********************************************************************************

* Get total population analyzed for each group *********************************
preserve 
keep if `treat' == 1
collapse (first) ctownpop_el (first) ctownpop_el2 (first) assigned_ever (first) weight_e1_e2, by(commcode)
total ctownpop_el [pw = weight_e1_e2] if `treat' == 1
mat t = e(b)
global pop_g1 = t[1,1]
total ctownpop_el2 [pw = weight_e1_e2] if `treat' == 1
mat t = e(b)
global pop_g2 = t[1,1]
restore 


* Get number of households in the sample, assuming 8 people per household ******
scalar hh_g1 = $pop_g1 / 8
scalar hh_g2 = $pop_g2 / 8

* Input our total decreases for year 1 and year 2 ******************************
mat net_g1 = ate_g1 * hh_g1
mat net_g2 = ate_g2 * hh_g2


* Input the total decline, interpolating the gap between surveys ***************
mat net_all = 1.5 * net_g1 + 1.5 * net_g2




********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************

qui frmttable, statmat(ate_g1) sdec(3) varlabels
qui frmttable, statmat(ate_g2) sdec(3) varlabels merge
qui frmttable, statmat(net_g1) sdec(0) varlabels merge
qui frmttable, statmat(net_g2) sdec(0) varlabels merge
qui frmttable, statmat(net_all) sdec(0) varlabels merge 

frmttable using out/tables/`filename', ctitle("", "\uline{\hfill ATE \hfill}", "", "\uline{\hfill Net effect \hfill}", "", "Net Effect imputed" \ ///
 "Dependent Variable", "Endline 1", "Endline 2", "Endline 1", "Endline 2", "for missing year") ///
multicol(1,2,2;1,4,2) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace

end 

///

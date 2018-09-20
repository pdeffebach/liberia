** The master do file **

clear 
clear matrix
clear mata
set more off
cap log close

********************************************************************************
* Set the directory for the frmttable ado file *********************************
********************************************************************************
qui adopath ++ ./ado


********************************************************************************
* Do the importing and merging *************************************************
********************************************************************************
/* 	Don't run import_from_external. It's a mess and contains global paths. We can 
	forget about it for now. 
*/

	* 	imports the data
	* 	censors outliers 
	* 	makes some global variables for covariates 
	* 	imputes missing values to median for select variables
	* 	adds correct suffixes to variables
	* 	constructs variables relating to 
		* 	voilent disputes
		* 	security 
		* 	use and improvement of land
		* 	ownership of land
	do do/import_clean_construct


********************************************************************************
* Do the Reshaping *************************************************************
********************************************************************************
/*
	* 	Reshapes with respect to farm and house 
		* 	"other" plot types are not in any of the reshaping codes in the 
			original analysis file
	* 	Labels all the new variables from the reshape
*/
	do do/reshaping


********************************************************************************
* Perform all the analyses *****************************************************
********************************************************************************
/* 	* 	Uses the "ready_analysis" .dta file created in the cleaning code 
*/
	do do/analysis


/* Uses the "ready_plots" .dta file */
	do do/analysis_plots


********************************************************************************

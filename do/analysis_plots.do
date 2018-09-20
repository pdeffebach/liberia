********************************************************************************
* Set the directory for the frmttable ado file *********************************
********************************************************************************
qui adopath ++ ./ado



********************************************************************************
* Set globals for analysis *****************************************************
********************************************************************************
do do/set_controls

/*
TO DO: Put all the control global macro stuff into its own do file and use 
"include" to set them each time so we don't have to change two do files when 
we change controlling variables. 
*/

********************************************************************************
* Perform the plot level analyses *********************************************
********************************************************************************

* Import the long (plot level) dataset *****************************************
use data/ready_analysis_plots, clear

* Change survey settings to cluster by respid **********************************
svyset respid [pweight=weight_e1_e2], strata(county)	// Set survey data specific to each dataset 

* Set globals ******************************************************************
global outcomes_invest ///
	z_improvement  ///
		monetary_improvement  ///
		non_monetary_improvement  ///
	improvement 

global outcomes_secured ///
	security_rights ///
		level_of_security ///
		inherit ///
		sell ///
		pawn ///
		survey 

* Make the tables **************************************************************
ate_maker $outcomes_invest, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(invest)
ate_maker $outcomes_secured, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(secure)
summary_table $outcomes_invest $outcomes_secured, filename(invest_secure_summary) subset($L1)

********************************************************************************
* Perform the heterogeneity analysis *******************************************
********************************************************************************

* Initialize the do-file for heterogeneity tables ******************************
do do/tables_do/ate_maker_inter

* Set globals of interaction variables and ouctome variables *******************
global variables_to_interact polcnnct_b_ec2 market_tenure ownership_self
global outcomes_hetero ///
	security_rights ///
	z_improvement ///
	size

* Make the table ***************************************************************
ate_maker_inter $outcomes_hetero, treat(assigned_ever) covariates($C_ec2) interactions($variables_to_interact) subset($L1) filename(hetero_political) ///
inter1("Political Connectedness") inter2("Market Tenure") inter3("Owns own land")
*/



********************************************************************************
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
		nonmoney  ///
	improvement 

global outcomes_secured ///
	security_rights ///
		level_of_security_dum ///
		inherit_dum ///
		sell_dum ///
		pawn_dum ///
		survey_dum 

* Make the tables **************************************************************
//ate_maker $outcomes_invest, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(invest)
//ate_maker $outcomes_secured, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(secure)
// summary_table $outcomes_invest $outcomes_secured, filename(invest_secure_summary) subset($L1)

********************************************************************************
* Perform the heterogeneity analysis *******************************************
********************************************************************************

* Initialize the do-file for heterogeneity tables ******************************
do do/tables_do/ate_maker_inter
do do/tables_do/ate_maker_inter_long

* Set globals of interaction variables and ouctome variables *******************
global variables_to_interact polcnnct_b_ec2 market_tenure ownership_self
global outcomes_hetero ///
	security_rights ///
	z_improvement ///
	size

* Make the table ***************************************************************
local headers = `" "", "Security index", "Property investment", "Size of land" \ "Independent variable", "through rights", "index, z-score", "(house and farm)" \ "", "(1)", "(2)", "(3)" "'
local multicols = `" "'
ate_maker_inter_long $outcomes_hetero, treat(assigned_ever) covariates($C_ec2) interactions($variables_to_interact) subset($L1) filename(hetero_political) ///
inter1("Is politically connected") inter2("Has market Tenure") inter3("Owns own land") headers(`headers') multicols(`multicols')

qui do do/tables_do/summary_stats_demo
* Summary statistics ***********************************************************
global regression_variables_to_interact female_ec2 age20_40_ec2 cwealthindex_below_med_bc minority_ec2 canypeace_bc cgpeace_bc
global summary_variables_to_interact female_ec2 age20_40_ec2 minority_ec2 polcnnct_b_ec2 market_tenure ownership_self

summary_stats_demo $outcomes_invest $outcomes_secured, interactions($summary_variables_to_interact) ///
intertitle1("Gender") inter1ZERO("Men") inter1ONE("Women") ///
intertitle2("Age") inter2ZERO("above 40") inter2ONE("20-40") ///
intertitle3("Any ethnic minority") inter3ZERO("No") inter3ONE("Yes") ///
intertitle4("Politically connected") inter4ZERO("No") inter4ONE("Yes") ///
intertitle5("Has market tenure") inter5ZERO("No") inter5ONE("Yes") ///
intertitle6("Owns plot") inter6ZERO("No") inter6ONE("Yes") ///
subset(ENDLINE2_RESIDENT) ///
filename(summary_stats_demo_plots)

* Security and Investment ******************************************************
local headers = `" "", "Security index", "Property investment", "Size of land" \ "Independent variable", "through rights", "index, z-score", "(house and farm)" \ "", "(1)", "(2)", "(3)" "'
local multicols = `" "'
ate_maker_inter_long $outcomes_hetero, treat(assigned_ever) covariates($C_ec2) interactions($regression_variables_to_interact) subset($L1) filename(hetero_demo_security) ///
inter1("Female") ///
inter2("20-40 years old") ///
inter3("Below median wealth") ///
inter4("Any ethnic minority") ///
inter5("\% town peace education at baseline") ///
inter6("\% town in peace group at baseline") ///
headers(`headers') multicols(`multicols')





********************************************************************************
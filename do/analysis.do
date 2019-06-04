********************************************************************************
* Set the directory for the frmttable ado file *********************************
********************************************************************************
qui adopath ++ ./ado

********************************************************************************
* Import the analysis dataset **************************************************
********************************************************************************
use data/ready_analysis, clear

********************************************************************************
* Set globals for analysis *****************************************************
********************************************************************************
* Set the control variables
qui qui do do/set_controls 
* Set the outcome variables 
qui qui do do/set_outcomes

********************************************************************************
* Initialize the ATE maker program *********************************************
********************************************************************************
qui qui do do/tables_do/ate_maker
qui qui do do/tables_do/adjust_p_values
qui qui do do/tables_do/ate_maker_year
qui do do/tables_do/ate_maker_dropped
qui do do/tables_do/ate_maker_inter_long
set more off

* Also initialize the summary table program ************************************
qui qui do do/tables_do/summary_table

********************************************************************************
* Make summary statistics of all covariates ************************************
********************************************************************************
* qui summary_table $C_ec2, filename(covariates_resident) subset($L1)


local nsims = 2
asdf
********************************************************************************
* Comparison between ATEs in Endline 1 and Endline 2 ***************************
********************************************************************************
 ate_maker_year  $land_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(land_conflict_paper) ///
     adjustvarsg1(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2) ///
     adjustvarsg2(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 ///
         conf_length_max_c_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2) ///
     nsims(`nsims')

ate_maker_year $land_conflict, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(land_conflict)

ate_maker_year $all_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(all_conflict_paper) ///
    adjustvarsg1( ///
        lmg_conf_u_ec2 ///
        lmg_unrslv_conf_u_ec2 ///
        lmg_forum_lastsuc_c_ec2 ///
        lmg_forum_inf_suc_c_ec2) ///
    adjustvarsg2( ///
        lmg_conf_u_ec2 ///
        lmg_unrslv_conf_u_ec2 ///
        lmg_conf_any_u_ec2 ///
        lmg_forum_lastsuc_c_ec2 ///
        lmg_forum_inf_suc_c_ec2 ///
        lmg_conf_any_c_ec2) ///
    nsims(`nsims')

ate_maker_year $all_conflict, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(all_conflict)

 ate_maker_year  $conflict_adj_p, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(conflict_adj_p) ///
     adjustvarsg1(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2 ///
	     lmg_conf_u_ec2 ///
         lmg_unrslv_conf_u_ec2 ///
         lmg_forum_lastsuc_c_ec2 ///
         lmg_forum_inf_suc_c_ec2) ///
     adjustvarsg2(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 ///
         conf_length_max_c_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2 ///
         lmg_conf_u_ec2 ///
         lmg_unrslv_conf_u_ec2 ///
         lmg_conf_any_u_ec2 ///
         lmg_forum_lastsuc_c_ec2 ///
         lmg_forum_inf_suc_c_ec2 ///
         lmg_conf_any_c_ec2) ///
     nsims(`nsims')



ate_maker_year $comm_conflict, treat(assigned_ever) group1(ENDLINE_LEADER) group2(ENDLINE2_LEADER) controls1($comm_ctrls_apsr) controls2($comm_ctrls) filename(comm_conflict) adjustvarsg1($comm_conflict) adjustvarsg2($comm_conflict) nsims(`nsims')
asdf
********************************************************************************
* Resident-level analysis ******************************************************
********************************************************************************
/* Land conflict and all conflict are moved to the E1-E2 comparison */ 
ate_maker $fallow_security_paper, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(fallow_security_paper) omitpct adjustvars($fallow_security_paper) nsims(`nsims')
ate_maker $fallow_security, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(fallow_security) 
ate_maker $bias_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(bias_index_ec2) omitpct  
ate_maker $defection_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(defection_index_ec2) omitpct 
ate_maker $forum_choice_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(forum_choice_index_ec2) omitpct 
ate_maker $managing_emotions_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(managing_emotions_index_ec2) omitpct
ate_maker $mediation_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(mediation_index_ec2) omitpct
ate_maker $negotiation_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(negotiation_index_ec2) omitpct 
ate_maker $all_index_categories, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(all_categories_ec2) omitpct adjustvars($all_index_categories) nsims(`nsims')


* Make a summary table of these outcomes ***************************************
qui summary_table $land_conflict, filename(land_conflict_summary) subset($L1)
qui summary_table $all_conflict, filename(all_conflict_summary) subset($L1)
qui summary_table $fallow_security, filename(fallow_security_summary) subset($L1)
qui summary_table $all_index_categories, filename(all_categories_summary) subset($L1)

********************************************************************************
* Intensive Treatment **********************************************************
********************************************************************************
* Initialize the program for the intensive treatment variable ******************
qui do do/tables_do/ate_maker_intensive
* Make the table ***************************************************************
ate_maker_intensive jpc_attend $intensive, treatmain(assigned_ever) treatintense(intense) controls1($C_apsr) controls2($C_ec2) filename(intensive) group1(resident_e1) group2(ENDLINE2_RESIDENT)

********************************************************************************
* Community-level impacts ******************************************************
********************************************************************************
* Make the tables **************************************************************
ate_maker $comdispute_leader, treat(assigned_ever) covariates($comm_ctrls) subset(ENDLINE2_LEADER) filename(comdispute_leader) adjustvars($comdispute_leader) nsims(`nsims')
summary_table $comdispute_leader, filename(comdispute_leader_summary) subset(ENDLINE2_LEADER)


********************************************************************************
* ITT tables where treatment is years since first workshop *********************
********************************************************************************
/* 	Previously we had an IV. This was a bad specification because we had no 
	number that reprsesented time-since-treatment for control communities. Now 
	the strategy is to use only treated communities and have the treatment 
	variable be the year since treatment. 
*/
qui do do/tables_do/IV_maker_year
qui svyset commcode [pweight=weight_e1_e2], strata(county)  // Set survey data specific to each dataset
ate_maker $land_conflict_paper, treat(years_treated_ec2) covariates($C_ec2 block1 block2 block12 block3 block4 block5 block4a block4b block4c block4c5) subset(ENDLINE2_RESIDENT) filename(land_conflict_years_treated)
IV_maker_year $land_conflict_paper, exogenous(block1 block2 block3) endogenous(years_treated_ec2) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($ate_ctrls_apsr $comm_ctrls_short) controls2($C_ec2) filename(land_conflict_years_treated)

********************************************************************************

********************************************************************************
* Interaction based on gender, age, minority ***********************************
********************************************************************************
// TODO: explain this weird header shit.
// This is code smell.
* Key violence outcomes ********************************************************
qui do do/tables_do/ate_maker_inter_demo
qui do do/tables_do/summary_stats_demo

local headers ///
`" "", "\uline{\hfill For all residents \hfill}", "", "\uline{\hfill Conditional on a dispute ocurring \hfill}", "" \  "", "Any land", "Any unresolved", "Any threats, property" "Resolved land" \ "Independent variable", "dispute", "dispute", "damage or violence", "dispute" \ "", "(1)", "(2)", "(3)", "(4)" "'

local multicols = ///
`" 1,2,2;1,4,2 "'

global regression_variables_to_interact            female_ec2 age20_40_ec2 cwealthindex_below_med_bc             minority_ec2 canypeace_bc cgpeace_bc
global summary_variables_to_interact    female_ec2 age20_40_ec2 cwealthindex_below_med_bc   minority_ec2 canypeace_dum_bc cgpeace_dum_bc
ate_maker_inter_long $hetero_demo_conflict, treat(assigned_ever) covariates($C_ec2) interactions($regression_variables_to_interact) subset($L1) filename(hetero_demo_conflict) ///
inter1("Female") ///
inter2("20-40 years old") ///
inter3("Below median wealth") ///
inter4("Any ethnic minority") ///
inter5("\% town peace education at baseline") ///
inter6("\% town peace group at baseline") ///
headers(`headers') multicols(`multicols')

summary_stats_demo $conflict_adj_p, interactions($summary_variables_to_interact) ///
intertitle1("Gender") inter1ZERO("Men") inter1ONE("Women") ///
intertitle2("Age") inter2ZERO("above 40") inter2ONE("20-40") ///
intertitle3("Below median wealth") inter3ZERO("No") inter3ONE("Yes") ///
intertitle4("Any ethnic minority") inter4ZERO("No") inter4ONE("Yes") ///
intertitle5("Any peace education in town at baseline") inter5ZERO("No") inter5ONE("Yes") ///
intertitle6("Any peace group in town at baseline") inter6ZERO("No") inter6ONE("Yes") ///
subset(ENDLINE2_RESIDENT) ///
filename(summary_stats_demo)

********************************************************************************
* See the effects of being dropped on endline 1 outcomes ***********************
********************************************************************************
do do/tables_do/ate_maker_dropped
ate_maker_dropped $conflict_adj_p_e1, treat(assigned_ever) covariates($C_apsr) subset(resident_e1) filename(conflict_adj_p_dropped) dropped(was_dropped_ec2)


svyset [pweight=s_weight2], psu(commcode) strata(county)
// see regression difference of dropping 
do do/tables_do/summary_table_diff
summary_table_diff $baseline_controls_comparison, subset(BASELINE_RESIDENT) filename(dropped_summary_table_resident) diffvar(was_dropped_ec2) covariates(assigned_ever county1 county2) zerostring("Kept") onestring("Dropped")
summary_table_diff $comm_controls_comparison, subset(COMMLEVEL) filename(dropped_summary_table_comm) diffvar(was_dropped_ec2) covariates(assigned_ever county1 county2) zerostring("Kept") onestring("Dropped")

summary_table_diff $baseline_controls_comparison, subset(BASELINE_RESIDENT) filename(baseline_balance_resident) diffvar(assigned_ever) covariates(assigned_ever county1 county2) zerostring("Control") onestring("Treatment")
summary_table_diff $comm_controls_comparison, subset(COMMLEVEL) filename(baseline_balance_comm) diffvar(assigned_ever) covariates(assigned_ever county1 county2) zerostring("Control") onestring("Treatment")



********************************************************************************
* Get the aggregate number of incidents prevented ******************************
********************************************************************************

* Initialize the table program *************************************************
qui do do/tables_do/aggregate_analysis_ate
svyset commcode [pweight=weight_e1_e2], strata(county) 
aggregate_analysis_ate $agg_analysis_variables, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(aggregate_analysis_ate)

********************************************************************************

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
qui do do/set_controls 
* Set the outcome variables 
qui do do/set_outcomes

********************************************************************************
* Initialize the ATE maker program *********************************************
********************************************************************************
qui do do/tables_do/ate_maker
qui do do/tables_do/adjust_p_values
qui do do/tables_do/ate_maker_year
set more off

* Also initialize the summary table program ************************************
qui do do/tables_do/summary_table

********************************************************************************
* Make summary statistics of all covariates ************************************
********************************************************************************
qui summary_table $C_ec2, filename(covariates_resident) subset($L1)


local nsims = 1000
********************************************************************************
* Comparison between ATEs in Endline 1 and Endline 2 ***************************
********************************************************************************
/*
 ate_maker_year  $land_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(land_conflict_paper) ///
     adjustvarsg1(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2) ///
     adjustvarsg2(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2) ///
     extraadjustvarsg1(   ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2) ///
     extraadjustvarsg2(   ///
         conf_length_max_c_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2) ///
     nsims(`nsims')



 ate_maker_year  $land_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(land_conflict_paper_b_adjust) ///
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

 ate_maker_year  $land_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(land_conflict_paper_col) ///
     adjustvarsg1(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 ///
	conf_threat_u_ec2 ///
	conf_damage_u_ec2 ///
	conf_viol_u_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2 ///
	 conf_threat_c_ec2 ///
	 conf_damage_c_ec2 ///
	 conf_viol_c_ec2) ///
     adjustvarsg2(   ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 ///
         conf_threat_u_ec2 ///
        conf_damage_u_ec2 ///
        conf_viol_u_ec2 ///
         conf_length_max_c_ec2 ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2 ///
         conf_any_c_ec2 ///
	 conf_threat_c_ec2 ///
	 conf_damage_c_ec2 ///
	 conf_viol_c_ec2 ///
	 conf_witch_c_ec2) ///	
     nsims(`nsims')

ate_maker_year $land_conflict, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(land_conflict)

 ate_maker_year $all_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(all_conflict_paper) ///
     adjustvarsg1( ///
         lmg_conf_u_ec2 ///
         lmg_unrslv_conf_u_ec2) ///
     adjustvarsg2( ///
         lmg_conf_u_ec2 ///
         lmg_unrslv_conf_u_ec2 ///
         lmg_conf_any_u_ec2) ///
     extraadjustvarsg1( ///
         lmg_forum_lastsuc_c_ec2 ///
         lmg_forum_inf_suc_c_ec2) ///
     extraadjustvarsg2( ///
         lmg_forum_lastsuc_c_ec2 ///
         lmg_forum_inf_suc_c_ec2 ///
         lmg_conf_any_c_ec2) ///
     nsims(`nsims')

 ate_maker_year $all_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(all_conflict_paper_b_adjust) ///
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

 ate_maker_year $all_conflict_paper, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(all_conflict_paper_col) ///
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
         lmg_conf_any_c_ec2 ///
	 lmg_conf_threat_c_ec2 ///
	 lmg_conf_damage_c_ec2 ///
	 lmg_conf_viol_c_ec2) ///
     nsims(`nsims')

// ate_maker_year $all_conflict, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(all_conflict)


 ate_maker_year $conflict_adj_p, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(conflict_adj_p) ///
     adjustvarsg1( ///
         anylndconf_u_ec2   ///  
         unrslv_lnd_conf_u_ec2 ///
         conf_any_u_ec2 /// 
         lmg_conf_u_ec2 ///
         lmg_unrslv_conf_u_ec2) ///
     adjustvarsg2( ///
	 anylndconf_u_ec2 ///
	 unrslv_lnd_conf_u_ec2 ///
	 conf_any_u_ec2 ///
	 lmg_conf_u_ec2 ///
	 lmg_unrslv_conf_u_ec2 ///
	 lmg_conf_any_u_ec2) ///    
extraadjustvarsg1( ///
         forum_lastsuc_c_ec2   ///  
         conf_any_c_ec2 ///
         lmg_forum_lastsuc_c_ec2 ///
         lmg_forum_inf_suc_c_ec2) ///
    extraadjustvarsg2( ///
        conf_length_max_c_ec2 ///
         forum_lastsuc_c_ec2 ///
         conf_any_c_ec2 /// 
         lmg_forum_lastsuc_c_ec2 ///
         lmg_forum_inf_suc_c_ec2 ///
         lmg_conf_any_c_ec2) ///
     nsims(`nsims')

*/

 ate_maker_year  $conflict_adj_p, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(conflict_adj_p_col) ///
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

asdf

 ate_maker_year $comm_conflict, treat(assigned_ever) group1(ENDLINE_LEADER) group2(ENDLINE2_LEADER) controls1($comm_ctrls_apsr) controls2($comm_ctrls) filename(comm_conflict)
********************************************************************************
* Resident-level analysis ******************************************************
********************************************************************************
/* Land conflict and all conflict are moved to the E1-E2 comparison */ 
ate_maker $fallow_security_paper, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(fallow_security_paper) omitpct
ate_maker $fallow_security, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(fallow_security) 
ate_maker $bias_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(bias_index_ec2) omitpct
ate_maker $defection_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(defection_index_ec2) omitpct
ate_maker $forum_choice_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(forum_choice_index_ec2) omitpct
ate_maker $managing_emotions_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(managing_emotions_index_ec2) omitpct
ate_maker $mediation_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(mediation_index_ec2) omitpct
ate_maker $negotiation_index, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(negotiation_index_ec2) omitpct
ate_maker $all_index_categories, treat(assigned_ever) covariates($C_ec2) subset($L1) filename(all_categories_ec2) omitpct

* Make a summary table of these outcomes ***************************************
qui summary_table $land_conflict, filename(land_conflict_summary) subset($L1)
qui summary_table $all_conflict, filename(all_conflict_summary) subset($L1)
qui summary_table $fallow_security, filename(fallow_security_summary) subset($L1)
qui summary_table $all_index_categories, filename(all_categories_summary) subset($L1)

********************************************************************************
* Make a table of all the norms/skills categories for residents and leaders ****
********************************************************************************
do do/tables_do/ate_maker_res_leader
/* 	Remember that I cheated here, and that leaders' information is in variabels
	ending in _ec2. */
ate_maker_res_leader $all_index_categories, treat(assigned_ever) covariatesres($C_ec2) covariatesleader($C_el2) filename(all_categories) resgroup(ENDLINE2_RESIDENT) leadergroup(ENDLINE2_LEADER) 

********************************************************************************
* Intensive Treatment **********************************************************
********************************************************************************
* Initialize the program for the intensive treatment variable ******************
do do/tables_do/ate_maker_intensive
* Make the table ***************************************************************
ate_maker_intensive jpc_attend $intensive, treatmain(assigned_ever) treatintense(intense) controls1($C_apsr) controls2($C_ec2) filename(intensive) group1(resident_e1) group2(ENDLINE2_RESIDENT)

********************************************************************************
* Community-level impacts ******************************************************
********************************************************************************
* Make the tables **************************************************************
ate_maker $comdispute_leader, treat(assigned_ever) covariates($comm_ctrls) subset(ENDLINE2_LEADER) filename(comdispute_leader)
summary_table $comdispute_leader, filename(comdispute_leader_summary) subset(ENDLINE2_LEADER)


********************************************************************************
* ITT tables where treatment is years since first workshop *********************
********************************************************************************
/* 	Previously we had an IV. This was a bad specification because we had no 
	number that reprsesented time-since-treatment for control communities. Now 
	the strategy is to use only treated communities and have the treatment 
	variable be the year since treatment. 
*/
do do/tables_do/IV_maker_year
qui svyset commcode [pweight=weight_e1_e2], strata(county)  // Set survey data specific to each dataset
ate_maker $land_conflict_paper, treat(years_treated_ec2) covariates($C_ec2 block1 block2 block12 block3 block4 block5 block4a block4b block4c block4c5) subset(ENDLINE2_RESIDENT) filename(land_conflict_years_treated)
IV_maker_year $land_conflict_paper, exogenous(block1 block2 block3) endogenous(years_treated_ec2) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($ate_ctrls_apsr $comm_ctrls_short) controls2($C_ec2) filename(land_conflict_years_treated)
*/
********************************************************************************
*/
********************************************************************************
* Interaction based on gender, age, minority ***********************************
********************************************************************************

* Key violence outcomes ********************************************************
do do/tables_do/ate_maker_inter_demo
global variables_to_interact  female_ec2 age20_40_ec2 cwealthindex_bc muslim_ec2 minority_ec2 cgpeace_bc canypeace_bc 
ate_maker_inter_demo $hetero_demo_conflict, treat(assigned_ever) covariates($C_ec2) interactions($variables_to_interact) subset($L1) filename(hetero_demo_conflict) ///
inter1("Female") inter2("Youth") inter3("Wealth") inter4("Muslim minority") inter5("Any ethnic minority") inter6("Prior peace education") inter7("Pct. town prior peace")

* Security and Investment ******************************************************
global hetero_demo_security security_rights improvez fallow_index size_farm
ate_maker_inter_demo $hetero_demo_security , treat(assigned_ever) covariates($C_ec2) interactions($variables_to_interact) subset($L1) filename(hetero_demo_security) ///
inter1("Female") inter2("Youth") inter3("Wealth") inter4("Muslim minority") inter5("Any ethnic minority") inter6("Prior peace education") inter7("Pct. town prior peace")


********************************************************************************
* Get the aggregate number of incidents prevented ******************************
********************************************************************************

* Initialize the table program *************************************************
do do/tables_do/aggregate_analysis_ate
aggregate_analysis_ate $agg_analysis_variables, treat(assigned_ever) group1(resident_e1) group2(ENDLINE2_RESIDENT) controls1($C_apsr) controls2($C_ec2) filename(aggregate_analysis_ate)

********************************************************************************

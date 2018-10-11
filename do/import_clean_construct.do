
********************************************************************************
* Import the dataset ***********************************************************
********************************************************************************
/*	Original location of this data: 
"IPA Liberia Peace CoRE/DATA/Analysis/PEACE/Data/jpc_analysis_test.dta"
*/


	clear 
	clear mata 
	clear matrix 
	set maxvar 6000
	use data/jpc_analysis_test, clear
	set more off


********************************************************************************
* Make adjustments to the dataset **********************************************
********************************************************************************

* Outliers and extreme values **********************************************
foreach x of varlist farm_size_et land_size_et farm_size_ec land_size_ec {

	local lbl : variable label `x'			
	gen `x'p95c=`x'
	sum `x',d
	replace `x'p95c=r(p95) if `x'>r(p95) & `x'!=.
	la var `x'p95 "`lbl' capped at p95"
}		

* Impute median for missing data *******************************************
foreach x of varlist age_ec age_et age_ec2 {
	qui sum `x',d
	replace `x'=r(p50) if `x'==.
	
}
					

********************************************************************************
* Generate weights we will use in the analysis *********************************
********************************************************************************
// Generate sampling weight: the inverse probability of being sampled
	* s_weight1 is used for community member regressions
	* s_weight2 is used for leader, trainee, and community-level regressions (b/c their probability of seleciton is 1)
	* s_weight3 is used for community member regressions or sum stats at baseline
		* Note: transforming weights to have a mean of 1 changes neither coeffs nor se's.
	
gen s_weight1=1/(commcount_ec/popest2)
	la var s_weight1 "inverse prob. of selection (endline)"

gen s_weight2=1
	la var s_weight2 "1 for all observations--no weighting for differntial probability of selection within communities"	

gen s_weight3=1/(commcount_bc/popest2)
	la var s_weight3 "inverse prob. of selection (baseline)"

gen s_weight4=s_weight1
replace s_weight4=1 if TARGETED_RESIDENT==1 | ENDLINE_LEADER==1
	la var s_weight4 "inverse prob. of selection for C; 1 for T & L"
	
**NOTE: due to the dropping of 40 control communities, weight_ec2 will be used for the endline2 analysis.





********************************************************************************
* Clean the data related to Treatment status ***********************************
********************************************************************************

gen START_TREATMENT_DATA=.
la var START_TREATMENT_DATA "========== START TREATMENT DATA ============"

* Assigned to treatment

ren impl_befroct assigned
	la var assigned "Randomly assigned to be treated by October 2010"	

replace assigned_nov = 0 if assigned==1
	la var assigned_nov "Randomly assigned to be treated during November/December 2010"	

gen assigned_ever = (assigned==1 | assigned_nov==1)
	la var assigned_ever "Randomly assigned to be treated by November/December 2010"	

replace intense = 0 if assigned==0

gen blocks1to5 = (block!=0)
	la var blocks1to5 "Randomly assigned to Blocks 1 to 5 (i.e. original assignment)"	

gen assigned_dropped = (blocks1to5==1 & assigned_ever==0)
	la var assigned_dropped "Randomly assigned to Blocks 1 to 5 but randomly not treated (in reassignment)"	


* Treated

gen treated_oct=(assigned==1 & jpc_treat>0)
replace treated_oct=0 if commcode==2010 | commcode==2660 
	la var treated_oct "Treated by October 2010" 

gen treated_nov=(assigned_nov==1 & jpc_treat>0)
replace treated_nov=1 if commcode==2010 | commcode==2660 
	la var treated_nov "Treated during Nov/Dec 2010" 

gen treated_ever=(treated_oct==1 | treated_nov==1)
	la var treated_ever "Treated ever" 

* Months since implementation
	
des impl*_month
forvalues i = 1/5 {
	gen month`i'=monthly(impl`i'_month, "MY")						// Returns stata assigned # for month of survey between 590 (3/2009) and 611 (12/2010)
	gen month`i'_bfr_impl=611-month`i' 								// Months before December (survey month 611) 
	gen weighted_monthbfr`i'= month`i'_bfr_impl*impl`i'_month_num	// Months before december weighted by number of workshops in that month
}	

egen tot_workshops=rowtotal(impl1_month_num impl2_month_num impl3_month_num impl4_month_num impl5_month_num ) 					// total number of workshops implemented
egen tot_month_weight=rowtotal(weighted_monthbfr1 weighted_monthbfr2 weighted_monthbfr3 weighted_monthbfr4 weighted_monthbfr5)	// weighted by months since implementation

gen months_treated=tot_month_weight/tot_workshops
replace months_treated=0 if assigned_nov==1
	la var months_treated "# months b/t impl. of assigned_oct and _nov communities and the survey (weighted)"

gen lmonths_treated=ln(1+months_treated)


* Get a good date of the Endline 2 interview ***********************************
split datetime_ec2, generate(t)
drop t2
gen date_ec2 = date(t1, "MDY")

* Some dates are in 2007, replace those with the median date *******************
sum date_ec2, detail
replace date_ec2 = r(p50) if (date_ec2 < date("01jan2008", "DMY") & !missing(date_ec2))

gen t = date(impl1_month, "MY")
gen months_treated_ec2 = date_ec2 - t
replace months_treated_ec2 = floor(months_treated_ec2 / 30.5)

replace months_treated_ec2 = 0 if ((ENDLINE2_RESIDENT == 1 | ENDLINE2_LEADER == 1) & (assigned_ever == 0 | missing(months_treated_ec2))) 

label var months_treated_ec2 "Months since treatment at second endline"

gen years_treated_ec2 = months_treated_ec2 / 12
label var years_treated_ec2 "Years since treatment at second endline"

replace years_treated_ec2 = months_treated / 12 if (ENDLINE_RESIDENT == 1 | ENDLINE_LEADER == 1 | TARGETED_RESIDENT == 1)
replace years_treated_ec2 = . if ((ENDLINE_RESIDENT == 1 | ENDLINE_LEADER == 1 | TARGETED_RESIDENT == 1) & (assigned_ever == 0 | missing(months_treated)))
//replace years_treated_ec2 = . if years_treated_ec2 == 0 & ENDLINE2_RESIDENT == 1
drop month1-tot_month_weight
		
* Assigned to Block 1, Block 34 dummy and TOT counterparts
	* Note: Some block 3 4 communities not actually assigned due to implementing capacity constraints. 
	* AH and BSM randomized implementation in Block34 and this is accounted for in "assigned"
					
gen block1 = (block==1) 
	la var block1 "Treatment block 1"

gen block2 = (block==2) 
	la var block2 "Treatment block 2"

gen block12 = (block==1 | block==2) 						// all of blocks 1 and 2 were implemented
	la var block12 "Treatment block 1/2"

gen block3 = (block==3) 
	la var block3 "Treatment block 3"

gen block4 = (block==4) 
	la var block4 "Treatment block 4"

gen block5 = (block==5) 
	la var block5 "Treatment block 5"

gen block4a = (block==4 & assigned==1) 							// includes only those block 4 members assigned to Oct (i.e. reassigned to block 3)
	la var block4a "4 from Block 4 assigned to treatment"

gen block4b = (assigned_nov==1) 							// includes only those block 16 members assigned to Nov/Dec
	la var block4b "16 from Block 4 assigned to late treatment concurrent with survey"

gen block4c = (block4==1 & block4a==0 & block4b==0) 							
	la var block4c "the rest from Block 4 assigned to control"
	
gen block4c5 = (block4c==1 | block5==1) 							
	la var block4c5 "Those randomly reassigned to control"
	

* % of town implemented for use in spillover analysis

** prop_treated3 using ctownpop_el2?
gen prop_treated=cond(treated_oct==1, jpc_treat*35/ctownpop_el,0)
	la var prop_treated "% of town treated (endline population estimates)"
gen prop_treated2=cond(treated_oct==1, jpc_treat*35/ctownpop_bl,0)
	la var prop_treated2 "% of town treated (baseline population estimates)"

** adultprop_treated3 using ctownpop_el2?
gen adultprop_treated=cond(treated_oct ==1, jpc_treat*35/(ctownpop_el*(1.7/3.5)),0) // town population scaled by the % of adult population from http://www.unicef.org/wcaro/wcaro_liberia_fact_CP_indicators.pdf
	la var adultprop_treated "% of town treated (endline population estimates)" 
gen adultprop_treated2=cond(treated_oct ==1, jpc_treat*35/(ctownpop_bl*(1.7/3.5)),0)
	la var adultprop_treated2 "% of town treated (baseline population estimates)" // town population scaled by the % of adult population from http://www.unicef.org/wcaro/wcaro_liberia_fact_CP_indicators.pdf
		
pwcorr prop_treated prop_treated2 if COMMLEVEL==1
sum prop_treated if  treated_oct==1 & COMMLEVEL==1,d					
sum prop_treated2 if  treated_oct==1 & COMMLEVEL==1,d					
sum adultprop_treated if  treated_oct==1 & COMMLEVEL==1,d					
sum adultprop_treated2 if  treated_oct==1 & COMMLEVEL==1,d					
			
* Where only 1 TARGETED RESIDENT found in community, we dump into catch-all, by county, and use this version of commcode for clustering. 
	
tab county, gen(county)
gen commcode_adj=commcode
	la var commcode_adj "Adjusted commcode"
replace commcode_adj=1001 if commcount_et==1 & county1==1 		// 5 changes made
replace commcode_adj=1002 if commcount_et==1 & county2==1		// 2 changes made
replace commcode_adj=1003 if commcount_et==1 & county3==1		// 7 changes made

* Control variable for if in community w/ other quarter assigned to treatment blocks 1-4

gen quartdummy=cond(commcode==3011 | commcode==2041 | commcode==1082 | commcode==2112 | commcode==3291 | commcode==2431 | commcode==2430 | commcode==1312 | commcode==1321 | commcode==2612 | commcode==2902 | commcode==1472 |commcode==1473,1,0)
	la var quartdummy "Treatment: Control quater in community with other quarter assigned to treatment blocks 1-4"


********************************************************************************
* Construct variables related to leader attitudes, norms, and skills ***********
********************************************************************************
********************************************************************************
* Fix all the norms and skills variables for the leaders  **********************
********************************************************************************

/* 	The following categories are deprecated, but are still useful because I don't
	want to rewrite the de-stringing code. 

	Additionally, notice that this next section renames the variables ending in 
	_el2 to get rid of the suffix. Then it adds the suffix again. Don't ask me
	why it was written this way. But it works and i don't want to add the 
	suffix to this code manually. 
*/

/* 	Rename skbringtogehter to skbringtogether. Not sure why this wasn't caught
	earlier. 
*/
rename skbringtogehter* skbringtogether*


* Destring the norms and skills variables **************************************
local att_neg	"nospoilpropop nocompromop nogiftop"
local norm_neg	"nospoilpropco nocompromco nogiftco"
local att_bias	"nogossipop nosmalllieop notakesideop"
local norm_bias	"nogossipco nosmalllieco notakesideco"
local att_med	"noadviseop nomediateop nohelpcompop"
local norm_med	"noadviseco nomediateco nohelpcompco"
local att_def	"norenegeop nochiefsupportop nopoliceop nocontactsop"
local norm_def	"norenegeco nochiefsupportco nopoliceco nocontactsco"
local att_cho	"notalkfirstop nocommfirstop nopolicefirstop"
local norm_cho	"notalkfirstco nocommfirstco nopolicefirstco"

local skill_com	"sklisten skconvincetalk sktalkpalava sktalkbad"
local skill_emp	"skempathy skthinkwrong skthinkshoes"
local skill_emo "skstaycalm skcooltemper skcooltemperothers"
local skill_neg	"sktalkgood skproposesolution skcompromise skforgive"
local skill_med "skbringtogether skhelpagree skhelpunderstand"

foreach sub in att_neg norm_neg att_bias norm_bias att_med norm_med att_def norm_def att_cho norm_cho skill_com skill_emp skill_emo skill_neg skill_med {
	foreach x in ``sub'' {
		// do the weird renaming thing. 
		ren `x'_el2 `x'
	}
}

foreach sub in att_neg norm_neg att_bias norm_bias att_med norm_med att_def norm_def att_cho norm_cho skill_com skill_emp skill_emo skill_neg skill_med {
	foreach x in ``sub'' {
		local lab : var label `x'
		split `x', p("-")
		destring `x'1, replace force
			la var `x'1 "`lab'"
		drop `x'2
		drop `x'
		rename `x'1 `x'
	}
}

* Make standardized forms of each variable *************************************
foreach sub in att_neg att_bias att_med att_def att_cho {
	local `sub'_st
	foreach x in ``sub'' {
		loc lab: var label `x'
		egen `x'_st=std(`x')
			la var `x'_st "`lab', z-score"
		local `sub'_st ``sub'_st' `x'_st
	}
	display "``sub'_st'"
}

foreach sub in norm_neg norm_bias norm_med norm_def norm_cho {
	local `sub'_st
	foreach x in ``sub'' {
		loc lab: var label `x'
		egen `x'_st=std(`x')
			la var `x'_st "`lab', z-score"
		local `sub'_st ``sub'_st' `x'_st
	}
	display "``sub'_st'"
}

foreach sub in skill_com skill_emp skill_emo skill_neg skill_med {
	local `sub'_st
	foreach x in ``sub'' {
		loc lab: var label `x'
		egen `x'_st=std(`x')
			la var `x'_st "`lab', z-score"
		local `sub'_st ``sub'_st' `x'_st
	}
	display "``sub'_st'"
}


foreach sub in att_neg norm_neg att_bias norm_bias att_med norm_med att_def norm_def att_cho norm_cho skill_com skill_emp skill_emo skill_neg skill_med {
	foreach x in ``sub'' {
		ren `x' `x'_el2
		ren `x'_st `x'_st_el2
	}
}




* Make sure all variables point in the same direction **************************
/* 	All the resident-level norms, attitudes, and skills variables are changed
	to point in the same direction further upstream. Now we just have to do it 
	for the leaders. 
*/

* skills ***********************************************************************
* make sure things point in the right direction 
foreach x in sklisten_el2 skconvincetalk_el2 skempathy_el2 skthinkwrong_el2 skthinkshoes_el2 ///
sktalkpalava_el2 skstaycalm_el2 skcooltemper_el2 sktalkgood_el2 skproposesolution_el2 skcompromise_el2 ///
skforgive_el2 skbringtogether_el2 skhelpagree_el2 skhelpunderstand_el2 skcooltemperothers_el2 {
	replace `x'=5-`x'
}

* attitudes ********************************************************************
* make sure that a bigger number is more consistent with ADR
foreach x in nocompromop_el2 nogiftop_el2 noadviseop_el2 notalkfirstop_el2 nocommfirstop_el2 ///
	nomediateop_el2 nohelpcompop_el2 nopoliceop_el2 nopolicefirstop_el2 {
	replace `x'=5-`x'
}


* norms ************************************************************************
* make sure that a bigger number is more consistent with ADR
foreach x in nospoilpropco_el2 nogossipco_el2 nosmalllieco_el2 norenegeco_el2 nochiefsupportco_el2 nopoliceco_el2 nocontactsco_el2 nopolicefirstco_el2 notakesideco_el2 {
	replace `x'=7-`x'
}

/*

TODO: Deprecate this set of norms. We are now interested in "themes" of 
attitudes, skills, and norms, not any of them separately. 

*/

********************************************************************************
* Define a program for making indices ******************************************
********************************************************************************
/* Is this really so hard? */
cap program drop make_index 
program define make_index 
	syntax varlist, INDEXNAME(name)

	cap drop Z* 

	foreach sub_var in `varlist' {
		cap drop Z_`sub_var'


		sum `sub_var' if ENDLINE2_RESIDENT == 1
		replace `sub_var' = r(p50) if missing(`sub_var') & ENDLINE2_RESIDENT == 1
		egen Z_`sub_var' = std(`sub_var') 
	}

	egen `indexname' = rowtotal(Z_*), m 
	sum `indexname', detail 
	replace `indexname' = (`indexname' - r(mean)) / r(sd)

	drop Z_* 
	
end


********************************************************************************
* Make the indices for the Residents *******************************************
********************************************************************************

* Impute medians ***************************************************************
foreach sub in att_neg norm_neg att_bias norm_bias att_med norm_med att_def norm_def att_cho norm_cho skill_com skill_emp skill_emo skill_neg skill_med {
	sum `sub'_st_ec2 
	replace `sub'_st_ec2 = r(p50) if missing(`sub'_st_ec2) & ENDLINE2_RESIDENT
}

local bias_index_vars nogossipop_ec2 nogossipco_ec2 nosmalllieop_ec2 ///
	nosmalllieco_ec2 notakesideop_ec2 notakesideco_ec2
make_index `bias_index_vars', indexname(bias_index_ec2)

local defection_index_vars norenegeop_ec2 norenegeco_ec2 nochiefsupportop_ec2 ///
	nochiefsupportco_ec2 nopoliceop_ec2 nopoliceco_ec2 nocontactsop_ec2 nocontactsco_ec2 
make_index `defection_index_vars', indexname(defection_index_ec2)

local empathy_index_vars sklisten_ec2 skconvincetalk_ec2 skempathy_ec2 skthinkwrong_ec2 ///
	skthinkshoes_ec2
make_index `empathy_index_vars', indexname(empathy_index_ec2)

local forum_choice_index_vars notalkfirstop_ec2 notalkfirstco_ec2  ///
	nocommfirstop_ec2 nocommfirstco_ec2 nopolicefirstop_ec2 nopolicefirstco_ec2
make_index `forum_choice_index_vars',indexname(forum_choice_index_ec2)

local managing_emotions_index_vars nospoilpropop_ec2 nospoilpropco_ec2 skstaycalm_ec2 skcooltemper_ec2 ///
	sktalkbad_ec2
make_index `managing_emotions_index_vars', indexname(managing_emotions_index_ec2)


local mediation_index_vars noadviseop_ec2 noadviseco_ec2 nomediateop_ec2 nomediateco_ec2 ///
	nohelpcompop_ec2 nohelpcompco_ec2 skbringtogether_ec2 skhelpagree_ec2 ///
	skhelpunderstand_ec2 skcooltemperothers_ec2 
make_index `mediation_index_vars', indexname(mediation_index_ec2)


local negotiation_index_vars nocompromop_ec2 nocompromco_ec2 nogiftop_ec2 nogiftco_ec2 ///
	sktalkpalava_ec2 sktalkgood_ec2 skproposesolution_ec2 skcompromise_ec2 ///
 	skforgive_ec2
make_index `negotiation_index_vars', indexname(negotiation_index_ec2)

********************************************************************************
* Make the indices for the Residents *******************************************
********************************************************************************

local bias_index_vars nogossipop_el2 nogossipco_el2 nosmalllieop_el2 ///
	nosmalllieco_el2 notakesideop_el2 notakesideco_el2
make_index `bias_index_vars', indexname(bias_index_el2)

local defection_index_vars norenegeop_el2 norenegeco_el2 nochiefsupportop_el2 ///
	nochiefsupportco_el2 nopoliceop_el2 nopoliceco_el2 nocontactsop_el2 nocontactsco_el2 
make_index `defection_index_vars', indexname(defection_index_el2)

local empathy_index_vars sklisten_el2 skconvincetalk_el2 skempathy_el2 skthinkwrong_el2 ///
	skthinkshoes_el2
make_index `empathy_index_vars', indexname(empathy_index_el2)

local forum_choice_index_vars notalkfirstop_el2 notalkfirstco_el2 notalkfirstop_el2 ///
	nocommfirstop_el2 nocommfirstco_el2 nopolicefirstco_el2
make_index `forum_choice_index_vars',indexname(forum_choice_index_el2)

local managing_emotions_index_vars nospoilpropop_el2 nospoilpropop_el2 skstaycalm_el2 skcooltemper_el2 ///
	sktalkbad_el2
make_index `managing_emotions_index_vars', indexname(managing_emotions_index_el2)

local mediation_index_vars noadviseop_el2 noadviseco_el2 nomediateop_el2 nomediateco_el2 ///
	nohelpcompop_el2 nohelpcompco_el2 skbringtogether_el2 skhelpagree_el2 ///
	skhelpunderstand_el2 skcooltemperothers_el2 
make_index `mediation_index_vars', indexname(mediation_index_el2)

local negotiation_index_vars nocompromop_el2 nocompromco_el2 nogiftop_el2 nogiftco_el2 ///
	sktalkpalava_el2 sktalkgood_el2 skproposesolution_el2 skcompromise_el2 ///
 	skforgive_el2
make_index `negotiation_index_vars', indexname(negotiation_index_el2)



********************************************************************************
* Cheat! Fill in the _ec2 variables with leader data ***************************
********************************************************************************
/* 	When I make tables down the line, i want to be able to input one list of 
	variables, and then be able to run regressions for leaders and residents at 
	once. So I make the _ec2 indices the resident one for leaders. Remember that
	leaders and residents are mutually exclusive groups, so no data is being
	overwritten. This just means we need to be careful with using if statements
	whenever we do anything. 
*/
foreach sub in bias_index defection_index empathy_index ///
forum_choice_index managing_emotions_index mediation_index negotiation_index {
 		replace `sub'_ec2 = `sub'_el2 if (ENDLINE2_LEADER == 1)
 }

make_index ///
	bias_index_ec2 ///
	defection_index_ec2 ///
	empathy_index_ec2 ///
	forum_choice_index_ec2 ///
	managing_emotions_index_ec2 ///
	mediation_index_ec2 ///
	negotiation_index_ec2, indexname(all_cats_index_ec2)


********************************************************************************
* Add correct suffixes for resident and targeted resident data *****************
********************************************************************************
/* I'm not sure the global $ate_ctrls exists, but I'm too afraid to delete it. 
*/
foreach x in ///
	$ate_ctrls $ate_ctrls_l $comm_ctrls christian age land_size farm_size cashearn_imputed displa_rfugem	/// 
	jpc_attend minority under30 prgrsv_attitudes jpc_attend_risk_ls minortribe_assigned jpc_attend_highrisk_ls 	/// 
	money_resolution_type displaced refugee land_resolution_type viol_experienced 	///
	housetake_dum lndtake_dum lndhousetake_dum log_land_size log_farm_size land_size displa_rfugem landless ///
	farm_size farmless propdest_landconf viol_landconf threat_landconf ///
	female stranger yrs_edu noland ageover60 age40_60 age20_40 under30 wealthindex chiefrel_dup minority minortribe prog_ldr_beliefs ///
	mnyconf {
	
		cap local lbl: variable label `x'		
		cap local lbl: variable label `x'_et		
		cap local lbl: variable label `x'_ec
		cap local lbl: variable label `x'_el
		cap local lbl: variable label `x'_el2		
		cap local lbl: variable label `x'_ec2
		
		cap gen `x'=`x'_et if TARGETED_RESIDENT==1
		cap gen `x'=`x'_ec if ENDLINE_RESIDENT==1
		cap gen `x'=`x'_el if ENDLINE_LEADER==1
		cap gen `x'=`x'_ec2 if ENDLINE2_RESIDENT==1
		cap gen `x'=`x'_el2 if ENDLINE2_LEADER==1
							
		cap replace `x'=`x'_et if TARGETED_RESIDENT==1
		cap replace `x'=`x'_ec if ENDLINE_RESIDENT==1
		cap replace `x'=`x'_el if ENDLINE_LEADER==1 // LEADERS DONT HAVE ALL VARS THAT TRAINEES AND CITIZENS DO
		cap replace `x'=`x'_ec2 if ENDLINE2_RESIDENT==1
		cap replace `x'=`x'_el2 if ENDLINE2_LEADER==1
		
		cap la var `x' "`lbl'"
}


********************************************************************************
* Add value lables to money resolution variables *******************************
********************************************************************************
la values money_resolution_type money_resolution_type
la values land_resolution_type land_resolution_type			

foreach y in land_size farm_size cashearn_imputed displa_rfugem {
	local lab : var label `y'
	gen `y'hst = ln(`y'+((`y'^2)+1)^.5)
		la var `y'hst "Hst: `lab'"
}	



********************************************************************************
* Add miscellaneous variables **************************************************
********************************************************************************
/* 	Apologies for the miscellaneous section. It is bad practice. However this
	has been ported over from much messier and worse code. 
*/

	
* Indicator for resident or targeted resident **********************************

gen resident=cond(TARGETED_RESIDENT==1 | ENDLINE_RESIDENT==1 | ENDLINE2_RESIDENT==1,1,0 )

gen targ_or_leader=cond(TARGETED_RESIDENT==1 | ENDLINE_LEADER==1 | ENDLINE2_LEADER==1,1,0)					


* Respondent type **************************************************************

gen leader=(ENDLINE_LEADER==1) if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1
	la var leader "Leader"

gen trainee=(TARGETED_RESIDENT==1) if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 // used as control in pooled resident and targeted resident regressions
	la var trainee "Targeted resident"

* Displaced or refugee *********************************************************

gen displ_or_refugee = (displaced==1 | refugee==1)
	la var displ_or_refugee "Was displaced or a refugee"

* Town size ********************************************************************

replace ctownhh_el=133 if ctownhh_el==. & town=="Baylaybo" 
replace ctownpop_el=1388 if ctownpop_el==. & town=="Baylaybo" 

**NOTE: updated for the endline2
gen ctownhh_log_el2=log(ctownhh_el2)
la var ctownhh_log_el2 "Log of town population"


* small community dummies by quartile ******************************************
		
xtile quart = ctownpop_el2 if ENDLINE2_LEADER==1 | ENDLINE2_RESIDENT==1 | COMMLEVEL==1, nq(4) 

gen vsmall = (commcode==1050 | commcode==1312 | commcode==2290 | commcode==2850)

gen small = (quart==1) if quart!=.
	la var small "1 if community in 1st quartile for population"
	
gen small2 = (quart==2) if quart!=.
	la var small2 "1 if community in 2nd quartile for population"

gen small3 = (quart==3) if quart!=.
	la var small3 "1 if community in 3rd quartile for population"

gen small4 = (quart==4) if quart!=.
	la var small4 "1 if community in 4th quartile for population"
			

*placevar ctownhh_log_el2 small small2 small3 small4, after(quart)
drop quart		

********************************************************************************	
* Construct variables for Heterogeneity Analysis *******************************
********************************************************************************

* Make new binaries for community size and related to powerful person **********

	* Lives in a small community? **********************************************
	gen comm_small=0 
	replace comm_small=1 if small==1 | small2==1
	label var comm_small "indicator of below median size"

	* Related to a powerful person? ********************************************
	gen rltn_to_powerful=0
	replace rltn_to_powerful=1 if chiefrel_dup==1
	label var rltn_to_powerful "Are you related to a big person from before or after the war"


* For loop to make new variables ***********************************************
foreach y in female age40_60 age20_40 under30 cwealthindex_bc rltn_to_powerful minority minortribe {
	local lab : var label `y'
	gen assigned_`y' = assigned_ever * `y'
	la var assigned_`y' "`lab' * assigned_ever"
	gen treated_`y' = treated_ever * `y'
	la var treated_`y' "`lab' * treated_ever" 
}

* Make some dummies *************************************************************
gen cgpeace_dum_bc = cgpeace_bc != 0
label var cgpeace_dum_bc "Any peace group in town at baseline"
gen canypeace_dum_bc = canypeace_bc != 0 
label var canypeace_dum_bc "Community had peace education at basline"
gen cwealthindex_below_med_bc = 0 
sum cwealthindex_bc if ENDLINE_RESIDENT == 1, det
replace cwealthindex_below_med_bc = 1 if cwealthindex_bc < r(p50)


********************************************************************************
* Constructing new violence measures *******************************************
********************************************************************************

* Participation in violence ****************************************************
egen anyviol_el2 = rowmax(tribviol_dum_el2 strkviol_dum_el2 pvytheld_dum_el2 strkpeac_dum_el2 cfamlndcn_dum_el2 dtwnldcn_dum_el2  suspwitc_dum_el2 sasycutl_dum_el2)
	la var anyviol_el2 "Indicator for any violence (Table 7 col. 1-8)"
	 
egen sumviol_el2 = rowtotal(tribviol_dum_el2 strkviol_dum_el2 pvytheld_dum_el2 strkpeac_dum_el2 cfamlndcn_dum_el2 dtwnldcn_dum_el2  suspwitc_dum_el2 sasycutl_dum_el2), m
replace sumviol_el2 = . if missing(tribviol_dum_el2) & missing(strkviol_dum_el2) & !missing(cfamlndcn_dum_el2)
	la var sumviol_el2 "Overall violence indicator (0-9) (Table 7 col. 1-8)"

egen sasywitch_el2 = rowmax(suspwitc_dum_el2 sasycutl_dum_el2) 
	la var sasywitch_el2 "Witch killing or trial by ordeal"


* Indicators for money + land disputes *****************************************


* Making dummies?  what the fuck is going on here? 
gen unrsvl_u_ec2 = unrslv_lnd_conf_u_ec2
gen conf_u_ec2= anylndconf_u_ec2
gen mnyconflength1_u_st_ec2 = mnyconf_length1_u_ec2
gen unrslv_conf_u_ec2 = unrslv_lnd_conf_u_ec2
gen mnyunrslv_conf_u_ec2 = mnyconf_unrslv_u_ec2
gen mnyconf_u_ec2= mnyconf_ec2

* Disputes
* Max (0,1 indicator)
foreach var in conf_u_ec2 unrslv_conf_u_ec2 conf_freq_u_ec2 {
	egen lm_`var' = rowmax(`var' mny`var') if !missing(`var') | !missing(mny`var')
	la var lm_`var' "`var', land and money disputes"
}
 
* Mean (dispute length, months)
foreach var in conflength1_u_st_ec2 {
	egen lm_`var' = rowmean(`var' mny`var') if !missing(`var') | !missing(mny`var')
	la var lm_`var' "`var', land and money disputes"
}

* Violence
* Max (0,1 indicator)
foreach var in conf_any_u_ec2 conf_threat_u_ec2 conf_witch_u_ec2 conf_damage_u_ec2 conf_viol_u_ec2 {
	egen lm_`var' = rowmax(`var' mny`var') if !missing(`var') | !missing(mny`var')
	la var lm_`var' "`var', land and money disputes"
}

* Resolution
* Max (0,1 indicator)
foreach var in forum_lastsuc_c_ec2   forum_inf_suc_c_ec2 forum_lastsat_c_ec2  {
	egen lm_`var' = rowmax(`var' mny`var') if !missing(`var') | !missing(mny`var')
	la var lm_`var' "`var', land and money disputes"
}

* Mean (# of forums used)
foreach var in conf_forum_c_ec2  {
	egen lm_`var' = rowmean(`var' mny`var') if !missing(`var') | !missing(mny`var')
	la var lm_`var' "`var', land and money disputes"
}


* Any money or land fighting, conditional on dispute
gen lm_conf_any_c_ec2 = conf_any_u_ec2 if lm_conf_u_ec2==1 


* Indicators for money + land + gender disputes ********************************
gen wmconflength1_u_st_ec2 = wmconf_length1_u_ec2
gen wmunrslv_conf_u_ec2 = wmconf_unrslv_u_ec2
gen wmconf_u_ec2= wmconf_ec2

foreach x in la1palavalength_ec2 mopalavalength_ec2 wopalavalength_ec2 {
	replace `x' = 0 if missing(`x') & ENDLINE2_RESIDENT==1
}

* Disputes
* Max (0,1 indicator)
foreach var in conf_u_ec2 unrslv_conf_u_ec2 conf_freq_u_ec2 {
	egen lmg_`var' = rowmax(`var' mny`var' wm`var') if !missing(`var') | !missing(mny`var') | !missing(wm`var')
	la var lmg_`var' "`var', land, money, and gender disputes"
}

* Violence
* Max (0,1 indicator)
foreach var in conf_any_u_ec2 conf_threat_u_ec2 conf_witch_u_ec2 conf_damage_u_ec2 conf_viol_u_ec2 {
	egen lmg_`var' = rowmax(`var' mny`var' wm`var') if !missing(`var') | !missing(mny`var') | !missing(wm`var')
	la var lmg_`var' "`var', land, money, and gender disputes"
}

* Resolution
* Max (0,1 indicator)
foreach var in forum_lastsuc_c_ec2 forum_inf_suc_c_ec2 forum_othsuc_c_ec2  forum_lastsat_c_ec2 forum_inf_sat_c_ec2 forum_othsat_c_ec2 {
	egen lmg_`var' = rowmax(`var' mny`var' wm`var') if !missing(`var') | !missing(mny`var') | !missing(wm`var')
	la var lmg_`var' "`var', land, money, and gender disputes"
}

* Mean (# of forums used)
foreach var in conf_forum_c_ec2  {
	egen lmg_`var' = rowmean(`var' mny`var' wm`var') if !missing(`var') | !missing(mny`var') | !missing(wm`var')
	la var lmg_`var' "`var', land, money, and gender disputes"
	replace lmg_`var' = 0 if lmg_`var'<0 & !missing(lmg_`var')
}

* Any money, land or gender fighting, conditional on dispute
foreach var in conf_any_c_ec2 {
	egen lmg_`var' = rowmax(`var' mny`var' wm`var') if lmg_conf_u_ec2==1
	la var lmg_`var' "`var', land, money, and gender disputes"
}	

// ANY GENDER DISPUTE
gen finsult_et = finsltpt_et
gen mwconflict_et = 0 if TARGETED_RESIDENT==1&(!missing(minsult_et)|!missing(finsult_et))
foreach var in insult_et threatht_et pushhit_et kckdrag_et  {
	foreach s in m f {
		replace mwconflict_et=1 if `s'`var'==1 | `s'`var'==2 | `s'`var'==3
	}
}
la var mwconflict_et "reports m/f conflict"

** ANY CONFLICT (LAND + CONFLICT + GENDER )
egen lmg_conflict_ec = rowmax(anylndconf_alt2_ec mnyconf_ec mwconflict_et )
la var lmg_conflict_ec "Any conflict (L+M+G)"



********************************************************************************
* Dummies for the cause of conflict ********************************************
********************************************************************************
/* 	One observation in la1palavaabout is 0, meaning none. I just change this to
	"other"
*/
replace la1palavaabout_ec2 = 88 if la1palavaabout == 0

gen house_cause_boundaries 		= la1palavaabout_ec2 == 1
gen house_cause_inherit 		= la1palavaabout_ec2 == 2
gen house_cause_use 			= la1palavaabout_ec2 == 3
gen house_cause_other_issue 	= la1palavaabout_ec2 == 88

gen farm_cause_boundaries 		= la2palavaabout_ec2 == 1
gen farm_cause_inherit			= la2palavaabout_ec2 == 2
gen farm_cause_use 				= la2palavaabout_ec2 == 3
gen farm_cause_other_issue 		= la2palavaabout_ec2 == 88

gen other_cause_boundaries 		= la3palavaabout_ec2 == 1
gen other_cause_inherit 		= la3palavaabout_ec2 == 2
gen other_cause_use 			= la3palavaabout_ec2 == 3
gen other_cause_other_issue 	= la3palavaabout_ec2 == 88

gen mny_cause_other_payback		= mopalavaabout_ec2 == 1
gen mny_cause_i_payback			= mopalavaabout_ec2 == 2
gen mny_cause_other_stole		= mopalavaabout_ec2 == 3
gen mny_cause_i_stole			= mopalavaabout_ec2 == 4
gen mny_cause_other_cheated		= mopalavaabout_ec2 == 5
gen mny_cause_i_cheated			= mopalavaabout_ec2 == 6
gen mny_cause_other_issue		= mopalavaabout_ec2 == 88

gen wm_cause_sex 				= wopalavaabout_ec2 == 1
gen wm_cause_money				= wopalavaabout_ec2 == 2
gen wm_cause_disrespect			= wopalavaabout_ec2 == 3
gen wm_cause_listening			= wopalavaabout_ec2 == 4
gen wm_cause_stealing			= wopalavaabout_ec2 == 5
gen wm_cause_disobeying			= wopalavaabout_ec2 == 6
gen wm_cause_children			= wopalavaabout_ec2 == 7
gen wm_cause_nonsupport 		= wopalavaabout_ec2 == 8



********************************************************************************
* Construct variable on Political Connectedness Level **************************	
********************************************************************************
label def binary 0 "N" 1 "Y", replace

foreach var in currentlead chiefrelp pastlead chiefrelc {
	encode `var'_ec2, gen(`var'_b_ec2) label(binary)
}
gen polcnnct_ec2 =  currentlead_b_ec2 + chiefrelp_b_ec2 + pastlead_b_ec2 + chiefrelc_b_ec2
	la var polcnnct_ec2 "Political connection, 0-4"
	
qui sum polcnnct_ec2, d
gen polcnnct_b_ec2 = polcnnct_ec2>r(p50) if !missing(polcnnct_ec2)
	la var polcnnct_b_ec2 "Above median political connectedness"

gen a_polcnnct_b_ec2 = assigned*polcnnct_b_ec2
	la var a_polcnnct_b_ec2 "Assigned X above median pol cnnct"	


********************************************************************************
* Construct a variable about political district and ownership ******************
********************************************************************************

la de owner2 1 "Me" 2 "My family/household" 3 "My extended family" 4 "Other person (same tribe)" 5 "Other person different tribe" 97 "Don't know" 88 "N/A"
la val la1houseown owner2
la val la2farmown owner2


********************************************************************************
* Construct variables about plot-level violence ********************************
********************************************************************************	
local housenum 1
local farmnum 2
local othernum 3


foreach type in house farm other {
	* conflicts about land
	label def binary 0 "N" 1 "Y", replace
	encode la``type'num'palava_ec2, gen(conf_plot_`type') label(binary)
	la var conf_plot_`type' "`type' dispute"
	
	* unresolved conflicts 
	gen unresolve_`type' = -1*la``type'num'resolvelastsuc_c_ec2+1
	replace unresolve_`type'= 0 if missing(unresolve_`type') & ENDLINE2_RESIDENT==1
	la var unresolve_`type' "Unresolved dispute"
	
	* Number of months of dispute 
	gen conf_m_`type' = la``type'num'palavalength_ec2 if la``type'num'palavaunit_ec2 =="2-months"
	replace conf_m_`type' = la``type'num'palavalength_ec2 / (365/12) if la``type'num'palavaunit_ec2 =="1-Days"
	replace conf_m_`type' = la``type'num'palavalength_ec2 * 12 if la``type'num'palavaunit_ec2 =="3-Years"
	qui sum conf_m_`type' if conf_plot_`type' == 1, d 
	replace conf_m_`type'=r(p95) if conf_m_`type'>r(p95) & !missing(conf_m_`type') 
	replace conf_m_`type'=0 if missing(conf_m_`type') & ENDLINE2_RESIDENT==1
	la var conf_m_`type' "Conflict length (months), `type'"
	
	* Types of Violence
	label def binary 0 "N" 1 "Y", replace
	foreach v in threat witch damage viol {
		cap drop __00*
		encode la``type'num'palava`v'_ec2, gen(`v'_`type') label(binary)
		la var `v'_`type' "`type' dispute resulted in `v'"
		replace `v'_`type'= 0 if missing(`v'_`type') & ENDLINE2_RESIDENT==1
	}
	rename threat_`type' threaten_`type'
	rename witch_`type' witchcrft_`type'
	rename viol_`type' viole_`type'
	
	* Any threat or violence *
	gen anythreatviol_`type' = (threaten_`type'==1 |viole_`type'==1|witchcrft_`type'==1|damage_`type'==1) 
	la var anythreatviol_`type' "Any threat or violence in `type' dispute"
	gen anythreatviol_c_`type' = anythreatviol_`type' if conf_plot_`type'==1
	la var anythreatviol_c_`type' "Any threat or violence, conditional"
	
	* Resolved land dispute
	gen resolve_`type' = 0 if la``type'num'resolvelastsuc_ec2=="0-No"
	replace resolve_`type'= 1 if la``type'num'resolvelastsuc_ec2=="1-Yes"
	la var resolve_`type' "Resolved dispute, `type'"
	
	* Number of forums used
	foreach count in 1 2 3 4 oth {
		gen forum_`count'_`type' = (la``type'num'resolve`count'_ec2!= "88-N/A" ) if !inlist(la``type'num'resolve`count'_ec2, "", ".")
		la var forum_`count'_`type' "Went to `count' forum for `type' dispute"
	}
	egen forums_`type'= rowtotal(forum_1_`type' forum_2_`type' forum_3_`type' forum_4_`type' forum_oth_`type'),m
	replace forums_`type'=. if missing(resolve_`type')
	la var forums_`type' "Total # of forums used for `type' dispute"
	cap drop __00*
	
	* Resolved via informal mechanism
	label def tertiary 0 "0-No" 1 "1-Yes", replace
	foreach v in resolveagree  {
		encode la``type'num'`v'_ec2, gen(`v'_`type') label(tertiary)
		replace `v'_`type' = . if `v'_`type'==2
		la var `v'_`type' "Resolve via `v', `type'"
	}
	gen rslve_inf_`type' = resolveagree_`type'==1 if !missing(resolveagree_`type')  & inlist(resolve_`type',0,1)
	replace rslve_inf_`type' = 0 if missing(resolveagree_`type')  & inlist(resolve_`type',0,1)
	la var rslve_inf_`type' "Resolved `type' dispute by informal mechanism"
	
	* Satisfied with outcome
	qui gen satisfied_`type' = 1 if inlist(la``type'num'resolvelastsat_ec2,"1-Very satisfied", "2-Satisfied")
	replace  satisfied_`type' = 0 if inlist(la``type'num'resolvelastsat_ec2,"3-Not satisfied", "4-Not satisfied at all")
	
	* Used community forum as last
	gen forum_community_`type' = inlist(la``type'num'resolvelast_ec2,"10-Family, friends or neighbors", "14-Landlord", "16-Local NGOs", "23-Peace Committee") if la``type'num'palava_ec2=="Y"
	replace forum_community_`type' = 1 if inlist(la``type'num'resolvelast_ec2,"9-Elders","26-Sectional chief", "27-Town Chief", "3-Clan Chief") & la``type'num'palava_ec2=="Y"
	replace forum_community_`type' = 1 if inlist(la``type'num'resolvelast_ec2,"28-Traditional authority","30-quarter Chief") & la``type'num'palava_ec2=="Y"		
	replace forum_community_`type' = . if inlist(la``type'num'resolvelast_ec2,"88-N/A", "32-Other") & la``type'num'palava_ec2=="Y"		
	la var forum_community_`type' "Used community forum for `count' dispute"
}
 
 * Mean (dispute length, months)
egen conf_length_max_u_ec2 = rowmax(conf_m_house conf_m_farm conf_m_other) 
egen conf_length_mean_u_ec2 = rowmean(conf_m_house conf_m_farm conf_m_other) 

gen conf_length_max_c_ec2 = conf_length_max_u_ec2 if anylndconf_u_ec2 == 1
gen conf_length_mean_c_ec2 = conf_length_mean_u_ec2 if anylndconf_u_ec2 == 1


* Cap conflict length for money and gender conflict because we did so for land.
sum mnyconf_length1_u_ec2 if mnyconf_u_ec2 == 1, detail 
replace mnyconf_length1_u_ec2 = r(p95) if mnyconf_length1_u_ec2 > r(p95) & !missing(mnyconf_length1_u_ec2)


sum wmconf_length1_u_ec2 if wmconf_u_ec2 == 1, detail
replace wmconf_length1_u_ec2 = r(p95) if wmconf_length1_u_ec2 > r(p95) & !missing(wmconf_length1_u_ec2)

* Make the value for land, money, gener 
egen lmg_conf_length_max_u_ec2 =  rowmax(conf_m_house conf_m_farm conf_m_other mnyconf_length1_u_ec2 wmconf_length1_u_ec2) 
egen lmg_conf_length_mean_u_ec2 =  rowmean(conf_m_house conf_m_farm conf_m_other mnyconf_length1_u_ec2 wmconf_length1_u_ec2) 

gen lmg_conf_length_max_c_ec2 = lmg_conf_length_max_u_ec2 if  lmg_conf_u_ec2 == 1
gen lmg_conf_length_mean_c_ec2 = lmg_conf_length_mean_u_ec2 if  lmg_conf_u_ec2 == 1



foreach type in house farm {
	
	* Used statutory forum as last
	gen forum_statutory_`type' = -1*forum_community_`type'+1
	la var forum_statutory_`type' "Used statutory forum for `count' dispute"
	
	* Occupied/claimed during way
	foreach action in occupy claim  {
		encode la``type'num'`type'`action'_ec2, gen(`action'_`type') label(binary)
		la var `action'_`type' "`type' `action' during war"
	}
	* Palava due to war
	encode la``type'num'palavapostwar_ec2, gen(postwar_`type') label(binary)
	la var postwar_`type' "postwar `type' palava"
}


********************************************************************************
* Construct new variables about number of incidents ****************************
********************************************************************************
gen land_dispute_times_ec2 = farmconf_u_ec2 + houseconf_u_ec2 + otherconf_u_ec2

/*	Generate a new variable that is property damage + violence. 
	This variable might already exist somewhere, but I couldn't find the name. 
*/


********************************************************************************
* Construct variables about investment *****************************************
********************************************************************************
foreach type in house farm {
	* Land size
	gen size_`type' = la``type'num'`type'size_ec2
	replace size_`type'=la``type'num'`type'size_ec2*.25 if la``type'num'`type'unit=="3-Lots"
	replace size_`type'=la``type'num'`type'size_ec2*1.5 if la``type'num'`type'unit=="2-Tins of rice"
	replace size_`type'=la``type'num'`type'size_ec2*.75 if la``type'num'`type'unit=="4-Buckets"
	replace size_`type'=la``type'num'`type'size_ec2*1.5 if la``type'num'`type'unit=="5-Koon"
	
	
	la var size_`type' "Land size (acres), `type'" 	
	qui sum size_`type', d
		replace size_`type'=r(p90) if size_`type'>=r(p90) & !missing(size_`type')
}


********************************************************************************
* Construct variables relating to land security ********************************
********************************************************************************

* Locals make it easier to read the data ***************************************
local housenum 1
local farmnum 2
local othernum 3

* Index of security through rights *********************************************
label def how_sure 0 "Not sure at all" 1 "Not sure" 2 "Sure" 3 "Very sure"
foreach type in house farm {
	cap drop __00*
	* Secure boundaries
	qui gen secured_`type' = -1*la``type'num'`type'sec_ec2 + 4
	label values secured_`type' how_sure
	gen secured_dum_`type' = inlist(secured_`type', 2, 3)
	la var secured_`type' "Secure boundaries, `type'"

	* Appoint someone to inherit
	gen inherit_`type' = -1*la``type'num'`type'inherit_ec2 + 4
	label values inherit_`type' how_sure
	gen inherit_dum_`type' = inlist(inherit_`type', 2, 3)
	la var inherit_`type' "Ability to inherit, `type'"
	
	* Sell land for money
	gen sell_`type' = -1*la``type'num'`type'sell_ec2 + 4
	label values sell_`type' how_sure
	gen sell_dum_`type' = inlist(sell_`type', 2, 3)
	la var sell_`type' "Ability to sell, `type'"
	
	* Pawn land for money
	gen pawn_`type' = -1*la``type'num'`type'pawnfut_ec2 + 4
	label values pawn_`type' how_sure
	gen pawn_dum_`type' = inlist(pawn_`type', 2, 3)
	la var pawn_`type' "Ability to pawn, `type'"
	
	* Survey land
	gen survey_`type' = -1*la``type'num'`type'svyfut_ec2 + 4
	label values survey_`type' how_sure
	gen survey_dum_`type' = inlist(survey_`type', 2, 3)
	la var survey_`type' "Ability to survey, `type'"
	
	* Z-score
	foreach v in secured inherit sell pawn survey {
		qui sum `v'_`type' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
	}
	egen security_rights_`type' = rowtotal(Z_*), m 
	qui sum security_rights_`type'
	replace security_rights_`type' = (security_rights_`type'-r(mean))/r(sd)
	la var security_rights_`type' "Index of security through rights, `type'"
	drop Z_*
}

* Respondent-level index across 2 measures of plots ****************************
foreach v in house farm {
		qui sum security_rights_`v' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (security_rights_`v' - r(mean))/r(sd) if !missing(security_rights_`v')
	}
	egen security_rights = rowtotal(Z_*) if ENDLINE2_RESIDENT==1
	qui sum security_rights
	replace security_rights = (security_rights-r(mean))/r(sd)
	la var security_rights "index of security through rights, for respondent"
	drop Z_*


********************************************************************************
* Construct variables relating to use of Land **********************************
********************************************************************************

* Index of fallow land *********************************************************
foreach type in farm {
	cap drop __00*

	* Ever let the land rest
	gen landrestpast_`type' = la``type'num'`type'restever_ec2
	la var landrestpast_`type' "Ever let land rest, `type'"
	** I ADDED A NEW VARIABLE: WILL LET LAND REST
	gen landrestfut_`type' = la``type'num'`type'restfut_ec2
	la var landrestfut_`type' "Will let land rest in future, `type'"
	* Seasons to rest
	gen restseasons_`type' = la``type'num'`type'restseasons_ec2
	qui replace restseasons_`type' = 0 if missing(restseasons_`type') & inlist(landrestpast_`type',0,1)
	la var restseasons_`type' "# of seasons to rest, `type'"

	* No one would take
	gen securerest_`type'=-1*la``type'num'`type'take_ec2+4
	la var securerest_`type' "Secure if land rested, `type'"

	* Z-score
	foreach v in landrestpast landrestfut restseasons securerest {
		qui sum `v'_`type' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
	}
	egen fallowland_`type' = rowtotal(Z_*), m 
	la var fallowland_`type' "Index of fallow land, `type'"
	qui sum fallowland_`type'
	qui replace fallowland_`type' = (fallowland_`type'-r(mean))/r(sd)
	drop Z_*
}

********************************************************************************
* Construct variables related to improvement of land ***************************
********************************************************************************

* Investment in House **********************************************************

foreach type in house {
	
	* House improvement (0-1)
	gen improveexisting_`type' = la``type'num'`type'work_ec2
	la var improveexisting_`type' "Improved existing `type'"
	gen improvenew_`type' = la``type'num'`type'build_ec2
	la var improvenew_`type' "Build new `type'"
	
	* Number of days
	gen daysexisting_`type' = la``type'num'`type'workdys_ec2
	la var daysexisting_`type' "Days spent on existing `type'"
	gen daysnew_`type' = la``type'num'`type'builddys_ec2
	la var daysnew_`type' "Days spent on existing `type'"
	
	* Money spent
	gen spentexisting_`type' = la``type'num'`type'workmonusd_ec2
	la var spentexisting_`type' "USD spent on existing `type'"
	gen spentnew_`type' = la``type'num'`type'buildmonusd_ec2
	la var spentnew_`type' "USD spent on existing `type'"
	
	* Impute 0 for no improvement
	foreach v in improve days spent {
		foreach suffix in existing new {
			replace `v'`suffix'_`type' = 0 if la1nohousespot_ec2!=0 & missing(`v'`suffix'_`type') & ENDLINE2_RESIDENT==1
		}
	}


	* Any improvement on house

	gen improve_`type' = 0 if ENDLINE2_RESIDENT==1 & ( !missing(improvenew_`type') | !missing(improveexisting_`type'))
	foreach v in improvenew improveexisting {
		replace improve_`type' = 1 if `v'_`type'==1
	}
	
	* Money
	foreach v in spentnew spentexisting {
		qui sum `v'_`type' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
	}
	
	egen mny_`type' = rowtotal(Z_*), m 
	la var mny_`type' "USD `type' improvement, z-score"
	qui sum mny_`type'
	qui replace mny_`type' = (mny_`type'-r(mean))/r(sd)
	drop Z_*
	
	* Non-money
	foreach v in daysnew daysexisting {
		qui sum `v'_`type' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
	}
	
	egen nonmoney_`type' = rowtotal(Z_*), m 
	la var nonmoney_`type' "Other (non-money) `type' improvement, z-score"
	qui sum nonmoney_`type'
	qui replace nonmoney_`type' = (nonmoney_`type'-r(mean))/r(sd)
	drop Z_*
}

		
* Investment in Farm ***********************************************************
foreach type in farm {
	
	* Farm improvement (0-1)
	foreach c in gutter fence tree {
		gen improve`c'_`type' = la``type'num'`type'`c'_ec2
		la var improve`c'_`type' "Improved `c' in `type'"
	}
	
	rename improvegutter_`type' improvegut_`type'
	
	* Money spent
	foreach c in gut fence tree {
		gen spent`c'_`type' = la``type'num'`type'`c'mon_ec2
		la var spent`c'_`type' "USD spent on `c' in `type'"
	}
	
	*Acres/number of benefited land/trees
	foreach c in gut {
		gen acres`c'_`type' = la``type'num'`type'`c'land_ec2
		la var acres`c'_`type' "Acres affected, `c' in `type'"
	}
	
	foreach c in fence {
		gen acres`c'_`type' = la``type'num'`type'`c'bound_ec2
		la var acres`c'_`type' "`c' put up in `type'"
	}
	
	foreach c in tree {
		gen acres`c'_`type' = la``type'num'`type'`c'amt_ec2
		la var acres`c'_`type' "`c' planted in `type'"
	}
	
	
	* Impute 0 for no improvement
	foreach v in improve spent acres {
		foreach suffix in gut fence tree {
			replace `v'`suffix'_`type' = 0 if la``type'num'`type'size_ec2!=0 & missing(`v'`suffix'_`type') & ENDLINE2_RESIDENT==1
		}
	}
	
	gen improve_`type' = 0 if ENDLINE2_RESIDENT==1 & (!missing(improvegut_`type')|!missing(improvefence_`type') | !missing(improvetree_`type'))
	foreach v in improvegut improvefence improvetree {
		replace improve_`type' = 1 if `v'_`type'==1
	}

	
	* Money
	foreach v in spentgut spentfence spenttree {
		qui sum `v'_`type' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
	}
	
	egen mny_`type' = rowtotal(Z_*), m 
	la var mny_`type' "USD `type' improvement, z-score"
	qui sum mny_`type'
	qui replace mny_`type' = (mny_`type'-r(mean))/r(sd)
	drop Z_*
	
	* Non-money
	
	foreach v in acresgut acresfence acrestree {
		qui sum `v'_`type' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
	}
	egen nonmoney_`type' = rowtotal(Z_*), m 
	la var nonmoney_`type' "Other (non-money) `type' improvement, z-score"
	qui sum nonmoney_`type'
	qui replace nonmoney_`type' = (nonmoney_`type'-r(mean))/r(sd)
	drop Z_*
}

* Overall land improvement (house and farm) ************************************	
foreach type in house farm {
	foreach v in improve mny nonmoney {
			qui sum `v'_`type' if ENDLINE2_RESIDENT==1
			qui gen Z_`v' = (`v'_`type' - r(mean))/r(sd) if !missing(`v'_`type')
		}
		egen improvez_`type' = rowtotal(Z_*), m 
		la var improvez_`type' "All `type' improvement, z-score"
		qui sum improvez_`type'
		qui replace improvez_`type' = (improvez_`type'-r(mean))/r(sd)
		drop Z_*
}


* Repondent level improvement index ********************************************
foreach v in house farm {
		qui sum improvez_`v' if ENDLINE2_RESIDENT==1
		qui gen Z_`v' = (improvez_`v' - r(mean))/r(sd) if !missing(improvez_`v')
	}
	egen improvez = rowtotal(Z_*) if ENDLINE2_RESIDENT==1
	qui sum improvez
	replace improvez = (improvez-r(mean))/r(sd)
	la var improvez "Index of improvement, for respondent"
	drop Z_*
	

********************************************************************************
* Construct variables on years of ownershipt and strength of ownership *********
********************************************************************************

* Years of ownership ***********************************************************
local num_house 1
local num_farm 2

foreach type in house farm {
	
	gen ownyrs_`type' = la`num_`type''`type'yrs_ec2
	replace ownyrs_`type' = 0 if la`num_`type''`type'yrs_ec2<0 
	
	qui sum ownyrs_`type', d
	replace ownyrs_`type' = r(p95) if ownyrs_`type'>r(p95) & !missing(ownyrs_`type')
}

* How did they get the farm? ***************************************************
local num_house 1
local num_farm 2

foreach g in house farm {

	gen `g'_inherit = inlist(la`num_`g''`g'access, 1)
	gen `g'_request = inrange(la`num_`g''`g'access, 2,5)
	gen `g'_buyrent = inrange(la`num_`g''`g'access, 6,9)
	gen `g'_squat = inlist(la`num_`g''`g'access, 10)
	
	gen distenure_`g' = `g'_request ==1 | `g'_squat==1
	gen markettenure_`g' = `g'_request != 1 & `g'_squat!=1
}

* Who owns the farm? ***********************************************************
local num_house 1
local num_farm 2

foreach g in house farm {

	gen `g'_me = la`num_`g''`g'own== 1
	gen `g'_family = la`num_`g''`g'own== 2
	gen `g'_extendfamily = la`num_`g''`g'own == 3
	gen `g'_opersonsame = la`num_`g''`g'own == 4
	gen `g'_opersondiff = la`num_`g''`g'own == 5
	gen `g'_own = `g'_me==1
	gen `g'_notown = `g'_me!=1
	
	gen self_`g' = `g'_me==1 
	gen selffam_`g' = `g'_me==1 | `g'_family==1
	gen nonkin_`g' = `g'_opersonsame==1 | `g'_opersondiff==1
}


********************************************************************************
* Impute unresolved gender fights **********************************************
********************************************************************************
/* 	Don't know why this is all the way down here. 
*/
replace wmconf_unrslv_u_ec2 = 0 if missing(wmconf_unrslv_u_ec2) & ENDLINE2_RESIDENT==1


********************************************************************************
* small cleanings for the Endline 1 analysis ***********************************
********************************************************************************
/* 	We also report endline 1 effects in a few tables. So we have to make a few
	adjustments to get those to work. 
*/ 
	// % of town implemented for use in spillover analysis 
	gen resident_e1 =	cond(TARGETED_RESIDENT==1 | ENDLINE_RESIDENT==1,1,0)

********************************************************************************
/* 	Make a small correction to the districts for the 4 observations of leaders
	without a baseline district value. 
*/	
	replace district_bl = 4 if (ENDLINE2_LEADER == 1 & missing(district_bl))
	tab district_bl, gen(district_ec)






	gen lndconf = anylndconf_alt2_ec
	gen mny_unrslv_conf = unrslv_mny_conf_ec
	gen lnd_unrslv_conf = unrslv_lnd_conf_ec
	gen mny_rslv_conf= rslv_money_conf_ec
	gen lnd_rslv_conf = rslv_lnd_conf_ec
	gen mny_rslv_infrml = rslv_money_infrml_ec
	gen lnd_rslv_infrml = rslv_lnd_conf_infrml_ec
	gen mny_stsfd = mnyresfair_ec
	gen lnd_stsfd = satisfied_res_ec

	replace lndconf = anylndconf_alt2_et if TARGETED_RESIDENT == 1
	replace mny_unrslv_conf = unrslv_mny_conf_et if TARGETED_RESIDENT == 1
	replace lnd_unrslv_conf = unrslv_lnd_conf_et if TARGETED_RESIDENT == 1
	replace mny_rslv_conf= rslv_money_conf_et if TARGETED_RESIDENT == 1
	replace lnd_rslv_conf = rslv_lnd_conf_et if TARGETED_RESIDENT == 1
	replace mny_rslv_infrml = rslv_money_infrml_et if TARGETED_RESIDENT == 1
	replace lnd_rslv_infrml = rslv_lnd_conf_infrml_et if TARGETED_RESIDENT == 1
	replace mny_stsfd = mnyresfair_et if TARGETED_RESIDENT == 1
	replace lnd_stsfd = satisfied_res_et if TARGETED_RESIDENT == 1

	
	foreach var in conf _unrslv_conf  _rslv_conf _rslv_infrml _stsfd {
		* L+M+G
		egen lm`var' = rowmax(lnd`var' mny`var') if !missing(lnd`var') | !missing(mny`var')
		la var lm`var' "`var', land and money disputes"
		
	}
	
	gen sevlandconf_dummy_c_ec = sevlandconf_dummy_ec if anylndconf_alt2_ec==1 & resident_e1 == 1
	gen sevlandconf_dummy_c_et = sevlandconf_dummy_et if anylndconf_alt2_et==1 & resident_e1 == 1


// Small community dummies by quartile
		
	xtile quart_e1 = ctownpop_el if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 | COMMLEVEL==1, nq(4) 
	
	gen vsmall_e1 = (commcode==1050 | commcode==1312 | commcode==2290 | commcode==2850)
	
	gen small_e1 = (quart_e1==1) if quart_e1!=.
		
	gen small2_e1 = (quart_e1==2) if quart_e1!=.
	
	gen small3_e1 = (quart_e1==3) if quart_e1!=.

	gen small4_e1 = (quart_e1==4) if quart_e1!=.
				
	drop quart_e1

	replace vsmall 	= vsmall_e1  	if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 | COMMLEVEL==1
	replace small 	= small_e1   	if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 | COMMLEVEL==1
	replace small2 	= small2_e1  	if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 | COMMLEVEL==1
	replace small3 	= small3_e1   	if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 | COMMLEVEL==1
	replace small4 	= small4_e1  	if ENDLINE_LEADER==1 | ENDLINE_RESIDENT==1 | TARGETED_RESIDENT==1 | COMMLEVEL==1




	

/* 	This next section renames variables so that they match the observation they 
	correspond to. For example, anylndconf_alt2 has values for both residents and 
	targeted residents. So they create new variables full of misisng values. 

	I did not write this! This set of code is horrible and qualifies as "worst 
	practices". But I was a afraid to change this giant block for fear of something 
	not working. 
*/
foreach x in anylndconf_alt2 unrslv_lnd_conf propdest_landconf viol_landconf threat_landconf conflictwith_fam conflictwith_neigh conflictwith_strgr /// 
	conflictwith_oth rslv_lnd_conf satisfied_res rslv_lnd_conf_infrml rslv_lnd_conf_cust rslv_lnd_conf_frml rslv_lnd_conf_adm rslv_lnd_conf_oth rslv_lnd_conf_none /// 
	conflictover_boundary conflictover_inher conflictover_use conflictover_other landconf_propdest landconf_confviol landconf_threatviol mnyconf unrslv_money_conf /// 
	moneyconflict_fam moneyconflict_neigh moneyconflict_strgr moneyconflict_oth rslv_money_conf mnyresfair rslv_money_infrml rslv_money_cust rslv_money_frml rslv_money_adm ///
	rslv_money_oth rslv_money_none anylndconf_alt2 unrslv_lnd_conf propdest_landconf viol_landconf threat_landconf rslv_lnd_conf rslv_lnd_conf_infrml  ///
	satisfied_res anylndconf_alt2 unrslv_lnd_conf propdest_landconf satisfied_res log_farm_size business_land tree_assets hhqual_index /// 
	land_fiveyrs mnyconf unrslv_mny_conf rslv_money_conf rslv_money_infrml mnyresfair fights_dummy fightweap_dummy tribviol_el strkviol_el /// 
	youthelder_el strkpeac_el interfamlanddisp_el confothtown_el witchkilling_el sasycutl_el sasywitch_el magcourt1_court assertiveprogram_alt ///
	prgrsv_attitudes3 diffdiff_res_e confsolve_res_e nolike_res_e age male yrs_edu notbornintown excom disp_ref viol_experienced lndtake_dum /// 
	housetake_dum land_size noland secure_farm trainee conflictover_boundary_v2 conflictover_inher_v2 conflictover_use_v2 conflictover_other_v2 unrslv_lnd_over_boundary /// 
	unrslv_lnd_over_inher unrslv_lnd_over_use unrslv_lnd_over_other landconf_threatviol_v2 landconf_propdest_v2 landconf_confviol_v2 anylndconf_alt2 propdest_landconf ///
	viol_landconf threat_landconf sevlandconf_dummy unrslv_lnd_conf viol_landconf_dummy landconf_propdest landconf_confviol landconf_threatviol rslv_lnd_conf rslv_lnd_conf_infrml ///
	satisfied_res sprog_gendbeliefs smnrty_landbeliefs sno_ethnic_bias_alt intermarriage land_resolution_type money_resolution_type ///
	$ate_ctrls $ate_ctrls_l $comm_ctrls age land_size farm_size cashearn_imputed displa_rfugem	/// 
	jpc_attend minority under30 prgrsv_attitudes jpc_attend_risk_ls minortribe_assigned jpc_attend_highrisk_ls 	/// 
	money_resolution_type displaced refugee land_resolution_type viol_experienced 	///
	housetake_dum lndtake_dum lndhousetake_dum log_land_size log_farm_size land_size displa_rfugem landless ///
	farm_size farmless propdest_landconf viol_landconf threat_landconf ///
	female stranger ageover60 age40_60 age20_40 under30 wealthindex chiefrel_dup minority minortribe {

			cap local lbl: variable label `x'		
			cap local lbl: variable label `x'_et		
			cap local lbl: variable label `x'_ec		
			cap gen `x'=`x'_et if TARGETED_RESIDENT==1
			cap gen `x'=`x'_ec if ENDLINE_RESIDENT==1
			cap replace `x'=`x'_ec if ENDLINE_RESIDENT==1
			cap replace `x'=`x'_el if ENDLINE_LEADER==1 // LEADERS DONT HAVE ALL VARS THAT TRAINEES AND CITIZENS DO
			cap la var `x' "`lbl'"
	}


/* 	Add Endline 1 observations for some key Endline 2 outcome variables. This 
	will allow us to make a table with ITT estimates for both E1 and E2 at the
	same time. The link betweeen E1 variable and E2 variable was found using 
	the "Table - t2" excel table in the "output_excel" folder. I replace missing
	for some variables that we don't have any data on in Endline 1. Making sure
	that everything is missing for resident_e1 observations will  be crucual
	to making the table work.  


	Yes, adding the "_ec2" suffixes is confusing, since no other E1 data will 
	have that suffix. However they should never have had different names in 
	the first place. I am okay introducing this messiness. 
*/

replace anylndconf_u_ec2		=	anylndconf_alt2_ec 			if (ENDLINE_RESIDENT == 1)
replace unrslv_lnd_conf_u_ec2	=	unrslv_lnd_conf_ec 			if (ENDLINE_RESIDENT == 1)
replace conf_any_u_ec2			=	sevlandconf_dummy_ec 		if (ENDLINE_RESIDENT == 1)
replace conf_threat_u_ec2		=	threat_landconf_ec 			if (ENDLINE_RESIDENT == 1)
replace conf_damage_u_ec2		=	propdest_landconf_ec 		if (ENDLINE_RESIDENT == 1)
replace conf_viol_u_ec2			=	viol_landconf_ec 			if (ENDLINE_RESIDENT == 1)
replace conf_witch_u_ec2		=	. 							if (ENDLINE_RESIDENT == 1)
replace conf_any_c_ec2			=	sevlandconf_dummy_c_ec 		if (ENDLINE_RESIDENT == 1)
replace forum_lastsuc_c_ec2		=	rslv_lnd_conf_ec 			if (ENDLINE_RESIDENT == 1)
replace conf_forum_c_ec2		=	. 							if (ENDLINE_RESIDENT == 1)
replace forum_inf_suc_c_ec2		=	rslv_lnd_conf_infrml_ec 	if (ENDLINE_RESIDENT == 1)
replace forum_lastsat_c_ec2		=	satisfied_res_ec 			if (ENDLINE_RESIDENT == 1)
replace conf_any_c_ec2 			= 	sevlandconf_dummy_c_ec 		if (ENDLINE_RESIDENT == 1)
replace conf_threat_c_ec2 		= 	threat_landconf_ec 			if (ENDLINE_RESIDENT == 1 & anylndconf_u_ec2 == 1)
replace conf_damage_c_ec2 		= 	propdest_landconf_ec 		if (ENDLINE_RESIDENT == 1 & anylndconf_u_ec2 == 1)
replace conf_viol_c_ec2 		= 	viol_landconf_ec 			if (ENDLINE_RESIDENT == 1 & anylndconf_u_ec2 == 1)
replace conf_witch_c_ec2 		= 	. 							if (ENDLINE_RESIDENT == 1 & anylndconf_u_ec2 == 1)



replace anylndconf_u_ec2 		= 	anylndconf_alt2_et 			if (TARGETED_RESIDENT == 1)
replace forum_lastsuc_c_ec2		=	rslv_lnd_conf_et 			if (TARGETED_RESIDENT == 1) 
replace anylndconf_u_ec2		=	anylndconf_alt2_et 			if (TARGETED_RESIDENT == 1)
replace unrslv_lnd_conf_u_ec2	=	unrslv_lnd_conf_et 			if (TARGETED_RESIDENT == 1)
replace conf_m_house			=	.	 						if (TARGETED_RESIDENT == 1)
replace conf_any_u_ec2			=	sevlandconf_dummy_et 		if (TARGETED_RESIDENT == 1)
replace conf_threat_u_ec2		=	threat_landconf_et 			if (TARGETED_RESIDENT == 1)
replace conf_damage_u_ec2		=	propdest_landconf_et 		if (TARGETED_RESIDENT == 1)
replace conf_viol_u_ec2			=	viol_landconf_et 			if (TARGETED_RESIDENT == 1)
replace conf_witch_u_ec2		=	. 							if (TARGETED_RESIDENT == 1)
replace conf_any_c_ec2			=	sevlandconf_dummy_c_et 		if (TARGETED_RESIDENT == 1)
replace forum_lastsuc_c_ec2		=	rslv_lnd_conf_et 			if (TARGETED_RESIDENT == 1)
replace conf_forum_c_ec2		=	. 							if (TARGETED_RESIDENT == 1)
replace forum_inf_suc_c_ec2		=	rslv_lnd_conf_infrml_et 	if (TARGETED_RESIDENT == 1)
replace forum_lastsat_c_ec2		=	satisfied_res_et 			if (TARGETED_RESIDENT == 1)

replace conf_any_c_ec2 			= 	sevlandconf_dummy_c_et 		if (TARGETED_RESIDENT == 1)
replace conf_threat_c_ec2 		= 	threat_landconf_et 			if (TARGETED_RESIDENT == 1 & anylndconf_u_ec2 == 1)
replace conf_damage_c_ec2 		= 	propdest_landconf_et 		if (TARGETED_RESIDENT == 1 & anylndconf_u_ec2 == 1)
replace conf_viol_c_ec2 		= 	viol_landconf_et 			if (TARGETED_RESIDENT == 1 & anylndconf_u_ec2 == 1)
replace conf_witch_c_ec2 		= 	. 							if (TARGETED_RESIDENT == 1 & anylndconf_u_ec2 == 1)
/* 	The previous cleaning code does this replacement. I am not sure why. They 
	call these "erroneously missing values."

	Obviously, this is really bad, since we are imputing the value to our 
	outcome variable that would show the program working. Take note, though, 
	that the Endline 1 results have alrady been published at the time of me 
	writing this. This imputation only applied to Endline 1 data. 
*/
replace forum_lastsuc_c_ec2 = 1 if(missing(forum_lastsuc_c_ec2) &!missing(conf_any_c_ec2) & (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1))


/* 	Notice lmg_conf_any_u_ec2 and lmg_conf_any_c_ec2 
	Since we didn't ask about violence at for non-land disputes at Endline 1, we 
	Just use the same variables as above. As in we pretend that land-money
	is just land.	
*/



replace 	mnyconf_u_ec2 			= 	mnyconf_ec 				if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)

replace 	lmg_conf_u_ec2			=	lmconf					if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)
replace 	lmg_unrslv_conf_u_ec2	=	lm_unrslv_conf			if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)


replace 	lmg_forum_lastsuc_c_ec2	=	lm_rslv_conf			if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)
replace 	lmg_conf_forum_c_ec2	=	.						if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)
replace 	lmg_forum_inf_suc_c_ec2	=	lm_rslv_infrml			if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)
replace 	lmg_forum_lastsat_c_ec2	=	lm_stsfd				if (ENDLINE_RESIDENT == 1 | TARGETED_RESIDENT == 1)

/*
replace 	lmg_conf_u_ec2			=	lmconf					if (resident_e1 == 1)
replace 	lmg_unrslv_conf_u_ec2	=	lm_unrslv_conf_et		if (resident_e1 == 1)
replace 	lmg_conf_m				= 	. 						if (resident_e1 == 1)
replace 	lmg_conf_any_u_ec2		=	sevlandconf_dummy_et	if (resident_e1 == 1)
replace 	lmg_conf_any_c_ec2		=	sevlandconf_dummy_c_et	if (resident_e1 == 1)
replace 	lmg_forum_lastsuc_c_ec2	=	lm_rslv_conf_et			if (resident_e1 == 1)
replace 	lmg_conf_forum_c_ec2	=	.						if (resident_e1 == 1)
replace 	lmg_forum_inf_suc_c_ec2	=	lm_rslv_infrml_et		if (resident_e1 == 1)
replace 	lmg_forum_lastsat_c_ec2	=	lm_stsfd_et				if (resident_e1 == 1)
*/

********************************************************************************
* Make variable for money disputes + land disputes *****************************
********************************************************************************
// the _ec2 suffix is just a convention here. It includes e1 data as well. 
gen lmg_conf_times_ec2 = mnyconf_ec2 + anylndconf_u_ec2 if ENDLINE_RESIDENT == 1
replace lmg_conf_times_ec2 = mnyconf_ec2 + anylndconf_u_ec2 + wmconf_ec2 if ENDLINE2_RESIDENT == 1


gen conf_dam_violence = conf_damage_u_ec2 + conf_viol_u_ec2
label var conf_dam_violence "\quad Property damage + violence (land)"

gen conf_dam_violence_threat = conf_damage_u_ec2 + conf_viol_u_ec2 + conf_threat_u_ec2
label var conf_dam_violence_threat "\quad Threats + property damage + violence (land)"

egen conf_dam_violence_bin_u = rowmax(conf_damage_u_ec2 conf_viol_u_ec2)
label var conf_dam_violence_bin_u "\quad Property damage or violence in land dispute"

gen conf_dam_violence_bin_c = conf_dam_violence_bin_u if anylndconf_u_ec2 == 1
label var conf_dam_violence_bin_c "\quad Property damage or violence \tab"


gen lmg_conf_dam_violence = lmg_conf_damage_u_ec2 + lmg_conf_viol_u_ec2
label var conf_dam_violence "\quad Property damage + violence (land)"

gen lmg_conf_dam_violence_threat = lmg_conf_damage_u_ec2 + lmg_conf_viol_u_ec2 + lmg_conf_threat_u_ec2
label var conf_dam_violence_threat "\quad Threats + property damage + violence (land)"

egen lmg_conf_dam_violence_bin_u = rowmax(lmg_conf_damage_u_ec2 lmg_conf_viol_u_ec2)
label var lmg_conf_dam_violence_bin_u "\quad Property damage or violence in a land dispute"

gen lmg_conf_dam_violence_bin_c = lmg_conf_dam_violence_bin_u if lmg_conf_u_ec2 == 1
label var lmg_conf_dam_violence_bin_c "\quad Property damage or violence"


gen lmg_conf_threat_c_ec2 = lmg_conf_threat_u_ec2 if lmg_conf_u_ec2 == 1
	label var lmg_conf_threat_c_ec2 "\quad  Threats"

gen lmg_conf_viol_c_ec2 = lmg_conf_viol_u_ec2 if lmg_conf_u_ec2 == 1
	label var lmg_conf_viol_c_ec2 "\quad Violence"

gen lmg_conf_damage_c_ec2 = lmg_conf_damage_u_ec2 if lmg_conf_u_ec2 == 1
	label var lmg_conf_damage_c_ec2 "\quad Property damage"

gen lmg_conf_witch_c_ec2 = lmg_conf_witch_u_ec2 if lmg_conf_u_ec2 == 1
	label var lmg_conf_witch_c_ec2 "\quad Witchcraft \quad"


********************************************************************************
* Repeat the same process for community level violence variables ***************
********************************************************************************
			
		// Indicators for community-level disputes
		
		gen youthelder_el = cond(pvytheld_el>0 & pvytheld_el!=.,1,0) if ENDLINE_LEADER==1
			label var youthelder_el "Indicator: Any youth-elder disputes"				
		
		gen interfamlanddisp_el = cond(famlndcn_el>0 & famlndcn_el!=.,1,0) if ENDLINE_LEADER==1
			label var interfamlanddisp_el "Indicator: Any inter-family landdisputes"				

		gen confothtown_el = cond(dtwnldcn_el>0 & dtwnldcn_el!=.,1,0) if ENDLINE_LEADER==1
			label var confothtown_el "Indicator: Any conflicts with other towns disputes"				
			
		foreach y in tribviol_el strkviol_el strkpeac_el sasycutl_el witchkilling_el sasywitch_el {
			replace `y'=0 if `y'==. & ENDLINE_LEADER==1
			}
			
			
// 4.4 TREATMENT INTERACTIONS  -- VARIABLES MISSING NEED TO CHECK THIS

	foreach y in displ_or_refugee lndhousetake_dum viol_experienced female under30 minority twn_ldr minrty_ldr wmn_ldr yth_ldr oth_ldr eldr_ldr {
		gen assigned_`y'_`x'=`y'*assigned_ever
		gen treated_`y'_`x'=`y'*treated_ever
		}

 egen anyviol_el = rowmax(tribviol_el strkviol_el youthelder_el strkpeac_el interfamlanddisp_el confothtown_el witchkilling_el sasycutl_el)
 la var anyviol_el "Indicator for any violence (Table 7 col. 1-8)"
 
 egen sumviol_el = rowtotal(tribviol_el strkviol_el youthelder_el strkpeac_el interfamlanddisp_el confothtown_el witchkilling_el sasycutl_el), m
 la var sumviol_el "Overall violence indicator (0-9) (Table 7 col. 1-8)"
	


replace tribviol_dum_el2 =	tribviol_el			  	if (ENDLINE_LEADER == 1)
replace strkviol_dum_el2 =	strkviol_el			  	if (ENDLINE_LEADER == 1)
replace pvytheld_dum_el2 =	youthelder_el		  	if (ENDLINE_LEADER == 1)
replace strkpeac_dum_el2 =	strkpeac_el			  	if (ENDLINE_LEADER == 1)
replace cfamlndcn_dum_el2 =	interfamlanddisp_el	  	if (ENDLINE_LEADER == 1)
replace dtwnldcn_dum_el2 =	confothtown_el		  	if (ENDLINE_LEADER == 1)
replace suspwitc_dum_el2 =	witchkilling_el		  	if (ENDLINE_LEADER == 1)
replace sasycutl_dum_el2 =	sasycutl_el				if (ENDLINE_LEADER == 1)
replace sasywitch_el2    =	sasywitch_el			if (ENDLINE_LEADER == 1)
replace anyviol_el2      =	anyviol_el				if (ENDLINE_LEADER == 1)
replace sumviol_el2      =	sumviol_el				if (ENDLINE_LEADER == 1)	


********************************************************************************
* Make a log town size variable for endline 1 **********************************
********************************************************************************
gen ctownhh_log_el=log(ctownhh_el)

********************************************************************************
* Figure out which communities were dropped between Endline 1 and Endline 2 ****
********************************************************************************
preserve 
keep if ENDLINE2_RESIDENT == 1
bysort commcode: keep if _n == 1
gen was_not_dopped_ec2 = 1 
rename weight_ec2 dropping_weight_ec2
keep commcode was_not_dopped_ec2 dropping_weight_ec2
tempfile endline2_communities 
save `endline2_communities'
restore

merge m:1 commcode using `endline2_communities' 
replace was_not_dopped_ec2 = 0 if missing(was_not_dopped_ec2)
gen was_dropped_ec2 = was_not_dopped_ec2 != 1


gen weight_e1_e2 = weight_ec2
replace weight_e1_e2 = s_weight2 if resident_e1 == 1


********************************************************************************
* Label all variables **********************************************************
********************************************************************************
include do/label_vars

********************************************************************************
* Rename variables to make the reshape easier in the next step *****************
********************************************************************************
drop mny_cause_other_payback	
drop mny_cause_i_payback		
drop mny_cause_other_stole	
drop mny_cause_i_stole		
drop mny_cause_other_cheated	
drop mny_cause_i_cheated		
drop mny_cause_other_issue	


drop self_suff_bc
rename improvez_* 		z_improvement_*
rename improve_* 		improvement_*
rename mny_* 			monetary_improvement_*
rename secured_*		level_of_security_*
rename fallowland_* 	fallow_index_*
rename distenure_*		non_market_tenure_*
rename markettenure_* 	market_tenure_*
rename nonkin_*			non_kin_*
rename self_* 			ownership_self_*
rename selffam_* 		ownership_fam_*


********************************************************************************
* Save this dataset and never worry about this monstrous code again ************
********************************************************************************
save data/ready_analysis, replace

/********************************************************************************

*******************************************************************************/

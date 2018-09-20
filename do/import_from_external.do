/***************************************************************************
*			Title: PEACE-CoRE Master Analysis
*			Input: jpc_analysis.dta
*			Date: December 2013
****************************************************************************/

clear
cap clear matrix
set mem 500m
set more off
set maxvar 6000
tempfile trainee_end trainee_base comm_end_indiv comm_end_comm leader_end_indiv leader_end_comm leader_base_comm comm_base_comm comm_base_indiv tempdata skits lisgis comm_end2_indiv leader_end2_indiv leader_end2_comm
set matsize 800


/*****************************************************************************************************
* Table of Contents
1.0 CLEAN AND CONSTRUCTE DATA FROM RAW DATA
	1.1 CLEAN AND CONSTRUCT RESIDENT BASELINE DATA
	1.2 CLEAN AND CONSTRUCT LEADERS BASELINE DATA
	1.3 CLEAN AND CONSTRUCT TARGETED RESIDENT BASELINE DATA
	1.4 CLEAN AND CONSTRUCT LEADERS ENDLINE DATA 
	1.5 CLEAN AND CONSTRUCT COMMUNTIY ENDLINE DATA
	1.6 CLEAN AND CONSTRUCT TRAINEE ENDLINE DATA
	1.7 CLEAN AND CONSTRUCT SKITS ENDLINE DATA

2.0 CONSTRUCT MASTER DATASET BY MERGING AND APPENDING DATASETS
	2.1 PREP DATASETS
		2.1.1 RESIDENT ENDLINE
		2.1.2 RESIDENT BASELINE 
		2.1.3 TRAINE ENDLINE
		2.1.4 TARGETED RESIDENT BASELINE
		2.1.5 LEADER ENDLINE
		2.1.6 LEADER BASELINE
		2.1.7 SKITS ENDLINE
		2.1.8 HIGH RISK PREDICTION
		2.1.9 LISGIS ADMIN DATA
	
3.0 MERGE	
	3.1 Merge TARGETED RESIDENT endine and TARGETED RESIDENT baseline
	3.2 Append RESIDENT Endline and Leader Endline
	3.3 Merge in the community level variables (leaders, admin, lisgis, CORE prediction)

4.0 ORGANIZE VARIABLES
5.0 MISC CLEANING
6.0 MISC VAR CONSTRUCTION
7.0 TREATMENT VARIABLE CONSTRUCTIONS	
8.0 OUTLIERS 
9.0 IMPUTATION
10.0 LABELS FOR TABLES
******************************************************************************************************/

// Set global for user directory
	
	// Chris
	*gl JPC "/Users/chrisblattman/Dropbox/Research & Writing/Projects/IPA Liberia Peace CoRE/DATA"
	
	// Anselm
	*gl JPC "/Users/anselmrink/Dropbox/Blattman Research/IPA Liberia Peace CoRE/DATA"
	
	// Natalie
	*gl JPC "C:/Users/RA/Dropbox/IPA Liberia Peace CoRE/DATA"
	
	// Yuequan Guo
	*gl JPC "C:\Users\Yuequan Guo\Dropbox\IPA Liberia Peace CoRE\DATA"
	
	
	// Patryk Perkowski
	*gl JPC "C:\Users\pperkowski\Dropbox\IPA Liberia Peace CoRE\DATA"
	
	// Peter 
	gl JPC "C:\Users\PDeffebach\Dropbox\Chicago\IPA Liberia Peace CoRE\DATA"
	
	
	
	
	
// 1.0 CLEAN DATA FROM RAW DATA
/*

** BASELINE
	
	// 1.1 RESIDENT BASELINE DATA 
			
		* Clean baseline RESIDENT survey..
			* Runs off of merged raw data
			* Saves as comm_baseline_survey.dta
	
			do "$JPC/Baseline/Community/community_baseline_clean.do"
	
		* Construct baseline RESIDENT survey variables
			* Runs off of comm_baseline_survey.dta
			* Constructs variables
				
			do "$JPC/Baseline/Community/community_baseline_construct.do"
	
		
	// 1.2 CLEAN AND CONSTRUCT LEADERS BASELINE DATA
	
		// Clean baseline leader survey
			* Runs off of merged rawdata
			* Saves as "leaders_baseline_survey.dta"
			
		do "$JPC/Baseline/Leaders/leaders_baseline_clean.do"
		
		// Construct baseline leader variables
			* Runs off of leaders_baseline_survey.dta
			* Saves as "leaders_baseline_clean.dta
			
		do "$JPC/Baseline/Leaders/leaders_baseline_construct"
		
	
	// 1.3 CLEAN AND CONSTRUCT TARGETED RESIDENT BASELINE DATA	
		
		// Clean baseline TARGETED RESIDENT survey
			* Runs off of merged rawdata
			* Saves as "trainee_baseline_survey.dta"
		
		do "$JPC/Baseline/Trainees/trainee_baseline_clean.do"
		
		// Construct baseline TARGETED RESIDENT variables
		
			* Runs off of "trainee_baseline_survey.dta"
			* Saves as "trainee_baseline_clean.dta"
		
		do "$JPC/Baseline/Trainees/trainee_baseline_construct.do"
	
	
	// 1.4 CLEAN AND CONSTRUCT LEADERS ENDLINE DATA 
		
		// Clean endline leaders data
			* Insheets rawdata
			* Cleans data
		
		do "$JPC/Endline/Leaders/leaders_clean.do"
		
		// Construct endline leaders data
			* Constructs endline leader variables
			* Saves as leader_endline_clean.dta 
			
		do "$JPC/Endline/Leaders/leaders_endline_construct.do"
	
	// 1.5 CLEAN AND CONSTRUCT COMMUNTIY ENDLINE DATA
	
		// Clean endline RESIDENT data
			* Insheets rawdata
			* Cleans data
		
		do "$JPC/Endline/Community/comm_endline_clean.do"
		
		// Construct endline RESIDENT data
			* Constructs variables
			* Saves as comm_endline_clean.dta
			
		do "$JPC/Endline/Community/community_endline_construct.do"
	
	// 1.6 CLEAN AND CONSTRUCT TARGETED RESIDENT ENDLINE DATA
		
		// Clean endline TARGETED RESIDENT data
			* Insheets rawdata
			* Cleans data
		* Saves as trainee_endline_clean		
			
		do "$JPC/Endline/Trainees/trainee_endline_clean.do"
		
		// Construct endline TARGETED RESIDENT data
			* Constructs variables
			* Saves as trainee__endline_construct.dta
			
		do "$JPC/Endline/Trainees/trainee_endline_construct.do"
	
		
	// 1.7 CLEAN AND CONSTRUCT SKITS ENDLINE DATA
		* insheets raw skit data, cleans, constructions
		* saves as skits.dta
		
		do "$JPC/Endline/Skits/skits.do"
*/

************************************************
************** APPEND AND MERGE ****************
************************************************

// 2.1 PREP DATASETS
	
	// 2.1.1 RESIDENTS
	
		// RESIDET ENDLINE 1
	
			use "$JPC/Endline/Community/comm_endline_clean.dta", clear
		
			* Keep only constructed variables individual level variables
				keep START_INDIV - END_INDIV commcode surveyid resolutiontype
					drop _I_SHOCKS - reachpol_hrs_dum			// Drop unimportant variables from CORE project	
			
			* Rename all the variables with _ec suffix
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_ec
				}
				ren commcode_ec commcode 					// commcode is used to merge with other datasets below so varname must stay the same
		
			* Gen dummy for dataset 
				gen ENDLINE1=1
					la var ENDLINE1 "ENDLINE, 2010"
				gen ENDLINE_RESIDENT=1
					la var ENDLINE_RESIDENT "ENDLINE RESIDENT DATASET INDICATOR"
		
			ren surveyid_ec respid
			placevar START_INDIV_ec,f
			placevar END_INDIV_ec,l
			save "`comm_end_indiv'", replace 				// these individual level will for the base of the dataset to which targeted residents will be appended, and comm-level outcomes merged

		// Comm level outcomes d seperately and merged once all residents, targeted residents, and leaders are appended
		
			use "$JPC/Endline/Community/comm_endline_clean.dta", clear
		
			* Keep only constructed variables individual level variables
				keep START_COMM - END_COMM commcode community 
				bysort commcode: drop if _N!=_n		

			* Rename all the variables with _ec suffix
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_ec
				}
				ren commcode_ec commcode // commcode is used to merge with other datasets below so varname must stay the same
				ren community_ec community 
				placevar START_COMM_ec,f
				placevar END_COMM_ec,l
				sort commcode
		
			save "`comm_end_comm'", replace 				// Comm level outcomes saved seperately and merged once all residents, targeted residents, and leaders are appended
		
		// RESIDENT ENDLINE 2
		
			use "$JPC/Endline 2/Residents/data/residents_endline2_clean_test.dta", clear
		
			* Keep only constructed variables individual level variables
				*keep START_INDIV - END_INDIV partid commcode 
					
			* Rename all the variables with _ec2 suffix
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_ec2
				}
				ren commcode_ec2 commcode 				// commcode is used to merge with other datasets below so varname must stay the same
				gen respid=partid
				destring respid, force replace
		
			* Gen dummy for dataset 
				gen ENDLINE2=1
					la var ENDLINE2 "ENDLINE, 2013"
				gen ENDLINE2_RESIDENT=1
					la var ENDLINE2_RESIDENT "ENDLINE 2 RESIDENT DATASET INDICATOR"
		
	
			placevar START_INDIV_ec2,f
			placevar END_INDIV_ec2,l
			
			** 4 dropped communities were surveyed by GG team
			drop if commcode==1260 | commcode==1420 | commcode==1440 | commcode==1460
			
			save "`comm_end2_indiv'", replace 				// these individual level will for the base of the dataset to which targeted residents will be appended, and comm-level outcomes merged
		
** note: no resident community-level variables yet

		// RESIDENT BASELINE 

		use "$JPC/Baseline/Community/comm_baseline_clean.dta", clear
			
			* Keep only constructed variables individual level variables
				keep START_INDIV - END_INDIV commcode surveyid gpeace

			* Rename all the variables 
				
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_bc
				}
				
				ren commcode_bc commcode
				ren surveyid_bc respid
			
			* Gen dummy for dataset 
				gen BASELINE=1
					la var BASELINE "BASELINE"
				gen BASELINE_RESIDENT=1
					la var BASELINE_RESIDENT "BASELINE RESIDENT INDICATOR"
		
			placevar START_INDIV_bc,f
			placevar END_INDIV_bc,l
				
		save "`comm_base_indiv'", replace

		use "$JPC/Baseline/Community/comm_baseline_clean.dta", clear
			
			* Keep only constructed variables individual level variables
				keep START_COMM - END_COMM commcode 
				bysort commcode: drop if _N!=_n		

				* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_bc
				}
				ren commcode_bc commcode
				sort commcode
			
			placevar START_COMM_bc,f
			placevar END_COMM_bc,l
				
			save "`comm_base_comm'", replace
		
	// 2.1.2 TARGETED RESIDENT (TRAINEES)
	
		// TRAINEES ENDLINE 1
	
		use "$JPC/Endline/Trainees/trainee_endline_clean.dta", clear
			* Keep only constructed variables 
				*keep START - END baselineid commcode endlineid wrong_base 
	
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_et
				}	
				
				ren baselineid_et baselineid
				ren commcode_et commcode
				ren endlineid_et respid 
			
			* Gen dummy for dataset 
				gen ENDLINE1=1
					la var ENDLINE1 "ENDLINE, 2010"
				gen TARGETED_RESIDENT=1
					la var TARGETED_RESIDENT "TARGETED RESIDENT DATASET INDICATOR"

			placevar START_INDIV_et,f
			placevar END_INDIV_et,l
			
		save "`trainee_end'", replace
		
		// BASELINE
		
		* Variables for attrition regressions: b_edulevel b_age b_male b_famsupport b_grpleader b_distress2 b_health_index b_headisab b_nonfarm_occ		
		
		use "$JPC/Baseline/Trainees/trainee_baseline_clean",clear
		keep START-END baselineid commcode resptype
			
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_bt
				}	
				
				ren baselineid_bt baselineid
				ren commcode_bt commcode
			
			* Gen dummy for dataset 
				gen BASELINE=1
					la var BASELINE "TARGETED BASELINE"
			
			placevar START_INDIV_bt,f
			placevar END_INDIV_bt,l
			
			sort baselineid
		
		save "`trainee_base'", replace 
		
	// 2.1.3 LEADERS
	
		// LEADER ENDLINE 1
	
		use "$JPC/Endline/Leaders/leader_endline_clean.dta", clear
		
			* Keep only constructed variables
				keep START_INDIV - END_INDIV commcode surveyid tribviol strkviol pvytheld strkpeac famlndcn dtwnldcn sasycutl sasycutlnum witchkilling 
		
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_el	
				}	
			
			ren commcode_el commcode
			ren surveyid_el respid 
				
			* Gen dummy for dataset
				gen ENDLINE1=1
					la var ENDLINE1 "ENDLINE, 2010"
				gen ENDLINE_LEADER=1
					la var ENDLINE_LEADER "ENDLINE LEADER INDICATOR"
			
			placevar START_INDIV_el,f
			placevar END_INDIV_el,l
			
		save "`leader_end_indiv'", replace		
		
		use "$JPC/Endline/Leaders/leader_endline_clean.dta", clear
		
			* Keep only constructed variables
				keep START_COMM - END_COMM commcode 
				bysort commcode: drop if _N!=_n		
		
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_el
				}	

				ren commcode_el commcode
				sort commcode

			placevar START_COMM_el,f
			placevar END_COMM_el,l
				
		save "`leader_end_comm'", replace
		
		// ENDLINE 2
		
		use "$JPC/Endline 2/Leaders/data/leaders_endline2_clean.dta", clear
		
			* TEMPORARY - KEEP LEADER ATTITUDES, NORMS AND SKILLS
			* Keep only constructed variables
				keep notext1-skcooltemperothers START_INDIV - END_INDIV partid commcode
				
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_el2	
				}	
			
			ren commcode_el2 commcode
			gen respid=partid
				destring respid, force replace
				
			* Gen dummy for dataset
				gen ENDLINE2=1
					la var ENDLINE2 "ENDLINE, 2013"
				gen ENDLINE2_LEADER=1
					la var ENDLINE2_LEADER "ENDLINE 2 LEADER INDICATOR"
			
			placevar START_INDIV_el2,f
			placevar END_INDIV_el2,l
			
		save "`leader_end2_indiv'", replace	
		
		use "$JPC/Endline 2/Leaders/data/leaders_endline2_clean.dta", clear
		
			* Keep only constructed variables
				keep START_COMM - END_COMM commcode partid
				bysort commcode: drop if _N!=_n		
		
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_el2
				}	
			ren commcode_el2 commcode
			gen respid=partid
				destring respid, force replace
			sort commcode
			placevar START_COMM_el2,f
			placevar END_COMM_el2,l
				
		save "`leader_end2_comm'", replace
		
		// BASELINE
			* Note: All baseline leader vars are merged at the COMMUNITY level--therefore, no individual level variables should be merged

		use "$JPC/Baseline/Leaders/leaders_baseline_clean.dta",clear
		
			* Keep only constructed variables
				keep START_COMM - END_COMM district commcode 
				bysort commcode: drop if _N!=_n		
		
			* Rename all the variables 
				unab vlist: _all
				foreach x of varlist `vlist' {
					ren `x' `x'_bl
				}	
				ren commcode_bl commcode
					
			sort commcode
		save "`leader_base_comm'", replace

	
	// 2.1.4 SKITS ENDLINE

		use "$JPC/Endline/Skits/jpc_skit_data.dta", clear
		
		gen START_SKIT=.
		la var START_SKIT "============= SKIT DATA ===================="
		placevar START,f
		
		foreach x of varlist START _ADMIN_INFO - county town - resolution_score {
			rename `x' `x'_es
		}
		
		* drop string vars
		drop enumname_es town_es quarter_es
		gen END_SKIT_es=.
		la var END_SKIT_es "============ END SKIT DATA ====================="
		sort commcode
		save "`skits'",replace


	// 2.1.5 LISGIS ADMIN DATA

		* Note: vars not well labeled because we don't have a codebook for the lisgis data

			use "$JPC/Admin/data/LISGIS data for JPC communities.dta",clear
			gen LISGIS_START=.
			la var LISGIS_START "==== ENDLINE LISGIS DATA ====="
			replace commcode=3400 if name_wsc50=="Karnwee (1)"
			ren ccode2k4c2 ccode
			ren dcode_2k4c4 dcode
			placevar LISGIS_START,f
			
			gen END_LISGIS=.
			sort commcode
			
			save "`lisgis'",replace
		
	
// 3.0 MERGE	

	// 3.1 Merge TARGETED RESIDENT endine and TARGETED RESIDENT baseline

		use "`trainee_end'", clear
		sort baselineid
		merge baselineid using "`trainee_base'", _merge(_merge_traineeendbas)
			label var _merge_traineeendbas "1 if only endline, 2 in only in baseline"
			
		ta _merge_traineeendbas
		
		* replace respid with baselineid if unfound at endline
		replace respid=baselineid if _merge_traineeendbas==2
		drop baselineid

	// 3.2 Append RESIDENT Endline and Leader Endline
		
		* Append RESIDENT Endline
			append using "`comm_end_indiv'"
		
		* Append RESIDENT Endline 2
			append using "`comm_end2_indiv'"

		* Append Leader Endline
			append using "`leader_end_indiv'" 
			
		* Append Leader Endline 2
			append using "`leader_end2_indiv'"

		* Append RESIDENT Baseline Individual
			append using "`comm_base_indiv'"

			
	placevar respid TARGETED_RESIDENT ENDLINE_RESIDENT ENDLINE2_RESIDENT ENDLINE2_LEADER BASELINE_RESIDENT ENDLINE_LEADER ENDLINE2_RESIDENT ENDLINE2_LEADER,f

	
	// 3.3 Merge in the community level variables (community endline and baseline, leaders baseline and endline, admin, lisgis, CORE prediction)		
		
		* Merge in the RESIDENT endline
			sort commcode
			merge m:1 commcode using "`comm_end_comm'", gen(_merge_comm_endline)
		
		* Merge in the RESIDENT baseline
			sort commcode
			merge m:1 commcode using "`comm_base_comm'", gen(_merge_comm_baseline)

		* Merge in the Leader endline
			sort commcode
			merge m:1 commcode using "`leader_end_comm'", gen(_merge_leader_endline)
		
		* Merge in the Leader baseline
			sort commcode
			merge m:1 commcode using "`leader_base_comm'", gen(_merge_leader_baseline)
		
		* Merge in Leader endline 2 
			sort commcode
			merge m:1 commcode using "`leader_end2_comm'", gen(_merge_leader_endline2)
		
		* Merging the adm data
			sort commcode	
			merge m:1 commcode using "$JPC/Admin/data/jpc_adm.dta", gen(_merge_adm)
				
		* Merging the LISGIS data
			sort commcode	
			merge m:1 commcode using "`lisgis'", gen(_merge_LISGIS)
		
		* Merging the SKITS data
			sort commcode	
			merge m:1 commcode using "`skits'", gen(_merge_skits)

		* Merging E2 sample data
			sort commcode
			merge m:1 commcode using "$JPC/Endline/Community/dropped.dta", gen(_merge_dropped)
			
			*drop1 and e2_weight1 were not used
				drop drop1 e2_weight1
				ren drop2 drop_ec2
					la var drop_ec2 "if dropped in endline 2 due to logistic reasons, 1; otherwise, 0"
				ren e2_weight2 weight_ec2
					la var weight_ec2 "weights adjusted for the dropped communities in endline 2"

	
// 4.0 ORGANIZE VARIABLES

		bys commcode: gen count = _n
		gen COMMLEVEL = count==1
			drop count
			la var COMMLEVEL "COMMUNITY LEVEL DATASET"
			placevar COMMLEVEL, after(ENDLINE_LEADER)
		
	* Identify dataset 
		
		gen META_DATA=.
			la var META_DATA "================== META DATA =================="
		gen IDENTIFICATION = .
			la var IDENTIFICATION "================== IDENTIFICATION =================="
			placevar META_DATA IDENTIFICATION,f		
			
	// Re-order dataset as needed
	
	* USERS TAKE NOTE!
	
		* Order: 
				* 1. Treatment data 										// comm-level
				* 2. Resident Endline 										// individual level
				* 3. Targeted resident endline and baseline		 			// individual level
				* 4. Leader Endline 										// individual level
				* 5. Resident Endline 2										// individual level
				* 6. Leader Endline 2										// individual level
				* 7. Resident baseline 										// individual level
				
				* 8. Resident endline										// comm-level
** note: Resident community-level variables?
				* 9. Leader endline											// comm-level
** note: Leader community-level variables?
				* 10. Resident baseline										// comm-level
				* 11. Leader baseline										// comm-level
				* 12. LISGIS												// comm-level
				* 13. SKITS													// comm-level


		* 1. Treatment data 												// comm-level				
			placevar START_ADMIN-END_ADMIN, after(COMMLEVEL)				

		* 2. Resident Endline 												// individual level
			placevar START_INDIV_ec- END_INDIV_ec, after (END_ADMIN)		

		* 3. Targeted resident endline and baseline		 					// individual level
			placevar START_INDIV_et - END_INDIV_bt, after (END_INDIV_ec)		

		* 4. Leader Endline 												// individual level
			placevar START_INDIV_el - END_INDIV_el, after(END_INDIV_bt)				

		* 5. Resident Endline 2												// individual level
			placevar START_INDIV_ec2- END_INDIV_ec2, after (END_INDIV_el)		

		* 6. Leader Endline 2 												// individual level
			placevar START_INDIV_el2 - END_INDIV_el2, after(END_INDIV_ec2)				
			
		* 7. Resident baseline 												// individual level
			placevar START_INDIV_bc - END_INDIV_bc, after (END_INDIV_el2)			

		* 8. Resident endline												// comm-level
			placevar START_COMM_ec-END_COMM_ec, after (END_INDIV_bc)

		* 9. Leader endline													// comm-level
			placevar START_COMM_el-END_COMM_el, after (END_COMM_ec)

		* 10. Resident baseline												// comm-level
			placevar START_COMM_bc-END_COMM_bc, after (END_COMM_el)

		* 11. Leader baseline												// comm-level
			placevar START_COMM_bl-END_COMM_bl, after (END_COMM_bc)

		* 12. LISGIS														// comm-level
			placevar LISGIS_START-END_LISGIS, after (END_COMM_bl)

		* 13. SKITS															// comm-level
			placevar START_SKIT_es-END_SKIT_es, after (END_LISGIS)
		
	save "$JPC/Analysis/PEACE/Data/jpc_analysis_test.dta",replace	

	
// 5.0 CLEANING
		
	* Assign respondent types to those TARGETED RESIDENTS surveyed at endline but NOT at baseline data
	
		* Note: Respondent type is documented ONLY in the baseline survey. 
		* Therefore we do not have respondent types for those 
		* below not surveyed at baseline. Here, we deduce respondent type, providing justification for each case
		
		* 2 other respondents are infln and elder, thus the 3rd is problematic
			replace resptype_bt=2 if respid==72407634
		* 2 other respondents infln and problematic, thus 3rd is elder
			replace resptype_bt=1 if respid==75680633
		* 2 other respondents elder and infln, thus 3rd is problematic
			replace resptype_bt=2 if respid==73608798
		* 2 other respondents elder and problematic person
			replace resptype_bt=3 if respid==72928744
		* 2 other respondents elder and problematic person						
			replace resptype_bt=3 if respid==76633628			
		* 2 other respondents infln and problematic, thus 3rd is elder
			replace resptype_bt=1 if respid==72838278		
		* other respondents elder and problematic			
			replace resptype_bt=3 if respid==75082389		
		* Note: for commcode 1082, wrong TARGETED RESIDENTs at baseline, therefore no resptype_bt data
		* ID 72737952: Other TARGETED RESIDENTs are elder and problematic
			replace resptype_bt=3 if respid==72737952
		* ID 73977255: Other TARGETED RESIDENTs are ifln and problematic
			replace resptype_bt=1 if respid==73977255
		* ID 74657357: Other TARGETED RESIDENT trainee is problematic. another baselineid without resptype_bt-- significantly younger, assumed infln
			replace resptype_bt=1 if respid==74657357
		* ID 74656452: Other TARGETED RESIDENTs are elder and problematic (see 74657357, above)
			replace resptype_bt=3 if respid==74656452
		* ID 75158601: oldest TARGETED RESIDENT assumed elder
			replace resptype_bt=1 if respid==75158601
		* ID 75158889: youngest TARGETED RESIDENT (18) assumed problematic
			replace resptype_bt=2 if respid==75158889
		* ID 75158875: middle aged male TARGETED RESIDENT assumed influential
			replace resptype_bt=3 if respid==75158875			
		* ID 75161546: oldest TARGETED RESIDENT assumed elder
			replace resptype_bt=1 if respid==75161546
		* ID 75166338: youngest TARGETED RESIDENT (57) assumed problematic
			replace resptype_bt=2 if respid==75166338
		* ID 77531575: middle aged male TARGETED RESIDENT assumed influential
			replace resptype_bt=3 if respid==77531575
		* Respondent 85 yrs old, 1 TARGETED RESIDENT at baseline was a influential person, the 3rd TARGETED RESIDENT not surveyed at baseline
			replace resptype_bt=1 if respid==72930502 
		* 2 other respondents elder and problematic person						
			replace resptype_bt=3 if respid==76894145	
			* other respondents elder and 55 yr/o female, assuming problematic
			replace resptype_bt=2 if respid==73278905	
		* 1 other respondent elder, this one assumed infln
			replace resptype_bt=3 if respid==73285848	
			* ID 74812691 eldest, thus elder	
			replace resptype_bt=1 if respid==74812691 
		* ID 74817259 youngest male, thus ASSUMED problematic		
			replace resptype_bt=2 if respid==74817259 
			replace resptype_bt=3 if respid==74814602		
	

// 6.0 VARIABLE CONSTRUCTION

	// 1 if unfound at endline
		gen unfound=(_merge_traineeendbas==2) if _merge_traineeendbas!=.
			la var unfound "1 if unfound at endline"
			placevar unfound, after( START_INDIV_et)

		
	// Break out TARGETED RESIDENT respondent type
		gen elder= (resptype_bt==1) if resptype_bt!=.
			label var elder "Elder TARGETED RESIDENT"
		gen trbl_mkr= (resptype_bt==2) if resptype_bt!=.
			label var trbl_mkr "Troublesome TARGETED RESIDENT"
		gen infl_prsn= (resptype_bt==3) if resptype_bt!=.
			label var infl_prsn "Influential TARGETED RESIDENT"

		placevar elder trbl_mkr infl_prsn, after( START_INDIV_et)


	// Baseline war exposure data used for TARGETED RESIDENTS (a panel) b.c. war exposure not asked at endline
		
		gen displa_rfugem_et=displa_rfugem_bt 					
		gen disp_ref_et=disp_ref_bt	
		gen displaced_et=displaced_bt 
		gen refugee_et=refugee_bt 
		gen excom_et=excom_bt	
		gen viol_experienced_et=viol_experienced_bt		
		gen minortribe_et=(tribe_dup_et!=cmajortribe_ec) if TARGETED_RESIDENT==1 
			placevar displa_rfugem_et disp_ref_et displaced_et excom_et refugee_et viol_experienced_et viol_experienced_et minortribe_et, after( _I_COVARIATES_et)
			
		
	// District Dummies
	
		replace dcode=3308 if dcode==. & district==9
		replace dcode=1508 if dcode==. & district==10
		replace dcode=2114 if dcode==. & district==7
		tab dcode, gen(district)
		
	// New Identifier
		
		gen survey=.
		replace survey=1 if BASELINE==1
		replace survey=2 if ENDLINE1==1
		replace survey=3 if ENDLINE2==1
			la var survey "1=baseline survey, 2=2010 endline survey, 3=2013 endline survey"
		
		gen surveytype=.
		replace surveytype=1 if !mi(_merge_traineeendbas)
		replace surveytype=2 if ENDLINE_RESIDENT==1 | ENDLINE2_RESIDENT==1 | BASELINE_RESIDENT==1
		replace surveytype=3 if ENDLINE_LEADER==1 | ENDLINE2_LEADER==1
			la var surveytype "1=trainees, 2=residents, 3=leaders" //note: due to Row456, the surveytype indicator cannot distinguish between resident and leader at the baseline survey.
		
		** two pairs of obs from Endline1 have the same respid
		replace respid=73449644 if respid==73449643 & town=="Beezohn"
		replace respid=74387493 if respid==74387492 & town=="Boundary"
		
		tostring survey surveytype respid, replace
		gen id2013=survey+surveytype+respid
			la var id2013 "unique identifier, 2013"

/*
// 10.0 labels for tables
	
	la var womens_rights_et "Index of pro women's rights attitudes"
	la var human_rights_et "Index of pro human rights attitudes"
	la var mnrty_rights_et "Index of pro minority rights attitudes"
	la var no_ethnic_bias_et "Index of low ethnic bias"
	
	la var prog_gendbeliefs_ec "Index of pro women's rights attitudes"
	la var mnrty_landbeliefs_ec "Index of pro minority rights attitudes"
	la var no_ethnic_bias_alt_ec "Index of low ethnic bias"
	la var prog_ldr_beliefs_ec "Index of progressive political attitudes"
	la var prgrsv_attitudes_ec "Index of overall progressive attitudes"

	la var prog_gendbeliefs_el "Index of pro women's rights attitudes"
	la var mnrty_landbeliefs_el "Index of pro minority rights attitudes"
	la var no_ethnic_bias_alt_el "Index of low ethnic bias"
	la var prog_ldr_beliefs_el "Index of progressive political attitudes"
	la var prgrsv_attitudes_el "Index of overall progressive attitudes"
 
	la var statcitizen_et "Understands statutory citizenship rights"
	la var pol_knwldg_et "Index of politcal knowledge"

	la var assertiveprogram_alt_et "Additive index of all dispute resolution norm questions (higher = more ADR)"			
	la var assertiveprogram_alt_el "Additive index of all dispute resolution norm questions (higher = more ADR)"			

	la var assertiveprogram_et "Additive index of all dispute resolution norm questions (higher = more ADR)"			
	la var assertiveprogram_el "Additive index of all dispute resolution norm questions (higher = more ADR)"						
	
	la var civic_safe_comm_et "Perceive safety and civility in community"
	la var equity_comm_et "Perceive equity & integrity in comm. leadership"
	la var comm_ldrshp_empwrment_et "Perceive integrity in nat'l gov't (gol, courts, lnp) and unmil"
	la var civic_safe_comm_ec "Perceive safety and civility in community"
	la var equity_comm_ec "Perceive equity & integrity in comm. leadership"
	la var govt_corr_el "Perceive integrity in nat'l gov't (gol, courts, lnp) and unmil"
	la var govt_no_bias_el "Perceive equal treatment by unmil, gol, lnp of tribes and religions"

	la var landconf_dummy_ec "Reports land dispute in 2010"
	
	la var anylndconf_alt_ec "Reports land dispute in 2010 and/or serious land dispute"
	la var anylndconf_alt_et "Reports land dispute in 2010 and/or serious land dispute"

	la var anylndconf_alt2_ec "Any serious land dispute"
	la var anylndconf_alt2_et "Any serious land dispute"
			
	la var unrslv_lnd_conf_ec "Any unresolved land dispute"
	la var unrslv_lnd_conf_et "Any unresolved land dispute"
				
	la var sevlandconf_dummy_ec "Land dispute involving violence destruction or threats"
	la var sevlandconf_dummy_et "Land dispute involving violence destruction or threats"
	
	la var propdest_landconf_ec "Land dispute involving property destruction"
	la var propdest_landconf_et "Land dispute involving property destruction"
	
	la var viol_landconf_ec "Land dispute involving violence"
	la var viol_landconf_et "Land dispute involving violence"
	
	la var threat_landconf_ec "Land dispute involving threats"
	la var threat_landconf_et "Land dispute involving threats"

	la var viol_landconf_dummy_ec "Land dispute results in violence destruction or threats"
	la var viol_landconf_dummy_et "Land dispute results in violence destruction or threats"

	la var satisfied_res_ec "Conditional on land dispute: Satisfied with outcome"
	la var satisfied_res_et "Conditional on land dispute: Satisfied with outcome"
	
	la var rslv_lnd_conf_infrml_ec "Conditional on land dispute: Resolved dispute via informal mechanism"
	la var rslv_lnd_conf_infrml_et "Conditional on land dispute: Resolved dispute via informal mechanism"
	
	la var rslv_lnd_conf_ec "Conditional on land dispute: Resolved land dispute"
	la var rslv_lnd_conf_et "Conditional on land dispute: Resolved land dispute"

	
	la var ccoll_viol_el "Violent strike or inter-tribal dispute" 
	la var ctribal_conf_el "Witch killing or trial by ordeal" 


	la var fights_dummy_et "Physical fights with others"
	la var mnyconf_et "Interpersonal dispute over money"
	la var anylndconf_alt_et "Land dispute"
	la var fightweap_dummy_et "Fight with weapons"

	la var fights_dummy_ec "Physical fights with others"
	la var mnyconf_ec "Interpersonal dispute over money"
	la var anylndconf_alt_ec "Land dispute"
	la var fightweap_dummy_ec "Fight with weapons"
	la var unrslv_money_conf_ec "Any unresolved money dispute"

	
	la var cpvytheld_el "Number of youth-elder disputes"
	la var cfamlndcn_el "Number of inter-family land disputes"
	la var cdtwnldcn_el "Number of conflicts with other towns"
	la var ctot_palava_el "Total no. of disputes between families; youth and elders; other towns"
	la var cstrkpeac_dummy_el "Peaceful strike or protest"
	la var ccoll_viol_el "Violent strike or inter-tribal dispute"
	la var ctribal_conf_el "Witch killing or trial by ordeal"
	

	la var cedulevel_bc "Town education level"
	la var cnum_tribes_bc "Number of tribes in town"
	la var cwealthindex_bc "Town wealth index"
	la var cviol_experienced_bc "Town exposure to war violence"
	la var clndtake_bc "Proportion of town losing land during war"
	la var clandconf_scale_bc "Proportion of town reporting land dispute"

	la var age_ec "Age"
	la var male_ec "Male"
	la var yrs_edu_ec "Years of education"
	la var minortribe_ec "Member of minority tribe in community"
	la var excom_ec "Ex-combatant"		
*/
	
	
saveold "$JPC/Analysis/PEACE/Data/jpc_analysis_test.dta",replace

/*
// SAVE CoRE DO-FILE

	bys commcode: gen count=_n
	keep if count==1
	
	saveold "$JPC/Analysis/CoRE/Data/CoRE_comm-level_endline2.dta",replace
*/


********************************************************************************
* Make a long version of the analysis data *************************************
********************************************************************************
/* 	Here long means plot-level. This is for analyzing the effect on investment /
	security for different plots. 
*/
	
	use data/ready_analysis, clear
	keep if ENDLINE2_RESIDENT == 1

	set more off
	cap drop newid
	cap drop finalid
	cap egen newid = group(respid)
	cap gen finalid = string(newid) + string(ENDLINE2_RESIDENT)
	drop newid
	duplicates drop finalid, force
	cap drop survey_et

	cap drop security_rights
/*	Something about stata's namespace makes there be a conflict between stuff
	called "survey" and other stuff. I don't fully understand it, but we
	rename the survey variable just in case. 
*/

cap drop monetary_improvement_rslv_conf monetary_improvement_unrslv_conf monetary_improvement_rslv_infrml monetary_improvement_stsfd

drop survey surveytype


gl outcomes_for_reshape ///
	z_improvement			///
	improvement			///
	improveexisting		///
	improvenew			///
	improvegut			///
	improvefence		///
	improvetree			///
	monetary_improvement				///
	spentexisting		///
	spentnew			///
	spentgut			///
	spentfence			///
	spenttree			///
	nonmoney			///
	daysexisting		///
	daysnew				///
	acresgut			///
	acresfence			///
	acrestree			///
	security_rights 	///
	secured				///
	inherit				///
	survey  		///
	sell				///
	pawn				///
	level_of_security			///
	inherit_dum				///
	survey_dum  		///
	sell_dum				///
	pawn_dum				///
	level_of_security_dum			///
	fallow_index			///
	non_market_tenure		///
	market_tenure		///
	non_kin				///
	ownership_self		///
	ownership_fam 		///
	size

drop sizec50

	reshape long $outcomes_for_reshape, i(finalid) j(plottype, string)

	// 6 is not an important number. Just longer than both the words "house" and "farm"
	replace plottype = substr(plottype, 2, 6)


label var z_improvement				"Property investment index, z-score"
label var monetary_improvement		"\quad Monetary value of improvement, house and farm, (z-score)"
label var nonmoney	"\quad Non-monetary improvement, house and farm (z-score)"
label var improvement				"\quad Made an improvement, house and farm"

label var improveexisting			"Improved Existing house"
label var improvenew				"Built a new house"
label var improvegut				"Improved gutter in farm"
label var improvefence				"Improved fence in farm"
label var improvetree				"Improved tree in farm"
label var spentexisting				"Amount spent on existing house (USD)"
label var spentnew					"Amount spent on new house (USD)"
label var spentgut					"Amount spent on gutter in farm (USD)"
label var spentfence				"Amount spent on fence in farm (USD)"
label var spenttree					"Amount spent on tree in farm (USD)"
label var daysexisting				"Days spent improving existing house"
label var daysnew					"Days spent building new house"
label var acresgut					"Acres affected by gutter improvements in farm"	
label var acresfence				"Acres affected by fence improvement in farm"
label var acrestree					"Acres affected by tree improvement in farm"


label var security_rights 			"Security rights index, z-score"
label var inherit					"\quad Ability to inherit, house and farm (0-3)"
label var sell						"\quad Ability to sell, house and farm (0-3)"
label var pawn						"\quad Ability to pawn, house and farm (0-3)"
label var survey					"\quad Ability to survey, house and farm (0-3)"
label var level_of_security			"\quad Level of security of boundaries, house and farm"
label var inherit_dum					"\quad Has ability to inherit, house and farm"
label var sell_dum						"\quad Has ability to sell, house and farm"
label var pawn_dum						"\quad Has ability to pawn, house and farm"
label var survey_dum					"\quad has ability to survey, house and farm"
label var level_of_security_dum			"\quad Feels secure in boundaries, house and farm"
label var fallow_index				"Index of fallow land, farm"
label var non_market_tenure			"Has access to land through non-market, house and farm"
label var market_tenure				"has access to land through market, house and farm"
label var non_kin					"Did not receive from family member, house and farm"
label var ownership_self		"Individual owns land"
label var ownership_fam		"Individual or family owns land"
label var size				"Size of land (house and farm)"



********************************************************************************
* Drop one observation for variables without plot-level variation **************
********************************************************************************
/*	Some variables are about land but are not tied to a farm or house 
	specifically. When we do the reshape, the observations for these variables 
	double. To counteract this, we just set that variable to missing when the 
	plottype is a house. This is hacky, but it makes code easier down the line. 
*/

local vars_to_drop_one_obs farm_size_ec2 anylndconf_u_ec2  lmg_conf_any_u_ec2 size
foreach variable in `vars_to_drop_one_obs' {
	replace `variable' = . if (plottype == "house")
}



save data/ready_analysis_plots, replace


********************************************************************************
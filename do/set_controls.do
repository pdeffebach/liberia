
* Globals for individual controls *******************************************************
gl ate_ctrls        "ageover60 age40_60 age20_40 yrs_edu female stranger christian minority cashearn_imputedhst noland farm_sizehst houseoccupy houseclaim housepalavapostwar farmclaim farmpalavapostwar"
gl ate_ctrls_leader "ageover60 age40_60 age20_40 yrs_edu female stranger christian minority cashearn_imputedhst"
gl ate_ctrls_apsr   "ageover60 age40_60 age20_40 yrs_edu female stranger christian minority cashearn_imputedhst noland farm_sizehst land_sizehst housetake_dum lndtake_dum"

* Globals for community-level controls *****************************************
gl comm_ctrls       "district1-district14 vsmall small small2 small3 quartdummy cedulevel_bc ctownhh_log_el2 cwealthindex_bc cviol_experienced_bc clndtake_bc cviol_scale_bc clandconf_scale_bc cwitchcraft_scale_bc cpalaviol_imputed_bc cprog_ldr_beliefs_bc cattitudes_tribe_bc crelmarry_bc"
gl comm_ctrls_apsr  "district1-district14 vsmall small small2 small3 quartdummy cedulevel_bc ctownhh_log_el  cwealthindex_bc cviol_experienced_bc clndtake_bc cviol_scale_bc clandconf_scale_bc cwitchcraft_scale_bc cpalaviol_imputed_bc cprog_ldr_beliefs_bc cattitudes_tribe_bc crelmarry_bc assigned_nov"       
gl comm_ctrls_short "district1-district5 district8-district15 vsmall small small2 small3 cedulevel_bc ctownhh_log_el cwealthindex_bc cviol_experienced_bc clndtake_bc cviol_scale_bc clandconf_scale_bc cwitchcraft_scale_bc cpalaviol_imputed_bc cprog_ldr_beliefs_bc cattitudes_tribe_bc crelmarry_bc"

    
gl C_apsr $ate_ctrls_apsr $comm_ctrls_apsr trainee
gl C_t $ate_ctrls_t $comm_ctrls_t


gl Z assigned_ever
gl L1 ENDLINE2_RESIDENT
gl L2 ENDLINE2_LEADER
gl C_ec2 $ate_ctrls $comm_ctrls
gl C_el2 $ate_ctrls_leader $comm_ctrls


gl comm_controls_comparison ///
    ctownpop_bl ///
    cedulevel_bc ///
    cnum_tribes_bc ///
    cprop_domgroup_bc ///
    cwealthindex_bc ///
    cfacilities_bl ///
    ctot_resources_bl ///
    croad_dist_rainy_bl ///
    cviol_experienced_bc ///
    clndtake_bc ///
    cprog_ldr_beliefs_bc ///
    cattitudes_tribe_bc ///
    canypeace_bc ///
    cgpeace_bc ///
    crelmarry_bc ///
    cviol_scale_bc ///
    clandconf_scale_bc ///
    cwitchcraft_scale_bc ///
    cpalaviol_imputed_bc ///
    cstrkpeac_dummy_bl ///
    ccoll_viol_bl ///
    ctribal_conf_bl ///
    ccapital_offense_bl

cap drop resident_demo
gen resident_demo = . 
label var resident_demo "\textbf{Resident demograhics}"

cap drop resident_war_experience
gen resident_war_experience = . 
label var resident_war_experience "\textbf{Resident war experience}"

cap drop resident_conflict
gen resident_conflict = . 
label var resident_conflict "\textbf{Resident land and interpersonal conflict}"


gl baseline_controls_comparison ///
resident_demo /// 
    age_bc ///
    male_bc ///
    yrs_edu_bc ///
    muslim_bc ///
    traditional_bc ///
    christian_bc ///
    wealthindex_bc ///
    landless_bc ///
    farmless_bc ///
    anypeace_bc ///
    gpeace_bc ///
resident_war_experience ///
    refugee_bc ///
    displaced_bc ///
    viol_experienced_bc ///
resident_conflict ///
    lndtake_dum_bc ///
    landconf_dummy_bc ///
    moneyconflict_bc ///
    crime_dummy_bc ///
    witchcraft_dummy_bc ///
    palawater_dum_bc






svyset commcode [pweight=weight_e1_e2], strata(county)  // Set survey data 

***
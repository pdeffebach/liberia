
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

svyset commcode [pweight=weight_e1_e2], strata(county)  // Set survey data specific to each dataset

***
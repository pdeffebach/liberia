* Set globals of dependent variables *******************************************

gen unconditional_label_land = .
label var unconditional_label_land "\textbf{Panel A: Ouctomes for all residents}"
gen conditional_label_land = .
label var conditional_label_land "\textbf{Panel B: Conditional on a land dispute}"

gl land_conflict_paper ///
    unconditional_label_land ///
    anylndconf_u_ec2   ///  
    unrslv_lnd_conf_u_ec2 ///
    conf_any_u_ec2 ///
        conf_dam_violence_bin_u ///
        conf_threat_u_ec2 ///
        conf_damage_u_ec2 ///
        conf_viol_u_ec2 ///
    conditional_label_land ///
    conf_length_max_c_ec2 ///
    forum_lastsuc_c_ec2   ///
    conf_any_c_ec2         ///
        conf_dam_violence_bin_c ///
        conf_threat_c_ec2 ///
        conf_damage_c_ec2 ///
        conf_viol_c_ec2 ///
        conf_witch_c_ec2 

gl land_conflict ///
    unconditional_label_land ///
    anylndconf_u_ec2   ///  
    unrslv_lnd_conf_u_ec2 ///
    conf_any_u_ec2 ///
        conf_dam_violence_bin_u ///
        conf_threat_u_ec2 ///
        conf_damage_u_ec2 ///
        conf_viol_u_ec2 ///
    conf_length_max_u_ec2 ///
        conf_length_mean_u_ec2 ///
    conditional_label_land ///
    forum_lastsuc_c_ec2   ///
        forum_inf_suc_c_ec2  ///
    conf_any_c_ec2         ///
        conf_dam_violence_bin_c ///
        conf_threat_c_ec2 ///
        conf_damage_c_ec2 ///
        conf_viol_c_ec2 ///
        conf_witch_c_ec2 ///

gen unconditional_label_all = .
label var unconditional_label_all "\textbf{Panel A: Ouctomes for all residents}"
gen conditional_label_all = .
label var conditional_label_all "\textbf{Panel B: Conditional on dispute}"

global all_conflict_paper ///   
    unconditional_label_all ///
    lmg_conf_u_ec2                  ///
    lmg_unrslv_conf_u_ec2           ///
    lmg_conf_any_u_ec2              ///
    conditional_label_all ///
    lmg_forum_lastsuc_c_ec2     ///
        lmg_forum_inf_suc_c_ec2 ///
    lmg_conf_any_c_ec2              ///
        lmg_conf_dam_violence_bin_c ///
            lmg_conf_threat_c_ec2 ///
            lmg_conf_damage_c_ec2 ///
            lmg_conf_viol_c_ec2 

// a global for all conflicts
gen g_unconditional_label_land = .
label var g_unconditional_label_land "\textbf{Panel A: Land dispute outomes for all residents}"
gen g_conditional_label_land = .
label var g_conditional_label_land "\textbf{Panel B: Conditional on a land dispute}"
gen g_unconditional_label_all = .
label var g_unconditional_label_all "\textbf{Panel C: General dispute outcomes for all residents}"
gen g_conditional_label_all = .
label var g_conditional_label_all "\textbf{Panel D: Conditional on a dispute}"


gl conflict_adj_p ///
    g_unconditional_label_land ///
    anylndconf_u_ec2   ///  
    unrslv_lnd_conf_u_ec2 ///
    conf_any_u_ec2 ///
        conf_dam_violence_bin_u ///
        conf_threat_u_ec2 ///
        conf_damage_u_ec2 ///
        conf_viol_u_ec2 ///
    g_conditional_label_land ///
    conf_length_max_c_ec2 ///
    forum_lastsuc_c_ec2   ///
    conf_any_c_ec2         ///
        conf_dam_violence_bin_c ///
        conf_threat_c_ec2 ///
        conf_damage_c_ec2 ///
        conf_viol_c_ec2 ///
        conf_witch_c_ec2  ///
    g_unconditional_label_all ///
    lmg_conf_u_ec2                  ///
    lmg_unrslv_conf_u_ec2           ///
    lmg_conf_any_u_ec2              ///
    g_conditional_label_all ///
    lmg_forum_lastsuc_c_ec2     ///
        lmg_forum_inf_suc_c_ec2 ///
    lmg_conf_any_c_ec2              ///
        lmg_conf_dam_violence_bin_c ///
            lmg_conf_threat_c_ec2 ///
            lmg_conf_damage_c_ec2 ///
            lmg_conf_viol_c_ec2 

global all_conflict ///
    unconditional_label_all ///
    lmg_conf_u_ec2                  ///
    lmg_unrslv_conf_u_ec2           ///
    lmg_conf_any_u_ec2              ///
        lmg_conf_dam_violence_bin_u ///
        lmg_conf_threat_u_ec2 ///
        lmg_conf_damage_u_ec2 ///
        lmg_conf_viol_u_ec2   ///
    lmg_conf_length_max_u_ec2 ///
        lmg_conf_length_mean_u_ec2 ///
    lmg_conf_length_mean_c_ec2 ///
        lmg_conf_length_max_c_ec2 ///
    conditional_label_all ///
    lmg_forum_lastsuc_c_ec2     ///
        lmg_forum_inf_suc_c_ec2 ///
    lmg_conf_any_c_ec2              ///
        lmg_conf_dam_violence_bin_c ///
        lmg_conf_threat_c_ec2 ///
        lmg_conf_damage_c_ec2 ///
        lmg_conf_viol_c_ec2 ///
        lmg_conf_witch_c_ec2 

gl fallow_security_paper ///
    security_rights ///
    improvez ///
    fallow_index_farm ///
    size_farm 

gl fallow_security ///
    security_rights ///
        security_rights_farm ///
        security_rights_house ///
    improvez ///
        z_improvement_farm ///
        z_improvement_house  ///
    fallow_index_farm ///
        landrestpast ///
        landrestfut ///
        restseasons ///
        securerest ///
    size_farm 


gl bias_index ///
    bias_index_ec2 ///
        nogossipop_st_ec2 ///
        nogossipco_st_ec2 ///
        nosmalllieop_st_ec2 ///
        nosmalllieco_st_ec2 ///
        notakesideop_st_ec2 ///
        notakesideco_st_ec2 
    
gl defection_index  ///
    defection_index_ec2 ///
        norenegeop_st_ec2 ///
        norenegeco_st_ec2 ///
        nochiefsupportop_st_ec2 ///
        nochiefsupportco_st_ec2 ///
        nopoliceop_st_ec2 ///
        nopoliceco_st_ec2 ///
        nocontactsop_st_ec2 ///
        nocontactsco_st_ec2

gl empathy_index ///
    empathy_index_ec2 ///
        sklisten_st_ec2 ///
        skconvincetalk_st_ec2 ///
        skempathy_st_ec2 ///
        skthinkwrong_st_ec2 ///
        skthinkshoes_st_ec2

gl forum_choice_index ///
    forum_choice_index_ec2 ///
        notalkfirstop_st_ec2 ///
        notalkfirstco_st_ec2 ///
        nocommfirstop_st_ec2 ///
        nocommfirstco_st_ec2 ///
        nopolicefirstop_st_ec2 ///
        nopolicefirstco_st_ec2  

gl managing_emotions_index ///
    managing_emotions_index_ec2 ///
        nospoilpropop_st_ec2 ///
        nospoilpropco_st_ec2 ///
        skstaycalm_st_ec2 ///
        skcooltemper_st_ec2 ///
        sktalkbad_st_ec2

gl mediation_index ///
    mediation_index_ec2 ///
        noadviseop_st_ec2 ///
        noadviseco_st_ec2 ///
        nomediateop_st_ec2 ///
        nomediateco_st_ec2 ///
        nohelpcompop_st_ec2 ///
        nohelpcompco_st_ec2 ///
        skbringtogether_st_ec2 ///
        skhelpagree_st_ec2 ///
        skhelpunderstand_st_ec2 ///
        skcooltemperothers_st_ec2


gl negotiation_index ///
    negotiation_index_ec2 ///
        nocompromop_st_ec2 ///
        nocompromco_st_ec2 ///
        nogiftop_st_ec2 ///
        nogiftco_st_ec2 ///
        sktalkpalava_st_ec2 ///
        sktalkgood_st_ec2 ///
        skproposesolution_st_ec2 ///
        skcompromise_st_ec2 ///
        skforgive_st_ec2

 gl all_index_categories ///
    bias_index_ec2 ///
        defection_index_ec2 ///
        empathy_index_ec2 ///
        forum_choice_index_ec2 ///
        managing_emotions_index_ec2 ///
        mediation_index_ec2 ///
        negotiation_index_ec2

global intensive ///
    anylndconf_u_ec2 ///
    conf_any_u_ec2 ///
    security_rights ///
    improvez

gl comdispute_leader ///
    tribviol_dum_el2 ///
    strkviol_dum_el2 ///
    pvytheld_dum_el2 ///
    strkpeac_dum_el2 ///
    cfamlndcn_dum_el2 ///
    dtwnldcn_dum_el2  ///
    suspwitc_dum_el2 ///
    sasycutl_dum_el2 ///
    sasywitch_el2 ///
    anyviol_el2 ///
    sumviol_el2 

global comm_conflict ///
    anyviol_el2         ///
    sumviol_el2         /// 
        tribviol_dum_el2    ///
        strkviol_dum_el2    ///
        pvytheld_dum_el2  ///
        strkpeac_dum_el2    ///
        cfamlndcn_dum_el2 /// 
        dtwnldcn_dum_el2  ///
        suspwitc_dum_el2    ///
        sasycutl_dum_el2    

global hetero_demo_conflict ///
    anylndconf_u_ec2 ///
    unrslv_lnd_conf_u_ec2 ///
    conf_damage_u_ec2 ///
    forum_lastsuc_c_ec2

global agg_analysis_variables ///
    conf_any_u_ec2 ///
    conf_threat_u_ec2 ///
    conf_dam_violence_bin_u ///
    conf_damage_u_ec2 ///
    conf_viol_u_ec2 ///
    conf_dam_violence 

***
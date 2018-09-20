use data/ready_analysis, clear

keep if ENDLINE2_RESIDENT == 1
keep district_bl village town commcode assigned_ever
//commcode is the level at which treatments are assigned
bysort commcode: keep if _n == 1

// district_bl seems to be how treatments were assigned.
forvalues i = 1/1000 { 
    cap drop shuffle_rand
    cap drop tt
    gen shuffle_rand = runiform()
    bysort district_bl (shuffle_rand): gen tt = _n
    bysort district_bl (assigned_ever): gen assigned_ever_`i' = assigned_ever[tt]
}
keep commcode district assigned_ever_*
save data/simulated_treatments
***
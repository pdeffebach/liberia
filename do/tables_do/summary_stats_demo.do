

cap program drop summary_stats_demo
program define summary_stats_demo
    clear mata 
    set matsize 10000
    syntax varlist, INTERACTIONS(varlist) FILENAME(name) SUBSET(varlist) ///
    INTERTITLE1(string) INTER1ZERO(string) INTER1ONE(string) ///
    INTERTITLE2(string) INTER2ZERO(string) INTER2ONE(string) ///
    INTERTITLE3(string) INTER3ZERO(string) INTER3ONE(string) ///
    INTERTITLE4(string) INTER4ZERO(string) INTER4ONE(string) ///
    INTERTITLE5(string) INTER5ZERO(string) INTER5ONE(string) ///
    INTERTITLE6(string) INTER6ZERO(string) INTER6ONE(string)

    local dep_vars `varlist' // creating a local for dep. variables
    local M = `:word count `dep_vars''

    local K = `:word count `interactions'' + 1 // for everyone

    // Initializing all the matices 
    /*  we have to have separate matrices for each number format we want, I 
        think. We can't store control means and counts in the same matrix 
        because obviously we don't want counts to have decimal places, but 
        we do want decimal places for means. */

    mat means      = J(`M', 2 * `K',.)
    mat rownames means = `dep_vars'
    mat colnames means = ///
    "Everyone mean" "Everyone sd" ///
    "`inter1ZERO'" "`inter1ONE'" ///
    "`inter2ZERO'" "`inter2ONE'" ///
    "`inter3ZERO'" "`inter3ONE'" ///
    "`inter4ZERO'" "`inter4ONE'" ///
    "`inter5ZERO'" "`inter5ONE'" ///
    "`inter6ZERO'" "`inter6ONE'" 

    mat Pcts = J(1, 2 * `K', .)
    mat rownames Pcts = "\textbf{Pct. of Endline 2 residents}"
    mat colnames Pcts = ///
    "Everyone mean" "Everyone sd" ///
    "`inter1ZERO'" "`inter1ONE'" ///
    "`inter2ZERO'" "`inter2ONE'" ///
    "`inter3ZERO'" "`inter3ONE'" ///
    "`inter4ZERO'" "`inter4ONE'" ///
    "`inter5ZERO'" "`inter5ONE'" ///
    "`inter6ZERO'" "`inter6ONE'" 
* Percents for everyone ********************************************************
local k = 2 
foreach inter_var in `interactions' {
    cap drop z
    gen z = `inter_var' == 1 & `subset' == 1
    qui sum z if `subset' == 1
    mat Pcts[1,`k' * 2 - 1] = 1 - r(mean)
    mat Pcts[1,`k' * 2] = r(mean)
    local ++k
}

* Mean and sd for everyone *****************************************************
local m = 1 
foreach y in `dep_vars' {
    qui sum `y' if `subset' == 1
    mat means[`m', 1] = r(mean)
    mat means[`m', 2] = r(sd)
    local ++m
}

loc m = 1
foreach y in `dep_vars'{ 
    loc k = 2
    foreach inter_var in `interactions' {
        qui sum `y' if `subset' == 1 & `inter_var' == 0 
        mat means[`m', `k' * 2 - 1] = r(mean)
        qui sum `y' if `subset' == 1 & `inter_var' == 1 
        mat means[`m', `k' * 2] = r(mean)
    local ++k
    }
local ++m   
}

********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
cap frmttable, statmat(Pcts) 
cap frmttable, statmat(means) append varlabels
frmttable using out/tables/`filename', ///
ctitle( ///
"", "\uline{\hfill All Endline 2 residents}", "", "\uline{\hfill `intertitle1' \hfill}", "", "\uline{\hfill `intertitle2' \hfill}", "", "\uline{\hfill `intertitle3' \hfill}", "", "\uline{\hfill `intertitle4' \hfill}", "", "\uline{\hfill `intertitle5' \hfill}", "",  "\uline{\hfill `intertitle6' \hfill}", "" \ ///
"", "Mean", "SD",  "`inter1ZERO'", "`inter1ONE'", "`inter2ZERO'", "`inter2ONE'", "`inter3ZERO'", "`inter3ONE'", "`inter4ZERO'", "`inter4ONE'", "`inter5ZERO'", "`inter5ONE'", "`inter6ZERO'", "`inter6ONE'") ///
multicol(1,2,2; 1,4,2; 1,6,2; 1,8,2; 1,10,2; 1,12,2; 1,14,2) ///
tex ///
fragment ///
varlabels ///
nocenter ///
replace


end 

///
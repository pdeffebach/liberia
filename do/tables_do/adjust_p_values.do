********************************************************************************
* 
* P-value adjustment ***********************************************************
*
********************************************************************************
cap program drop adjust_p_values 
program define adjust_p_values 
syntax, adjustvars(varlist) adjustvarsmat(name) controls(varlist) treat(varlist) nsims(integer) strata(varlist) group(varlist)
local regressors `treat' `controls'  
preserve 
keep if `group' == 1
wyoung `adjustvars', cmd(svy: regress OUTCOMEVAR `regressors')  cluster(commcode) familyp(`treat') bootstraps(`nsims') strata(`strata')  

********************************************************************************
* Put the selected adjusted ps in with the rest of the adjusted ps *************
********************************************************************************
mat table = r(table)
local y_counter = 1
foreach y in `adjustvars' {
    local all_mat = rownumb(`adjustvarsmat', "`y'")
    mat `adjustvarsmat'[`all_mat', 1] = table[`y_counter', 4]
    mat `adjustvarsmat'[`all_mat', 2] = table[`y_counter', 6]
    local ++y_counter
}
restore 
end

***
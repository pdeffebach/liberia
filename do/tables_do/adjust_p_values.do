********************************************************************************
* 
* P-value adjustment ***********************************************************
*
********************************************************************************
cap program drop adjust_p_values // drop the program
program define adjust_p_values 
syntax, adjustvars(varlist) adjustvarsmat(name) controls(varlist) treat(varlist) nsims(integer) strata(varlist) group(varlist)
local regressors `treat' `controls'  
preserve // we are going to use `keep` to avoid sample-issues with the `wyoung` 
         // command. So we preserve. This is usually expensive, but not in com-
         // parison to the simulations. 
keep if `group' == 1 
qui wyoung `adjustvars', /// input our family of regressions
    cmd(svy: regress OUTCOMEVAR `regressors')  /// this is the exact same command in our normal regressions
    cluster(commcode) /// `svy:` handles the clustering in the regression, but we still need 
                      /// clustering in the bootstrapping! Otherwise our p-values will be too small. 
    familyp(`treat')  /// This is the coefficient we are interested in. 
    bootstraps(`nsims') /// number of simulations we are using 
    strata(`strata')  // This also is used to make sure bootstrapping is done properly. 

********************************************************************************
* Put the selected adjusted ps in with the rest of the adjusted ps *************
********************************************************************************
mat table = r(table) // this is the output from the `wyoung` command. 
local y_counter = 1
foreach y in `adjustvars' { 
    local all_mat = rownumb(`adjustvarsmat', "`y'") 
    mat `adjustvarsmat'[`all_mat', 1] = table[`y_counter', 4] // westfall-young
    mat `adjustvarsmat'[`all_mat', 2] = table[`y_counter', 6] // sidak-holmes
    local ++y_counter
}
restore 
end

***
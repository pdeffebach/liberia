

cap program drop ate_maker_inter_long
program define ate_maker_inter_long
    clear mata 
    set matsize 10000
    syntax varlist, TREAT(varlist) COVARIATES(varlist) INTERACTIONS(varlist) FILENAME(name) SUBSET(varlist) ///
    [INTER1(string)] [INTER2(string)] [INTER3(string)] [INTER4(string)] [INTER5(string)] [INTER6(string)] ///
    [INTER7(string)] [INTER8(string)] ///
    HEADERS(string asis) MULTICOLS(string asis) 

********************************************************************************
* FUCK STATA *******************************************************************
********************************************************************************
local treatment_cov_0 = "Treatment"
local effect_covariate = "Covariate"
local interaction_term = "Treatment x Covariate"
local treatment_cov_1 = "Sum of Treatment and Interaction"

    local dep_vars `varlist' // creating a local for dep. variables
    local M = `:word count `dep_vars''

    /* making longer local for regression because reg takes only one local */
    local regressors `treat' `covariates'
    
    local K `:word count `interactions''

    // Initializing all the matices 
    /*  we have to have separate matrices for each number format we want, I 
        think. We can't store control means and counts in the same matrix 
        because obviously we don't want counts to have decimal places, but 
        we do want decimal places for means. */

    ****************************************************************************
    * Make matrices for long-form display of effects ***************************
    ****************************************************************************
    local i = 1
    foreach var in `interactions' {
        mat mat_`var' = J(5, `M'*2, .)
        mat rownames mat_`var' = "inter_`i'" "treatment_cov_0" "effect_covariate" "interaction_term" "treatment_cov_1"
        mat colnames mat_`var' = `dep_vars'

        mat stars_`var' = J(5, `M'*2, 0)
        mat rownames stars_`var' = "inter_`i'" "treatment_cov_0" "effect_covariate" "interaction_term" "treatment_cov_1"
        mat colnames stars_`var' = `dep_vars'
        dis `dep_vars'
        local ++i    
    }



    /*  This upcoming for loop does the following: 
        1)  For each dependent variable it runs a regression of y on treat and 
            the covariates. 
        2)  Calculates the p-values and significance levels of the coefficients
        3)  Inputs the estimates for beta (on treat only), into the matrix. It 
            inputs beta hat in one column and SE hat in another. 
        
        In order to understand why I generate stars the way I do, please see 
        this link: https://www.pdx.edu/econ/sites/www.pdx.edu.econ/files/frmttable_sj.pdf
        frmttable adds stars to estimates based on a matrix that here i call 
        stars. If stars(i,j) = 3, for example, than cell (i,j) will get 3 stars. 
        I set the first column of stars all to zero because we want stars to 
        go next to the standard errors, not the beta estimates. 
    */

    foreach inter_var in `interactions' {
        cap drop a_`inter_var'
        gen a_`inter_var' = `inter_var' * `treat' 
        local lab: var lab `inter_var'
        label var a_`inter_var' "Assigned x `lab'"
    }

    loc m = 1
    foreach y in `dep_vars'{ 
    qui sum `y' if `subset' == 1 
    if r(N) != 0 {
        loc k = 1
        foreach inter_var in `interactions' {

        /*  We don't have to worry about having the variable we are interacting
        with in the list of covariates, beacause stata is smart enough to omit
        the second appearance of that variable from the regression. As long as
        the interactions come first we are good. 
        */  
        local regressors `treat' `inter_var' a_`inter_var' `covariates'

        * Run the regression ***************************************************
        qui svy: reg `y' `regressors' if (`subset' == 1)

        * Input the betas and the standard errors for treatment ****************
        mat mat_`inter_var'[2,2*`m'-1] = _b[`treat'] // put in beta estimate
        mat mat_`inter_var'[2,2*`m'] = _se[`treat'] // put in standard error estimate
        local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
        if (`p' < .1)   mat stars_`inter_var'[2,2*`m'] = 1 // less than 10%?
        if (`p' < .05)  mat stars_`inter_var'[2,2*`m'] = 2 // less than 5%?
        if (`p' < .01)  mat stars_`inter_var'[2,2*`m'] = 3 // less than 1%?

        * Input the betas and standard errors for covariate itself *************
        mat mat_`inter_var'[3, 2*`m'-1] = _b[`inter_var']
        mat mat_`inter_var'[3, 2*`m'] = _se[`inter_var']
        local p = (2 * ttail(e(df_r), abs(_b[`inter_var']/_se[`inter_var'])))
        if (`p' < .1)   mat stars_`inter_var'[3,2*`m'] = 1 // less than 10%?
        if (`p' < .05)  mat stars_`inter_var'[3,2*`m'] = 2 // less than 5%?
        if (`p' < .01)  mat stars_`inter_var'[3,2*`m'] = 3 // less than 1%

        * Input the betas and standard errors for the interaction term *********
        mat mat_`inter_var'[4, 2*`m'-1] = _b[a_`inter_var']
        mat mat_`inter_var'[4, 2*`m'] = _se[a_`inter_var']
        local p = (2 * ttail(e(df_r), abs(_b[a_`inter_var']/_se[a_`inter_var'])))
        if (`p' < .1)   mat stars_`inter_var'[4,2*`m'] = 1 // less than 10%?
        if (`p' < .05)  mat stars_`inter_var'[4,2*`m'] = 2 // less than 5%?
        if (`p' < .01)  mat stars_`inter_var'[4,2*`m'] = 3 // less than 1%

        * Input the betas and standard errors for the net effect ***************
        qui lincom assigned_ever + a_`inter_var'
        mat mat_`inter_var'[5, 2*`m' - 1] = r(estimate)
        mat mat_`inter_var'[5, 2*`m'   ] = r(se)
        local p = (2 * ttail(e(df_r), abs(r(estimate))/r(se)))
        if (`p' < .1)   mat stars_`inter_var'[5,2*`m'] = 1 // less than 10%?
        if (`p' < .05)  mat stars_`inter_var'[5,2*`m'] = 2 // less than 5%?
        if (`p' < .01)  mat stars_`inter_var'[5,2*`m'] = 3 // less than 1%

        local ++k
        }
    }
    local ++m   
    }

********************************************************************************
* Merge matrices to form our larger, final matrix. *****************************
********************************************************************************
    local t `:word 1 of `interactions''
    frmttable, statmat(mat_`t') sdec(3) substat(1) annotate(stars_`t') ///
    asymbol(*,**,***) varlabels squarebrack ///
    rtitle( ///
        "\textbf{`inter1'}" \  ///
        "" \ ///
        "`treatment_cov_0'" \ ///
        "" \ ///
        "`effect_covariate'" \ ///
        "" \ ///
        "`interaction_term'" \ ///
        "" \ ///
        "`treatment_cov_1'" \ ///
        "") 

    dis `k'
    forvalues i = 2/`K' {
        local t `:word `i' of `interactions''   
        qui frmttable, statmat(mat_`t') sdec(3) substat(1) annotate(stars_`t') ///
        asymbol(*,**,***) varlabels squarebrack ///
        rtitle( ///
            "\textbf{`inter`i''}" \  ///
            "" \ ///
            "`treatment_cov_0'" \ ///
            "" \ ///
            "`effect_covariate'" \ ///
            "" \ ///
            "`interaction_term'" \ ///
            "" \ ///
            "`treatment_cov_1'" \ ///
            "") append
    }
    frmttable
    frmttable using out/tables/`filename', ctitle(`headers') multicol(`multicols') ///
    tex ///
    fragment ///
    varlabels ///
    nocenter ///
    replace 


    //frmttable using out/tables/`filename', ///
    //ctitle("", "\uline{\hfill `inter1' \hfill}", "","", "\uline{\hfill `inter2' \hfill}", "","", "\uline{\hfill `inter3' \hfill}","","", "\uline{\hfill `inter4' \hfill}","","", "\uline{\hfill `inter5' \hfill}","","", "\uline{\hfill `inter6' \hfill}","","", \ ///
    // "", "Treatment", "Interaction", "Sum", "Treatment", "Interaction", "Sum", "Treatment", "Interaction", "Sum", "Treatment", "Interaction", "Sum", "Treatment", "Interaction", "Sum","Treatment", "Interaction", "Sum" \ ///
    // "", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)", "(8)", "(9)", "(10)", "(11)", "(12)", "(13)", "(14)", "(15)", "(16)", "(17)", "(18)") ///
    //multicol(1,2,3; 1,5,3; 1,8,3; 1,11,3; 1,14,3; 1,17,3) ///
    //tex ///
    //fragment ///
    //varlabels ///
    //nocenter ///
    //replace 
    */
end 

///
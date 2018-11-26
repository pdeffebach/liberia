# Overview

This document serves to explain the entire process of conducting analysis for *Engineering informal institutions: Long run impacts of alternative dispute resolution on violence and property rights in Liberia*. I describe the data used for the analyses, then go through each table in the paper and explain where in the code it was made. Then I go through the process of creating a table to help you construct similar functions in R.

## General orientation
All code is run out of the `master.do` file in the project folder. In order to run the code, you should manually set your working directory to where the `master.do` file lives. Then typing `do master` in the Stata console should produce every table in the paper automatically.

`ado/`: Stores a slightly modified version of the `frmttable` package. The code will automatically set Stata to use this version of `frmttable` before any other versions on your machine. 

`do/`: This folder contains all do-files in the analysis. It has an `Archive` folder, which is essentially a trash-bin, and a `tables_do` folder. `tables_do` contains all the do-files that define functions used for making tables. Because initially, we are having you replicate the analysis, you don't need to worry about the cleaning files, `import_external`, `import_clean_construct` and `reshaping`. In the future, when it becomes time for you to trace back the creation of a few key variables, we can work together to go through those do-files. The `label_vars` do-file might serve as a useful reference for connecting the labels used in the tables to specific variables. 

`data/`: Stores all the `.dta` files used in analysis.

`docs/`: Contains this document.

`logs/`: Contains log files. It was mostly used for exploratory analysis, and is not an integral part of the workflow. 

`out/`: Contains the output tables used in the analysis in `tables`, and a pdf document of all tables used in the paper in the `analysis` folder. The tables in the pdf document should always match what is in the paper exactly. 


# Data

## A brief history

### Sampling Design

If you have read the paper, this should be clear by now, but the methodology of this intervention bears repeating. This intervention was performed at the village level. We randomized villages into treatment and control, but did not specifically assign villages to attend the program. 

This means that whenever we conducted a survey, Baseline, Endline 1, or Endline 2, we surveyed a random sample of villages in each village. Our sampling strategy was along the lines of having an enumerator go to the center of a village, then turning in a random direction, walking a random number of paces, and going to the closest house to perform a survey. This makes the dataset very complicated, because we have about 20 observations per village, but we don't have a panel at the individual level. In addiiton to having resident-level information, we also have interviews with community leaders.

However we do not have a relational database. All observations are in the same dataset, with questions from different surveys ending in different suffixes. For instance, the suffix `_el2` means an *E*ndline *l*eader survey from Endline *2*. 

This is complicated. If they are the same suvey questions, they should be the same column in the data. We already differentiate between Endline and Endline 2 with identification dummies. **So if a survey question is present in both Endline 1 and Endline 2, I renamed its variable to match the name in the Endline 2 dataset**. This way I would only need to pass one variable to my table-making functions instead of two. In retrospect, however, this causes further confusion, because it means that some variables with Endline 1 values have Endline 2 suffices (`_ec2` and `el2`). This is something to watch out for. 

## The Datasets

### `ready_analaysis.dta`

If you look at the first few variables in the dataset, you will see a number of important dummy variables, they have the following meanings:

`TARGETED_RESIDENT`: We decided to track a few specific people in Endline 1, but we did not do the same in Endline 2. You don't need to worry about these observations
`ENDLINE_RESIDENT`: Dummy for if someone was a resident at Endline 1.
`ENDLINE2_RESIDENT`: Dummy for if someone was a resident at Endline 2.
`ENDLINE2_LEADER`: Dummy for if someone was a community leader at Endline 2.
`BASELINE_RESIDENT`: Dummy for being a baseline resident.
`ENDLINE_LEADER`: Dummy for if someone was an Endline leader.
`COMMLEVEL`: To be honest I can't explain this variable. You don't need to worry about it. 

Keep in mind that the dummies aren't real dummies. They have missing values instead of zeros. 

Note that all relevant variables are labeled. So `describe` should be able to answer all your questions about which variables mean what. 

### `ready_analysis_plots.dta` 

This dataset *only* contains observations from Endline 2 residents. If you want to see how it's made, check out the do-file `reshaping.do`. In the `ready_analysis.dta` dataset, survey questions that were asked about both house and farm types have variables ending in `_house` and `_farm`, respecively. The reshaping do-file takes all the variables ending in those suffixes and puts the data in "long" format, in the process creating a new variable called `plottype`. This means that every respondent now has 2 observations, and all variables that *didn't* have the `_house` and `_farm` suffixes are now duplicated. However we can ignore these variables and just work with the ones that are listed in `reshaping.do`. 

### Key variables
`assigned_ever`: The variable for if a community was ever assigned treatment. 
`treated_ever`: The variable for it a community *received* treatment. Only one community was assigned treatment but did not receive it.
`assigned_nov`: This variable represents communities who, due to implementation issues, were only just getting treatment at Endline 1. We use it as a control in Endline 1 but not Endline 2. In the IV specification used in our Endline 1 paper, we use both `assigned_ever` and `assigned_nov` to predict receiving treatment, however we do not do this in our analysis this time. 
`weight_e1_e2`: A vector of weights at the village level. Due to budget constraints, we were not able to select all villages for the Endline surveys, so we used a propensity-score weighting method to pair up villages and drop some. Consequently, some villages similar to those we dropped have more weight. 
`district1-district14`: A local macro of district dummies for district-fixed effects. These are not to be confused with `district_ec1-district_ec14`! There was some discrepancy in the district definitions, and we ultimately chose the one from the `dcode` variable. The results should match regardless of what we choose. 
`county`: This is our "strata" using the `svyset` command. My impression is that this does very little to change estimates, but I don't know what the equivalent to "strata" is in `felm` of `lme4`. 

# Tables 

## Specifications
With the exception of the plot-level analyses, all regressions have the following specification: 
**Main treatment variable**: `assigned_ever`.
**Clustering**: `commcode` (community level) 
**Weights**: `weight_e1_e2`. The column has values for Endline 1 and Endline 2, even though Endline 1 and Endline 2 are never used in the same regression. This was to prevent us from having to write new `svyset` commands everywhhere.

In the plot-level analysis, which is only one table, the only difference is that we cluster at the respondent level (`respid`) instead of the community level.

**Table 1: Program impacts on number, length, severity, and resolution of land disputes**
Do file: `analysis.do`
Function used: `ate_maker_year.do`
Global macro used: `land_conflict_e1_e2_paper`
Notes: This table shows the impact of the treatment on land disputes: whether they happened, if they were violent, and how they were resolved. Notice the description of the various Ns in the table notes. There are Ns for all 4 combinations of variables based on Endline (1 or 2) and whether or not the variables is conditional on a dispute ocurring or not. 

**Table 2: Program impacts on number, length, severity, and resolution of all dispute types**
Do file: `analysis.do`
Function used: `ate_maker_year.do`
Global macro used: `all_conflict_e1_e2_paper`
Notes: In Endline 1, we asked about land disputes *and* money disputes, and in Endline 2 we asked about land, money, *and* gender disputes. In Endline 1, we asked about violence only for land disputes, while in Endline 3, we asked about violence for all three dispute types. 

**Table 3: Effect on land security and investment, 3-year endline**
Do file: `analysis.do`
Function used: `ate_maker.do`
Global macro used: `outcomes_fallow_security_paper`
Notes: Not all individuals have farms, causing the N to vary across regressions. Notice that while the `paper_tables.pdf` file has a column titled "ITT / control mean", it is omitted in the in the actual paper. This is because since the dependent variables are standardized indices, they by-definition have a mean of 0, so the treatment effect as a proportion of the control mean has no meaning. Obviously, *Size of farm* doesn't have this problem. When we re-submit I will fix this by adding a conditional and only inputting *ITT / control mean* if the variable is not a standardized index. I would suggest you do something like this in your R code. 

**Table 4: Heterogeneity in land security and investment, 3-year endline**
Do file: `analysis_plots.do`
Function used: `ate_maker_inter`
Global macro used: `outcomes_hetero`
Notes: This is the first complicated table in the paper. In Table 3, we saw that the treatment effect on the *Security rights index* was actually *negative*, meaning people in treated villages felt less secure. In Table 4, we explore this odd result by looking at heterogeneity based on people's relationships with the plots they own. However there is a key difference between Tables 3 and 4 in that Table 3 is at the individual level, and Table 4 is at the plot level (using the `ready_analysis_plots.dta` file). In the survey, we ask about 2 types of plots, house plots (which everyone has) and farm plots (which only some people have). Additionally, it is important to remember that we only ask about *one* farm plot, their largest one. 

In all, this means that in the main analysis data (`ready_analysis.dta`), the dataset is "wide", with one security index for an individual's house plot and one security index for an individual's farm plot. To analyze the effect on the security index, then, I created an aggregated variable, that is just the average security index between the farm and house plots. When we run plot-level analysis, we do it on a dataset that has been reshaped to "long" form, where we now have a separate observation for each person's house plot and farm plot. 

Regressions at the plot-level and at the resident-level give similar results. Because the resident-level regressions have a simpler specification (no individual-level clustering), we opt to use resident-level results as much as possible. However when we perform the heterogeneity analysis, there are a two important variables that have plot-level variation. These are *Market tenure* and *Owns own land*. Because we want to look at heterogeneity by a person's relationship to their plot, we run regressions at the plot level. 


**Table 5: Effect on norms, attitudes and skills, 3-year Endline**
Do file: `analysis.do`
Function used `ate_maker_res_leader.do`
Global macro used: `outcomes_all_categories`
Notes: Each of the variables in this paper is an index of a series of questions about people's conflicts, behaviors, and relationships to violence. If you want to know which variables go into each index, just write `note list index_name` to see it. 

**Table 6: Effect on community-level disputes**
Do file: `analysis.do`
Function used `ate_maker_year.do`
Global macro used: `comm_conflict_e1_e2`
Notes: Even though other do-files use this function for resident-level regressions, it can also be used for community-level regressions. All variables in this table are dummies. 

**Table 7: Estimated aggregate effects of the program on violent disputes among the 30,000 households in treatment communities** 
Do file: `analysis.do`
Function used: `aggregate_analysis_ate.do`
Global macro used: `agg_analysis_variables`



# Table-making functions 

## `frmttable`
All tables are made using a Stata `ado` file called `frmttable`. In order for you to understand how I made the tables in this paper, you need to read the documentation [here](http://fmwww.bc.edu/repec/bocode/f/frmttable.html) and a guide [here](https://www.pdx.edu/econ/sites/www.pdx.edu.econ/files/frmttable_sj.pdf)

There are 14 different functions in the `tables_do` folder. Given the length of code for each function, you might be overwhelmed. Don't be! They all have the exact same structure, and much of the code is copied between them. Let's walk through the program `ate_maker` to see what's going on. 

## Function definition 

```
cap program drop ate_maker // drop the program if it already exists
program define ate_maker // define the program
clear mata // clear the internal matrix memory
// the next code defines the syntax for the function
syntax varlist, TREAT(varlist) COVARIATES(varlist) SUBSET(varlist) FILENAME(name) [omitpct] ///
    [ADJUSTVARS(varlist) NSIMS(integer 0)] [EXTRAADJUSTVARS(varlist)]
// Defines the `adjust_p_values` program, to be explained later. 
qui do do/tables_do/adjust_p_values
local dep_vars `varlist' // creating a local for dep. variables
local number_dep_vars = `:word count `dep_vars''
```

Unlike other programming languages, Stata does not overwrite functions silently. You have to explicitly drop them in order to create a new one. 

Next you definte the syntax for the function. The names for arguments in a Stata function are listed in capital letters so we don't use shortened names. The arguments are as follows:

* `varlist`: The set of dependent variables you are analyzing. We rename it a few lines down to make the code more readable (Stata is weird)
* `TREAT`: Your treatment variable. This is almost always `assigned_ever`, but we might want to see the effect of, say, actually receiving treatment. 
* `COVARIATES`: Your vector of control variables. *Note* that the vector of control variables changes for Endline 1 regressions and Endline 2 regressions. I will detail that more below. 
* `SUBSET`: We often want the function to apply to only one group of people in the dataset, say, Endline 2 residents instead of everyone else. So when we have `summarize` and `regress` commands in the function, we add on the option ``if `subset' == 1`` at the end.  This is very important! If you dont subset the data properly you will end up regressing leaders and residents together on accident. 
* `FILENAME`: This is where the name of the `.doc` and `.tex` files that will be produced. 
* `omitpct`: An optional argument for if we want to omit the "Effect as percentage of control mean" column from tables. This is useful when we are working with standardized indices and the control mean is `0`. 
* `ADJUSTVARS`: An optional argument for if we want to perform a p-value adjustment on the outcomes in the table. 
* `NSIMS`: The number of bootstraps we use to make the adjusted p-values
* `EXTRAADJUSTVARS`: Sometimes we want two separate groups of variables be adjusted in the same table. This option is never used and should be deleted. 


## Initializing matrices
```
mat control_mean    = J(`number_dep_vars',1,.) // holds the control means for each variable
mat reg_count       = J(`number_dep_vars',1,.) // holds the regression Ns for each variable
mat reg_main        = J(`number_dep_vars',2,.) // holds the beta and SE for each variable
mat stars           = J(`number_dep_vars',2,0) // count of stars attached to standard errors
mat reg_pct_control = J(`number_dep_vars',1,.) // regression estimates as a percentage of control means
mat estimated_ps    = J(`number_dep_vars',1,.) // estimated p-values, from the regression
mat adjusted_ps     = J(`number_dep_vars',2,.) // adjusted p values from westfall young (column 1) and 
                                               // Sidak-Holmes (column 2)
mat adjusted_ps_syms = J(`number_dep_vars',2,0) // Similar to `stars`. Let's us know the family 
                                                // groupings for the corrected p-values

```

Here we initialize the matrices that we will eventually merge together in our `frmttable` commands. Stata's matrix initialization syntax is odd, but it should be clear what the syntax is doing. The last command is the fill type. We make all matrices full of missing values except for the `stars` matrix. 

We also add rownames to all the matrices. This will enable us to merge all the matrices together in the `frmttable` commands. 

## The `for` loop

```
loc y_counter = 1
foreach y in `dep_vars'{ 
    qui sum `y' if `subset' == 1
    if r(N) != 0 {
    * Run the regression ***************************************************
    // defined above
    qui svy: reg `y' `regressors' if (`subset' == 1)
    
    * Input number of obs. in regression ***********************************
    mat reg_count[`y_counter',1] = e(N) // put in number of observations used in regression
    
    * Calculate the p-value of treatment ***********************************
    local p = (2 * ttail(e(df_r), abs(_b[`treat']/_se[`treat'])))
    // input it 
    mat estimated_ps[`y_counter',1] = `p'
    * Use p-value to make stars ********************************************
        if (`p' < .1)   mat stars[`y_counter',2] = 1 // less than 10%?
        if (`p' < .05)  mat stars[`y_counter',2] = 2 // less than 5%?
        if (`p' < .01)  mat stars[`y_counter',2] = 3 // less than 1%?
    
    * Input the betas and the standard errors ******************************
    mat reg_main[`y_counter',1] = _b[`treat'] // put in beta estimate
    mat reg_main[`y_counter',2] = _se[`treat'] // put in standard error estimate
    
    * Save the beta for use in calculating beta / control mean 
    /*  The command svy: mean overwrites the beta matrix that was created 
        in the regression. 
    */
    local beta = _b[`treat']
    
    * Get the control mean *************************************************
    qui svy: mean `y' if (`treat' == 0 & `subset' == 1) // get summary stats for control mean
    mat mean_mat = e(b) // store the mean as a temporary local because the way stata handles matrices is dumb
    mat control_mean[`y_counter',1] = mean_mat[1, 1] // put in control mean 
    local temp_mean = mean_mat[1, 1]
    mat reg_pct_control[`y_counter', 1] = 100 * `beta' / `temp_mean'
    } // end if r(N) != 0 (for new blank variables that are labels)
    
    * Increment the counters ***********************************************
    loc ++y_counter
}
```

The comments should make this code mostly self-explanatory. We look through each variable in our list of dependent variables. For a given dependent variable, we run a regression and save the results of that regression in various matrices. 

Notice that we use the `svy:` prefix before the regression. This is because we work with Stata's incredibly useful `survey` package. In the `analysis.do` file, notice that we include the following line: 

```
svyset commcode [pweight=weight_e1_e2], strata(county)
```

This saves the clustering, weighting, and fixed effects setting for all future regressions that are prefixed with the `svy:` command, enabling us to write a general function that can run different types of regressions seamlessly. There might be `svyset` commands sprinkled throughout the code, depending on if we are doing community-level or leader-level regressions. 

Read the documentation of `frmttable` to understand what's going on with the `stars` matrix. Matrices that hold the count of stars always have the same shape of the regression matrix, `reg_main`. 

## Adjusted p-values

To adjust p-values, we use the program referenced above `adjust_p_values`. Let's unpack the code here before going into that function, though. 

```
if "`adjustvars'" != "" {
    adjust_p_values, adjustvars(`adjustvars') adjustvarsmat(adjusted_ps) controls(`covariates') treat(`treat') nsims(`nsims') strata(district_bl) group(`subset')
    foreach y in `adjustvars' {
        local t = rownumb(adjusted_ps, "`y'")
        mat adjusted_ps_syms[`t', 1] = 1 
    }
}
```

Here, `adjustvars` is our family of outcomes we would like to group together in our analysis, and `adjusted_ps` is the name of the adjusted-p value matrix we will fill in. To fill in the matrix, we first get the row-number of the variable we are interested in, then impute it. 

### The `adjust_p_values` function. 

This code is really just a wrapper for the `wyoung` function. Many thanks to Damon Jones et al. for writing the this command. The comments in this code should make things self-explanatory. 

We use 1000 simulations in our analysis. However if you are pressed for time, feel free to drop the value down to 2! Given that we do not set a seed, we do not expect these numbers to replicate exactly. 


## The `frmttable` command

The following is a simplified version of the `frmttable` code in the table-making code. Given the otional arguments `omitpct` and `adjustvars`, the main code includes a variety of `if` statements. 

```
	cap frmttable, statmat(reg_count) sdec(0) varlabels 
	cap frmttable, statmat(control_mean) sdec(3) varlabels merge
	cap frmttable, statmat(reg_main) sdec(3) annotate(stars) asymbol(*,**,***) varlabels merge substat(1) squarebrack 
	cap frmttable, statmat(reg_pct_control) sdec(1) varlabels merge


	frmttable using out/tables/`filename', ///
	ctitle("Dependent Variable", "N", "Control Mean", "ITT", "ITT / control mean" \ ///
	"", "(1)", "(2)", "(3)", "(4)") ///
	tex ///
	fragment ///
	varlabels ///
	nocenter ///
	replace


	frmttable using out/rtf_tables/`filename', ///
	ctitle("Dependent Variable", "N", "Control Mean", "ITT", "ITT / control mean" \ ///
	"", "(1)", "(2)", "(3)", "(4)") ///	varlabels ///
	replace
```

Again, read the frmttable documentation to fully understant what this code is doing. To summarize, we merge all the different matrices together, then save the table as a`.tex` format in the `out/tables` folder

The most important command to understand here is `substat(1)`. Substat takes a table that looks like this: 

| a | b |
|---|---|
| c | d |
| e | f |

and turns it into 

|a|
|-|
|[b]|
|c|
|[d]|
|e|
|[f]|


## Notes about other functions

`aggregate_analysis_ate.do`: Notice the command `1.5 * net_g1 + 1.5 * net_g2`. This is because we have a 1-year survey and a 3-year survey, but only ask about behaviors in the past year. So we interpolate the gap using haalf of each estimate.

`ate_maker.do`: The most basic of the table-making programs. It can be used on any subset of the population.

`ate_maker_intensive.do`: Only used for the intensive treatment table, and nothing else. You will notice that we are *not* running a regression with an interaction term. `intense` observations are a strict subset of `assigned_ever` observations. Also notice that we have separate lists of controls for Endline 1 and Endline 2 regressions. We changed the specification for Endline 2 because we asked some new background questions, but wanted to keep our Endline 1 numbers matching exactly our previous published paper. This will definitely cause a bit of a headache when writing code. I apologize for the fact that this do-file calles covariates "regressors" while `ate_maker.do` calls them "covariates".

`ate_maker_inter` and `ate_maker_inter_demo`: These two are practically the same functions, the only difference being that `ate_maker_inter` allows for 3 interaction variables and `ate_maker_inter_demo` allows for 7. Why didn't I just make one function that allowed for any number of interaction variables? Good question. Adding the multi-level columns in an automated way would require some work generating strings. Stata is pretty far from a general purpose programming language, but R is closer. It might be worth trying to combine the two functions into one in R. 

`ate_maker_res_leader`: This function is for variables that both residents and leaders have in common, which is really just the norms and skills questions. 

`ate_maker_year`: This code is for comparing Endline 1 and Endline 3 effects. Only the outcomes related to conflict, at the resident level and community level, are present in both years. **Note that the function adds the suffix `_year` onto the end of the filename.**

`IV_maker_year`: The same as `ate_maker_year` but it uses instrumental variables instead of a normal ITT. In the Endline 1 paper, we used an instrumental variables approach because many treated commnuities had a long delay in receiving treatment, and were consequently just receiving treatment as we were performing the Endline survey. Ultimately, we decided that for the 3-year follow up we would use a simple ITT.

`summary_table`: Just a simple table that makes summary statistics. I think `estout` is ugly so I always have my own summary table and simple regression (column of covariates instead of dependent variables) done in `frmttable`. 

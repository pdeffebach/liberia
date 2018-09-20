
cap program drop summary_table
program define summary_table
	
	clear mata 
	set matsize 10000
	syntax varlist, FILENAME(name) SUBSET(varlist)


	mat stats = J(`:word count `varlist'', 8, .)
	mat rownames stats = `varlist'

	local i = 1
	foreach var in `varlist' {

		qui summarize `var' if `subset' == 1, detail

	mat stats[`i', 1] = r(mean)
	mat stats[`i', 2] = r(sd)
	mat stats[`i', 3] = r(min)
	mat stats[`i', 4] = r(p25)
	mat stats[`i', 5] = r(p50)
	mat stats[`i', 6] = r(p75)
	mat stats[`i', 7] = r(max)
	mat stats[`i', 8] = r(N)
	local ++i
	}

frmttable, ///
statmat(stats) ///
varlabels ///
sdec(3, 3, 2, 2, 2, 2, 2, 0) 


frmttable using out/tables/`filename', ///
ctitle("Variable", "Mean", "Std. dev", "Min", "25", "Median", "75", "Max", "Count" \ ///
"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)", "(8)") ///
varlabels /// 
tex ///
fragment ///
replace ///
nocenter


frmttable using out/rtf_tables/`filename', ///
ctitles("Variable", "Mean", "Std. dev", "Min", "25", "Median", "75", "Max", "Count" \ ///
"", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)", "(8)") ///
varlabels ///
replace

end

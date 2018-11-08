// Generate empty table //

clear all
eststo clear
estimates drop _all

loc columns = 5

set obs 10
gen x = 1
gen y = 1

forval i = 1/`columns' {
	qui eststo col`i': reg x y
}

loc count = 1
loc countse = `count' + 1

loc statnames ""
loc varlabels ""
loc surlist ""

// Load data //

use "$data_dir/UCT_FINAL_CLEAN.dta", clear

gen include = 1
replace include = 0 if maleres == 1

replace asset_total_ppp1 =  asset_total_ppp1 - asset_valroof_ppp1 if asset_niceroof1 == 1 // Exclude metal roof value from comparisons with metal roof households
replace asset_lntotal_ppp1 = asset_lntotal_noroof_ppp1 if asset_niceroof1 == 1

tempfile usedata
save `usedata'

// Construct distance measure //

loc meanvarlist ""
loc sdvarlist ""

foreach yvar in $regvars {

	loc meanvarlist "`meanvarlist' `yvar'_vmean = `yvar'0"
	loc sdvarlist "`sdvarlist' `yvar'_vsd = `yvar'0"

}

collapse (mean) `meanvarlist' (sd) `sdvarlist', by(village purecontrol)
keep if purecontrol == 0
merge 1:m village using `usedata', nogen

save `usedata', replace

loc meanvarlist ""
loc sdvarlist ""

foreach yvar in $regvars {

	loc meanvarlist "`meanvarlist' `yvar'_vmean = `yvar'1"
	loc sdvarlist "`sdvarlist' `yvar'_vsd = `yvar'1"

}

collapse (mean) `meanvarlist' (sd) `sdvarlist', by(village purecontrol)
keep if purecontrol == 1
merge 1:m village using `usedata', update nogen

foreach yvar in $regvars {

	gen `yvar'_absdev = abs(`yvar'_vmean - `yvar'0) / `yvar'_vsd if purecontrol == 0
	replace `yvar'_absdev = abs(`yvar'_vmean - `yvar'1) / `yvar'_vsd if purecontrol == 1

}

save `usedata', replace

/* SUR */

foreach yvar in $regvars {

	if "`yvar'" == "psy_index_z" replace include = 1 if maleres == 1
	else replace include = 0 if maleres == 1

	reg `yvar'1 i.spillover##c.`yvar'_absdev if include == 1 & treat == 0 & ~mi(endlinedate)
	est store e_`yvar'
	loc surlist "`surlist' e_`yvar'"

	loc `yvar'_N = e(N)

}

suest `surlist', vce(cl village)
est store sur

/* Hypothesis tests */

loc varindex = 1
loc varlist "$regvars"
loc length: list sizeof varlist

forval i = 1/3 {

	mat def B`i' = J(`length', 1, .)
	mat def SE`i' = J(`length', 1, .)
	mat def P`i' = J(`length', 1, .)

}

foreach yvar in $regvars {

	loc H1 = "[e_`yvar'_mean]1.spillover#c.`yvar'_absdev"
	loc H2 = "[e_`yvar'_mean]1.spillover"
	loc H3 = "[e_`yvar'_mean]`yvar'_absdev"

 	est restore sur

	forval i = 1/3 {

		qui lincom `H`i''
		mat def B`i'[`varindex', 1] = r(estimate)
		mat def SE`i'[`varindex', 1] = r(se)

		qui test `H`i'' = 0
		mat def P`i'[`varindex', 1] = r(p)

	}

	loc ++varindex

}

/* Fill table cells */

loc varindex = 1

foreach yvar in $regvars {

	forval i = 1/3 {

		loc b = B`i'[`varindex', 1]
		loc se = SE`i'[`varindex', 1]
		loc p = P`i'[`varindex', 1]

		sigstar, b(`b') se(`se') p(`p') prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col`i'
		estadd loc thisstat`countse' = "`r(sestar)'": col`i'

	}

	/* Column 4: Control Mean */

	qui sum `yvar'1 if purecontrol & include == 1
	estadd loc thisstat`count' = string(`r(mean)', "%9.2f"): col4
	estadd loc thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")": col4

	/* Column 5: N */

	estadd loc thisstat`count' = ``yvar'_N': col5

	/* Row Labels */

	loc thisvarlabel: variable label `yvar'1
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	loc statnames "`statnames' thisstat`count' thisstat`countse'"
	loc count = `count' + 2
	loc countse = `count' + 1
	loc ++varindex

}

/* Table options */

esttab col* using "$output_dir/${regtitle}_absdev.tex",  cells(none) booktabs nonum nonotes compress replace mtitle("Interaction" "\specialcell{Treated village}" "Sq. distance" "\specialcell{Control mean\\(Std. dev.)}" "Obs.") stats(`statnames', labels(`varlabels') )

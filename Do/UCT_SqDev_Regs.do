
foreach thisvarlist in $regvars {

*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	local totalcols = 5
	forvalues x = 1/`totalcols' {
		qui eststo col`x': reg x y
	}

	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""

*** DENOTE HOUSEHOLD VS INDIVIDUAL OUTCOMES ***
	local indcase = 0
	local hhcase = 0
	// weighting will be by the number of observations per household, as this is not balanced.
	if "`thisvarlist'" == "psyvars" | "`thisvarlist'" == "psyvars_weighted" | "`thisvarlist'" == "psyvars_weighted2" | "`thisvarlist'" == "politicalvars" local indcase = 1
	else local hhcase = 1
	if "`thisvarlist'" == "psyvars_weighted2" local thisweighting "[aw=weight2]"
	else if "`thisvarlist'" == "psyvars_weighted" local thisweighting "[aw=weight]"
	else local thisweighting ""


*** DATASET ***
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	cap drop weight weight2
	drop if treat
	drop if endlinedate == .
	gen include = 1
	if `hhcase' == 1 replace include = 0 if maleres
	if "`thisvarlist'" == "entvars_cond_ppp" replace include = 0 if ent_nonagbusiness0 ~= 1 // Conditional on Enterprise Ownership
	xi i.village, pref(fev) // village fixed effects
	replace asset_total_ppp1 =  asset_total_ppp1 - asset_valroof_ppp1 if asset_niceroof1 == 1 // Exclude metal roof value from comparisons with metal roof households
	replace asset_lntotal_ppp1 = asset_lntotal_noroof_ppp1 if asset_niceroof1 == 1
	tempfile usedata
	save `usedata'

	*** BASELINE DEVIATIONS ***

	loc meanvarlist ""
	loc sdvarlist ""

	foreach var in $`thisvarlist' {
		loc meanvarlist "`meanvarlist' `var'_vmean = `var'0"
		loc sdvarlist "`sdvarlist' `var'_vsd = `var'0"
	}

	collapse (mean) `meanvarlist' (sd) `sdvarlist', by(village spillover)
	keep if spillover == 1
	merge 1:m village using `usedata', nogen

	save `usedata', replace

	loc meanvarlist ""
	loc sdvarlist ""

	foreach var in $`thisvarlist' {
		loc meanvarlist "`meanvarlist' `var'_vmean = `var'1"
		loc sdvarlist "`sdvarlist' `var'_vsd = `var'1"
	}

	collapse (mean) `meanvarlist' (sd) `sdvarlist', by(village spillover)
	keep if spillover == 0
	merge 1:m village using `usedata', update nogen

	foreach var in $`thisvarlist' {
		gen `var'_sqdev = ((`var'_vmean - `var'0)^2) / `var'_vsd if spillover == 1
		replace `var'_sqdev = ((`var'_vmean - `var'1)^2) / `var'_vsd if spillover == 0
	}

	save `usedata', replace

*** REGRESSIONS FOR EACH ENDLINE OUTCOME ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres
		if `hhcase' == 1 & "`var'" ~= "psy_index_z" local thisweighting ""

		*** WEIGHTS FOR OUTCOMES AT THE INDIVIDUAL LEVEL ***
		cap drop weight weight2
		bysort surveyid: egen weight = count(`thisvarname') if include == 1
		bysort village: egen weight2 = count(`thisvarname') if include == 1
		replace weight2 =  1 / weight2 / weight
		replace weight = 1 / weight

		*** COLUMN 1: INTERACTION ***
		reg `thisvarname' i.spillover##c.`var'_sqdev if include == 1 `thisweighting', cluster(village)
		pstar 1.spillover#c.`var'_sqdev, prec(3)
		estadd local thisstat`count' = "`r(bstar)'": col1
		estadd local thisstat`countse' = "`r(sestar)'": col1

		*** COLUMN 2: DEVIATION ***
		pstar `var'_sqdev, prec(3)
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2

		*** COLUMN 3: SPILLOVER ***
		pstar 1.spillover, prec(3)
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3

		*** COLUMN 4: CONTROLS ***
		sum `thisvarname' if purecontrol & include == 1
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col4
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col4

		*** COLUMN 5: N ***
		sum `thisvarname' if include == 1
		local thisN = `r(N)'
		estadd scalar thisstat`count' = `thisN': col5

		*** SAVE AND ITERATE ***

		local thisvarlabel: variable label `thisvarname'
		if `count' == 1 local varlabels "`varlabels' "\midrule `thisvarlabel'" " " "
		else local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"

		local count = `count' + 2
		local countse = `count' + 1
	}

	esttab col* using "$output_dir/`thisvarlist'_sqdev.tex",  cells(none) booktabs nonum nonotes compress replace mtitle("Interaction" "Sq. deviation" "\specialcell{Treated village}" "\specialcell{Control mean\\(Std. dev.)}" "Obs.") stats(`statnames', labels(`varlabels') )
}

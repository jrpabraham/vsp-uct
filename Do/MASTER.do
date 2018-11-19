version 13.1
clear all
clear matrix
clear mata
cap log close
set matsize 5000
set maxvar 20000
set more off
set seed 479316908

global root "/Users/Justin/Repos/vsp-uct"
global ado_dir "$root/Ado"
global data_dir "$root/Data"
global output_dir "$root/Tables"
global figs_dir "$root/Figs"
global do_dir "$root/Do"

adopath + "$ado_dir"
cap cd "$root_dir"

// Set PPP Rate
global ppprate = 0.01601537

timer clear
timer on 1

********************************************************************************
******************************* DEFINE OUTCOMES ********************************
********************************************************************************

// Outcomes

global indices_ppp "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index psy_index_z ih_overall_index_z"
global indices_log "asset_ihstotal_ppp cons_ihsnondurable_ppp ent_ihstotal_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index psy_index_z ih_overall_index_z"
global fsvars "fs_adskipm_often fs_adwholed_often fs_chskipm_often fs_chwholed_often fs_hhcheapf_often fs_hhfriendf_often fs_foodcred_often fs_wildf_often fs_hhbeg_often fs_2meals fs_eatcont fs_meat fs_enoughtom fs_sleephun fs_selfprotein fs_hhfracprotein fs_childfracprotein  fs_childfoodindexnew fs_hhfoodindexnew"
global ihvars ""

// Controls as specified in Haushofer/Shapiro

global controlvars "b_age b_married b_edu b_children b_hhsize ent_wagelabor0 ent_ownfarm0 ent_business0 ent_nonagbusiness0"

********************************************************************************
********************************* CHECK DATA ***********************************
********************************************************************************

use "$data_dir/UCT_FINAL_CLEAN.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_MetalRoofHHs.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_UNMATCHED.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_Village_Collapsed.dta", clear
datasignature confirm, strict

***********************************************************************************
******************************* Distance ******************************************
***********************************************************************************

use "$data_dir/UCT_FINAL_CLEAN.dta", clear

// Construct additional outcome variables

replace asset_total_ppp1 =  asset_total_ppp1 - asset_valroof_ppp1 if asset_niceroof1 == 1 // Exclude metal roof value from comparisons with metal roof households
replace asset_lntotal_ppp1 = asset_lntotal_noroof_ppp1 if asset_niceroof1 == 1

forval i = 0/1 {

	gen asset_ihstotal_ppp`i' = asinh(asset_total_ppp`i')
	la var asset_ihstotal_ppp`i' "`: var la asset_total_ppp`i'' (log)"

	gen cons_ihsnondurable_ppp`i' = asinh(cons_nondurable_ppp`i')
	la var cons_ihsnondurable_ppp`i' "`: var la cons_nondurable_ppp`i'' (log)"

	gen ent_ihstotal_rev_ppp`i' = asinh(ent_total_rev_ppp`i')
	la var ent_ihstotal_rev_ppp`i' "`: var la ent_total_rev_ppp`i'' (log)"

}

// Construct distance measure //

loc regvars "$indices_ppp $indices_log"
global regvars: list uniq regvars

tempfile tempdata
save `tempdata'

loc meanvarlist ""
loc sdvarlist ""

foreach yvar in $regvars {

	loc meanvarlist "`meanvarlist' `yvar'_vmean = `yvar'0"
	loc sdvarlist "`sdvarlist' `yvar'_vsd = `yvar'0"

}

collapse (mean) `meanvarlist' (sd) `sdvarlist', by(village purecontrol)
keep if purecontrol == 0
merge 1:m village using `tempdata', nogen

save `tempdata', replace

loc meanvarlist ""
loc sdvarlist ""

foreach yvar in $regvars {

	loc meanvarlist "`meanvarlist' `yvar'_vmean = `yvar'1"
	loc sdvarlist "`sdvarlist' `yvar'_vsd = `yvar'1"

}

collapse (mean) `meanvarlist' (sd) `sdvarlist', by(village purecontrol)
keep if purecontrol == 1
merge 1:m village using `tempdata', update nogen

foreach yvar in $regvars {

    gen `yvar'_sqdev = ((`yvar'0 - `yvar'_vmean)^2) / `yvar'_vsd if purecontrol == 0
    replace `yvar'_sqdev = ((`yvar'1 - `yvar'_vmean)^2) / `yvar'_vsd if purecontrol == 1

    gen `yvar'_absdev = abs(`yvar'0 - `yvar'_vmean) / `yvar'_vsd if purecontrol == 0
    replace `yvar'_absdev = abs(`yvar'1 - `yvar'_vmean) / `yvar'_vsd if purecontrol == 1

}

saveold "$data_dir/UCT_FINAL_VSP.dta", replace

***********************************************************************************
******************************* Estimation ****************************************
***********************************************************************************

// Balance tables

global immutable_baseline "b_age b_married b_children b_hhsize b_edu"
do "$do_dir/UCT_PC_Baseline.do"

// Interaction with distances based on baseline outcome

global regvars "$indices_ppp"
global reglabel "indices_ppp"

do "$do_dir/UCT_SqDev_Regs.do"
do "$do_dir/UCT_AbsDev_Regs.do"
do "$do_dir/UCT_Poly_Regs.do"

global regvars "$indices_log"
global reglabel "indices_log"

do "$do_dir/UCT_SqDev_Regs.do"
do "$do_dir/UCT_AbsDev_Regs.do"
do "$do_dir/UCT_Poly_Regs.do"

// Interaction with Mahalanobis distance

global regvars "$indices_ppp"
global reglabel "indices_ppp"

do "$do_dir/UCT_Vector_Regs.do"

***********************************************************************************
******************************* Visualization *************************************
***********************************************************************************

global regvars "$indices_ppp"
global reglabel "indices_ppp"

do "$do_dir/UCT_Dist_Plot.do"

global regvars "$indices_log"
global reglabel "indices_log"

do "$do_dir/UCT_Dist_Plot.do"

timer off 1
qui timer list
di "Finished in `r(t1)' seconds."

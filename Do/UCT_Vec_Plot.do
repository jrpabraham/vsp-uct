use "$data_dir/UCT_FINAL_VSP.dta", clear

gen include = 1
replace include = 0 if maleres == 1

loc gphlist

foreach yvar in $regvars {

	if "`yvar'" == "psy_index_z" replace include = 1 if maleres == 1
	else replace include = 0 if maleres == 1

	qui reg `yvar'1 i.spillover##c.`yvar'_absdev##c.`yvar'_absdev if include == 1 & treat == 0 & ~mi(endlinedate)

	margins, dydx(1.spillover) at(c.`yvar'_absdev == (0(0.25)4))
	marginsplot, title("`:var la `yvar'1'", color(black)) xtitle("") ytitle("") ylabel(#4,glwidth(vthin) glcolor(black)) xlabel(0(1)4) plotopts(lcolor(black) mcolor(black)) ciopts(lcolor(black)) graphregion(color(white)) saving(`yvar'_margins, replace)
	loc gphlist "`gphlist' `yvar'_margins.gph"

}

graph combine `gphlist', col(2) ysize(8) xcommon graphregion(color(white))
graph export "$figs_dir/${reglabel}_margins.pdf", replace

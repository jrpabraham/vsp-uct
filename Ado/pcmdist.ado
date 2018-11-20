program define pcmdist, rclass
syntax varlist(min=1) [if] [in], gen(string) [by(string)]

cap noi {

	tempvar touse
	mark `touse' `if' `in'

	gen `gen' = .

	if `"`by'"' != "" {

		tempvar vuse
		gen `vuse' = 0

		ta `by' if `touse', matrow(bymat)
		loc rows = rowsof(bymat)

		forval i = 1/`rows' {

			replace `vuse' = (`by' == bymat[`i', 1]) & `touse'

			mat accum Cov = `varlist' if `vuse', nocons means(Means) deviations
			count if `vuse'
			mat Cov = Cov/(r(N)-1)

			mata: mu = st_matrix("Means")
			mata: S = st_matrix("Cov")
			mata: st_view(data = ., ., "`varlist'", "`vuse'")
			mata: st_view(distance = ., ., "`gen'", "`vuse'")
			mata: diff = data - (J(rows(data),1,1) * mu)
			mata: distance[., 1] = sqrt(diagonal(diff*invsym(S)*diff'))

		}

	}

	else {

		mat accum Cov = `varlist' if `touse', nocons means(Means) deviations
		count if `touse'
		mat Cov = Cov/(r(N)-1)

		mata: mu = st_matrix("Means")
		mata: S = st_matrix("Cov")
		mata: st_view(data = ., ., "`varlist'", "`touse'")
		mata: st_view(distance = ., ., "`gen'", "`touse'")
		mata: diff = data - (J(rows(data),1,1) * mu)
		mata: distance[., 1] = sqrt(diagonal(diff*invsym(S)*diff'))

	}

}

end

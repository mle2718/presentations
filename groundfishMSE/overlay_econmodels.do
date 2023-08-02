
/* load baseline sim data */
local resultsfolder "results_2023-06-27-16-57-45"


/* load in model level results ie bias and ieF */

use "$MSEprojdir/`resultsfolder'/model_level_results.dta", replace

sort replicate mproc stock
replace stock="yellowtailGB" if stock=="yellowtailflounderGB"

replace ie_F=ie_F_hat if ImplementationClass=="Economic"
replace ie_bias=iebias_hat if ImplementationClass=="Economic"

drop ie_F_hat iebias_hat
save `ies', replace


/* load in annual results and merge to model results & management procedures*/
use "$MSEprojdir/`resultsfolder'/yearly_results.dta", replace
qui summ year
local maxyear=r(max)
merge m:1 replicate mproc stock using `ies'
assert _merge==3
drop _merge

gen modeltype="baseline"
keep if mproc==1





keep if year>=2010

encode stock, gen(mystock)

replace stock="yellowtailGB" if stock=="yellowtailflounderGB"


sort stock year replicate mproc


/* this works, but it is a bit confusing

I need to borrow the prices from the relevant economic model. 
 */

assert mproc==1
levelsof stock, local(mystock)
sort mproc stock replicate year

foreach l of local mystock{
	
	
	
/*twoway (line Simulated_SSB year if mproc==1 & replicate==1 & stock=="`l'" & year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line Simulated_SSB year if replicate==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)), name(SSBcomp_`l',replace) title("`l'") */


twoway (line sumCW year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", connect(L) lcolor(gs12)) (line sumCW year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline" & replicate<=5, connect(L)) , name(sumcw_`l', replace) legend(off) ytitle("catch of `l'")

twoway (line Simulated_SSB year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", connect(L) lcolor(gs12)) (line Simulated_SSB year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline" & replicate<=5, connect(L)) , name(SSB_`l', replace) legend(off) ytitle("SSB of `l'")

	
twoway (line F_fullAdvice year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", connect(L) lcolor(gs12)) (line F_fullAdvice year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline" & replicate<=5, connect(L))  , name(FFA_`l', replace) legend(off) ytitle("F Advice for `l'")

twoway (line ACL year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", connect(L) lcolor(gs12)) (line ACL year if mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline" & replicate<=5, connect(L)) , name(ACL_`l', replace) legend(off) ytitle("ACL for `l'")

	
}

graph combine sumcw_codGB sumcw_codGOM sumcw_haddockGB sumcw_pollock sumcw_yellowtailGB
graph export "$MSEprojdir/`resultsfolder'/EconModel_CW_exp_comparisons.png", replace as(png) width(2000) 

	
graph combine SSB_codGB  SSB_codGOM SSB_haddockGB SSB_pollock SSB_yellowtailGB
graph export "$MSEprojdir/`resultsfolder'/EconModel_SSB_exp_comparisons.png", replace as(png) width(2000) 



graph combine FFA_codGB  FFA_codGOM FFA_haddockGB FFA_pollock FFA_yellowtailGB
graph export "$MSEprojdir/`resultsfolder'/EconModel_FFA_exp_comparisons.png", replace as(png) width(2000) 


graph combine ACL_codGB  ACL_codGOM ACL_haddockGB ACL_pollock ACL_yellowtailGB
graph export "$MSEprojdir/`resultsfolder'/EconModel_ACL_exp_comparisons.png", replace as(png) width(2000) 










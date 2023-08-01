
/* My experimental data all corresponds to simulations where mproc =1
	match to the actual data.
*/
global pounds_per_kg=2.20462
global kg_per_mt=1000

local myresults results_2023-07-18-14-26-18 results_2023-07-24-16-29-36


foreach resultsfolder of local myresults {
	tempfile new
	local NEWfiles `"`NEWfiles'"`new'" "'
	clear

/* load in model level results ie bias and ieF */

	use "$MSEprojdir/`resultsfolder'/model_level_results.dta", replace
	tempfile ies
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


	/* column renames to append into the baseline data */
	drop mproc
	rename replicate xreplicate
	rename ie_from_replicate replicate
	rename ie_from_model mproc
	gen modeltype="experimental"

	save `new', replace
}
clear
append using `NEWfiles'

tempfile experimental
save `experimental'
	

/* load baseline sim data */
local resultsfolder "results_2023-06-27-16-57-45"


/* load in model level results ie bias and ieF */

use "$MSEprojdir/`resultsfolder'/model_level_results.dta", replace
tempfile ies
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
gen xreplicate=0

append using `experimental', force


sort mproc replicate xreplicate stock year


/* pull prices from the economic model */

bysort stock year mproc replicate (xreplicate): replace avgprice_per_lb=avgprice_per_lb[1] if avgprice_per_lb==.
gen catchvalue=sumCW*${kg_per_mt}*${pounds_per_kg}*avgprice_per_lb/1000
label var catchvalue "catch value in thousands of real dollars"


keep if year>=2010

encode stock, gen(mystock)

replace stock="yellowtailGB" if stock=="yellowtailflounderGB"


sort stock year replicate mproc
preserve

keep if xreplicate<=40

/* this works, but it is a bit confusing

I need to borrow the prices from the relevant economic model. 
 */

assert mproc==1
levelsof stock, local(mystock)
sort mproc stock replicate xreplicate year

foreach l of local mystock{
	
		
		
	/*twoway (line Simulated_SSB year if mproc==1 & replicate==1 & stock=="`l'" & year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line Simulated_SSB year if replicate==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)), name(SSBcomp_`l',replace) title("`l'") */

	foreach myr of numlist 1(1)8{

		twoway (line sumCW year if mproc==1 & replicate==`myr' & stock=="`l'" &year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line sumCW year if replicate==`myr' & mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)) , name(sumcw_`myr', replace) legend(off) ytitle("catch of `l'")

		twoway (line Simulated_SSB year if mproc==1 & replicate==`myr' & stock=="`l'" &year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line Simulated_SSB year if replicate==`myr' & mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)) , name(SSB_`myr', replace) legend(off) ytitle("SSB of `l'")

			
		twoway (line F_fullAdvice year if mproc==1 & replicate==`myr' & stock=="`l'" &year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line F_fullAdvice year if replicate==`myr' & mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)) , name(FFA_`myr', replace) legend(off) ytitle("F Advice for `l'")

		twoway (line ACL year if mproc==1 & replicate==`myr' & stock=="`l'" &year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line ACL year if replicate==`myr' & mproc==1 & stock=="`l'" &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)) , name(ACL_`myr', replace) legend(off) ytitle("ACL for `l'")

		
	}

	graph combine sumcw_1 sumcw_2 sumcw_3 sumcw_4 sumcw_5 sumcw_6 sumcw_7 sumcw_8, ycommon
	graph export "$MSEprojdir/`resultsfolder'/CW_`l'_exp_comparisons.png", replace as(png) width(2000) 


		
	graph combine SSB_1 SSB_2 SSB_3 SSB_4 SSB_5 SSB_5 SSB_6 SSB_8, ycommon
	graph export "$MSEprojdir/`resultsfolder'/SSB_`l'_exp_comparisons.png", replace as(png) width(2000) 



	graph combine FFA_1 FFA_2 FFA_3 FFA_4 FFA_5 FFA_6 FFA_7 FFA_8, ycommon
	graph export "$MSEprojdir/`resultsfolder'/FFA_`l'_exp_comparisons.png", replace as(png) width(2000) 


	graph combine ACL_1 ACL_2 ACL_3 ACL_4 ACL_5 ACL_6 ACL_7 ACL_8, ycommon
	graph export "$MSEprojdir/`resultsfolder'/ACL`l'_exp_comparisons.png", replace as(png) width(2000) 

}
restore
keep if replicate<=8

/* compute IAVs */
preserve
bysort mproc modeltype stock replicate xreplicate (year): gen YOYcatch=sumCW-sumCW[_n-1]
bysort mproc modeltype stock replicate xreplicate (year): gen YOYSSB=Simulated_SSB-Simulated_SSB[_n-1]
bysort mproc modeltype stock replicate xreplicate (year): gen YOYcatchvalue=catchvalue-catchvalue[_n-1]


gen IAVcatch=YOYcatch^2
gen IAVSSB=YOYSSB^2
gen IAVcatchvalue=YOYcatchvalue^2


keep if year>=2020
gen marker=1
collapse (sum) IAVcatch IAVSSB IAVcatchvalue sumCW Simulated_SSB  catchvalue (count) marker, by(mproc replicate xreplicate stock)
gen denom1=sumCW/marker
replace IAVcatch=sqrt(IAVcatch/(marker-1))/denom1
gen denom2=Simulated_SSB/marker

replace IAVSSB=sqrt(IAVSSB/(marker-1))/denom2
gen denom3=catchvalue/marker
replace IAVcatchvalue=sqrt(IAVcatchvalue/(marker-1))/denom3

drop marker denom*
save "$MSEprojdir/`resultsfolder'/IAVexperimental.dta", replace

restore


/* aggregate revenues */
collapse (sum) catchvalue, by(year mproc replicate xreplicate modeltype)

preserve
sort mproc replicate xreplicate year
keep if xreplicate<=40
foreach myr of numlist 1(1)8{

	twoway (line catchvalue year if mproc==1 & replicate==`myr' & year>=2020 & modeltype=="experimental", connect(L) lcolor(gs12)) (line catchvalue year if replicate==`myr' & mproc==1 &year>=2020 & modeltype=="baseline", lwidth(medthick) lcolor(black)) , name(revs_`myr', replace) legend(off) ytitle("Modeled revenue")

}
graph combine revs_1 revs_2 revs_3 revs_4 revs_5 revs_6 revs_7 revs_8, ycommon
graph export "$MSEprojdir/`resultsfolder'/grossRev_exp_comparisons.png", replace as(png) width(2000)

restore



bysort mproc modeltype replicate xreplicate (year): gen YOYcatchvalue=catchvalue-catchvalue[_n-1]
gen IAVcatchvalue=YOYcatchvalue^2
keep if yea>=2020
gen marker=1
collapse (sum) IAVcatchvalue catchvalue (count) marker, by(mproc modeltype replicate xreplicate )

gen denom3=catchvalue/marker
replace IAVcatchvalue=sqrt(IAVcatchvalue/(marker-1))/denom3



ttest IAVcatch==.4626 if replicate==1 & xreplicate~=0
ttest IAVcatch==.4336 if replicate==2 & xreplicate~=0
ttest IAVcatch==.419 if replicate==3 & xreplicate~=0
ttest IAVcatch==0.44698 if replicate==4 & xreplicate~=0
ttest IAVcatch==0.35043 if replicate==5 & xreplicate~=0



local resultsfolder "results_2023-06-27-16-57-45"


/* load in model level results ie bias and ieF */

use "$MSEprojdir/`resultsfolder'/model_level_results.dta", replace
tempfile ies
sort replicate mproc stock
replace stock="yellowtailGB" if stock=="yellowtailflounderGB"

replace ie_F=ie_F_hat if ImplementationClass=="Economic"
replace ie_bias=iebias_hat if ImplementationClass=="Economic"

drop ie_F_hat iebias_hat
save `ies'


/* load in annual results and merge to model results & management procedures*/
use "$MSEprojdir/`resultsfolder'/yearly_results.dta", replace
qui summ year
local maxyear=r(max)
merge m:1 replicate mproc stock using `ies'
assert _merge==3
drop _merge



keep if year>=2010

encode stock, gen(mystock)

replace stock="yellowtailGB" if stock=="yellowtailflounderGB"

global pounds_per_kg=2.20462
global kg_per_mt=1000

sort stock year replicate mproc

bysort stock year replicate (mproc): replace avgprice_per_lb=avgprice_per_lb[1] if avgprice_per_lb==.
gen catchvalue=sumCW*${kg_per_mt}*${pounds_per_kg}*avgprice_per_lb/1000
label var catchvalue "catch value in thousands of real dollars"



bysort replicate stock year (mproc): gen baselinevalue=catchvalue[1]
bysort replicate stock year (mproc): gen baselinecatch=sumCW[1]

bysort replicate stock year (mproc): gen baselineSSB=Simulated_SSB[1]


gen Dvalue=catchvalue-baselinevalue
gen Dfrac=Dvalue/baselinevalue
label var Dvalue "Simulated Value minus EconMproc value"
label var Dfrac "Dvalue divided by EconMproc value"


gen Dcatch=sumCW-baselinecatch
label var Dvalue "Simulated Catch minus EconMproc catch"

gen DSSB=Simulated_SSB-baselineSSB


/* correlations in Catch, Value, and SSB by species*/


bysort stock: corr sumCW baselinecatch if mproc==4 
bysort stock: corr sumCW baselinecatch if mproc==4 & year>=2025 /* eliminate burn in stuff */
bysort stock: corr sumCW baselinecatch if mproc==4 & year==`maxyear' 



bysort stock: corr catchvalue baselinevalue if mproc==4 
bysort stock: corr catchvalue baselinevalue if mproc==4 & year>=2025 /* eliminate burn in stuff */
bysort stock: corr catchvalue baselinevalue if mproc==4 & year==`maxyear' 



bysort stock: corr Simulated_SSB baselineSSB if mproc==4 
bysort stock: corr Simulated_SSB baselineSSB if mproc==4 & year>=2025 /* eliminate burn in stuff */
bysort stock: corr Simulated_SSB baselineSSB if mproc==4 & year==`maxyear' 

levelsof stock, local(stocknames)


foreach l of local stocknames{

twoway(scatter Simulated_SSB baselineSSB if mproc==4 & stock=="`l'"& year>=2025)  (lfit Simulated_SSB baselineSSB if mproc==4 & stock=="`l'"& year>=2025) (scatter baselineSSB baselineSSB if mproc==4 & stock=="`l'"& year>=2025, c(l) ms(none)), legend(order(1 "IE Simulated SSB" 2 "least squares fit" 3 "45 degree")) name(SSB_`l', replace) title("`l'")


twoway(scatter Simulated_SSB baselineSSB if mproc==4 & stock=="`l'" & year>=`maxyear' )  (lfit Simulated_SSB baselineSSB if mproc==4 & stock=="`l'" & year>=`maxyear' ) (scatter baselineSSB baselineSSB if mproc==4 & stock=="`l'" & year>=`maxyear', c(l) ms(none)), legend(order(1 "IE Simulated SSB" 2 "least squares fit" 3 "45 degree")) name(End_SSB_`l',replace) title("`l'")



twoway(scatter catchvalue baselinevalue if mproc==4 & stock=="`l'" & year>=2025)  (lfit catchvalue baselinevalue if mproc==4 & stock=="`l'" & year>=2025) (scatter baselinevalue baselinevalue if mproc==4 & stock=="`l'"& year>=2025, c(l) ms(none)), legend(order(1 "IE Catch Value" 2 "least squares fit" 3 "45 degree")) name(catchvalue_`l',replace) title("`l'")


twoway(scatter sumCW baselinecatch if mproc==4 & stock=="`l'"& year>=2025)  (lfit sumCW baselinecatch if mproc==4 & stock=="`l'"& year>=2025) (scatter baselinecatch baselinecatch if mproc==4 & stock=="`l'"& year>=2025, c(l) ms(none)), legend(order(1 "IE Catch" 2 "least squares fit" 3 "45 degree")) name(catch_`l',replace) title("`l'")

}

/* on a replicate-by-replicate basis, the ie models really don't match the baseline models very well*/
graph combine catch_codGOM catch_codGB catch_haddockGB catch_pollock catch_yellowtailGB
graph export "$MSEprojdir/`resultsfolder'/catch_comparisons.png", replace as(png) width(2000)

graph combine catchvalue_codGOM catchvalue_codGB catchvalue_haddockGB catchvalue_pollock catchvalue_yellowtailGB
graph export "$MSEprojdir/`resultsfolder'/value_comparisons.png", replace as(png) width(2000)

graph combine SSB_codGOM SSB_codGB SSB_haddockGB SSB_pollock SSB_yellowtailGB

graph export "$MSEprojdir/`resultsfolder'/SSB_comparisons.png", replace as(png) width(2000)


/* keep if mproc==1 will give me my economic model results


 twoway (line Simulated_SSB year if replicate<=30 & mproc==4 & stock=="`l'" &year>=2020, connect(L) lcolor(gs12)) (line baselineSSB year if replicate==1 & mproc==4 & stock=="`l'" & year>=2020, lwidth(medthick) lcolor(black)) name(SSBcomp_`l',replace) title("`l'")

*/


preserve

/* A'mar IAV */
/* year-on-year changes */

bysort mproc replicate stock (year): gen YOYcatch=sumCW-sumCW[_n-1]
bysort mproc replicate stock (year): gen YOYSSB=Simulated_SSB-Simulated_SSB[_n-1]
bysort mproc replicate stock (year): gen YOYcatchvalue=catchvalue-catchvalue[_n-1]


gen IAVcatch=YOYcatch^2
gen IAVSSB=YOYSSB^2
gen IAVcatchvalue=YOYcatchvalue^2


keep if yea>=2020
gen marker=1
collapse (sum) IAVcatch IAVSSB IAVcatchvalue sumCW Simulated_SSB  catchvalue (count) marker, by(mproc replicate stock)
gen denom1=sumCW/marker
replace IAVcatch=sqrt(IAVcatch/(marker-1))/denom1
gen denom2=Simulated_SSB/marker

replace IAVSSB=sqrt(IAVSSB/(marker-1))/denom2
gen denom3=catchvalue/marker
replace IAVcatchvalue=sqrt(IAVcatchvalue/(marker-1))/denom3

drop marker denom*
save "$MSEprojdir/`resultsfolder'/IAV.dta", replace

restore

/*
1. Are things correlated?
	F, catch, landings across species at the same time?
		This is simple, I can just by replicate (mproc) : "corr" depvar	
	ie_F? (not the average ie, but the deviations: F-F_FullAdvice.)
	
	The errors are simply "F_full divided by F_fullAdvice"
	
      iefit_n <- length(errs)
      iefit_lx <- log(errs)
      iefit_mx <- mean(iefit_lx)
      
      #ieF_hat is simply the sdlog term.
      omval$ie_F_hat[r,m]<-ie_F_hat <- sqrt((iefit_n - 1)/iefit_n) * sd(iefit_lx)
      omval$iebias_hat[r,m]<-  iebias_hat<- exp(iefit_mx)-1

	
	
	
	
*/
preserve
collapse (sum) catchvalue , by(replicate mproc year)
replace catch=catch/1000
label var catchvalue "catch value in millions of real dollars"

keep if year>=2020
graph box catch if inlist(mproc,1,2,4), over(mproc) over(year)
bysort year: ttest catchvalue if mproc<=2, by(mproc)


keep if inlist(mproc,1,2, 4)
reshape wide catchvalue, i(replicate year) j(mproc)
gen delta14=catchvalue1-catchvalue4
gen delta12=catchvalue1-catchvalue2
gen delta24=catchvalue2-catchvalue4

levelsof year, local(myyears)
foreach y of local myyears{
	di "working on year `y'"
	sktest delta14 if year==`y'
	
}
gen df3=(1.03)^(-1*(year-2020))
gen df7=(1.07)^(-1*(year-2020))


gen Dcatchvalue1=catchvalue1*df3
gen Dcatchvalue2=catchvalue2*df3
gen Dcatchvalue4=catchvalue4*df3

collapse (sum) Dcatch* catch*, by(replicate)


restore

preserve
keep if year>=2018
keep rep mproc year stock Sim sumCW ACL F_full F_fullAdvice
rename Sim SSB
rename F_fullAdvice F_FA
gen errs=F_full/F_FA
gen catchRatio=sumCW/ACL


reshape wide SSB sumCW ACL F_full F_FA catchRatio errs, i(replicate mproc year) j(stock) string


*keep if replicate==11

/*

bysort replicate year stock (mproc): gen deltaCW=sumCW-sumCW[_n-1]
bysort replicate year stock (mproc): gen deltaFfull=F_full-F_full[_n-1]

local CWnames 
levelsof stock, local(mystocks)
foreach l of local mystocks{
	local CWnames `" `CWnames' CW_`l' "'

	graph box deltaCW if mproc==2 & stock=="`l'", over(year) name(CW_`l', replace) title("Catch Weight `l'") 
	graph box deltaFfull if mproc==2 & stock=="`l'", over(year) name(FFull_`l', replace) title("F Full `l'") 


}
mac list

graph combine `CWnames'

local FFull: subinstr local CWnames "CW_" "FFull_", all

graph combine `FFull'


/* are yearly species outcomes correlated?

	Do we get high catch of all stocks and low catch of all stocks?

 */



bysort mproc: corr sumCW*

/* the simple correlation shows a pretty large correlations in catch of the GB stocks in the econ model. */

bysort mproc: corr sumCW* if year>=2025




/* here is the ie in R 

      iefit_n <- length(errs)
      iefit_lx <- log(errs)
      iefit_mx <- mean(iefit_lx)
      
      #ieF_hat is simply the sdlog term.
      omval$ie_F_hat[r,m]<-ie_F_hat <- sqrt((iefit_n - 1)/iefit_n) * sd(iefit_lx)
      omval$iebias_hat[r,m]<-  iebias_hat<- exp(iefit_mx)-1

	  
  FIMP=FFA*(1+iebias)

F_Full is drawn from a log-normal distribution with mean=ln(FIMP) and sdlog=ie_F


Divided F_Full by F_FA, then subtract 1.
	  
	  
*/

scatter iepollock iecodGOM if mproc==1
scatter iepollock iecodGOM if mproc==2



bidensity sumCWhaddockGB sumCWcodGB if mproc==1 , colorlines legend(off) levels(4)
bidensity sumCWhaddockGB sumCWcodGB if mproc==2 , colorlines legend(off) levels(4)


bidensity catchRatiopollock catchRatiocodGOM if mproc==1 , colorlines legend(off) levels(4)
bidensity catchRatiopollock catchRatiocodGOM if mproc==2 , colorlines legend(off) levels(4)

 */

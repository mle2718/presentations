global output_dir "${presentations}\groundfishMSE\20230807_Integrated_Economic_Models_Lee\Images"


use "$MSE_network\data\data_raw\econ\input_price_series_MSE.dta",clear
keep gffishingyear spstock2 doffy fuelprice wkly_crew
collapse (mean) fuel wkly, by(gffishing doffy)
drop if doffy==366
gen date=mdy(4,30,gffishingyear)
replace date=date+doffy
format date %td

tsset gffishingyear doffy

xtline fuelprice if inlist(gffishingyear,2011,2015), scheme(plottigblind)  overlay ytitle("fuel price") xtitle("day of fishing year") legend(order(1 "2011" 2 "2015") rows(1) position(6))
graph export ${output_dir}/fuelprice.png, width(2000) as(png) replace

use "$MSE_network\data\data_raw\econ\output_price_series_MSE.dta",clear

keep gearcat gffishing doffy p_*
collapse (mean) p_*, by(gearcat gffishing doffy)
collapse (mean) p_*, by(gffishing doffy)

drop if doffy==366
gen date=mdy(4,30,gffishingyear)
replace date=date+doffy
format date %td
gen month=month(date)
replace month=month-4
replace month=month+12 if month<=0


order month
rename month month_of_fy
collapse (mean) p*, by(month gffishingyear)
tsset gffishingyear month

xtline p_codGB, overlay scheme(plottigblind)  ytitle("GB Cod Price") xtitle("month of fishing year") legend(order(1 "2010" 2 "2011" 3 "2012" 4 "2013" 5 "2014" 6 "2015") rows(1) position(6))


gen cod_to_monk=p_codGOM/p_monk

xtline cod_to_monk if inlist(gffishingyear, 2010, 2013), overlay scheme(plottigblind)  ytitle("Ratio of Cod to Monkfish Price") xtitle("month of fishing year") legend(order(1 "2010" 2 "2013") rows(1) position(6))
graph export ${output_dir}/cod_to_monk_ratio.png, width(2000) as(png) replace



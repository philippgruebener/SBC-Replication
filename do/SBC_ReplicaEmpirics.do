/*
	This file replicates the empirical results for 
	Skewed Business Cycles by Salgado, Guvenen, and Bloom 
	First version Apr, 04, 2019
	This  version Dec, 16, 2019
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado
	ssalgado@wharton.upenn.edu
	https://sergiosalgadoi.wordpress.com/
*/

clear all
set more off
set matsize 1000
cd "../SBC-Replication/"
	// Main location

*##################################	
*REPLICA TABLE 2 OF PAPER
*##################################	
	*Aggregate 
	*Annual US GDP from FRED
	import excel using "replicationxls/SBC_AGGREGATE.xls", sheet("US Growth Annual GDP Per Capita") cellrange(A1:B54) first clear 
	sort year
	save "replicationxls/auxA.dta", replace
	
	*Quarterly US GDP from FRED
	import excel using "replicationxls/SBC_AGGREGATE.xls", sheet("US Growth Qtr GDP Per Capita") cellrange(A1:B191) first clear 
	sort qtr
	save "replicationxls/auxQ.dta", replace
	
	*Annual Country GDP per capita from WDI
	import excel using "replicationxls/SBC_AGGREGATE.xls", sheet("Ctry Growth Annual GDP Per Cap") cellrange(A1:C839) first clear 
	sort iso3 year
	save "replicationxls/auxC.dta", replace	
	
	*Quarterly Country GDP per capita from OECD Stats
	import excel using "replicationxls/SBC_AGGREGATE.xls", sheet("Ctry Growth Qtr GDP Per Cap") cellrange(A1:C4626) first clear 
	sort iso3 qtr
	save "replicationxls/auxCQ.dta", replace
	

	*Column 1. USA LBD Employment Growth
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	merge 1:1 year using "replicationxls/auxA.dta", nogenerate keep(1 3)
	tsset year 
	
	*Re scale GDP growth
	sum dAGDPPC
	replace dAGDPPC = dAGDPPC/r(sd)
	
	*Trend 	
	gen trend = _n
	
	eststo ksk_model1: newey  ksk dAGDPPC trend,  lag(1)
	predict aux if e(sample)
	corr ksk aux  if e(sample)
	di r(rho)^2
	drop aux
	
	*Column 2. USA Sales Growth
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:U1097) first clear 
	replace ksk = 100*ksk
	keep if group == "all"
	merge 1:1 year using "replicationxls/auxA.dta", nogenerate keep(1 3)
	tsset year 
	
	*Re scale GDP growth
	sum dAGDPPC
	replace dAGDPPC=dAGDPPC/r(sd)
	
	*Trend 	
	gen trend = _n
	
	*regs
	eststo ksk_model2: newey  ksk dAGDPPC trend,  lag(1)
	predict aux if e(sample)
	corr ksk aux  if e(sample)
	di r(rho)^2
	drop aux
	
	*Column 3. USA Stock Returns
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Quarter Stock Returns") cellrange(A1:U189) first clear 
	replace ksk = 100*ksk
	keep if group == "all"
	merge 1:1 qtr using "replicationxls/auxQ.dta", nogenerate keep(1 3)
	split(qtr), p(q)
	destring qtr1 qtr2, replace 
	rename qtr2 quarter
	drop qtr
	gen qtr = yq(year,quarter)
	format %tq qtr
	tsset qtr 
	
	*Re scale GDP growth
	sum dQGDPPC
	replace dQGDPPC =dQGDPPC/r(sd)
	
	*Trend 	
	gen trend = _n
	
	*Regs
	eststo ksk_model3: newey  L4.ksk dQGDPPC trend,  lag(1)
	predict aux if e(sample)
	corr ksk aux  if e(sample)
	di r(rho)^2
	drop aux
	
	*Column 4. Cross Country Employment Growth
	set more off
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Country Employment Growth") cellrange(A1:T706) first clear 
	replace ksk = 100*ksk
	sort iso3 year
	merge 1:1 iso3 year using "replicationxls/auxC.dta",nogenerate
	sort iso3 year
	
	*Re scale GDP growth
	levelsof iso3, local(iso) clean
	foreach ii of local iso{
		qui: sum dAGDPPC  if iso3  == "`ii'"
		qui: replace dAGDPPC  = dAGDPPC/r(sd)  if iso3  == "`ii'"
	}	
	egen iso_id = group(iso3)
	drop if ksk < -90
	drop if ksk > 90
	eststo ksk_model4 : reg ksk dAGDPPC i.year i.iso_id, vce(cl iso_id )
	
	*Column 5. Cross Country Sales Growth
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Country Annual Sales Growth") cellrange(A1:T721) first clear 
	replace ksk = 100*ksk
	sort iso3 year
	merge 1:1 iso3 year using "replicationxls/auxC.dta",nogenerate
	sort iso3 year
	
	*Re scale GDP growth
	levelsof iso3, local(iso) clean
	foreach ii of local iso{
		qui: sum dAGDPPC  if iso3  == "`ii'"
		qui: replace dAGDPPC  = dAGDPPC/r(sd)  if iso3  == "`ii'"
	}	
	egen iso_id = group(iso3)
	keep if ksk != . & dAGDPPC != . 
	eststo ksk_model5 : reg ksk dAGDPPC i.year i.iso_id, vce(cl iso_id)
	
	
	*Column 6. Cross Country Stock Returns
	*NOTE: data from the US is the same as the one used in column 3
	set more off
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Country Stock Returns") cellrange(A1:Q9646) first clear 
	replace ksk = 100*ksk
	
	keep if num >= 100		// Keep quarter/year cell with more than 100 firms
							// This keeps 40 countries. It is the data of quaterly GDP growth that reduces the 
							// number of observations to 28
	sort iso3 qtr
	merge 1:1 iso3 qtr using "replicationxls/auxCQ.dta",nogenerate keep(3)
	split(qtr), p(q)
	destring qtr1 qtr2, replace 
	rename qtr1 year
	rename qtr2 quarter
	drop qtr
	gen qtr = yq(year,quarter)
	format %tq qtr
	sort iso3 qtr
	egen iso_id = group(iso3)

	*Re scale GDP growth
	levelsof(iso3), local(iso) clean
	foreach ii of local iso{
		sum dQGDPPC if iso3 == "`ii'"
		replace dQGDPPC  = dQGDPPC /r(sd) if iso3 == "`ii'"
	}
	
	drop if ksk < -90		// Drop some extreme outliers. Results not affected. 
	drop if ksk > 90
	eststo ksk_model6: reg  ksk dQGDPPC i.iso_id i.qtr, vce(cl iso_id) 
	
	*Colum 7. Cross Country TFP
	*Load  data
	set more off
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", ///
		sheet("Amadeus TFP Shocks") cellrange(A1:CW7420) first clear 

	*Droping Outliers and moments calculated with less than 100 observations. 
	*results stronger if we do not control for outliers/number of observations
	egen isonum = group(iso3)
	keep if nobs1 >100										
	foreach ii in 1 2 3 4{
		_pctile ksk`ii', p(5 95)
		replace ksk`ii' =  r(r1) if (ksk`ii' < r(r1))
		replace ksk`ii' =  r(r2) if (ksk`ii' > r(r2))
		_pctile me`ii', p(5 95)
		replace me`ii' =  r(r1) if (me`ii' < r(r1))
		replace me`ii' =  r(r2) if (me`ii' > r(r2))
	}
		
	*This is for the regression table
	egen isoxnai = group(isonum nai)
	tsset isoxnai year
	gen aux = megs
	drop megs 
	rename aux megs
	
	levelsof isonum, local(isos)
	foreach ii of local isos{
			sum megs if isonum == `ii' 
			replace megs = megs/r(sd) if isonum == `ii'
	}
	eststo ksk_model7:  reg ksk1 megs i.year i.isonum i.nai, vce(cl isonum)
	
	
	*Column 8. Industry Employment
		*Load data of sales growth 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 
		
		drop if inlist(group,"all")
		egen idnaics = group(group )
		tsset idnaic year
		
		*Adjusting outliers. Qualitatively, does not matter
		drop if me == . | ksk ==. 
		replace me = -.2 if me <= -.2
		replace me =  .2 if me >=  .2 
		
		levelsof group, local(dsub)
		foreach vv of local dsub{
			sum me if group == "`vv'"
			replace me = me/(r(sd)) if group == "`vv'" 
		}
		keep group year me 
		rename me me_sales_g1
		sort group year
		save "replicationxls/aux_data_g1.dta",replace
		
		*Load data of employment
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Employment Growth") cellrange(A1:V1095) first clear 
		merge 1:1 group year ///
			using  "replicationxls/aux_data_g1.dta", nogenerate keep(1 3)
		drop if inlist(group,"all")
		egen idnaics = group(group )
		tsset idnaic year
		
		replace ksk = . if ksk > 0.90 | ksk < -.90
		drop if ksk == . 
		replace ksk = 100*ksk
		
		eststo ksk_model8: reg ksk me_sales_g1 i.year i.idnaic , vce(cl idnaic)	
	
	*Column 9. Industry Sales
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 
	
	drop if inlist(group,"all")
	egen idnaics = group(group )
	tsset idnaic year
	
	*Adjusting outliers. Qualitatively, does not matter
	drop if me == . | ksk ==. 
	replace me = -.2 if me <= -.2
	replace me =  .2 if me >=  .2 
	replace ksk = . if ksk > 0.9 
	replace ksk = . if ksk < -0.9 
	
	replace ksk = 100*ksk
	
	levelsof group, local(dsub)
		foreach vv of local dsub{
			sum me if group == "`vv'"
			replace me = me/(r(sd)) if group == "`vv'" 
	}
	
	eststo ksk_model9: reg ksk me i.year i.idnaic, cl(idnaics)
	
	
	*Column 10. Industry Stock Returns	
		*Load data of sales growth 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Quarter Sales Growth") cellrange(A1:U4325) first clear 
		
		drop if inlist(group,"all")
		egen idnaics = group(group )
		
		*Adjusting outliers. Qualitatively, does not matter
		drop if me == .
		replace me = -.2 if me <= -.2
		replace me =  .2 if me >=  .2 
		
		levelsof group, local(dsub)
		foreach vv of local dsub{
			sum me if group == "`vv'"
			replace me = me/(r(sd)) if group == "`vv'" 
		}
		keep group qtr me 
		rename me me_sales_g2
		sort group qtr
		save "replicationxls/aux_data_g2.dta",replace
	
		*Load data of Stock Prices
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Quarter Stock Returns") cellrange(A1:U4325) first clear 
		drop if inlist(group,"all")
		egen idnaics = group(group )
		
		*merge sales data 
		merge 1:1 group qtr using "replicationxls/aux_data_g2.dta"

		*Adjust for outliers
		replace ksk = . if ksk > 0.9 
		replace ksk = . if ksk < -0.9 
		replace ksk = 100*ksk
		
		*gen qtr as numebr for regression
		egen nqtr = group(qtr)
		
		eststo ksk_model10: reg ksk me_sales_g2  i.nqtr i.idnaic, cl(idnaics)
		
	*Column 11 from Census. Underlying data not reported;	
	
	*Save table with results 
	esttab ksk_model* using  "figs/TABLE2.tex", replace   ///
	stats(r2 N, labels(R-squared "N. of Observations "))  star(* 0.1 ** 0.05 *** 0.01) se  	///
	keep(dAGDPPC dQGDPPC me megs me_sales_g1 me_sales_g2)
	eststo clear
	
*##################################	
*REPLICA MAIN FIGURES OF THE PAPER 
*##################################	

*Replica Figure 1A. This figure was created using LBD data. Underlying data not reported

*Replica Figure 1B. The first part only replicates plot. To replicate kernel density from 
*the underlying data, run do-files for raw data,
*construct the file SBC_A_CSTAT_1961_2018_clean.dta using corresponding do-file. 
	
		*Load 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Kernel Density") cellrange(A1:D87) first clear 
		
		*Plot
		tw line boom_density rece_density rece_x if rece_x >= -1.5 & rece_x <= 1.5, ///							
		  lwidth(medthick medthick) lcolor(blue red) lpattern(dash solid)  ///
			xlabel(-1.5 "-1.5" -1.0 "-1.0" -0.5  "-.5" 0  "0".5  ".5" 1.0  "1.0" 1.5  "1.5",grid format(%9.1f)) ///						
		xtitle("Log Sales Growth") ytitle("Density") plotregion(lcolor(black)) ///
		graphregion(color(white)) ylabel(0 "0" 0.5 "0.5" 1 "1" 1.5 "1.5" 2 "2") ///
		legend(order(1 "Expansion" 2 "Recession") rows(2) position(2) ring(0)) graphregion(color(white))  	
		cap noisily: graph export "figs/SBC_Fig1B.pdf", replace	

*Replica Figure 2A:
	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", ///
		sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	keep if year>= 1978
	*Recession variable 
	gen recession = 0
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009 
	
	replace ksk = ksk/100
	
	*Plot
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected  ksk year , color(blue black) lpattern(solid dash dash_dot) ///
	msymbol(O S) msize(large) mfcolor(blue*0.25 black*0.25)  ///	Fill color
	mlcolor(blue black) ///
	yaxis(2) yscale(alt axis(2)) plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Log Employment Growth", axis(2)) ylabel(-0.2(0.1)0.3,axis(2))) , ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid) ///
	legend( off position(7) ring(0) rows(2) order(2 "Census LBD" 3 "Compustat") region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig2A.pdf", replace	

*Replica Figure 2B:
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1087) first clear 
		
	*Recession variable 
	gen recession = 0
	replace recession = 1/4 if year == 1973
	replace recession = 1 if year == 1974
	replace recession = 1/4 if year == 1975
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009
	
	*Scaling 
	keep if group == "all"
	
	*drop  if year if above 2013
	*Something odd happens in the data in 2014 that makes the skewness declines substantially which is 
	*not associated to a particular aggregate shock. We are currently investigating the reasons behind this drop 
	drop if year >= 2014
	
	*Plot 
	tw  (bar rece year,   c(l) color(gs12 ) yscale(off)) ///	
	(connected ksk year, color(black) msymbol(O S) msize(large) mfcolor(black*0.25)  ///	Fill color
	mlcolor(black)  plotregion(lcolor(black)) ///
	yaxis(2) yscale(alt axis(2)) ///
	ytitle("Kelley Skewness of Log Sales Growth", axis(2)) ylabel(-.2 "-.2" -.1 "-.1" 0 "0" .1 ".1" .2 ".2" .3 ".3",  axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1970(5)2010, grid) ///
	legend(size(small) off rows(1) order(1 "GDP growth" 2 "1 year" 3 "3 year" 4 "5 year") region(lcolor(white))) graphregion(color(white))
		cap: graph export "figs/SBC_Fig2B.pdf", replace 
		

*Replica Figure 3A:
	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	keep if year>= 1978
	
	*Recession variable 
	gen recession = 0
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009 
	
	replace p5010 = p5010/100
	replace p9050 = p9050/100
	
	*Plot
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected  p9050 p5010 year , color(blue black ) msymbol(O S) lpattern(dash solid dash_dot) ///
		 yaxis(2) yscale(alt axis(2)) msize(medlarge medlarge) mfcolor(blue*0.25 black*0.25)  ///
	ytitle("P90-P50 and P50-P10 of Log Employment Growth", axis(2)) ylabel(,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1978(4)2014,grid) ///
	legend(position(7) ring(0) rows(2) order(2 "P9050" 3 "P5010") region(lcolor(white))) ///
	graphregion(color(white))  plotregion(lcolor(black))
	cap noisily: graph export "figs/SBC_Fig3A.pdf", replace	
	
*Replica Figure 3B:
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 
		
	*Recession variable 
	gen recession = 0
	replace recession = 1/4 if year == 1973
	replace recession = 1 if year == 1974
	replace recession = 1/4 if year == 1975
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009
	
	keep if group == "all"	
	drop if year >= 2014
	
	*Plot
	tw  (bar rece year,   c(l) color(gs12 ) yscale(off)) ///	
	(connected p9050 p5010 year, ///
	msymbol(O S) color(blue black) lpattern(longdash solid) yaxis(2) yscale(alt axis(2)) ///
	msize(medlarge medlarge) mfcolor(blue*0.25 black*0.25)  plotregion(lcolor(black)) ///
	ytitle("P9050 and P5010 of Log Sales Growth", axis(2)) ylabel(0.1 ".1" 0.2 ".2" 0.3 ".3" 0.4 ".4" 0.5 ".5",axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1970(5)2010,grid) ///
	legend(ring(0) position(11) rows(2) order(2 "P9050" 3 "P5010") region(lcolor(white))) graphregion(color(white)) 
		cap: graph export "figs/SBC_Fig3B.pdf", replace


*Replica Figure 4A. The first part only replicates plot. To replicate kernel density from 
*the underlying data, run do-files for raw data,
	
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", ///
			sheet("Country Kernel Density") cellrange(A1:D56) first clear 
		
		*Plot		  	
		tw line boom_density rece_density rece_x if rece_x>= -1.5 & rece_x <= 1.5 , ///				
		  lwidth(medthick medthick) lcolor(blue red) lpattern(dash solid) ///
		xtitle("Log Sales Growth") ytitle("Density")  plotregion(lcolor(black)) ///
		graphregion(color(white)) xlabel(-1.5 "-1.5" -1 "-1" -.5 "-.5" 0 "0" .5 ".5" 1 "1" 1.5 "1.5", grid) ///
		legend(order(1 "Expansions" 2 "Recessions") rows(2) position(2) ring(0) ///
		 region(lcolor(black))) graphregion(color(white))  ylabel(0 "0" 0.5 "0.5" 1 "1" 1.5 "1.5")
		cap noisily: graph export "figs/SBC_Fig4A.pdf", replace	
		
*Replica Figure 4B1 and 4B2
	*Load 
	set more off
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Country Employment Growth") cellrange(A1:T706) first clear 

	
	*Gen numeric value of iso
	egen iso_id = group(iso3)
	
	*Regression 
	reg ksk me i.year i.iso_id, vce(cl iso_id)
	
	*Winsor some extreme growth values to have a more compact plot
	*This does not change the results
	replace me = .30 if me > .30
	replace me = -.30 if me < -.30
	keep if num > 100			// Keep only those calculated with more than 100 observations

	
	*Generating the binscatter 
	binscatter 	 ksk me, nodraw nquantiles(80)  controls(i.year i.iso_id) ///
		savedata("figs/emp_countries_1yr") 	replace
	insheet using "figs/emp_countries_1yr.csv", clear names comma
	erase "figs/emp_countries_1yr.csv"
	erase "figs/emp_countries_1yr.do"
	
	*Saving Scatter 
	tw (scatter ksk me, mcolor(navy) msize(vlarge) msymbol(O) mfcolor(navy*0.25) ) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Log Employment Growth",size(large))  plotregion(lcolor(black)) ///
	ytitle("",size(large)) title("Log Employment Growth", color(black) size(vlarge)) ///
	graphregion(color(white)) ylabel(-.30(.15).60,labsize(large)) xlabel(,grid labsize(large))  ///
	legend(off ) graphregion(color(white))  name(FIGE4A, replace)		
	
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Country Annual Sales Growth") cellrange(A1:T706) first clear 
	
	*Gen numeric value of iso
	egen iso_id = group(iso3)
	
	*Regression 
	reg ksk me i.year i.iso_id, vce(cl iso_id)
	
	*Winsor some extreme growth values 
	replace me = .30 if me > .30
	replace me = -.30 if me < -.30
	
	*Generating the binscatter 
	binscatter 	 ksk me,  nodraw nquantiles(70)  controls(i.year i.iso_id) ///
		savedata("figs/sale_countries_1yr") replace
	insheet using "figs/sale_countries_1yr.csv", clear names comma
	erase "figs/sale_countries_1yr.csv"
	erase "figs/sale_countries_1yr.do"
	
	*Saving Scatter
	tw (scatter ksk me, mcolor(navy) msize(vlarge) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Log Sales Growth",size(large))  plotregion(lcolor(black)) ///
	ytitle("",size(large)) title("Log Sales Growth", color(black) size(vlarge)) ///
	graphregion(color(white))  ylabel(-.1(.05).2, labsize(large)) xlabel(,grid labsize(large)) ///
	legend(off) graphregion(color(white))  	name(FIGE4B, replace)
	*cap: graph export "figs/SBC_Fig4B2.pdf", replace
	
	*Combine 
	graph combine FIGE4A FIGE4B , graphregion(color(white)) ///
		  l1title("Kelley Skewness") ysize(3) 
	cap: graph export "figs/SBC_4COMB.pdf", replace

	
	*NOTE: Figure 5A is based by Census data and the figure was generated inside 
	*the RDC. No underlying data is provided. Here we only reproduce the plot reported 
	*in the paper.
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("USA Employment Scatter") cellrange(A1:B51) first clear 
		
	tw (scatter ksk me, mcolor(navy) msize(large) msymbol(O)  mfcolor(navy*0.25)) ///
   (lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Log Employment Growth") plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Log Employment Growth") ///
	graphregion(color(white)) ylabel(-.20(.10).30) xlabel(-.08(0.04)0.12,grid) /// ///
	legend(off order(1 "Expansion" 2 "Recession") rows(2) position(2) ring(0)) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig5A.pdf", replace 		
	
	*Replica Figure 5B
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 

	*Clean
	drop if year < 1970
	drop if inlist(group,"naic99","all")
	egen idnaics = group(group)
	tsset idnaic year
	
	*Regression 
	reg ksk me i.year i.idnaic, vce(cl idnaic)
	
	*Winsor Some Extreme Values for better plot aspect (does not change the results)
	drop if me == . | ksk == . 	
	replace me = -.20 if me <= -.20
	replace me =  .20 if me >=  .20 
	replace ksk = .90 if  ksk > .90 
	replace ksk = -.90 if ksk < -.90 
		
	binscatter ksk me,  nquantiles(50) nodraw  controls(i.year i.idnaics) ///
		savedata("figs/sales_annual")  replace
	insheet using "figs/sales_annual.csv", clear names comma
	erase "figs/sales_annual.csv"
	erase "figs/sales_annual.do"
		
	*Saving Scatter
	tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Log Sales Growth")  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Log Sales Growth") ///
	graphregion(color(white))  ///
	ylabel(-.20(.10).40) xlabel(-.15(0.05).20,grid) ///
	legend(off) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig5B.pdf", replace
	

*Replica Figure 6 on TFP
	*6A: Amadeus data 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", ///
		sheet("Amadeus TFP Shocks") cellrange(A1:CM7420) first clear 

	*Droping Outliers
	egen isonum = group(iso3)
		
	keep if nobs1 > 100	
		
	foreach ii in 1 2 3 4{
		_pctile ksk`ii', p(5 95)
		replace ksk`ii' =  . if (ksk`ii' < r(r1))
		replace ksk`ii' =  . if (ksk`ii' > r(r2))
		_pctile me`ii', p(5 95)
		replace me`ii' =  . if (me`ii' < r(r1))
		replace me`ii' =  . if (me`ii' > r(r2))
	}
	reg ksk1 me1 i.year i.isonum i.nai 
	local be : di %4.2f _b[me1]
	local se : di %4.2f _se[me1]
	binscatter ksk1 me1, ///
		control(i.year i.isonum i.nai ) n(80) nodraw  savedata("figs/bdv_tfps")  replace
		
	insheet using "figs/bdv_tfps.csv", clear names comma
	erase "figs/bdv_tfps.csv"	
	erase "figs/bdv_tfps.do"	
	
	replace ksk = ksk/100
	replace me = me/100
	
	tw (scatter ksk me if me > -0.05 & me <.05, mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me if me > -0.05 & me <0.05,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of TFP Shocks",size(medium))  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of TFP Shocks", color(black) size(medium))  ///
	title("", color(blue) size(large)) ///
	graphregion(color(white))  ///
	 xlabel(, grid) ///
	legend(off) graphregion(color(white)) xlabel(-0.05(0.025)0.05)
	cap: graph export "figs/SBC_Fig6A.pdf", replace 
	
	*6B: Census Data. Binscatter plot generated in RDC; Underlying data not reported 
	*here we only report the figure in the paper
	import excel using "replicationxls/SBC_CENSUS_ASM.xls", ///
		sheet("INDUSTRIES") cellrange(A1:C81) first clear
		
		replace ksk_rltfp_bea = ksk_rltfp_bea/100 
		replace me_rltfp_bea = me_rltfp_bea/100
		
	tw (scatter  ksk_rltfp_bea me_rltfp_bea, mcolor(navy) msize(large) msymbol(O)  mfcolor(navy*0.25)) ///
       (lfit  ksk_rltfp_bea me_rltfp_bea,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of TFP Shocks", size(medium)) plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of TFP Shocks", size(medium)) ///
	graphregion(color(white)) ylabel(-0.15 "-.15" -0.1 "-.1" -0.05 "-.05" 0.0 "0" 0.05 ".05" 0.1 ".1",format(%9.2f)) ///
		xlabel(-0.03 "-.03" -0.02 "-.02" -0.01 "-.01" 0.0 "0" 0.01 ".01" 0.02 ".02" 0.03 ".03", grid format(%9.2f)) /// ///
	legend(off rows(2) position(2) ring(0)) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig6B.pdf", replace 
		

*#######################################	
*REPLICA APPENDIX FIGURES OF THE PAPER 
*#######################################	

*ROBUSTNESS CENSUS LBD
	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	keep if year>= 1978
	keep year ksk
	rename ksk kskLBD
	replace kskLBD = kskLBD/100
	save "replicationxls/aux.dta", replace
	
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Kelley") cellrange(A1:C328) first clear 
	merge m:1 year using "replicationxls/aux.dta", keep(1 3) nogenerate 
	erase "replicationxls/aux.dta"
	keep if year>= 1978
	
	*Recession variable 
	gen recession = 0
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009
	
	*Rescale
	
	*Figure A
	tw  (bar recession year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "fage1", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "fsize1", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize2", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize3", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of log Employment Growth", size(medlarge) axis(2)) ylabel(-0.30(0.10)0.30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(5) ring(0) rows(2) ///
	order(2 "All" 3 "1-19" 4 "20-49" 5 "50-99") ///
		region(color(none))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig11AA.pdf", replace	
	
	*Figure B
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "fage1", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "fsize4", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize5", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize6", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("", size(medlarge) axis(2)) ylabel(-0.30(0.10)0.30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(5) ring(0) rows(2) ///
	order(2 "All" 3 "100-499" 4 "500-999" 5 "1000+") ///
		region(color(none))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig11AB.pdf", replace
	
	*Figure C
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "fage1", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "fage1", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fage2", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25)yaxis(2) ) ///
	(connected  ksk year if group == "fage3", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Log Employment Growth", size(medlarge) axis(2)) ylabel(-0.30(0.10)0.30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(7) ring(0) rows(2) order(2 "All" 3 "Young" 4 "Middle" 5 "Mature") ///
		region(color(none))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig11AC.pdf", replace	
	
	*Figure D
	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	keep if year>= 1978
	keep year ksk
	rename ksk kskLBD
	replace kskLBD = kskLBD/100
	save "aux.dta", replace
	
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Estab. Employment Growth Kelley") cellrange(A1:C367) first clear 
	keep if group == "all"
	merge m:1 year using "aux.dta", keep(1 3) nogenerate 
	erase "aux.dta"
	keep if year>= 1978
	
	*Recession variable 
	gen recession = 0
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009
	

	*Plot
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "all", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "all", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ), ///
		ytitle("", size(medlarge) axis(2)) ylabel(-.30(.10).20,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(7) ring(0) rows(2) ///
	order(2 "All Firms" 3 "All Establishments") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig11AD.pdf", replace

	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:K40) first clear 
	keep if year >=1978
	replace ksk = ksk/100
	replace kskAC = kskAC/100
	replace ksk2 = ksk2/100 
	replace ksk3 = ksk3/100
	
	*Recession variable 
	gen recession = 0
	replace recession = 3/4 if year == 1980
	replace recession = 1/2 if year == 1981
	replace recession = 1 if year == 1982
	replace recession = 2/4 if year == 1990
	replace recession = 1/4 if year == 1991
	replace recession = 1 if year == 2001
	replace recession = 1/4 if year == 2007
	replace recession = 1 if year == 2008
	replace recession = 2/4 if year == 2009
	
	*Figure E
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
		(connected ksk kskAC year, color(blue black) mfcolor(blue*0.25 black*0.25) lpattern(solid solid) msymbol(O S) ///
			 yaxis(2) yscale(alt axis(2)) ///
		ytitle("Kelley Skewness of Log Employment Growth", size(medlarge)  axis(2)) ylabel(,axis(2))) , ///
		 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1978(4)2014, grid)  plotregion(lcolor(black)) ///
		legend( rows(3)  ring(0) position(7) region(lcolor(white)) ///
	order(2 "KSK of Log-change" 3 "KSK of Arc-percentage change"))	
		cap noisily: graph export "figs/SBC_Fig11AE.pdf", replace	
	
	*Figure F
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected  ksk ksk2 ksk3 year  , color(blue black red) mfcolor(blue*0.25 black*0.25 red*0.25) lpattern(solid solid solid) msymbol(O S D) ///
		 yaxis(2) yscale(alt axis(2)) ///
	ytitle("", size(medlarge) axis(2)) ylabel(,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend( position(7) ring(0) rows(3) ///
	order(2 "KSK (P90,P10)" 3 "KSK (P95,P5)"  4 "KSK (P97.5,P2.5)") region(lcolor(white))) graphregion(color(white)) 
	cap noisily: graph export "figs/SBC_Fig11AF.pdf", replace	

*ROBUSTNESS QUARTERLY SALES GROWTH

	   *Load data of sales growth 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Quarter Sales Growth") cellrange(A1:U4325) first clear 
		
		keep if inlist(group,"all")
		
		keep if year >= 1970 & year <= 2013	
		*Something odd happens in the data in 2014 that makes the skewness declines substantially which is 
		*not associated to a particular aggregate shock. We are currently investigating the reasons behind this drop 
			

		gen recession = 0
		replace recession = 1 if qtr == "1973q4"
		replace recession = 1 if year == 1974
		replace recession = 1 if qtr == "1975q1"
		
		replace recession = 1 if inlist(qtr,"1980q1","1980q2","1980q3")
		
		replace recession = 1 if inlist(qtr,"1981q3","1981q4")
		replace recession = 1 if year == 1982
		
		replace recession = 1 if inlist(qtr,"1990q3","1990q4","1991q1")
		
		replace recession = 1 if year == 2001
		
		replace recession = 1 if inlist(qtr,"2007q4")
		replace recession = 1 if year == 2008
		replace recession = 1 if inlist(qtr,"2009q1","2009q2")
		
		 
		split(qtr), p(q)
		destring qtr1 qtr2, replace 
		rename qtr2 quarter
		drop qtr
		gen qtr = yq(year,quarter)
		format %tq qtr
		tsset qtr 
		
	tw  (bar recession qtr,   c(l) color(gs12 ) yscale(off)) ///	
	(line ksk qtr , color(black) yaxis(2) yscale(alt axis(2)) ///
	ytitle("Kelley Skewness of Log Sales Growth", axis(2)) ///
	ylabel(-.30 "-.3" -0.2  "-.2" -0.1  "-.1" 0  "0" 0.1 ".1" 0.2 ".2" 0.3 ".3",axis(2))) , ///
	 graphregion(color(white)) xtitle("") xlabel(40(20)210)  plotregion(lcolor(black)) ///
	legend(size(small) off rows(1) order(1 "GDP growth" 2 "1 year" 3 "3 year" 4 "5 year") ///
	region(lcolor(white))) graphregion(color(white)) 
		cap noisily: graph export "figs/SBC_11A.pdf", replace	

		
	tw  (bar rece qtr,   c(l) color(gs12 ) yscale(off)) ///	
	(line p9050 p5010 qtr, ///
	color( blue black ) lpattern(longdash solid) yaxis(2) yscale(alt axis(2)) ///
	ytitle("P9050 and P5010 of Log Sales Growth", axis(2)) ylabel(.10 ".1" 0.2 ".2" 0.3 ".3" 0.4 ".4" .5 ".5",axis(2))) , ///
	 graphregion(color(white)) xtitle("")  xlabel(40(20)210)  plotregion(lcolor(black)) ///
	legend(ring(0) position(11) rows(2) order(2 "P90P50" 3 "P50P10") region(lcolor(white))) graphregion(color(white)) 
	cap noisily: graph export "figs/SBC_11B.pdf", replace	
	
			
*ROBUSTNESS SALES GROWTH AND EMPLOYMENT GROWTH IN AMADEUS
	*Load for Employment
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Amadeus Employment Growth") cellrange(A1:U239) first clear 
	
	*Winsorize (only for better plot; Does not change results)
	replace ksk = . if me > 0.2 | me <-0.2	
	replace ksk = . if ksk > 0.5 | ksk <-0.5

	
	*Gen id 
	egen idiso = group(iso3)

	
	binscatter ksk me,  nquantiles(80) nodraw controls(i.year i.idiso) ///
		savedata("figs/sales_annual")  replace
	insheet using "figs/sales_annual.csv", clear names comma
	erase "figs/sales_annual.csv"
	erase "figs/sales_annual.do"
		
	*Saving Scatter
	tw (scatter ksk me if me >= -.20 , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me if me >= -.20,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Log Employment Growth")  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Log Employment Growth") ///
	graphregion(color(white))  ///
	ylabel(-.40(.10).20) xlabel(,grid) ///
	legend(off) graphregion(color(white))  	
	cap noisily: graph export "figs/SBC_Fig12A.pdf", replace
	

	*Load for Sales
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("Amadeus Sales Growth") cellrange(A1:U246) first clear 
	
	*Winsorize (Does not change results)
	replace ksk = . if me > 0.2 | me <-0.2	
	replace ksk = . if ksk > 0.5 | ksk <-0.5	
	
	*Gen id 
	egen idiso = group(iso3)

	
	binscatter ksk me,  nquantiles(80) nodraw  controls(i.year i.idiso) ///
		savedata("figs/sales_annual")  replace
	insheet using "figs/sales_annual.csv", clear names comma
	erase "figs/sales_annual.csv"
	erase "figs/sales_annual.do"
		
	*Saving Scatter
	tw (scatter ksk me if me >= -.30 , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me if me >= -.30 ,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Log Sales Growth")  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Log Sales Growth") ///
	graphregion(color(white))  ///
	ylabel(-.40(.10).10) xlabel(,grid) ///
	legend(off) graphregion(color(white))  	
	cap noisily: graph export "figs/SBC_Fig12B.pdf", replace
	
*ROBUSTNESS: LEFT AND RIGHT TAIL OF DISPERSION 
	
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", ///
		sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 

	*Clean
	drop if year < 1970
	drop if inlist(group,"naic99","all")
	egen idnaics = group(group)
	tsset idnaic year
	
	*Gen numeric value of iso
	egen iso_id = group(idnaic)
	
	preserve 
		winsor2 p5010 me, cuts(1 99)  replace
		binscatter 	p5010 me, nodraw nquantiles(80)  controls(i.year i.iso_id) ///
			savedata("figs/sale_naics_1yr") replace
		insheet using "figs/sale_naics_1yr.csv", clear names comma
		erase "figs/sale_naics_1yr.csv"
		gen vari = "p5010"
 		save "figs/sale_naics_1yr_p5010.dta", replace
		erase "figs/sale_naics_1yr.do"
		
		*Saving Scatter
		tw (scatter p5010 me, mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
		(lowess p5010 me,  bwidth(1.0) lpattern(dash) lwidth(thick)) ,  ///						
		xtitle("Average of Log Sales Growth",size(medlarge))  plotregion(lcolor(black)) ///
		ytitle("P5010 of Log Sales Growth") ///
		graphregion(color(white))  xlabel(,grid) ///
		legend(off) graphregion(color(white))  	
		graph export "figs/SBC_Fig20B_UN.pdf", replace
	restore 
	
	preserve 
		winsor2 p9050 me, cuts(1 99)  replace
		binscatter 	p9050 me, nodraw nquantiles(100)  controls(i.year i.iso_id) ///
			savedata("figs/sale_naics_1yr") replace
		insheet using "figs/sale_naics_1yr.csv", clear names comma
		erase "figs/sale_naics_1yr.csv"
		gen vari = "p9050"
 		save "figs/sale_naics_1yr_p9050.dta", replace
		erase "figs/sale_naics_1yr.do"
		
		*Saving Scatter
		tw (scatter p9050 me, mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
		(lowess p9050 me,  bwidth(0.5) lpattern(dash) lwidth(thick)) ,  ///						
		xtitle("Average of Log Sales Growth",size(medlarge))  plotregion(lcolor(black)) ///
		ytitle("P9050 of Log Sales Growth") ylabel(0.1(0.1)0.6) ///
		graphregion(color(white)) xlabel(,grid) ///
		legend(off) graphregion(color(white))  	
		graph export "figs/SBC_Fig20A_UN.pdf", replace
	restore 

*ROBUSTNESS: WITHIN INDUSTRY REGRESSIONS
	*Load for Employment
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", ///
		sheet("USA Annual Employment Growth") cellrange(A1:V1097) first clear 

	*Clean
	drop if year < 1970
	drop if inlist(group,"naic99","all")
	egen idnaics = group(group)
	tsset idnaic year
	
	*Winsor Some Extreme Values (does not change the results)
	drop if me == . | ksk == . 
	replace me = -.2 if me <= -.2
	replace me =  .2 if me >=  .2 
	replace ksk = 0.9 if ksk > 0.9 
	replace ksk = -0.9 if ksk < -0.9 
	
	*Scale
	replace me = 100*me
	replace ksk = 100*ksk
	
	*Running within industry regressions
	levelsof(group), clean loca(naics)
	foreach vv of local naics{
		sum me if group == "`vv'"
		replace me = (me - r(mean))/r(sd) if group == "`vv'"
		newey ksk me year if group == "`vv'", lag(1)
		local b`vv' = _b[me]
		local cil`vv'= _b[me] - invttail( e(N)-e(df_m)-1,0.025) * _se[me]
		local ciu`vv'= _b[me] + invttail( e(N)-e(df_m)-1,0.025) * _se[me]
		
	}
	
	
	reg ksk me i.year i.idnaic 		// Run regression for the average. 
									// The paper reports results for LBD
	
	clear 
	set obs 1
	foreach vv of local naics{
		gen  b`vv' = `b`vv''
		gen cil`vv' = `cil`vv''
		gen ciu`vv' = `ciu`vv''
	}
	gen i = 1
	reshape long b cil ciu, i(i) j(value) string
	drop i 
	sort b
	gen indx = _n
	
	twoway (rcap cil ciu indx, color(maroon)) ///
		(scatter b indx,  mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25))  ,  ///						
	xtitle("")  plotregion(lcolor(black)) ///
	ytitle("Value of {&beta} and Confidence Intervals") legend(off) ///
	graphregion(color(white))  xlabel(1 "Man3" 2 "Prof" 3 "HSer" 4 "Ret1" 5 "Info" ///
	6 "Ret2" 7 "ASer" 8 "FiIn" 9 "Man2" 10 "WhTr" 11 "Man1" 12 "OSer" 13 "Util" ///
	14 "AdmW" 15 "Cons" 16 "ESer" 17 "Tran1" 18 "Tran1" 19 "Mini" 20 "Arts" 21 "Agro" 22 "Tran2", alternate labsize(small)) ///
	 yline(15.81, lcolor(black) lpattern(dash)) ///
	 text(25 5 "Kelley{subscript:j,t} = {&alpha} + {&beta}Me{subscript:j,t} + {&epsilon}{subscript:j,t}", ///
		 size(medlarge)) 
	cap noisily: graph export "figs/SBC_Fig13A.pdf", replace

	 
	*Load for Sales
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 

	*Clean
	drop if year < 1970
	drop if inlist(group,"naic99","all")
	egen idnaics = group(group)
	tsset idnaic year
	
	*Winsor Some Extreme Values (does not change the results)
	drop if me == . | ksk == . 
	replace me = -.2 if me <= -.2
	replace me =  .2 if me >=  .2 
	replace ksk = 0.9 if ksk > 0.9 
	replace ksk = -0.9 if ksk < -0.9 
	
	*Scale
	replace me = 100*me
	replace ksk = 100*ksk
	
	*Running within industry regressions
	levelsof(group), clean loca(naics)
	foreach vv of local naics{
		sum me if group == "`vv'"
		replace me = (me - r(mean))/r(sd) if group == "`vv'"
		newey ksk me year if group == "`vv'", lag(1)
		local b`vv' = _b[me]
		local cil`vv'= _b[me] - invttail( e(N)-e(df_m)-1,0.025) * _se[me]
		local ciu`vv'= _b[me] + invttail( e(N)-e(df_m)-1,0.025) * _se[me]
	}
	
	clear 
	set obs 1
	foreach vv of local naics{
		gen  b`vv' = `b`vv''
		gen cil`vv' = `cil`vv''
		gen ciu`vv' = `ciu`vv''
	}
	gen i = 1
	reshape long b cil ciu, i(i) j(value) string
	drop i 
	sort b
	gen indx = _n
	
	twoway (rcap cil ciu indx, color(maroon)) ///
		(scatter b indx,  mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25))  ,  ///						
	xtitle("")  plotregion(lcolor(black)) ///
	ytitle("Value of {&beta} and Confidence Intervals") legend(off) ///
	graphregion(color(white))  xlabel(1 "Mini" 2 "Man1" 3 "Info" 4 "Man2" 5 "Man3" ///
	6 "ASer" 7 "Prof" 8 "ReTr1" 9 "FinI" 10 "AdmW" 11 "Arts" 12 "WhTr" 13 "FiIn" ///
	14 "ReTr2" 15 "WhTr" 16 "ESer" 17 "Oser" 18 "Tran1" 19 "Util" 20 "ReEs" 21 "Agro" 22 "Tran2", alternate labsize(small)) ///
	 yline(13.24, lcolor(black) lpattern(dash)) ///
	 text(25 5 "Kelley{subscript:j,t} = {&alpha} + {&beta}Me{subscript:j,t} + {&epsilon}{subscript:j,t}", ///
		 size(medlarge)) 
	cap noisily: graph export "figs/SBC_Fig13B.pdf", replace	
	
	
	twoway (rcap cil ciu indx, color(maroon)) ///
		(scatter b indx,  mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25))  ,  ///						
	xtitle("")  plotregion(lcolor(black)) ///
	ytitle("Value of {&beta} and 95% Confidence Intervals", size(medium)) legend(off) ///
	graphregion(color(white))  xlabel(1 "Mini" 2 "Man1" 3 "Info" 4 "Man2" 5 "Man3" ///
	6 "ASer" 7 "Prof" 8 "ReTr1" 9 "FinI" 10 "AdmW" 11 "Arts" 12 "WhTr" 13 "FiIn" ///
	14 "ReTr2" 15 "WhTr" 16 "ESer" 17 "Oser" 18 "Tran1" 19 "Util" 20 "ReEs" 21 "Agro" 22 "Tran2", grid angle(90) alternate labsize(small)) ///
	 yline(13.24, lcolor(black) lpattern(dash)) ///
	 text(35 7 "Kelley{subscript:j,t} = {&alpha} + {&beta}Me{subscript:j,t} + {&epsilon}{subscript:j,t}", ///
		 size(medium)) text(17 3 "Average")
	cap noisily: graph export "figs/SBC_Fig13BB.pdf", replace
	
	
*ROBUSTNESS: REGRESSION TABLE WITH DIFFERENT TFP MEASURES
	
	*.Cross Country
	*Load  data
	set more off
	eststo clear
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRYDEC2019.xls", ///
		sheet("Amadeus TFP Shocks") cellrange(A1:CW7420) first clear 
	
	drop if nobs1== 0 &  nobs2== 0 &  nobs3== 0 ///
		&  nobs4== 0 &  nobs5== 0 &  nobs6== 0				// Drop if number of observation is 0
	
	*Droping Outliers
	egen isonum = group(iso3)
	keep if nobs2 >100									// Keep if moments were calculated using more than 100 observations	
	foreach ii in 1 2 3 4{
		_pctile ksk`ii', p(5 95)
		replace ksk`ii' =  r(r1) if (ksk`ii' < r(r1))
		replace ksk`ii' =  r(r2) if (ksk`ii' > r(r2))
		_pctile me`ii', p(5 95)
		replace me`ii' =  r(r1) if (me`ii' < r(r1))
		replace me`ii' =  r(r2) if (me`ii' > r(r2))
	}
	
	
	preserve 	
		reg ksk1 me1 i.year i.isonum i.nai 
		local be : di %4.2f _b[me1]
		local se : di %4.2f _se[me1]
		binscatter ksk1 me1, ///
		control(i.year i.isonum i.nai ) n(80) nodraw  savedata("figs/bdv_tfps")  replace
		
		*This is for the regression table
		egen isoxnai = group(isonum nai)
		tsset isoxnai year
		gen aux = megs
		drop megs 
		rename aux megs
		
		levelsof isonum, local(isos)
		foreach ii of local isos{
			sum megs if isonum == `ii' 
			replace megs = megs/r(sd) if isonum == `ii'
		}
		eststo ksktfp1:  reg ksk1 megs i.year i.isonum i.nai, vce(cl isonum)
		
		insheet using "figs/bdv_tfps.csv", clear names comma
		erase "figs/bdv_tfps.csv"	
		erase "figs/bdv_tfps.do"	
		replace ksk = ksk/100
		replace me = me/100
			tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
			(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
			xtitle("Average TFP Shocks",size(medlarge))  plotregion(lcolor(black)) ///
			ytitle("Kelley Skewness of TFP Shocks", color(black) size(medlarge))  ///
			title("", color(blue) size(large)) ///
			graphregion(color(white))  ///
			ylabel(, labsize(medlarge)) xlabel(, labsize(medlarge)grid) ///
			legend(off) graphregion(color(white))
			graph export "figs/SBC_Fig21A.pdf", replace 
	restore 
	
		
	preserve 
		reg ksk2 me2 i.year i.isonum i.nai 
		local be : di %4.2f _b[me2]
		local se : di %4.2f _se[me2]
		binscatter ksk2 me2, ///
		control(i.year i.isonum i.nai ) n(80) nodraw  savedata("figs/bdv_tfps")  replace
		
		
		*This is for the regression table
		egen isoxnai = group(isonum nai)
		tsset isoxnai year
		gen aux = megs
		drop megs 
		rename aux megs
		
		levelsof isonum, local(isos)
		foreach ii of local isos{
				sum megs if isonum == `ii'
				replace megs = megs/r(sd) if isonum == `ii'

		}
		eststo ksktfp2:  reg ksk2 megs i.year i.isonum i.nai, vce(cl isonum)
		
		insheet using "figs/bdv_tfps.csv", clear names comma
		erase "figs/bdv_tfps.csv"	
		erase "figs/bdv_tfps.do"	
		replace ksk = ksk/100
		replace me = me/100
			tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
			(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
			xtitle("Average TFP Shocks",size(medlarge))  plotregion(lcolor(black)) ///
			ytitle("Kelley Skewness of TFP Shocks", color(black) size(medlarge))  ///
			title("", color(blue) size(large)) ///
			graphregion(color(white))  ///
			ylabel(, labsize(medlarge)) xlabel(-.08(0.04)0.08, labsize(medlarge)grid) ///
			legend(off) graphregion(color(white))
			graph export "figs/SBC_Fig21B.pdf", replace 
	restore 
	
	
	
	preserve 
		reg ksk3 me3 i.year i.isonum i.nai 
		local be : di %4.2f _b[me3]
		local se : di %4.2f _se[me3]
		binscatter ksk3 me3, ///
		control(i.year i.isonum i.nai ) n(80) nodraw  savedata("figs/bdv_tfps")  replace
		
		
		*This is for the regression table
		egen isoxnai = group(isonum nai)
		tsset isoxnai year
		gen aux = megs
		drop megs 
		rename aux megs
		
		levelsof isonum, local(isos)
		foreach ii of local isos{
			sum megs if isonum == `ii'
			replace megs = megs/r(sd) if isonum == `ii'
		}
		eststo ksktfp3:  reg ksk3 megs i.year i.isonum i.nai, vce(cl isonum)
		
		insheet using "figs/bdv_tfps.csv", clear names comma
		erase "figs/bdv_tfps.csv"	
		erase "figs/bdv_tfps.do"	
		replace ksk = ksk/100
		replace me = me/100
			tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
			(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
			xtitle("Average TFP Shocks",size(medlarge))  plotregion(lcolor(black)) ///
			ytitle("Kelley Skewness of TFP Shocks", color(black) size(medlarge))  ///
			title("", color(blue) size(large)) ///
			graphregion(color(white))  ///
			ylabel(, labsize(medlarge)) xlabel(-0.08(0.04)0.08, labsize(medlarge)grid) ///
			legend(off) graphregion(color(white))
			graph export "figs/SBC_Fig21C.pdf", replace 
	restore 
		
	preserve 
	
		reg ksk4 me4 i.year i.isonum i.nai 
		local be : di %4.2f _b[me4]
		local se : di %4.2f _se[me4]
		binscatter ksk4 me4, ///
		control(i.year i.isonum i.nai ) n(80) nodraw  savedata("figs/bdv_tfps")  replace
			
		*This is for the regression table
		egen isoxnai = group(isonum nai)
		tsset isoxnai year
		gen aux = megs
		drop megs 
		rename aux megs
		
		levelsof isonum, local(isos)
		foreach ii of local isos{
			sum megs if isonum == `ii' 
			replace megs = megs/r(sd) if isonum == `ii'
		}
		eststo ksktfp4:  reg ksk4 megs i.year i.isonum i.nai, vce(cl isonum)
		
		insheet using "figs/bdv_tfps.csv", clear names comma
		erase "figs/bdv_tfps.csv"	
		erase "figs/bdv_tfps.do"	
		replace ksk = ksk/100
		replace me = me/100
			tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
			(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
			xtitle("Average TFP Shocks",size(medlarge))  plotregion(lcolor(black)) ///
			ytitle("Kelley Skewness of TFP Shocks", color(black) size(medlarge))  ///
			title("", color(blue) size(large)) ///
			graphregion(color(white))  ///
			ylabel(, labsize(medlarge)) xlabel(-0.08(0.04)0.08, labsize(medlarge)grid) ///
			legend(off) graphregion(color(white))
			graph export "figs/SBC_Fig21D.pdf", replace 
	restore 
	
		
	*Regression Table 
		*Save table with results 
	esttab ksktfp* using  "figs/TABLETFP.tex", replace   ///
	stats(r2 N, labels(R-squared "N. of Observations "))  star(* 0.1 ** 0.05 *** 0.01) se  	///
	keep(megs)
	eststo clear
	
	*Regressions and the country-level
	set more off
	levelsof iso3 , local(iso) clean
	levelsof isonum, local(isos)
		levelsof nai, local(nais)
		foreach ii of local isos{
			foreach nn of local nais{
				sum megs if isonum == `ii' & nai == `nn'
				replace megs = megs/r(sd) if isonum == `ii' & nai == `nn'
			}
		}
		
		
	foreach ii of local iso {
		disp "`ii'"
		eststo sk_model`ii': reg ksk2 me2 i.year i.nai if iso3 == "`ii'", vce(cl nai)
	}
	
	esttab sk_model* using  "figs/TABLE_TFP_KSK_CTYES.tex", replace   ///
	stats(r2 N, labels(R-squared "N. of Observations "))  star(* 0.1 ** 0.05 *** 0.01) se  	///
	keep(me2)
	eststo clear
		
	
*END OF THE CODE 
*#########################	



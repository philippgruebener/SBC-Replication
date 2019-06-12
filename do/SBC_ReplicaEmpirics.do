/*
	This file replicates the empirical results for 
	Skewed Business Cycles by Salgado, Guvenen, and Bloom 
	First version April, 04, 2019
	This  version June,  06, 2019
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado I.
	salga010@umn.edu
	
*/

clear all
set more off
set matsize 1000
cd "/Users/sergiosalgado/Dropbox/FIRM_SKEWNESS_205/Data/PlotsSep2018/ShareData/"
	// Direct where files are saved

*##################################	
*REPLICA TABLE 2
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
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:U1097) first clear 
	replace ksk = 100*ksk
	keep if group == "all"
	merge 1:1 year using "replicationxls/auxA.dta", nogenerate keep(1 3)
	tsset year 
	
	*Re scale GDP growth
	sum dAGDPPC
	replace dAGDPPC =dAGDPPC/r(sd)
	
	*Trend 	
	gen trend = _n
	
	*regs
	eststo ksk_model2: newey  ksk dAGDPPC trend,  lag(1)
	predict aux if e(sample)
	corr ksk aux  if e(sample)
	di r(rho)^2
	drop aux
	
	*Column 3. USA Stock Returns
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Quarter Stock Returns") cellrange(A1:U189) first clear 
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
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Employment Growth") cellrange(A1:T706) first clear 
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
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Annual Sales Growth") cellrange(A1:T721) first clear 
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
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Stock Returns") cellrange(A1:Q9646) first clear 
	replace ksk = 100*ksk
	
	keep if num >= 100		// Keep qyater/year cell with more than 100 firms
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
	
	*Column 7. Industry Employment
		*Load data of sales growth 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 
		
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
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Employment Growth") cellrange(A1:V1095) first clear 
		merge 1:1 group year ///
			using  "replicationxls/aux_data_g1.dta", nogenerate keep(1 3)
		drop if inlist(group,"all")
		egen idnaics = group(group )
		tsset idnaic year
		
		replace ksk = . if ksk > 0.90 | ksk < -.90
		drop if ksk == . 
		replace ksk = 100*ksk
		
		eststo ksk_model7: reg ksk me_sales_g1 i.year i.idnaic , vce(cl idnaic)	
	
	*Column 8. Industry Sales
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 
	
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
	
	eststo ksk_model8: reg ksk me i.year i.idnaic, cl(idnaics)
	
	
	*Column 9. Industry Stock Returns	
		*Load data of sales growth 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Quarter Sales Growth") cellrange(A1:U4325) first clear 
		
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
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Quarter Stock Returns") cellrange(A1:U4325) first clear 
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
		
		eststo ksk_model9: reg ksk me_sales_g2  i.nqtr i.idnaic, cl(idnaics)
	
	*Save table with results 
	esttab ksk_model* using  "figs/TABLE2.tex", replace   ///
	stats(r2 N, labels(R-squared "N. of Observations "))  star(* 0.1 ** 0.05 *** 0.01) se  	///
	keep(dAGDPPC dQGDPPC me me_sales_g1 me_sales_g2)
	eststo clear
	
*##################################	
*REPLICA MAIN FIGURES OF THE PAPER 
*##################################	

*Replica Figure 1A. This figure was created using LBD data. Replication material is not available

*Replica Figure 1B. The first part only replicates plot. To replicate kernel density from 
*the underlying data, run do-files for raw data,
*construct the file SBC_A_CSTAT_1961_2018_clean.dta using corresponding do-file. 
	
		*Load 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Kernel Density") cellrange(A1:D87) first clear 
		
		*Plot
		tw line boom_density rece_density rece_x, ///							
		  lwidth(medthick medthick) lcolor(blue red) lpattern(dash solid)  xlabel(-2.0(0.5)2.0,grid) ///						
		xtitle("Sales Growth") ytitle("Density") plotregion(lcolor(black)) ///
		graphregion(color(white))  ///
		legend(order(1 "Expansion" 2 "Recession") rows(2) position(2) ring(0)) graphregion(color(white))  	
		cap noisily: graph export "figs/SBC_Fig1B.pdf", replace	

		/*To generate this plot using firm level data use following code
		*Important: the file SBC_A_CSTAT_1961_2018_clean.dta must be created first
		
		*Load data
			use gvkey fyearq g_saler_ll if fyearq >= 1970 & fyearq <= 2014 ///
				 &  g_saler_ll != . using "SBC_A_CSTAT_1961_2018_clean.dta", clear 	
			
			*Select the Sample
			gen samp = inlist(fyearq,2003,2004,2005,2006,2001,2008) | (fyearq >= 2010 & fyearq <= 2014)
			bys gvkey: egen samp_yr = sum(samp)
			keep if inlist(fyearq,2003,2004,2005,2006,2001,2008) | (fyearq >= 2010 & fyearq <= 2014)
			
			*Expansions 
			sum g_saler_ll if inlist(fyearq,2003,2004,2005,2006) | (fyearq >= 2010 & fyearq <= 2014) ,d
			gen gz_saler_llb_gr = (g_saler_ll-r(p50))/r(sd) // Adjust distribution to have 0 mean and unit variance
				
			kdensity gz_saler_llb_gr if inlist(fyearq,2003,2004,2005,2006) | ///
				(fyearq >= 2010 & fyearq <= 2014),   n(600) ///
				generate(boom_x boom_density)  nograph
			local bwidth = r(bwidth) 
												
			sum gz_saler_llb_gr if inlist(fyearq,2003,2004,2005,2006) | (fyearq >= 2010 & fyearq <= 2014) , d		
			global p10 : di %4.2f r(p10)	
			global p90 : di %4.2f r(p90) 	
			disp (r(p90) + r(p10) - 2*r(p50))/(r(p90) - r(p10))		// Show Skewness
			
			*Recession 
			drop gz_saler_llb_gr
			sum g_saler_ll if inlist(fyearq,2001,2008),d
			gen gz_saler_llb_gr = (g_saler_ll-r(p50))/r(sd)		// Adjust distribution to have 0 mean and unit variance
						
			sum gz_saler_llb_gr if inlist(fyearq,2001,2008), d		
			global p102 : di %4.2f r(p10)	
			global p902 : di %4.2f r(p90) 	
			disp (r(p90) + r(p10) - 2*r(p50))/(r(p90) - r(p10))  	// Show Skewness
			
			kdensity gz_saler_llb_gr if inlist(fyearq,2001,2008),  bwidth(`bwidth')  ///
				at(boom_x) generate(rece_x rece_density)  nograph

			*Preparing data for plotting
			keep boom* rece*
			drop if boom_density ==.
			keep if rece_x <2.0 & rece_x >-2.0 	// Chop the borders for better plot
			sort rece_x
			order rece_x rece_density boom_density
		*/


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
	
	*Plot
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected  ksk year , color(blue black) lpattern(solid dash dash_dot) ///
	msymbol(O S) msize(large) mfcolor(blue*0.25 black*0.25)  ///	Fill color
	mlcolor(blue black) ///
	yaxis(2) yscale(alt axis(2)) plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Employment Growth (%)", axis(2)) ylabel(-20(10)30,axis(2))) , ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid) ///
	legend( off position(7) ring(0) rows(2) order(2 "Census LBD" 3 "Compustat") region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig2A.pdf", replace	

*Replica Figure 2B:

	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1087) first clear 
		
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
	replace ksk = 100*ksk
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
	ytitle("Kelley Skewness of Sales Growth (%)", axis(2)) ylabel(-20(10)30,axis(2))) , ///
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
	
	*Plot
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected  p9050 p5010 year , color(blue black ) msymbol(O S) lpattern(dash solid dash_dot) ///
		 yaxis(2) yscale(alt axis(2)) msize(large large) mfcolor(blue*0.25 black*0.25)  ///
	ytitle("P9050 and P5010 of Employment Growth (%)", axis(2)) ylabel(,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1978(4)2014,grid) ///
	legend(position(7) ring(0) rows(2) order(2 "P90-P50" 3 "P50-P10") region(lcolor(white))) ///
	graphregion(color(white))  plotregion(lcolor(black))
	cap noisily: graph export "figs/SBC_Fig3A.pdf", replace	
	
*Replica Figure 3B:
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 
		
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
	replace ksk =   100*ksk
	replace p5010 = 100*p5010
	replace p9050 = 100*p9050
	keep if group == "all"
	
	*drop  if year if above 2013
	*Something odd happens in the data in 2014 that makes the skewness declines substantially which is 
	*not associated to a particular aggregate shock. We are currently investigating the reasons behind this drop 
	drop if year >= 2014
	
	*Plot
	tw  (bar rece year,   c(l) color(gs12 ) yscale(off)) ///	
	(connected p9050 p5010 year, ///
	msymbol(O S) color(blue black) lpattern(longdash solid) yaxis(2) yscale(alt axis(2)) ///
	msize(large large) mfcolor(blue*0.25 black*0.25)  plotregion(lcolor(black)) ///
	ytitle("P9050 and P5010 of Sales Growth (%)", axis(2)) ylabel(,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1970(5)2010,grid) ///
	legend(ring(0) position(11) rows(2) order(2 "P90-P50" 3 "P50-P10") region(lcolor(white))) graphregion(color(white)) 
		cap: graph export "figs/SBC_Fig3B.pdf", replace

		

*Replica Figure 4A. The first part only replicates plot. To replicate kernel density from 
*the underlying data, run do-files for raw data,
*construct the file SBC_Clean_BvD_OSI.dta and SBC_TimeSeries_OSI_APR2019_uw.dta using corresponding do-files. 
	
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Kernel Density") cellrange(A1:D56) first clear 
		
		*Plot		  	
		tw line boom_density rece_density rece_x, ///				
		  lwidth(medthick medthick) lcolor(blue red) lpattern(dash solid) ///
		xtitle("Sales Growth (%)") ytitle("Density")  plotregion(lcolor(black)) ///
		graphregion(color(white)) xlabel(-2.0(0.5)2.0, grid) ///
		legend(order(1 "Expansions" 2 "Recessions") rows(2) position(11) ring(0) ///
		 region(lcolor(white))) graphregion(color(white))  
		cap noisily: graph export "figs/SBC_Fig4A.pdf", replace	
		
		
		/*TO GENERRATE THIS PLOT USING THE RAW DATAM USE THE FOLLOWING CODE
		*Important: the files SBC_Clean_BvD_OSI.dta and SBC_TimeSeries_OSI_APR2019_uw.dta must be created first
		*Load data
		use if g_saler_ll != . using "SBC_Clean_BvD_OSI.dta", clear 
		rename cntrycde iso2
		sort iso2 year
		merge m:1 iso2 year using "SBC_TimeSeries_OSI_APR2019_uw.dta", keep(3) nogenerate
		drop if inlist(iso3,"LKA","POL","VNM","CYM") 
		drop if g_rgdp_pc_us_ac == . 
		*Notice there are 39 countries, same number of countries used in regression
		
		*Create percentiles of the g_rgdp_pc_us_ac distribution
		*Define recessions as periods in the lower percentile of the growth distribution 

		preserve 
			keep iso2 year g_rgdp_pc_us_ac
			bys iso2 year: keep if _n == 1
			
			set more off
			sort iso2
			gen decile = 0
			levelsof(iso2), local(cids)		
			foreach vv of local cids{			
				qui: _pctile g_rgdp_pc_us_ac  if iso2 == "`vv'", p(10)
				qui: replace decile = 1 if g_rgdp_pc_us_ac <= r(r1) & iso2 == "`vv'"
			}	
			sort iso2 year
			save "$dfolder/aux.dta", replace
		restore
		
		*Merge back 
		merge m:1 iso2 year using "$dfolder/aux.dta", nogenerate keep(1 3)
		erase  "$dfolder/aux.dta"
		
		*Expansions 
		sum g_saler_ll if decile == 0 ,d
		gen gz_saler_llb_gr = (g_saler_ll-r(p50))/r(sd)
			
		kdensity gz_saler_llb_gr if decile == 0, n(600) generate(boom_x boom_density)  nograph
		local bwidth = r(bwidth) 
											
		sum gz_saler_llb_gr if decile == 0 , d		
		global p10 : di %4.2f r(p10)	
		global p90 : di %4.2f r(p90) 	
		disp (r(p90) + r(p10) - 2*r(p50))/(r(p90) - r(p10))
		
		*Recession 
		drop gz_saler_llb_gr
		sum g_saler_ll if decile == 1,d
		gen gz_saler_llb_gr = (g_saler_ll-r(p50))/r(sd)
					
		sum gz_saler_llb_gr if decile == 1, d		
		global p102 : di %4.2f r(p10)	
		global p902 : di %4.2f r(p90) 	
		disp (r(p90) + r(p10) - 2*r(p50))/(r(p90) - r(p10))
		
		kdensity gz_saler_llb_gr if decile == 1,  bwidth(`bwidth')  ///
			at(boom_x) generate(rece_x rece_density)  nograph

		*Preparing data for plotting
		keep boom* rece*
		drop if boom_density ==.
		keep if rece_x <=2.0 & rece_x >=-2.0 
		sort rece_x
		order rece_x rece_density boom_density
		*/
		
*Replica Figure 4B1 and 4B2
	*Load 
	set more off
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Employment Growth") cellrange(A1:T706) first clear 
	
	*Re scale
	replace me  = 100*me	
	replace ksk  = 100*ksk
	
	*Gen numeric value of iso
	egen iso_id = group(iso3)
	
	*Regression 
	eststo bin_scatter1: reg ksk me i.year i.iso_id, vce(cl iso_id)
	
	*Winsor some extreme growth values to have a more compact plot
	*This does not change the results
	replace me = 30 if me > 30
	replace me = -30 if me < -30
	
	*Generating the binscatter 
	binscatter 	 ksk me,  nquantiles(50)  controls(i.year i.iso_id) ///
		savedata("figs/emp_countries_1yr") 	replace
	insheet using "figs/emp_countries_1yr.csv", clear names comma
	erase "figs/emp_countries_1yr.csv"
	erase "figs/emp_countries_1yr.do"
	
	*Saving Scatter 
	tw (scatter ksk me, mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25) ) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Firm Employment Growth (%)",size(medlarge))  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Firm Employment Growth (%)") ///
	graphregion(color(white))  ylabel(-30(15)60) xlabel(-15(5)25,grid)  ///
	legend(off ) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig4B1.pdf", replace
	
	
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Annual Sales Growth") cellrange(A1:T706) first clear 
	
	*Re scale
	replace me  = 100*me	
	replace ksk  = 100*ksk
	
	*Gen numeric value of iso
	egen iso_id = group(iso3)
	
	*Regression 
	eststo bin_scatter2: reg ksk me i.year i.iso_id, vce(cl iso_id)
	
	*Winsor some extreme growth values 
	replace me = 30 if me > 30
	replace me = -30 if me < -30
	
	*Generating the binscatter 
	binscatter 	 ksk me,  nquantiles(50)  controls(i.year i.iso_id) ///
		savedata("figs/sale_countries_1yr") replace
	insheet using "figs/sale_countries_1yr.csv", clear names comma
	erase "figs/sale_countries_1yr.csv"
	erase "figs/sale_countries_1yr.do"
	
	*Saving Scatter
	tw (scatter ksk me, mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Firm Sales Growth (%)",size(medlarge))  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Firm Sales Growth (%)") ///
	graphregion(color(white))  ylabel(-15(5)25) xlabel(,grid) ///
	legend(off) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig4B2.pdf", replace
	
	
	
	*NOTE: Figure 5A is based by Census data and the figure was generated inside 
	*the RDC. No underlying data is provided. Here we only reproduce the plot reported 
	*in the paper.
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("USA Employment Scatter") cellrange(A1:B51) first clear 
	replace ksk = 100*ksk
	replace me = 100*me
	
	*Regression 
	eststo bin_scatter3: reg ksk me 
	
	tw (scatter ksk me, mcolor(navy) msize(large) msymbol(O)  mfcolor(navy*0.25)) ///
   (lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Employment Growth (%)") plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Employment Growth (%)") ///
	graphregion(color(white)) ylabel(-20(10)30) xlabel(-8(4)12,grid) /// ///
	legend(off order(1 "Expansion" 2 "Recession") rows(2) position(2) ring(0)) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig5A.pdf", replace 		
	
	
	*Replica Figure 5B
	*Load 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 

	*Clean
	drop if year < 1970
	drop if inlist(group,"naic99","all")
	egen idnaics = group(group)
	tsset idnaic year
	
	*Scale
	replace me = 100*me
	replace ksk = 100*ksk
	
	*Regression 
	eststo bin_scatter4: reg ksk me i.year i.idnaic, vce(cl idnaic)
	
	*Winsor Some Extreme Values (does not change the results )
	drop if me == . | ksk == . 	
	replace me = -20 if me <= -20
	replace me =  20 if me >=  20 
	replace ksk = 90 if  ksk > 90 
	replace ksk = -90 if ksk < -90 
		
	binscatter ksk me,  nquantiles(50)  controls(i.year i.idnaics) ///
		savedata("figs/sales_annual")  replace
	insheet using "figs/sales_annual.csv", clear names comma
	erase "figs/sales_annual.csv"
	erase "figs/sales_annual.do"
		
	*Saving Scatter
	tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Sales Growth (%)")  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Sales Growth (%)") ///
	graphregion(color(white))  ///
	ylabel(-20(10)40) xlabel(-15(5)20,grid) ///
	legend(off) graphregion(color(white))  	
	cap: graph export "figs/SBC_Fig5B.pdf", replace
	
	*This puts together the table of binscatters 
	*Save table with results 
	esttab bin_scatter* using  "figs/BINSCATTER_CORRS.tex", replace   ///
	stats(r2 N, labels(R-squared "N. of Observations "))  star(* 0.1 ** 0.05 *** 0.01) se  	///
	keep(me)
	eststo clear
	

*Replica Figure 6
	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	keep if year>= 1978
	keep year ksk
	rename ksk kskLBD
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
	replace ksk = 100*ksk
	
	*Figure 6A
	tw  (bar recession year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "fage1", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "fsize1", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize2", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize3", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", size(medlarge) axis(2)) ylabel(-30(10)30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(5) ring(0) rows(2) ///
	order(2 "All" 3 "1-19" 4 "20-49" 5 "50-99") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig6A.pdf", replace	
	
	*Figure 6B
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "fage1", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "fsize4", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize5", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fsize6", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", size(medlarge) axis(2)) ylabel(-30(10)30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(5) ring(0) rows(2) ///
	order(2 "All" 3 "100-499" 4 "500-999" 5 "1000+") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig6B.pdf", replace
	
	*Figure 6C
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "fage1", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "fage1", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "fage2", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25)yaxis(2) ) ///
	(connected  ksk year if group == "fage3", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", size(medlarge) axis(2)) ylabel(-30(10)30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(7) ring(0) rows(2) order(2 "All" 3 "Young" 4 "Middle" 5 "Mature") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig6C.pdf", replace	
	
	
	*Figure 6D
	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:I40) first clear 
	keep if year>= 1978
	keep year ksk
	rename ksk kskLBD
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
	
	*Rescale
	replace ksk = 100*ksk
	
	*Plot
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   kskLBD year if group == "all", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "all", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", size(medlarge) axis(2)) ylabel(-30(10)20,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(7) ring(0) rows(2) ///
	order(2 "All Firms" 3 "All Establishments") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig6D.pdf", replace

	*Load
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Firm Employment Growth Moments") cellrange(A1:K40) first clear 
	keep if year >=1978
	
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
	
	*Figure 7A
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected  ksk ksk2 ksk3 year  , color(blue black red) mfcolor(blue*0.25 black*0.25 red*0.25) lpattern(solid solid solid) msymbol(O S D) ///
		 yaxis(2) yscale(alt axis(2)) ///
	ytitle("Kelley Skewness of Employment Growth (%)", size(medlarge) axis(2)) ylabel(,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend( position(7) ring(0) rows(3) ///
	order(2 "KSK (P90,P10)" 3 "KSK (P95,P5)"  4 "KSK (P97.5,P2.5)") region(lcolor(white))) graphregion(color(white)) 
	cap noisily: graph export "figs/SBC_Fig6E.pdf", replace	

	*Figure 7B
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
		(connected ksk kskAC year, color(blue black) mfcolor(blue*0.25 black*0.25) lpattern(solid solid) msymbol(O S) ///
			 yaxis(2) yscale(alt axis(2)) ///
		ytitle("Kelley Skewness of Employment Growth (%)", size(medlarge)  axis(2)) ylabel(,axis(2))) , ///
		 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(1978(4)2014, grid)  plotregion(lcolor(black)) ///
		legend( rows(3)  ring(0) position(7) region(lcolor(white)) ///
	order(2 "KSK of Log-change" 3 "KSK of Arc-percent change"))	
		cap noisily: graph export "figs/SBC_Fig6F.pdf", replace	


*Replica Appendix Figures 11.1 and 11.2 on Quarterly Sales Growth 

	   *Load data of sales growth 
		import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Quarter Sales Growth") cellrange(A1:U4325) first clear 
		
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
		
		replace ksk = 100*ksk
		replace p9050 = 100*p9050
		replace p5010 = 100*p5010
		 
		split(qtr), p(q)
		destring qtr1 qtr2, replace 
		rename qtr2 quarter
		drop qtr
		gen qtr = yq(year,quarter)
		format %tq qtr
		tsset qtr 
		
	tw  (bar recession qtr,   c(l) color(gs12 ) yscale(off)) ///	
	(line ksk qtr , color(black) yaxis(2) yscale(alt axis(2)) ///
	ytitle("Kelley Skewness of Sales Growth (%)", axis(2)) ylabel(-30(10)30,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(40(20)210)  plotregion(lcolor(black)) ///
	legend(size(small) off rows(1) order(1 "GDP growth" 2 "1 year" 3 "3 year" 4 "5 year") ///
	region(lcolor(white))) graphregion(color(white)) 
		cap noisily: graph export "figs/SBC_11A.pdf", replace	

		
	tw  (bar rece qtr,   c(l) color(gs12 ) yscale(off)) ///	
	(line p9050 p5010 qtr, ///
	color( blue black ) lpattern(longdash solid) yaxis(2) yscale(alt axis(2)) ///
	ytitle("P9050 and P5010 of Sales Growth (%)", axis(2)) ylabel(10(10)50,axis(2))) , ///
	 graphregion(color(white)) xtitle("") ytitle("P90-P10", axis(1)) xlabel(40(20)210)  plotregion(lcolor(black)) ///
	legend(ring(0) position(11) rows(2) order(2 "P90-P50" 3 "P50-P10") region(lcolor(white))) graphregion(color(white)) 
		cap noisily: graph export "figs/SBC_11B.pdf", replace	
	
			
*Replica Appendix figures A.2a, A.2b (Called Figure 12)

	*Load for Employment
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Amadeus Employment Growth") cellrange(A1:U236) first clear 
	
	*Winsorize (only for better plot; Does not change results)
	replace  me = -0.5 if  me <-0.5		
	replace  ksk = -0.5 if ksk <-0.5	
	
	*Scale
	replace me = 100*me
	replace ksk = 100*ksk
	
	*Gen id 
	egen idiso = group(iso3)

	
	binscatter ksk me,  nquantiles(50)  controls(i.year i.idiso) ///
		savedata("figs/sales_annual")  replace
	insheet using "figs/sales_annual.csv", clear names comma
	erase "figs/sales_annual.csv"
	erase "figs/sales_annual.do"
		
	*Saving Scatter
	tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Employment Growth (%)")  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Employment Growth (%)") ///
	graphregion(color(white))  ///
	ylabel(-50(10)40) xlabel(-40(10)10,grid) ///
	legend(off) graphregion(color(white))  	
	cap noisily: graph export "figs/SBC_Fig12A.pdf", replace
	

	*Load for sales
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Amadeus Sales Growth") cellrange(A1:U246) first clear 
	
	*Winsorize (only for better plot; Does not change results)
	replace  me = -0.5 if  me <-0.5		
	replace  ksk = -0.5 if ksk <-0.5	
	
	*Scale
	replace me = 100*me
	replace ksk = 100*ksk
	
	*Gen id 
	egen idiso = group(iso3)

	
	binscatter ksk me,  nquantiles(50)  controls(i.year i.idiso) ///
		savedata("figs/sales_annual")  replace
	insheet using "figs/sales_annual.csv", clear names comma
	erase "figs/sales_annual.csv"
	erase "figs/sales_annual.do"
		
	*Saving Scatter
	tw (scatter ksk me , mcolor(navy) msize(large) msymbol(O) mfcolor(navy*0.25)) ///
	(lfit ksk me,  lpattern(dash) lwidth(thick)) ,  ///						
	xtitle("Average of Sales Growth (%)")  plotregion(lcolor(black)) ///
	ytitle("Kelley Skewness of Sales Growth (%)") ///
	graphregion(color(white))  ///
	ylabel(-50(10)10) xlabel(-50(10)20,grid) ///
	legend(off) graphregion(color(white))  	
	cap noisily: graph export "figs/SBC_Fig12B.pdf", replace
	

*Replica figures A.3a and A.3b
	*Load for Employment
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Employment Growth") cellrange(A1:V1097) first clear 

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
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("USA Annual Sales Growth") cellrange(A1:V1097) first clear 

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

*Replica Appendix figures A.4a, A.4b, A.4c (Called Figure 13)

	*Load the data
	import excel using "replicationxls/SBC_CENSUS_LBD.xls", sheet("Estab. Employment Growth Kelley") cellrange(A1:C367) first clear 
	
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
	replace ksk = 100*ksk
	
	*Figure 14A
	tw  (bar recession year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   ksk year if group == "all", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "esize1", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "esize2", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "esize3", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", axis(2)) ylabel(-30(10)30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(7) ring(0) rows(2) ///
	order(2 "All" 3 "1-19" 4 "20-49" 5 "50-99") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig14A.pdf", replace
	
	
	*Figure 14B
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   ksk year if group == "all", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "esize4", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "esize5", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "esize6", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", axis(2)) ylabel(-30(10)30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(11) ring(0) rows(2) ///
	order(2 "All" 3 "100-499" 4 "500-999" 5 "1000+") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig14B.pdf", replace
	
	*Figure 14C
	tw  (bar rec year, c(l) color(gray*0.5) yscale(off)) ///	
	(connected   ksk year if group == "all", color(blue) lpattern(solid) ///
		msymbol(O) mfcolor(blue*0.25) yaxis(2) yscale(alt axis(2))) ///
	(connected  ksk year if group == "eage1", color(black) lpattern(solid) ///
		msymbol(S) mfcolor(black*0.25) yaxis(2) ) ///
	(connected  ksk year if group == "eage2", color(red) lpattern(solid) ///
		msymbol(D) mfcolor(red*0.25)yaxis(2) ) ///
	(connected  ksk year if group == "eage3", color(green) lpattern(solid) ///
		msymbol(T) mfcolor(green*0.25) yaxis(2) ), ///
		ytitle("Kelley Skewness of Employment Growth (%)", axis(2)) ylabel(-30(10)30,axis(2)) ///
	 graphregion(color(white)) xtitle("") xlabel(1978(4)2014,grid)  plotregion(lcolor(black)) ///
	legend(position(7) ring(0) rows(2) order(2 "All" 3 "Young" 4 "Middle" 5 "Mature") ///
		region(lcolor(white))) graphregion(color(white))
	cap noisily: graph export "figs/SBC_Fig14C.pdf", replace
	

*Replica Appendix Table of List of Countries.
	
	*Sales 
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Annual Sales Growth") cellrange(A1:T706) first clear 
	bys iso3: keep if _n== 1 | _n == _N
	keep iso3 year
	bys iso3: gen tpos = _n
	tostring tpos, replace
	
	reshape wide year, i(iso3) j(tpos) string
	replace year2 = year2 + 1
	gen saledata = "X"
	keep iso3 saledata 
	save "replicationxls/saledata.dta", replace
	
	*Employment
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Employment Growth") cellrange(A1:T706) first clear 
	bys iso3: keep if _n== 1
	keep iso3 
	gen empdata = "X"
	keep iso3 empdata 
	save "replicationxls/empdata.dta", replace
	
	*Stock Returns
	set more off
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Country Stock Returns") cellrange(A1:Q9646) first clear 
	keep if num >= 100		// Keep qyater/year cell with more than 100 firms
							// This keeps 40 countries. It is the data of quaterly GDP growth that reduces the 
							// number of observations to 28
	sort iso3 qtr
	merge 1:1 iso3 qtr using "replicationxls/auxCQ.dta",nogenerate keep(3)
	bys iso3: keep if _n== 1
	keep iso3 
	gen stockdata = "X"
	keep iso3 stockdata 
	save "replicationxls/stockdata.dta", replace
	
	*Amadeus data on Employment
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Amadeus Employment Growth") cellrange(A1:U236) first clear 
	bys iso3: keep if _n== 1
	keep iso3 
	gen empdataAMA = "X"
	keep iso3 empdataAMA
	save "replicationxls/empdataAMA.dta", replace
	
	*Amadeus data on Sales
	import excel using "replicationxls/SBC_USA_AND_CROSSCOUNTRY.xls", sheet("Amadeus Sales Growth") cellrange(A1:U236) first clear 
	bys iso3: keep if _n== 1
	keep iso3 
	gen salesAMA = "X"
	keep iso3 salesAMA
	save "replicationxls/salesAMA.dta", replace

	*Put pieces together
	use "replicationxls/saledata.dta"
	merge 1:1 iso3 using "replicationxls/empdata.dta", nogenerate
	merge 1:1 iso3 using "replicationxls/stockdata.dta", nogenerate
	merge 1:1 iso3 using "replicationxls/salesAMA.dta", nogenerate
	merge 1:1 iso3 using "replicationxls/empdataAMA.dta", nogenerate
	
	erase "replicationxls/empdata.dta"
	erase "replicationxls/stockdata.dta"
	erase "replicationxls/salesAMA.dta"
	erase "replicationxls/empdataAMA.dta"
	
	*Notice this saves only the data available. The surce column showed in the paper
	*is done directly in the table. 
	sort iso3
	outsheet using "figs/TABLE_COUNTRIES.csv", replace comma name
	
*END OF THE CODE 
*#########################	



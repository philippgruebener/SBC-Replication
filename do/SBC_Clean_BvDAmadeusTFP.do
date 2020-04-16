/*
	MEASURIG TFP IN AMADEUS and  CPI from WDI
	Amadeus data downloaded on July 17th
	WDI data downloaded in July 17th
	
	This version December 09, 2019
	Last version March, 12, 2020
	
	
*/
*Options 
clear all 
set more off
cd ""				// Main folder
global dfolder = ""	// Where the data is stored
capture log close
capture noisily log using "log/amalog.log", replace					
			// Location of raw data  
global minobs = 100 	// Min number of observations in Factor Share Cost calculations 
global minobsNAICS = 10 // Min number of sector per year in factor share cost calculationss
global minfirmobs = 5	// Min numm of observation at the firm level for OP estimation
global minyear = 2005	// First year for which we run the OP estimations (same for all countries)
global maxyear = 2017	// Last year for which we run the OP estimation   (same for all countries)	

global shares = "no"	// Set yes to run labor shares sections
global tfp =    "no"	// Set yes to run the TFP estimation and moments section
global momcnc = "yes"	// Set yes to run the moments of countries and naic/country
global samstat = "no"	// Set yes to run the moments of countries and naic/country

local ctylist = "AUT CHE DEU DNK ESP FIN FRA GBR GRC HUN IRL ISL ITA NLD NOR POL PRT SWE UKR"
*local ctylist = "AUT CHE DEU DNK ESP FRA GBR GRC HUN IRL ISL ITA NLD NOR POL UKR"
// local ctylist = "GBR"


*.Load data of CPI and Deflator from WDI
	insheet using "agg/WDI_CPI.csv", clear name case
	keep if SeriesName == "Consumer price index (2010 = 100)"
	keep Country* YR*
	destring YR*, force replace
	reshape long YR, i(CountryName CountryCode) j(year)
	rename YR cpi
	rename CountryCode iso3
	drop if cpi == .
	save "agg/WDI_CPI.dta", replace
	
*--------------------------------------------------------------------	
*.SECTION 1: Calculating factor shares (Downloading  DNK SWE FIN)
*--------------------------------------------------------------------

if "${shares}" == "yes"{
foreach iso of local ctylist{	

if inlist("`iso'","SWE","FIN","PRT","FRA","ITA") | ///
	inlist("`iso'","DEU","ESP","NOR","POL","UKR"){
	
*.Load data from Amadeus
	use "${dfolder}/Amadeus_PROD_`iso'.dta", clear

*.Year, iso codes and merge to CPI
	rename closdate_year year
	gen iso3 = "`iso'"
	merge m:1 year iso3 using "agg/WDI_CPI.dta", keep(3) nogenerate

*.Transform data of SWE to Euros for comparison
	if inlist("`iso'","SWE"){
		replace opre = exchrate2*opre
		replace mate = exchrate2*mate
		replace fias = exchrate2*fias
		replace staf = exchrate2*staf
	}
	
*.Value added
	gen va = opre - mate 

*.Clean data (same as in the next section for TFP estimation)
	drop if opre == . | opre <=0 		// Sales
	drop if mate == . | mate <=0 		// Materials
	drop if va == .   | va   <=0 		// Value Added
	drop if fias == . | fias <= 0		// Fixed assets
	drop if staf == . | staf <= 0		// Cost of workers/Wage Bill 
	
	gen auxCID = substr(idnr,1,2)
	drop if auxCID != cntrycde		// Drop if Country code is incorrect
	drop auxCID
	
	drop if naics_core_code == ""		// Drop if no NAICS
	
	drop if naics_core_code == ""		// Drop if no closing year
	
	egen firmid = group(idnr)		// Firm variable
	
	sort firmid year			// Drop duplicates
	by firmid: gen repeated = 1 if year == year[_n-1] 
	by firmid: egen mrep = max(repeated)
	drop if mrep == 1
	drop repeated mrep
	
*.Industry codes 	
	gen naics2 = substr(naics_core_code,1,2)
	destring  ussic_core_code naics_core_code naics2, replace	
	
*. Calculate sum of VA and Wage bill at the industry level. 
*. Count also the number of observations
	collapse (count) nobs = va (sum) vasum = va stafsum = staf, by(iso3 year naics2)
	
	drop if nobs < ${minobs} 	// Drop if not enough observations in country-year-naic cell 
	bys year: egen nsec = count(nobs) 
	drop if nsec < ${minobsNAICS}
	drop nsec
	
*Calculating cost shares at the country-industry level
	gen labshare = stafsum/vasum
	replace labshare = 1 if labshare > 1
	gen capshare = 1 - labshare
	
	
*. Save data 
	save "${dfolder}/costshare_`iso'_mom.dta", replace 
}	// END of inlist
}	// END of loop 
}	// END of section calculating the labor shares

*--------------------------------------------------------------------
*SECTION 2: CALCULATING TFP MEASURES  
*--------------------------------------------------------------------
if "${tfp}" == "yes"{
foreach iso of local ctylist{	
*.Load data from Amadeus
	use if opre != . | turn != . using "${dfolder}/Amadeus_PROD_`iso'.dta", clear

*.Year, iso codes and merge to CPI
	rename closdate_year year
	gen iso3 = "`iso'"
	merge m:1 year iso3 using "agg/WDI_CPI.dta", keep(3) nogenerate
	
*.Value added
	gen va = opre - mate 

*.Clean data 
	replace opre  = . if opre <=0 		// Sales
	replace mate = . if mate <=0 		// Materials
	replace va = .   if va <=0 		// Value Added
	replace fias = . if fias <= 0		// Fixed assets
	replace staf = . if staf <= 0		// Cost of workers/Wage Bill
	
	drop if opre == . & turn == . 		// W/o this we cannot construct any measure
	
	gen auxCID = substr(idnr,1,2)
	drop if auxCID != cntrycde		// Drop if Country code is incorrect
	drop auxCID
	
	drop if naics_core_code == ""		// Drop if no NAICS
	
	drop if naics_core_code == ""		// Drop if no closing year
	
	egen firmid = group(idnr)		// Firm variable
	
	sort firmid year			// Drop duplicates
	by firmid: gen repeated = 1 if year == year[_n-1] 
	by firmid: egen mrep = max(repeated)
	drop if mrep == 1
	drop repeated mrep
	tsset firmid year
	
*. Gen sale 
	gen sale = turn 
	replace sale = opre if sale == . 
	
*.Deflate variables	
	replace va =   100*va/cpi
	replace fias = 100*fias/cpi
	replace staf = 100*staf/cpi
	replace sale = 100*sale/cpi
	
*.Gen some variables 
	gen lva = log(va)
	gen lfias = log(fias)
	gen lstaf = log(staf)
	gen lempl  = log(empl)
	gen lopre = log(opre)
	gen lsale = log(sale)
	
*.Industry codes 	
	gen naics2 = substr(naics_core_code,1,2)
	destring  ussic_core_code naics_core_code naics2, replace

*.Sub set of countries with richer data
	if inlist("`iso'","SWE","FIN","PRT","FRA","ITA") | ///
	inlist("`iso'","DEU","ESP","NOR","POL","UKR"){
		*.Merge with the cost shares at teh country-industry-year level 
		merge m:1 naics2 year using "${dfolder}/costshare_`iso'_mom.dta", ///
			keep(1 3) nogenerate keepusing(capshare labshare)
		
		*.Method 1: Measuring productivity as residuals from output shares 
		gen tfpm1 = lva - labshare*lemp - capshare*(lfias/100)
			
		*.Method 2: Measuring productivity as residual from within-sample regression
		reg lva lfias lstaf  		
		predict tfpm2 if e(sample), resid

		*.Method 3: Measuring productivity as OP using OPREG
		*.xt setting 
		xtset firmid year
		
		*.Num obs 
		by firmid: egen fobs = count(va)
		
		*Exit variable
		sum year 
		by firmid: gen fexit = _n == _N 
		replace fexit = 0 if year == r(max)
		
		*Investment Variable 
		gen linv = lfias - L1.lfias 
		gen inv = fias - L1.fias 
		
		*Running opreg
		opreg lva if fobs >= ${minfirmobs} & year >= ${minyear}, ///
		exit(fexit) state(lfias) proxy(inv) free(lstaf) cvars(year lempl) ///
		vce(bootstrap, reps(10))
		predict tfpm3 if e(sample), tfp
		
		*.Method 4: Measuring (labor) productivity 
		areg lva lemp, abso(firmid) 		
		predict tfpm4 if e(sample), resid
		
		*.Method 5: Measuring sales per worker controlling for capital 
		reg lsale lemp lfias 
		predict tfpm5 if e(sample), resid
		
		*.Method 6: Measuring (labor) productivity 
		areg lsale lemp, abso(firmid) 		
		predict tfpm6 if e(sample), resid
		
		*.Measuring productivity shock as the residual of AR1 as in RUBC
		tsset firmid year
		*Method 1
		cap noisily: areg tfpm1 L1.tfpm1 i.year, abso(firmid)
		predict etfpm1 if e(sample), resid
		winsor2 etfpm1, cuts(1 99) trim replace
		
		*Method 2
		cap noisily: areg tfpm2 L1.tfpm2 i.year, abso(firmid)
		predict etfpm2 if e(sample), resid
		winsor2 etfpm2, cuts(1 99) trim replace
		
		*Method 3
		cap noisily: areg tfpm3 L1.tfpm3 i.year, abso(firmid)
		predict etfpm3 if e(sample), resid
		winsor2 etfpm3, cuts(1 99) trim replace
		
		*Method 4
		cap noisily: areg tfpm4 L1.tfpm4 i.year, abso(firmid)
		predict etfpm4 if e(sample), resid
		winsor2 etfpm4, cuts(1 99) trim replace
		
		*Method 5
		areg tfpm5 L1.tfpm5 i.year, abso(firmid)
		predict etfpm5 if e(sample), resid
		winsor2 etfpm5, cuts(1 99) trim replace
		
		*Method 6
		areg tfpm6 L1.tfpm6 i.year, abso(firmid)
		predict etfpm6 if e(sample), resid
		winsor2 etfpm6, cuts(1 99) trim replace
	}
	else{
		*For the rest of the countries, these TFP measures are missing because 
		*do not have good enough data
		gen tfpm1 = . 
		gen tfpm2 = . 
		gen tfpm3 = . 
		gen tfpm4 = . 
		
		*.Method 5: Measuring sales per worker controlling for capital 
		reg lsale lemp lfias 
		predict tfpm5 if e(sample), resid
		
		*.Method 6: Measuring (labor) productivity 
		areg lsale lemp, abso(firmid) 		
		predict tfpm6 if e(sample), resid
		
		*.Measuring productivity shock as the residual of AR1 as in RUBC
		gen etfpm1 = . 
		gen etfpm2 = . 
		gen etfpm3 = . 
		gen etfpm4 = . 
		
		*Method 5
		areg tfpm5 L1.tfpm5 i.year, abso(firmid)
		predict etfpm5 if e(sample), resid
		winsor2 etfpm5, cuts(1 99) trim replace
		
		*Method 6
		areg tfpm6 L1.tfpm6 i.year, abso(firmid)
		predict etfpm6 if e(sample), resid
		winsor2 etfpm6, cuts(1 99) trim replace
	}

	
*. Calculate Sales Growth, Employment Growth, and TFP growth
	gen g_sale_llb = log(sale) - log(L1.sale)
	winsor2 g_sale_llb, cuts(1 99) trim replace
	
	gen g_emp_llb = log(emp) - log(L1.emp)
	winsor2 g_emp_llb, cuts(1 99) trim replace
	
	gen g_tfpm2_llb = tfpm2 - L1.tfpm2
	winsor2 g_tfpm2_llb, cuts(1 99) trim replace
	
	gen g_fias_llb = log(fias) - log(L1.fias)
	winsor2 g_fias_llb, cuts(1 99) trim replace
	
	
*. Save data to later calculate cross sectional moments 
	compress
	save "${dfolder}/tfpmeasures_`iso'_mom.dta", replace
} // END loop over isos
} // END of TFP measures construction
***
		 
*-----------------------------------------------------------------------------
*SECTION 3: CALCULATING CROSS SECTIONAL MOMENTS FOR COUNTRY/NAIC AND COUNTRY
*-----------------------------------------------------------------------------
*.Get moments for two levels of aggregations: NAICS/COUNTRY and COUNTRY
if "${momcnc}" =="yes"{
foreach iso of local ctylist{	
	foreach lev in nc c{
	disp("Working on iso `iso' and lev `lev'")
	
	use "${dfolder}/tfpmeasures_`iso'_mom.dta", clear
	if inlist("`iso'","CHE","AUT"){
		cap: gen g_sale_llb = log(sale) - log(L1.sale)
		winsor2 g_sale_llb, cuts(1 99) trim replace
		cap: gen g_emp_llb = log(emp) - log(L1.emp)
		winsor2 g_emp_llb, cuts(1 99) trim replace
		cap: gen g_tfpm2_llb = tfpm2 - L1.tfpm2
		winsor2 g_tfpm2_llb, cuts(1 99) trim replace
		cap: gen g_fias_llb = log(fias) - log(L1.fias)
		winsor2 g_fias_llb, cuts(1 99) trim replace
	}
	gen lifas = log(ifas)
	gen lstaf2emp = log(staf/emp)

	if "`lev'" == "nc"{
	collapse (count) nobs1 = etfpm1  nobs2 = etfpm2  nobs3 = etfpm3  nobs4 = etfpm4   nobs5 = etfpm5   ///
			nobs6 = etfpm6 nobsgs = g_sale_llb nobsge = g_emp_llb nobsl1 = tfpm1 nobsl2 = tfpm2 nobsl3 = tfpm3 nobsl4 = tfpm4  ///
			nobsgi = g_fias_llb ///
	 (p2) p021 = etfpm1  p022 = etfpm2 p023 = etfpm3 p024 = etfpm4 p025 = etfpm5 p026 = etfpm6 ///
		p02gt2 = g_tfpm2_llb   p02gs = g_sale_llb   p02ge = g_emp_llb p02l1 = tfpm1 p02l2 = tfpm2 p02l3 = tfpm3 p02l4 = tfpm4 ///
		p02gi = g_fias_llb ///	
	(p5) p051 = etfpm1  p052 = etfpm2 p053 = etfpm3 p054 = etfpm4 p055 = etfpm5 p056 = etfpm6 ///
		p05gt2 = g_tfpm2_llb   p05gs = g_sale_llb   p05ge = g_emp_llb p05l1 = tfpm1 p05l2 = tfpm2 p05l3 = tfpm3 p05l4 = tfpm4 ///
		p05gi = g_fias_llb ///	
	 (p10) p101 = etfpm1  p102 = etfpm2 p103 = etfpm3 p104 = etfpm4 p105 = etfpm5 p106 = etfpm6 ///
		p10gt2 = g_tfpm2_llb   p10gs = g_sale_llb   p10ge = g_emp_llb p10l1 = tfpm1 p10l2 = tfpm2 p10l3 = tfpm3 p10l4 = tfpm4 ///
		p10gi = g_fias_llb ///
	 (p50) p501 = etfpm1  p502 = etfpm2 p503 = etfpm3 p504 = etfpm4 p505 = etfpm5 p506 = etfpm6 ///
		p50gt2 = g_tfpm2_llb   p50gs = g_sale_llb  p50ge = g_emp_llb  p50l1 = tfpm1 p50l2 = tfpm2 p50l3 = tfpm3 p50l4 = tfpm4 ///
		p50gi = g_fias_llb ///
	 (p90) p901 = etfpm1  p902 = etfpm2 p903 = etfpm3 p904 = etfpm4 p905 = etfpm5 p906 = etfpm6 ///
		p90gt2 = g_tfpm2_llb   p90gs = g_sale_llb  p90ge = g_emp_llb p90l1 = tfpm1 p90l2 = tfpm2 p90l3 = tfpm3 p90l4 = tfpm4 ///
		p90gi = g_fias_llb ///
	(p95) p951 = etfpm1  p952 = etfpm2 p953 = etfpm3 p954 = etfpm4 p955 = etfpm5 p956 = etfpm6 ///
		p95gt2 = g_tfpm2_llb   p95gs = g_sale_llb  p95ge = g_emp_llb p95l1 = tfpm1 p95l2 = tfpm2 p95l3 = tfpm3 p95l4 = tfpm4 ///
		p95gi = g_fias_llb ///
	 (p98) p981 = etfpm1  p982 = etfpm2 p983 = etfpm3 p984 = etfpm4 p985 = etfpm5 p986 = etfpm6 ///
		p98gt2 = g_tfpm2_llb   p98gs = g_sale_llb  p98ge = g_emp_llb p98l1 = tfpm1 p98l2 = tfpm2 p98l3 = tfpm3 p98l4 = tfpm4 ///
		p98gi = g_fias_llb ///
	 (mean) me1 = etfpm1  me2 = etfpm2  me3 = etfpm3  me4 = etfpm4 me5 = etfpm5 me6 = etfpm6 ///
		megt2 = g_tfpm2_llb   megs = g_sale_llb  mege = g_emp_llb mel1 = tfpm1 mel2 = tfpm2 mel3 = tfpm3 mel4 = tfpm4 ///
		melemp = lemp meemp = emp melsale = lsale c = sale melva  = lva  meva = va ///
		meifas = ifas melifas = lifas melstaf2emp = lstaf2emp ///
		megi = g_fias_llb ///
	 (sd)	sd1 = etfpm1  sd2 = etfpm2 sd3 = etfpm3 sd4 = etfpm4 sd5 = etfpm5 sd6 = etfpm6 ///
		sdgt2 = g_tfpm2_llb   sdgs = g_sale_llb   sdge = g_emp_llb sdl1 = tfpm1 sdl2 = tfpm2 sdl3 = tfpm3 sdl4 = tfpm4 ///
		sdgi = g_fias_llb ///
	 , by(iso3 naics2 year)
	}
	
	if "`lev'" == "c"{
	collapse (count) nobs1 = etfpm1  nobs2 = etfpm2  nobs3 = etfpm3  nobs4 = etfpm4   nobs5 = etfpm5   ///
			nobs6 = etfpm6 nobsgs = g_sale_llb nobsge = g_emp_llb nobsl1 = tfpm1 nobsl2 = tfpm2 nobsl3 = tfpm3 nobsl4 = tfpm4  ///
			nobsgi = g_fias_llb ///
	(p2) p021 = etfpm1  p022 = etfpm2 p023 = etfpm3 p024 = etfpm4 p025 = etfpm5 p026 = etfpm6 ///
		p02gt2 = g_tfpm2_llb   p02gs = g_sale_llb   p02ge = g_emp_llb p02l1 = tfpm1 p02l2 = tfpm2 p02l3 = tfpm3 p02l4 = tfpm4 ///
		p02gi = g_fias_llb ///	
	(p5) p051 = etfpm1  p052 = etfpm2 p053 = etfpm3 p054 = etfpm4 p055 = etfpm5 p056 = etfpm6 ///
		p05gt2 = g_tfpm2_llb   p05gs = g_sale_llb   p05ge = g_emp_llb p05l1 = tfpm1 p05l2 = tfpm2 p05l3 = tfpm3 p05l4 = tfpm4 ///
		p05gi = g_fias_llb ///	
	 (p10) p101 = etfpm1  p102 = etfpm2 p103 = etfpm3 p104 = etfpm4 p105 = etfpm5 p106 = etfpm6 ///
		p10gt2 = g_tfpm2_llb   p10gs = g_sale_llb   p10ge = g_emp_llb p10l1 = tfpm1 p10l2 = tfpm2 p10l3 = tfpm3 p10l4 = tfpm4 ///
		p10gi = g_fias_llb ///
	 (p50) p501 = etfpm1  p502 = etfpm2 p503 = etfpm3 p504 = etfpm4 p505 = etfpm5 p506 = etfpm6 ///
		p50gt2 = g_tfpm2_llb   p50gs = g_sale_llb  p50ge = g_emp_llb  p50l1 = tfpm1 p50l2 = tfpm2 p50l3 = tfpm3 p50l4 = tfpm4 ///
		p50gi = g_fias_llb ///
	 (p90) p901 = etfpm1  p902 = etfpm2 p903 = etfpm3 p904 = etfpm4 p905 = etfpm5 p906 = etfpm6 ///
		p90gt2 = g_tfpm2_llb   p90gs = g_sale_llb  p90ge = g_emp_llb p90l1 = tfpm1 p90l2 = tfpm2 p90l3 = tfpm3 p90l4 = tfpm4 ///
		p90gi = g_fias_llb ///
	(p95) p951 = etfpm1  p952 = etfpm2 p953 = etfpm3 p954 = etfpm4 p955 = etfpm5 p956 = etfpm6 ///
		p95gt2 = g_tfpm2_llb   p95gs = g_sale_llb  p95ge = g_emp_llb p95l1 = tfpm1 p95l2 = tfpm2 p95l3 = tfpm3 p95l4 = tfpm4 ///
		p95gi = g_fias_llb ///
	 (p98) p981 = etfpm1  p982 = etfpm2 p983 = etfpm3 p984 = etfpm4 p985 = etfpm5 p986 = etfpm6 ///
		p98gt2 = g_tfpm2_llb   p98gs = g_sale_llb  p98ge = g_emp_llb p98l1 = tfpm1 p98l2 = tfpm2 p98l3 = tfpm3 p98l4 = tfpm4 ///
		p98gi = g_fias_llb ///
	 (mean) me1 = etfpm1  me2 = etfpm2  me3 = etfpm3  me4 = etfpm4 me5 = etfpm5 me6 = etfpm6 ///
		megt2 = g_tfpm2_llb   megs = g_sale_llb  mege = g_emp_llb mel1 = tfpm1 mel2 = tfpm2 mel3 = tfpm3 mel4 = tfpm4 ///
		melemp = lemp meemp = emp melsale = lsale c = sale melva  = lva  meva = va ///
		meifas = ifas melifas = lifas melstaf2emp = lstaf2emp ///
		megi = g_fias_llb ///
	 (sd)	sd1 = etfpm1  sd2 = etfpm2 sd3 = etfpm3 sd4 = etfpm4 sd5 = etfpm5 sd6 = etfpm6 ///
		sdgt2 = g_tfpm2_llb   sdgs = g_sale_llb   sdge = g_emp_llb sdl1 = tfpm1 sdl2 = tfpm2 sdl3 = tfpm3 sdl4 = tfpm4 ///
		sdgi = g_fias_llb ///
	 , by(iso3 naics2 year)
	}
	
	 
	foreach vv in 1 2 3 4 5 6 gs ge gi gt2 l1 l2 l3 l4{

		gen ksk`vv' = (p90`vv' + p10`vv' -2*p50`vv')/(p90`vv' - p10`vv')
		gen p9010`vv' = (p90`vv' - p10`vv')
		gen p5010`vv' = (p50`vv' - p10`vv')
		gen p9050`vv' = (p90`vv' - p50`vv')
		
		gen p5010`vv's = (p50`vv' - p10`vv')/p9010`vv'
		gen p9050`vv's = (p90`vv' - p50`vv')/p9010`vv'
		
		gen ksk`vv'_975_025 = (p98`vv' + p02`vv' -2*p50`vv')/(p98`vv' - p02`vv')
		gen ksk`vv'_95_05 = (p95`vv' + p05`vv' -2*p50`vv')/(p95`vv' - p05`vv')
		
		/*
		replace ksk`vv' = ksk`vv'
		replace me`vv' = me`vv'
		
		replace p9010`vv' = p9010`vv'
		replace p5010`vv' = p5010`vv'
		replace p9050`vv' = p9050`vv'
		
		replace p5010`vv's = p5010`vv's
		replace p9050`vv's = p9050`vv's
		*/
	}
	
	
	*Save moments 
	save "${dfolder}/`iso'_mom_`lev'.dta", replace
			
	}	// END of lev loop
}	// END iso loop
	
foreach lev in nc c{
	clear 
	foreach iso of local ctylist{	
		append using "${dfolder}/`iso'_mom_`lev'.dta"
		*erase  "${dfolder}/`iso'_mom_`lev'.dta"
	}
	saveold "out/bvd_tfp_amadeus_jan2020_`lev'.dta", replace
}
} // END section countries and naics/countries
***


*FOR TABLE OF STATISTICS

if "${samstat}" =="yes"{
clear
foreach iso of local ctylist{
if inlist("`iso'","SWE","FIN","PRT","FRA","ITA") | ///
	inlist("`iso'","DEU","ESP","NOR","POL","UKR"){
	append using "${dfolder}/tfpmeasures_`iso'_mom.dta", keep(emp sale firmid year)
}
}
	drop if emp == . & sale == .
	drop if sale <  0 | empl <= 0
	keep if year >= 1996
	sum sale, meanonly 
	global tobs = r(N)
	keep if year == 2010
	collapse mesa = sale meem = emp (p10)  p10sa = sale p10em = emp ///
				(p50)  p50sa = sale p50em = emp (p90)  p90sa = sale p90em = emp	///
				(p99)  p99sa = sale p99em = emp	
	
	gen tobs = ${tobs}
	global exrate = 1.33  // Avergae in 2010
	replace mesa = round(${exrate}*mesa) 
	replace meem = round(meem) 
	replace p10sa = round(${exrate}*p10sa) 
	replace p10em = round(p10em) 
	replace p50sa = round(${exrate}*p50sa)
	replace p50em = round(p50em)
	replace p90sa = round(${exrate}*p90sa) 
	replace p90em = round(p90em)
	replace p99sa = round(${exrate}*p99sa) 
	replace p99em = round(p99em)
	
	
	save "${dfolder}/SBC_TFP_sumstats.dta", replace
}	// END section summ stats
*END OF THE CODE
capture log close	

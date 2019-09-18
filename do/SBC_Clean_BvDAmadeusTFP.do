/*
	MEASURIG TFP IN AMADEUS and  CPI from WDI
	Amadeus data downloaded on July 17th
	WDI data downloaded in July 17th
	
	This version July 28th, 2019
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado I.
	ssalgado@wharton.upenn.edu
	https://sergiosalgadoi.wordpress.com/
	
	
*/
*Options 
clear all 
set more off
cd "/home/salga010/Desktop/SBC/DataRes_Apr2018/VerApril2019"		
	// Cd to where the results will be saved
global dfolder = "/home/salga010/Desktop/SBC/Amadeus/Data"		
	// Location of raw data  
			
global minobs = 100 	// Min number of observations in Factor Share Cost calculations 
global minobsNAICS = 10 // Min number of sector per year in factor share cost calculationss
global minfirmobs = 5	// Min numm of observation at the firm level for OP estimation
global minyear = 2005	// First year for which we run the OP estimations (same for all countries)
global maxyear = 2017	// Last year for which we run the OP estimation   (same for all countries)	

global shares = "yes"	// Set yes to run labor shares sections
global tfp = "yes"		// Set yes to run the TFP estimation and moments section

local ctylist = "SWE FIN PRT FRA ITA DEU ESP"

*--------------------------------------------------------------------
*.Load data of CPI and Deflator from WDI
*--------------------------------------------------------------------
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
*.Load data from Amadeus
	use "${dfolder}/Amadeus_PROD_`iso'.dta", clear

*.Year, iso codes and merge to CPI
	rename closdate_year year
	gen iso3 = "`iso'"
	merge m:1 year iso3 using "agg/WDI_CPI.dta", keep(3) nogenerate

*.Transform data from DNK, and SWE to Euros for comparison
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
}	// END of loop 
}	// END of section calculating the labor shares

*--------------------------------------------------------------------
*SECTION 2: CALCULATING TFP MEASURES  
*--------------------------------------------------------------------

foreach iso of local ctylist{	
*.Load data from Amadeus
	use "${dfolder}/Amadeus_PROD_`iso'.dta", clear

*.Year, iso codes and merge to CPI
	rename closdate_year year
	gen iso3 = "`iso'"
	merge m:1 year iso3 using "agg/WDI_CPI.dta", keep(3) nogenerate
	
*.Value added
	gen va = opre - mate 

*.Clean data 
	drop if opre == . | opre <=0 		// Sales
	drop if mate == . | mate <=0 		// Materials
	drop if va == .   | va <=0 		// Value Added
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
	tsset firmid year

*.Deflate variables	
	replace va = 100*va/cpi
	replace fias = 100*fias/cpi
	replace staf = 100*staf/cpi
	
*.Gen some variables 
	gen lva = log(va)
	gen lfias = log(fias)
	gen lstaf = log(staf)
	gen lempl  = log(empl)
	gen lopre = log(opre)
	
*.Industry codes 	
	gen naics2 = substr(naics_core_code,1,2)
	destring  ussic_core_code naics_core_code naics2, replace

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

*.Measuring productivity shock as the residual of AR1
	tsset firmid year
	*Method 1
	areg tfpm1 L1.tfpm1 i.year, abso(firmid)
	predict etfpm1 if e(sample), resid
	winsor2 etfpm1, cuts(1 99) trim replace
	
	*Method 2
	areg tfpm2 L1.tfpm2 i.year, abso(firmid)
	predict etfpm2 if e(sample), resid
	winsor2 etfpm2, cuts(1 99) trim replace

	*Method 3
	areg tfpm3 L1.tfpm3 i.year, abso(firmid)
	predict etfpm3 if e(sample), resid
	winsor2 etfpm3, cuts(1 99) trim replace
	
	*Method 4
	areg tfpm4 L1.tfpm4 i.year, abso(firmid)
	predict etfpm4 if e(sample), resid
	winsor2 etfpm4, cuts(1 99) trim replace
	
	
*. Calculate Sales Growth (Log change of OPRE)
	gen g_sale_llb = lopre - L1.lopre
	winsor2 g_sale_llb, cuts(1 99) trim replace

*.Get moments 
	collapse (count) nobs = etfpm1 ///
		 (p10) p101 = etfpm1  p102 = etfpm2 p103 = etfpm3 p104 = etfpm4   p10g = g_sale_llb  ///
		 (p50) p501 = etfpm1  p502 = etfpm2 p503 = etfpm3 p504 = etfpm4   p50g = g_sale_llb  ///
		 (p90) p901 = etfpm1  p902 = etfpm2 p903 = etfpm3 p904 = etfpm4   p90g = g_sale_llb  ///
		 (mean) me1 = etfpm1  me2 = etfpm2  me3 = etfpm3  me4 = etfpm4    meg = g_sale_llb  ///
		 , by(iso3 naics2 year)
		 
	foreach vv in 1 2 3 4 g{

		gen ksk`vv' = (p90`vv' + p10`vv' -2*p50`vv')/(p90`vv' - p10`vv')
		gen p9010`vv' = (p90`vv' - p10`vv')
		gen p5010`vv' = (p50`vv' - p10`vv')
		gen p9050`vv' = (p90`vv' - p50`vv')
		
		gen p5010`vv's = (p50`vv' - p10`vv')/p9010`vv'
		gen p9050`vv's = (p90`vv' - p50`vv')/p9010`vv'
		
		replace ksk`vv' = 100*ksk`vv'
		replace me`vv' = 100*me`vv'
		
		replace p9010`vv' = 100*p9010`vv'
		replace p5010`vv' = 100*p5010`vv'
		replace p9050`vv' = 100*p9050`vv'
		
		replace p5010`vv's = 100*p5010`vv's
		replace p9050`vv's = 100*p9050`vv's
	}
	
	
*Save moments 
	save "${dfolder}/`iso'_mom.dta", replace
}	// END iso loop
	
	
*--------------------------------------------------------------------
*.Appending the results and saving
*--------------------------------------------------------------------
	
clear 
foreach iso of local ctylist{	
	append using "${dfolder}/`iso'_mom.dta"
	erase  "${dfolder}/`iso'_mom.dta"
}
saveold "out/bvd_tfp_amadeus.dta", replace

*----------------------------
*END OF THE CODE
*----------------------------

	
	

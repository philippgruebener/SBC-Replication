/*
	This file generates the cross sectional moments from BvD Amadeus dataset used in
	Skewed Business Cycles by Salgado/Guvenen/Bloom 
	First version April, 12, 2019
	This  version May, 16, 2019	
	
	In case of any questions contact 
	Sergio Salgado I
	salga010@umn.edu
	
	The raw data was last updated on April, 11, 2018
	
*/
// Options 
clear all 
set more off 
cd "/home/salga010/Documents/KPS/KPS1TAX"
global dfolder = "/home/salga010/Desktop/SBC/Amadeus/Data"					
			// Location of raw data 
global cdata = "/home/salga010/Desktop/SBC/DataRes_Apr2018/VerApril2019/out"		
			// Location of clean data will be saved 
run "do/SBC_bvd_progs.do"
			// Simple programs used in the calculations
capture log close
capture noisily log using "${cdata}/Amadeus_v2.log", replace

// Running Loop over countries
*
local ctyes = "NO PL PT SE AT BE BY CH DE DK ES FI FR GB GR HU IE IS IT NL UA"

foreach iso of local ctyes{

// Load data by country 
	use if opre != . | empl != . | turn != . using "${dfolder}/Amadeus_`iso'.dta", clear 
	drop if opre == . & empl == . & turn == .		// In general, sales as more coverage

// Rename year variable 
	rename  closdate_year year 
	
// Sale and opre are sor of the same. But coded in different entries. Check this 
	gen sale = turn 
	replace sale = opre if sale == . 

// Doing some cleaning 
	drop if sale <= 0
	drop if empl <= 0 

//Define core sample: firms that have empl and turn 
	gen corespl = (empl != . & sale != . )
	tab year 
	egen firmid = group(idnr)
	
// Drop firm swith repeated variables	
	sort firmid year
	by firmid: gen repeated = 1 if year == year[_n-1] 
	by firmid: egen mrep = max(repeated)
	drop if mrep == 1
	drop repeated mrep
	tsset firmid year

// Gen some variables 
	gen lemp = log(empl)
	gen lsale = log(sale)
	
	gen vapworker = av/empl
	gen lvapworker = log(av/empl)
	
	gen sapworker = sale/empl
	gen lsapworker = log(sale/empl)
	
	gen g_sale_ll = F1.lsale - lsale
	gen g_emp_ll = F1.lemp - lemp
	
// Employment categories 
	gen empcat = .
	replace empcat = 1 if empl <= 100 &  empcat ==. & empl != . 
	replace empcat = 2 if empl <= 250 &  empcat ==. & empl != . 
	replace empcat = 3 if empl <= 1000 &  empcat ==. & empl != . 
	replace empcat = 4 if empl <= 5000 &  empcat ==. & empl != . 
	replace empcat = 5 if empl > 5000 &  empcat ==. & empl != . 
	

	local varis = "g_sale_ll g_emp_ll lsale lemp"
	
// Calculating moments for different variables		
	foreach vv of local varis {
	
// Gen some locals used in the loop 
	gen aux = `vv' != .
	bys year: egen nobs = count(`vv')
	qui: sum year if nobs >= 1000		// Only years w/more than 1000s observations
	local ymin = r(min)
	local ymax = r(max)
	drop aux nobs
	
	local wei = ""
	if inlist("`vv'","g_sale_ll"){
		local wei = "sale"
	}
	if inlist("`vv'","g_emp_ll"){
		local wei = "empl"
	}
	
	forvalues yr = `ymin'/`ymax'{
	*local yr = 2005		
	disp("Working iso `iso' year `yr' vari `vv'")	
	
	// Summary Stats 
	qui: sumdetail "`vv'" "`wei'" "year" `yr' "" "" "out"
			
	} // END loop over years
	} // END loop over variables 
	
// Put pieces together 

	*Summary Stats
	
	local ymin = 1990
	local ymax = 2015
	
	foreach vv of local varis {
	clear
	forvalues yr = `ymin'/`ymax'{
		cap: append using "${cdata}/sumstat_`vv'_year_`yr'.dta"
		cap: erase  "${cdata}/sumstat_`vv'_year_`yr'.dta"
	}	// END loop years
	
		cap: gen vari = "`vv'"
		cap: gen iso2 = "`iso'"

		cap: replace vari = "`vv'" if vari == ""
		cap: replace iso2 = "`iso'" if iso2 == ""
		
		sort iso2 year vari
		save "${cdata}/sumstat_`vv'_`iso'.dta", replace 
	}	// END loop varis
	
	clear 
	foreach vv of local varis {
		cap: append using "out/sumstat_`vv'_`iso'.dta"
		cap: erase "${cdata}/sumstat_`vv'_`iso'.dta"
	}	// END loop varis
	sort iso2 vari year 
	order iso2 vari year 
	saveold "${cdata}/sumstat_`iso'.dta", replace
	
}	// END loop over countries
		
local ctyes = "NO PL PT SE AT BE BY CH DE DK ES FI FR GB GR HU IE IS IT NL UA"
clear 
foreach iso of local ctyes{
	append using "${cdata}/sumstat_`iso'.dta"
	erase "${cdata}/sumstat_`iso'.dta"
}
saveold "${cdata}/bvd_sumstats_countries.dta", replace
	
capture log close

/*
		
	This file generates the cross sectional moments from  Global Compustat 
	for stock prices used in
	Skewed Business Cycles by Salgado/Guvenen/Bloom 
	(original version CleanGlobalCompustat_Mar2019_SP.do)
	First version April, 14, 2019
	This  version Dec , 16, 2019	
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado I.
	ssalgado@wharton.upenn.edu
	https://sergiosalgado.net/
	
	The raw data was last updated on April, 20, 2018
	
*/


*#############################################
*-- OPTIONS
*#############################################

clear all
set more off
cd "../SBC-Replication/"
	// Main location

global dfolder = "raw"	
			// Location of raw data 
global cdata = "out"		
			// Location of clean data will be saved 
global adata = "agg"
			// Location aggregate auxiliary data

*Local with the name of countries. Notice some contries will not have 
*moments in the final data because our sample restriction
 local cty = "ARE ARG AUS AUT BEL BFA BGD BGR BHR BMU BRA BWA CAN CHE CHL CHN CIV COL CYM CYP CZE DEU DNK EGY ESP EST FIN FRA FRO GAB GBR GHA GIB GRC GRL HKG HRV HUN IDN IMN IND IRL ISL ISR ITA JAM JEY JOR"
 local cty = "`cty' JPN KAZ KEN KHM KOR KWT LKA LTU LUX LVA MAC MAR MCO MEX MLT MNG MUS MWI MYS NAM NGA NLD NOR NZL OMN PAK PAN PER PHL PNG POL PRT PSE QAT ROU RUS SAU SDN SEN SGP SRB SVK SVN SWE THA TTO"
 local cty = "`cty' TUN TUR TWN TZA UGA UKR USA VEN VGB VNM ZAF ZMB ZWE"


 foreach bb in "o10"{
 
 foreach cc of local cty { 	
	di "Working `bb' for country `cc'"
	qui {
	
	use gvkey datadate prccd loc naics sic  if loc == "`cc'" & prccd != . ///
		using "${dfolder}/GC_SP_DailyPrices_Apr2018.dta", clear
		
	*-- Setting the date and destring the data 
	compress
	gen fyearq = year(datadate)
	gen fqtr = quarter(datadate)
	gen qtr = yq(fyearq,fqtr)
	format qtr %tq		
	gen fyear = fyearq
	destring gvkey, replace
	
	*-- Sort, drop dupplicates 
	sort gvkey datadate
	by gvkey: gen indica = 1 if datadate[_n] == datadate[_n-1]
	drop if indica == 1
	drop indica
	
	*Keep last obervation of the quarter 
	bys gvkey qtr: keep if _n == _N
	
	*Tsset 
	tsset gvkey qtr
	
	*-- Gen quarterly returns	
	gen ret = log(F4.prccd) - log(prccd)
	drop if ret == .
		
	*Using all the observations 
	*sort gvkey qtr	
	*by gvkey qtr: gen aux = 1 if _n == 1							
	
	*Using firs with more than 10 years of data 
	by gvkey: egen num_gvkey_tot = count(ret)
	if inlist("`bb'", "o10"){
		gen indica = (num_gvkey_tot >= 40)			// Approx Ten years of data 
		keep if indica == 1
	}
	
			
	*Calculate moments
	cap{	// Some countries not have anough after sample selection.
		// Using capture ensure the code runs over all possible countries w/o problems
	sort qtr		
	egen num_iso = count(ret)			// Number of Observations per iso
	by qtr: egen num_ret = count(ret)		// Number of Observations per iso-qtr
	by qtr: egen mea_ret = mean(ret)
	by qtr: egen sd_ret = sd(ret)
	by qtr: egen sk_ret = skew(ret)
	by qtr: egen p025_ret = pctile(ret), p(2.5)	
	by qtr: egen p10_ret = pctile(ret), p(10)	
	by qtr: egen p25_ret = pctile(ret), p(25)
	by qtr: egen p50_ret = pctile(ret), p(50)
	by qtr: egen p75_ret = pctile(ret), p(75)
	by qtr: egen p90_ret = pctile(ret), p(90)
	by qtr: egen p975_ret = pctile(ret), p(97.5)

	
	by qtr: gen p9010_ret = p90_ret - p10_ret
	by qtr: gen p5010_ret = p50_ret - p10_ret
	by qtr: gen p9050_ret = p90_ret - p50_ret
	by qtr: gen ksk_ret = (p9050_ret - p5010_ret)/p9010_ret
	by qtr: gen cku_ret = (p975 - p025)/(p75 - p25)


	*-- Collapsing to the first observations 
	sort qtr
	by qtr: keep  if _n == 1
	cap: keep *_ret num_* loc fyear fqtr qtr
	tsset qtr
	}	// END of capture statement
	*-- Re name iso 
	rename loc iso3
	
	*-- Compress and save	
	compress	
	save "${cdata}/aux_data_`cc'.dta", replace 
	} // END of qui statement 
	
 }	// END of loop over countries 
 
	clear
	foreach cc of local cty{ 
		append using "${cdata}/aux_data_`cc'.dta"
		erase "${cdata}/aux_data_`cc'.dta"
	}
	compress
	saveold "${cdata}/SBC_TimeSeries_GCSTAT_QTRLY_APR2019.dta", replace
		// Save to read in 

 } // END of loop over bases

*END OF CODE

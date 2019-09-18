/*
	This file generates the cross sectional moments from BvD Osiris dataset used in
	Skewed Business Cycles by Salgado/Guvenen/Bloom 
	(original version SBC_CleanOsirisIndustrial_v2.do)
	First version April, 12, 2019
	This  version April, 12, 2019	
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado I.
	ssalgado@wharton.upenn.edu
	https://sergiosalgadoi.wordpress.com/
	
	
	The raw data was last updated on April, 11, 2018
	
*/


*#############################################
*-- OPTIONS
*#############################################

clear all
set more off 

*Location and datasets
global dfolder = "/home/salga010/Desktop/SBC/DataRes_Apr2018/VerApril2019/raw"	
			// Location of raw data 
global cdata = "/home/salga010/Desktop/SBC/DataRes_Apr2018/VerApril2019/out"		
			// Location of clean data will be saved 
global adata = "/home/salga010/Desktop/SBC/DataRes_Apr2018/VerApril2019/agg"
			// Location aggregate auxiliary data
global dname = "OsirisIndustrial_Aprl112018.csv"			
			// Name of raw data

global  basecpi = 195.2667  			
//  Base is 2005 to be consistent with te base of the GDP growth for the WDI

global cleandata = "no"		// Yes if data need to be cleaned
global runmoments = "yes"		// Yes if momments need to be calculated

*#############################################
*-- CLEANING
*#############################################
if "${cleandata}" == "yes"{
*-- Loading the data 
	insheet using "${dfolder}/${dname}", clear comma names 
	
	*Creates year 
	split(closdate), p(-)
	rename closdate1 year
	destring year,replace
	order os_id_number year
		
	*Replace to missing if Sales, Employment, or Cogs are Negative 
	destring data13002 data22199 data23000, force replace		
	replace  data13002 = . if data13002 < 0			// Sales
	replace  data23000 = . if data23000 < 0			// Employment 
	replace  data22199 = . if data22199 < 0			// CoGS
	
	*Put everything in usd dollars 	
	replace data13002 = data13002*exrate_usd if currency != "USD"
	
	*Gen real variables 
	*Merge CPI of the US
	sort year
	merge m:1 year using "$adata/CPIAUCSL_A.dta", keep(3) nogenerate
	gen data13002r = data13002*(${basecpi}/cpi)
			
		
	*Dropping all firms with NAICS above 92000
	label var caics12cod "NAICS Core Code"
	drop if caics12cod== .
	drop if caics12cod>= 9200
	
	*Getting the series and Dropping the Repeated Values 
	egen firm_id = group(os_id_number)	
	
	sort firm_id year
	gen flag_repeat = .
	by firm_id: replace flag_repeat = 1 if year[_n] == year[_n-1]
	by firm_id: egen fla_rep = max(flag_repeat)
	drop if flag_repeat == 1
	
	*Tsseting the data 
	tsset firm_id year		
	tsfill,full		// TS full is necessary if one wants to use arc-percent measures
	
	
*-- 	Generating the new series and saving the dta. I will rename some of the series 
*	to accomodate to the rest of the do files. 	

	rename data13002 sale
	rename data13002r saler
	rename data22199 cogs
	rename data23000 emp
	
	gen salerz = saler
	replace salerz = 0 if salerz==.
	
	gen gp = sale - cogs		  		  
	gen l_sale = log(sale)
	gen l_gp = log(gp)		  
	gen l_emp = log(emp)		  
	    
	*For real sales
	by firm_id: gen g_saler_acb = -(L1.saler - saler)/(0.5*(L1.saler + saler))
	by firm_id: gen g_saler_acb3 = -(L3.saler - saler)/(0.5*(L3.saler + saler))
	by firm_id: gen g_saler_acb5 = -(L5.saler - saler)/(0.5*(L5.saler + saler))

	by firm_id: gen g_saler_ac = (F1.saler - saler)/(0.5*(F1.saler + saler))
	by firm_id: gen g_saler_ac3 = (F3.saler - saler)/(0.5*(F3.saler + saler))
	by firm_id: gen g_saler_ac5 = (F5.saler - saler)/(0.5*(F4.saler + saler))
	
	by firm_id: gen g_saler_ll = log(F1.saler) - log(saler)
	
	by firm_id: gen g_saler_llb = log(saler) - log(L1.saler)
	by firm_id: gen g_saler_llb3 = log(saler) - log(L3.saler)
	by firm_id: gen g_saler_llb5 = log(saler) - log(L5.saler)
	
	
	*For real sales with entry and exit
	by firm_id: gen g_salerz_acb = -(L1.salerz - salerz)/(0.5*(L1.salerz + salerz))
	by firm_id: gen g_salerz_acb3 = -(L3.salerz - salerz)/(0.5*(L3.salerz + salerz))
	by firm_id: gen g_salerz_acb5 = -(L5.salerz - salerz)/(0.5*(L5.salerz + salerz))

	by firm_id: gen g_salerz_ac = (F1.salerz - salerz)/(0.5*(F1.salerz + salerz))
	by firm_id: gen g_salerz_ac3 = (F3.salerz - salerz)/(0.5*(F3.salerz + salerz))
	by firm_id: gen g_salerz_ac5 = (F5.salerz - salerz)/(0.5*(F4.salerz + salerz))
	
	by firm_id: gen g_salerz_ll = log(F1.salerz) - log(salerz)
	
	by firm_id: gen g_salerz_llb = log(salerz) - log(L1.salerz)
	by firm_id: gen g_salerz_llb3 = log(salerz) - log(L3.salerz)
	by firm_id: gen g_salerz_llb5 = log(salerz) - log(L5.salerz)
	
	*For employment
	by firm_id: gen g_emp_acb = -(L1.emp - emp)/(0.5*(L1.emp + emp))
	by firm_id: gen g_emp_acb3 = -(L3.emp - emp)/(0.5*(L3.emp + emp))
	by firm_id: gen g_emp_acb5 = -(L5.emp - emp)/(0.5*(L5.emp + emp))

	by firm_id: gen g_emp_ac = (F1.emp - emp)/(0.5*(F1.emp + emp))
	by firm_id: gen g_emp_ac3 = (F3.emp - emp)/(0.5*(F3.emp + emp))
	by firm_id: gen g_emp_ac5 = (F5.emp - emp)/(0.5*(F4.emp + emp))
	
	by firm_id: gen g_emp_ll = log(F1.emp) - log(emp)
	
	by firm_id: gen g_emp_llb = log(emp) - log(L1.emp)
	by firm_id: gen g_emp_llb3 = log(emp) - log(L3.emp)
	by firm_id: gen g_emp_llb5 = log(emp) - log(L5.emp)
	
	*Checking if the composition is an issue. Does the sample changes much across the 
	*years. How many firms stay in the sample for more than 10 years?
	sort firm_id		
	by firm_id: egen num_obs_firm = count(g_saler_ll)
	
	gen identifica = num_obs_firm >= 10 		// Firms with 10+ years of data

	compress		
	saveold "${cdata}/SBC_Clean_BvD_OSI.dta", replace
}
**
	
*#############################################################
*-- CALCULATING THE CROSS SECTIONAL MOMENTS WITHIN COUNTRIES 
*#############################################################

*   Calculation of the time series for the different moments. The primary sample will be of firms 
*   with more than 10 years of data (Not necessarelly countinuous). 
*   Then, I will keep only countries with more than 5000 observations
if "${runmoments}" == "yes"{
set more off	
use cntrycde identifica using "${cdata}/SBC_Clean_BvD_OSI.dta",clear
local measures = "ll"	// possible acb acb3 acb5 ac ac3 ac5 ll llb llb3 llb5
local varies = "g_emp g_saler"				// possible g_salerz g_emp g_saler
local wei = "uw"

keep if identifica == 1						// Keep if firm has more than 10 years of data
levelsof(cntrycde), local(countries) clean

foreach ww of local wei{

foreach vv of local varies {
	foreach mm of local measures {
		di "Working in variable `vv' and measure `mm' with `ww'"
	qui{	
		local cuno = 1
		foreach cc of local countries{
		*foreach cc in "CN" "US"{
			*Selecting Countries and fixing years
			use if cntrycde == "`cc'" & identifica == 1 using "${cdata}/SBC_Clean_BvD_OSI.dta", clear
			sum fyearq
			local fmin = r(min)
			local fmax = r(max)
			local yuno = 1
			forvalues yy = `fmin'(1)`fmax'{
				preserve 
				keep if fyearq == `yy'
				
				if "`ww'" == "w"{
					sum `vv'_`mm' [aw = saler], d
				}
				else {
					sum `vv'_`mm', d
				}
				
				
				gen num_`vv'_`mm' = r(N)		
				gen mean_`vv'_`mm' = r(mean)		
				gen sd_`vv'_`mm' = r(sd)		
				gen sk_`vv'_`mm' = r(skewness)		
				gen ku_`vv'_`mm' = r(kurtosis)	
				
				gen p90_`vv'_`mm' = r(p90)	
					
				gen p75_`vv'_`mm' = r(p75)
				gen p50_`vv'_`mm' = r(p50)
				gen p25_`vv'_`mm' = r(p25)
				gen p10_`vv'_`mm' = r(p10)
				
				if "`ww'" == "w"{
					_pctile `vv'_`mm' [aw = saler], p(2.5 97.5)
				}
				else {
					_pctile `vv'_`mm', p(2.5 97.5)
				}
				
				
				gen p025_`vv'_`mm' = r(r1)
				gen p975_`vv'_`mm' = r(r2)	
				
				gen p9010_`vv'_`mm' = p90_`vv'_`mm' - p10_`vv'_`mm'				
				gen p9050_`vv'_`mm' = p90_`vv'_`mm' - p50_`vv'_`mm'
				gen p5010_`vv'_`mm' = p50_`vv'_`mm' - p10_`vv'_`mm'
				
				gen ksk_`vv'_`mm' = ///
					(p90_`vv'_`mm' + p10_`vv'_`mm' - 2*p50_`vv'_`mm')/(p90_`vv'_`mm' - p10_`vv'_`mm')	
					
				gen cku_`vv'_`mm' = ///
					(p975_`vv'_`mm' - p025_`vv'_`mm')/(p75_`vv'_`mm' - p25_`vv'_`mm')
						
				*Saving 
				keep fyearq cntrycde num* mean* sd* sk* ku* p90* p75* p50* p25* p10* p025* p975* ///
					p9010* p9050* p5010* ksk* cku*
				keep if _n == 1
				
				if `yuno' == 1{
					save "${dfolder}/aux_country.dta", replace 
					local yuno = 2
				}
				else{
					append using "${dfolder}/aux_country.dta"
					save "${dfolder}/aux_country.dta", replace 
				}
				
				restore 
			} // END loop over years
			
			*Retrieve the data for years and append accross countries
			use "${dfolder}/aux_country.dta", clear
			erase "${dfolder}/aux_country.dta"
			
			sort cntrycde fyear
			
			if `cuno' == 1{
				save "${dfolder}/aux_yrs_country.dta", replace 
				local cuno = 2
			}
			else{
				append using "${dfolder}/aux_yrs_country.dta"
				save "${dfolder}/aux_yrs_country.dta", replace 
			}
			
		} // END loop over countries 
		
		*Save to put together later 
		use "${dfolder}/aux_yrs_country.dta", clear
		erase "${dfolder}/aux_yrs_country.dta"
		sort cntrycde fyear 
		save "${cdata}/aux_`vv'_`mm'.dta", replace 
		
	} // END qui statement
	} // END measures loop
} // END vars loop

*Merge to Final Savel 
use "${cdata}/aux_g_emp_ll.dta",clear
foreach vv of local varies {
	foreach mm of local measures {
	merge 1:1 cntrycde fyearq using "${cdata}/aux_`vv'_`mm'.dta", nogenerate
	erase "${cdata}/aux_`vv'_`mm'.dta"
	sort cntrycde fyearq
	} // END measures loop
} // END vars loop

*erase "${cdata}/aux_g_emp_ll.dta"

egen id_country = group(cntrycde)
rename cntrycde iso2
rename fyearq year
tsset id_country year
sort iso2 year
gen wei = "`ww'"
compress	
saveold "${cdata}/aux_OSI_`ww'.dta", replace
}	// END of loop over weigthed
}	
*clear 
*append using "${cdata}/TimeSeries_OSI_w.dta"
*append using "${cdata}/TimeSeries_OSI_uw.dta"
***

*#############################################################################
*-- JOINING THE DATA WITH ISO INFORMATION AND PERFORMING FINAL CLEANING
*#############################################################################
set more off
clear	
local wei = "uw"		// Possible uw w
foreach ww of local wei{
*-- ISO and WDI data 
	*local ww = "uw"
	insheet using "${adata}/country_iso.csv", names comma clear	
	sort iso3
	
	merge 1:m iso3 using "${adata}/wdi_April262018.dta", keep(3) nogenerate
	sort iso2 year
	
*-- Merge with the cross sectional moments per country 
	merge 1:1 iso2 year using "${cdata}/aux_OSI_`ww'.dta"		
	keep if _merge == 3 | iso2 == "TW"
	drop _merge 
	
*-- WDI does not provide data for TWN si we get that data from the WEO
	replace iso3 = "TWN" if iso2 == "TW"
	sort iso3 year 
	merge 1:1 iso3 year using "${adata}/WEOApr2014all.dta", nogenerate
	replace g_rgdp_pc = g_rgdp_weo  if iso3 == "TWN"
	egen iso_id = group(iso3)
	tsset iso_id year
	
*-- Then we  calculate the growth rate of real gdp in us dollars 
	gen  g_rgdp_pc_us_acb = log(rgdp_pc_us) - log(L1.rgdp_pc_us)
	gen  g_rgdp_pc_us_ac = log(F1.rgdp_pc_us) - log(rgdp_pc_us)	

*-- All sample, previous to final Cleaning
	tsset iso_id year
	
*-- Final Cleaning 
	keep if num_g_saler_ll >= 100					// Keep country/years with more than 100 observations 
	by iso_id: egen num_obs_iso = count(p9010_g_saler_ll)		// Count the number years available in each contry 			
	keep if num_obs_iso >=10					// Keep countries with more tha  10 years of data 
	sort year
	by year: egen num_obs_year =  count(p9010_g_saler_ll)		// Count the number of countries per years
	keep if num_obs_year > 10					// Keep years with more than 5 countries
	tsset iso_id year	
	
*-- Compress and Save for the Regressions 
	compress 
	saveold "${cdata}/SBC_TimeSeries_OSI_APR2019_`ww'.dta", replace
	erase "${cdata}/aux_OSI_`ww'.dta"
}	// END of loop over weigths	
	

	
*END OF THE CODE	

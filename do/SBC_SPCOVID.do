/*
	This file replicates the empirical results for Stock Prices and COVID period
	Skewed Business Cycles by Salgado, Guvenen, and Bloom 
	First version March 30, 2020
	This  version April 16, 2020
	
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado
	ssalgado@wharton.upenn.edu
	https://sergiosalgadoi.wordpress.com/
	
	Daily stock returns obtained from COMPUSTAT/CAPITAL IQ from WRDS
	Downloaded on April 15, 2020
	
	The data used here can be also found
	
	https://www.dropbox.com/s/e51w9pq9xiwmu0g/CSTAT_SP_COVID.dta?dl=0
	
	use only for replication puposes. 
*/


*OPTIONS
*---------------------------------------------------------


	clear all
	set more off 
	cd ""
	global dlocation = ""
	global covidcrash = "21feb2020"			// Choose date of the crash
	global covidpre = "20feb2020"			// Choose date of pre crash
	global covend=    "23mar2020"			// Choose date end of the COVID analysis
	
	global grcrash =  "09sep2008"			// Choose date of Great Recession crash
	
*COMPUSTAT
*---------------------------------------------------------

*Load data and clean
	use if (datadate>=d(01jan2015) | (datadate >= d(01jan2008) ///
		& datadate <= d(29mar2009))) & fic == "USA" & loc == "USA" ///
			using "${dlocation}/CSTAT_2008_2020_SP.dta", clear
	
	keep if inlist(exchg,11,12,14)			// Keep those firms traded at NYSE,ASE,NASDAQ
	drop if cshoc  ==.						// If not oustanding shares
	keep if inlist(tpci,"0") 				// Keep common stock
	
	drop if year(ipodate)== 2020			// Drop firms with IPO in 2020
	
	
	egen idnew = group(gvkey tic)
	egen datenew = group(datadate)			//To create the growth rates
	gen year = year(datadate)
	
	gen naics1 = substr(naics,1,1)
	destring naics1, replace 
	
	sort idnew year datenew
	tsset idnew datenew
	
*Calculate daily returns and cum returns wrt to a date 

	*Which price to use?
	local pvar = "prccd"
	
	*.Daily log returns 
	gen d`pvar' = log(`pvar') - log(L1.`pvar')
	
	*.Returns wrt to covidcrash
	gen val0 = `pvar' if datadate == d(${covidpre})
	by idnew: egen mval0 = mean(val0)
	gen d0`pvar' = log(`pvar') - log(mval0)
	
	gen val02 = `pvar' if datadate == d(${covidpre})
	by idnew: egen mval02 = mean(val02)
	gen d0p`pvar' = log(mval02) - log(`pvar')

	*.Returns wrt to Sep/09/2008
	gen val1 = `pvar' if datadate == d(${grcrash})
	by idnew: egen mval1 = mean(val1)
	gen d1`pvar' = log(`pvar') - log(mval1)
		
*Define periods before and after the COVID Outbreak
	gen covperiod = . 
	replace covperiod = 0 if datadate >= d(01jan2020) & datadate< d(${covidpre})
	replace covperiod = 1 if datadate >= d(${covidcrash}) & datadate<= d(${covend})
	
*Define for cum growth at different dates
	gen d20p`pvar' = log(`pvar') - log(L35.`pvar')
	local pvar = "prccd"
			
*Calculate Market Cap 
	gen mkap0 = mval02*cshoc 
	gen mkap1 = mval1*cshoc 
	gen mkap = `pvar'*cshoc
	gen Lmkap = L35.mkap

*Save small dataset for plots
	compress
	drop tic div divd exchg secstat tpci fic idbflag loc naics sic stko 
	saveold "out/CSTAT_SP_COVID.dta", replace

*END OF THE CODE
*--------------------------------------
	
		

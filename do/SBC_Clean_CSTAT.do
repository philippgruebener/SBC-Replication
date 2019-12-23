/*
		
	This file generates the cross sectional moments from Compustat 
	for quarterly and annual frequency used in
	Skewed Business Cycles by Salgado/Guvenen/Bloom 
	(original version SBC_Clean_QUSA_v6.do)
	First version April, 13, 2019
	This  version Dec,16 2019	
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado I.
	ssalgado@wharton.upenn.edu
	https://sergiosalgado.net/
	
	The raw data was last updated on April, 11, 2018
	
*/

*#############################################
*-- OPTIONS
*#############################################
clear all
set more off
cap: ssc install winsor2 	// Used to winsor some outliers. Need internet to install

cd "../SBC-Replication/"
	// Main location
global dfolder = "raw"	
			// Location of raw data 
global cdata = "out"		
			// Location of clean data will be saved 
global adata = "agg"
			// Location aggregate auxiliary data


global basecpi = 217.07 		//  Base is 2009q4 to be consistent with te base of the GDP growth.
global abasecpi = 214.5647		// Base of annual CPI
global aclean = "no"
global qclean = "no"
global amomnt = "yes"
global qmomnt = "yes"
	// Four section
	// aclean: prepares annual data to calculate moments 
	// qclean: prepares quarterly data to calculate moments 
	// amomnt: creates cross sectional moments from annual data 
	// qmomnt: creates cross sectional moments from quarterly data 

			
*################################
*-- CLEAN ANNUAL DATA SECTION 
*################################

if "${aclean}" == "yes" {

*---- Loading the data on sales and employment 
	use "${dfolder}/A_CRSP_CSTAT_1961_2018.dta", clear
					
	keep if inlist(fic,"USA") // Keep if incorporated in the US
	
	destring gvkey, replace	
	rename fyear fyearq	
	sort gvkey fyear	
	gen indica = .
	gen indica2 = .
	by gvkey: replace indica= 1 if fyear == fyear[_n-1]
	drop if indica == 1				// Only 73 observations have two entries for the same year
		
*--- Calcualting the average employment distribution
	tsset gvkey fyear 
	replace emp = . if emp <= 0 		
	by gvkey: gen ave_emp = 1000*(L1.emp + L2.emp + L3.emp)*(1/3)		
	
*-- Calculating the age of the firm. Cohort in the period first observed in the sample. Which corresponds to the IPO	
	by gvkey: egen cohort = min(fyear)
	by gvkey: gen age = fyear - cohort 
	
*--- Drop if non positive sales
	drop if sale <= 0 | sale == . 

*-- Replace negative profits and negative invetories by missing	
*	These variables are used for robustness checks. 
	replace invfg = . if invfg <  0 
	replace gp    = . if gp    <  0 
	 
	
*--- Calcualting the Leverage as Total Debt to Total Assets 
	gen debt_total = dltt + dlc 
	gen lev = dt/at
	gen lev_dlc = dlc/at
	gen lev_tot = debt_total /at
	
*-- Compress and merges with CPI 	
	sort gvkey fyearq 
	compress
	merge m:1 fyearq using "${adata}/CPIAUCSL_A.dta",keep(3) nogenerate	

*-- Real sales, assets, stock prices, profits, and invetories
	gen saler = sale*(${abasecpi}/cpi)
	gen atr = at*(${abasecpi}/cpi)
	gen prcc_cr = prcc_c*(${abasecpi}/cpi)
	gen gpr =  	  gp*(${abasecpi}/cpi)
	gen invfgr =  invfg*(${abasecpi}/cpi)
	tsset gvkey fyear
	
*-- Residuals of a regression 
	gen lsaler = log(saler)
	gen lemp = log(emp)
	
	areg lsaler L1.lemp, abso(gvkey)
	predict lsaler_res if e(sample), resid 
	
	reg lsaler_res L1.lsaler_res i.year, abso(gvkey)
	predict lsaler_innov if e(sample), resid 

*-- Sales over employment 
	gen saler2emp = saler/emp
	
*-- Sales with exit 
	tsfill, full			// Neccessary to do entry and exit. 
	gen salerz = saler
	replace salerz = 0 if salerz  == .
	*Employment with exit 
	gen empz = emp 
	replace empz = 0 if empz == . 
	*Assets with exit 
	gen atrz = atr 
	replace atrz = 0 if atrz == . 
	
*-- Sum of inventories and sales
	gen salerinv = invfgr+saler
	
*-- NAICS 
	gen naics2 = substr(naics,1,2)
	destring naics2,replace force
	bys gvkey: egen mnaics = max(naics2)
	replace naics2 = mnaics if naics2 ==. 
	levelsof naics2, local(naicl) clean
	gen naiclab = ""
	foreach nn of local naicl{
		replace naiclab = "naic`nn'" if naiclab == "" & naics2 == `nn'
	}
	
	*SIC 
	destring sic, replace force
	bys gvkey: egen msic = max(sic)
	replace sic = msic if sic ==. 
	
	*1-digit SIC
	gen sic1 = . 
	replace sic1 = 1 if sic >=100 & sic <= 999 & sic1 == . 
	replace sic1 = 2 if sic >=1000 & sic <= 1499 & sic1 == . 
	replace sic1 = 3 if sic >=1500 & sic <= 1799 & sic1 == . 
	replace sic1 = 4 if sic >=2000 & sic <= 3999 & sic1 == . 
	replace sic1 = 5 if sic >=4000 & sic <= 4999 & sic1 == . 
	replace sic1 = 6 if sic >=5000 & sic <= 5199 & sic1 == . 
	replace sic1 = 7 if sic >=5200 & sic <= 5999 & sic1 == . 
	replace sic1 = 8 if sic >=6000 & sic <= 6799 & sic1 == . 
	replace sic1 = 9 if sic >=7000 & sic <= 8999 & sic1 == . 
	replace sic1 = 10 if sic >=9100 & sic <= 9729 & sic1 == . 
	replace sic1 = 11 if sic >=9900 & sic <= 9999 & sic1 == .
	
	/*	
	0100-0999	Agriculture, Forestry and Fishing
	1000-1499	Mining
	1500-1799	Construction
	1800-1999	not used
	2000-3999	Manufacturing
	4000-4999	Transportation, Communications, Electric, Gas and Sanitary service
	5000-5199	Wholesale Trade
	5200-5999	Retail Trade
	6000-6799	Finance, Insurance and Real Estate
	7000-8999	Services
	9100-9729	Public Administration
	9900-9999	Nonclassifiable
	*/	
	
*-- Leverage categories
	sort fyear
	replace lev_tot = . if lev_tot > 2
	by fyear: egen p25_lev_tot = pctile(lev_tot), p(25)
	by fyear: egen p50_lev_tot = pctile(lev_tot), p(50)
	by fyear: egen p75_lev_tot = pctile(lev_tot), p(75)
	gen cat_lev_tot = .
	replace cat_lev_tot = 1 if lev_tot  <= p25_lev_tot & cat_lev_tot == . 
	replace cat_lev_tot = 2 if lev_tot  <= p50_lev_tot & cat_lev_tot == . 
	replace cat_lev_tot = 3 if lev_tot  <= p75_lev_tot & cat_lev_tot == . 
	replace cat_lev_tot = 4 if lev_tot  >  p75_lev_tot & cat_lev_tot == . & lev_tot != . 
	drop p*_lev_tot
	tsset gvkey fyear

*-- Investmemt rate 
	gen inv_rate = capx/L1.ppent			
	
*-- Investment in R&D to Sales
	gen xrd_sale = xrd/sale					
	
*-- Growth rates of sales 
	*Forward 
	gen g_saler_pp =  (F1.saler - saler)/saler
	gen g_saler_pp3 = (F3.saler - saler)/saler
	gen g_saler_pp5 = (F5.saler - saler)/saler
	gen g_saler_pp10 = (F10.saler - saler)/saler
	
	gen g_saler_ll =  log(F1.saler) - log(saler)
	gen g_saler_ll3 = log(F3.saler) - log(saler)
	gen g_saler_ll5 = log(F5.saler) - log(saler)
	gen g_saler_ll10 = log(F10.saler) - log(saler)
	
	gen g_saler_ac =  (F1.saler - saler)/(0.5*(F1.saler + saler))	
	gen g_saler_ac3 = (F3.saler - saler)/(0.5*(F3.saler + saler))	
	gen g_saler_ac5 = (F5.saler - saler)/(0.5*(F5.saler + saler))	
	gen g_saler_ac10 = (F10.saler - saler)/(0.5*(F10.saler + saler))
	
	gen g_salerz_ac =  (F1.salerz - salerz)/(0.5*(F1.salerz + salerz))	
	gen g_salerz_ac3 = (F3.salerz - salerz)/(0.5*(F3.salerz + salerz))	
	gen g_salerz_ac5 = (F5.salerz - salerz)/(0.5*(F5.salerz + salerz))		
	gen g_salerz_ac10 = (F10.salerz - salerz)/(0.5*(F10.salerz + salerz))
	
	*Backwards
	gen g_saler_ppb =  (saler - L1.saler)/L1.saler
	gen g_saler_ppb3 = (saler - L3.saler)/L3.saler
	gen g_saler_ppb5 = (saler - L5.saler)/L5.saler
	gen g_saler_ppb10 = (saler - L10.saler)/L10.saler
	
	gen g_saler_llb =  log(saler) - log(L1.saler)
	gen g_saler_llb3 = log(saler) - log(L3.saler)
	gen g_saler_llb5 = log(saler) - log(L5.saler)
	gen g_saler_llb10 = log(saler) - log(L10.saler)
	
	gen g_saler_acb =  (saler - L1.saler)/(0.5*(L1.saler + saler))	
	gen g_saler_acb3 = (saler - L3.saler)/(0.5*(L3.saler + saler))	
	gen g_saler_acb5 = (saler - L5.saler )/(0.5*(L5.saler + saler))	
	gen g_saler_acb10 = (saler -  L10.saler)/(0.5*(L10.saler + saler))
	
	gen g_salerz_acb =  (salerz-L1.salerz)/(0.5*(L1.salerz + salerz))	
	gen g_salerz_acb3 = (salerz-L3.salerz )/(0.5*(L3.salerz + salerz))	
	gen g_salerz_acb5 = (salerz-L5.salerz)/(0.5*(L5.salerz + salerz))		
	gen g_salerz_acb10 = (salerz-L10.salerz )/(0.5*(L10.salerz + salerz))
	
	*Growth rates of employment 
	*Forward 
	gen g_emp_pp =  (F1.emp - emp)/emp
	gen g_emp_pp3 = (F3.emp - emp)/emp
	gen g_emp_pp5 = (F5.emp - emp)/emp
	gen g_emp_pp10 = (F10.emp - emp)/emp
	
	gen g_emp_ll =  log(F1.emp) - log(emp)
	gen g_emp_ll3 = log(F3.emp) - log(emp)
	gen g_emp_ll5 = log(F5.emp) - log(emp)
	gen g_emp_ll10 = log(F10.emp) - log(emp)
	
	gen g_emp_ac =  (F1.emp - emp)/(0.5*(F1.emp + emp))	
	gen g_emp_ac3 = (F3.emp - emp)/(0.5*(F3.emp + emp))	
	gen g_emp_ac5 = (F5.emp - emp)/(0.5*(F5.emp + emp))	
	gen g_emp_ac10 = (F10.emp - emp)/(0.5*(F10.emp + emp))
	
	gen g_empz_ac =  (F1.empz - empz)/(0.5*(F1.empz + empz))	
	gen g_empz_ac3 = (F3.empz - empz)/(0.5*(F3.empz + empz))	
	gen g_empz_ac5 = (F5.empz - empz)/(0.5*(F5.empz + empz))		
	gen g_empz_ac10 = (F10.empz - empz)/(0.5*(F10.empz + empz))
	
	*Backwards
	gen g_emp_ppb =  (emp - L1.emp)/L1.emp
	gen g_emp_ppb3 = (emp - L3.emp)/L3.emp
	gen g_emp_ppb5 = (emp - L5.emp)/L5.emp
	gen g_emp_ppb10 = (emp - L10.emp)/L10.emp

	gen g_emp_llb =  log(emp) - log(L1.emp)
	gen g_emp_llb3 = log(emp) - log(L3.emp)
	gen g_emp_llb5 = log(emp) - log(L5.emp)
	gen g_emp_llb10 = log(emp) - log(L10.emp)
	
	gen g_emp_acb =  (emp-L1.emp)/(0.5*(L1.emp + emp))	
	gen g_emp_acb3 = (emp-L3.emp)/(0.5*(l3.emp + emp))	
	gen g_emp_acb5 = (emp-L5.emp)/(0.5*(L5.emp + emp))	
	gen g_emp_acb10 = (emp-L10.emp)/(0.5*(L10.emp + emp))
	
	gen g_empz_acb =  (empz-L1.empz)/(0.5*(L1.empz + empz))	
	gen g_empz_acb3 = (empz-L3.empz)/(0.5*(L3.empz + empz))	
	gen g_empz_acb5 = (empz-L5.empz)/(0.5*(L5.empz + empz))		
	gen g_empz_acb10 = (empz-L10.empz)/(0.5*(L10.empz + empz))
	
	*Stock Prices
	gen g_prcc_cr_ll =  log(F1.prcc_cr) - log(prcc_cr)
	gen g_prcc_cr_ll3 = log(F3.prcc_cr) - log(prcc_cr)
	gen g_prcc_cr_ll5 = log(F5.prcc_cr) - log(prcc_cr)
	gen g_prcc_cr_ll10 = log(F10.prcc_cr) - log(prcc_cr)
	
	*Residualized Sales
	gen g_lsaler_res_ll = F1.lsaler_res - lsaler_res
	gen g_lsaler_res_ll3 = F3.lsaler_res - lsaler_res
	gen g_lsaler_res_ll5 = F5.lsaler_res - lsaler_res
	gen g_lsaler_res_ll10 = F10.lsaler_res - lsaler_res
	
	*Sales to employment 
	gen g_saler2emp_ll = log(F1.saler2emp) - log(saler2emp)
	gen g_saler2emp_ll3 = log(F3.saler2emp) - log(saler2emp)
	gen g_saler2emp_ll5 = log(F5.saler2emp) - log(saler2emp)
	gen g_saler2emp_ll10 = log(F10.saler2emp) - log(saler2emp)
	
	*Profits 
	gen g_gpr_ll = log(F1.gpr) - log(gpr)
	gen g_gpr_ll3 = log(F3.gpr) - log(gpr)
	gen g_gpr_ll5 = log(F5.gpr) - log(gpr)
	gen g_gpr_ll10 = log(F10.gpr) - log(gpr)
	
	*Inventories
	gen g_invfgr_ll = log(F1.invfgr) - log(invfgr)
	gen g_invfgr_ll3 = log(F3.invfgr) - log(invfgr)
	gen g_invfgr_ll5 = log(F5.invfgr) - log(invfgr)
	gen g_invfgr_ll10 = log(F10.invfgr) - log(invfgr)
	
	*Sales plus inventories
	gen g_salerinv_ll = log(F1.salerinv) - log(salerinv)
	gen g_salerinv_ll3 = log(F3.salerinv) - log(salerinv)
	gen g_salerinv_ll5 = log(F5.salerinv) - log(salerinv)
	gen g_salerinv_ll10 = log(F10.salerinv) - log(salerinv)
	
	*Identify firms with 10 yrs of data or more
	sort gvkey	
	by gvkey: egen count_number = count(sale)	
	by gvkey: gen identifica = 1 if count_number>=25
	by gvkey:replace identifica =  2 if count_number>=10 & identifica==.
	by gvkey:replace identifica =  3 if count_number>=2 & identifica==.
	by gvkey:replace identifica =  4 if count_number<2 & identifica==.
	
	*Average employment, average sales, average assets 
	tsset gvkey fyear 
	sort gvkey fyear
	gen ave_emp1 = 0.5*(F1.empz + empz)	
	gen ave_saler1 = 0.5*(F1.salerz + salerz)
	gen ave_atr1 = 0.5*(F1.atrz + atrz)

	gen ave_emp3 = 0.5*(F3.empz + empz)	
	gen ave_saler3 = 0.5*(F3.salerz + salerz)	
	gen ave_atr3 = 0.5*(F3.atrz + atrz)

	gen ave_emp5 = 0.5*(F5.empz + empz)	
	gen ave_saler5 = 0.5*(F5.salerz + salerz)	
	gen ave_atr5 = 0.5*(F5.atrz + atrz)
	
	*Compress and save
	compress
	sort gvkey fyearq
	saveold "${cdata}/SBC_A_CSTAT_1961_2018_clean.dta", replace
	
	
}	// END of cleaning annual data section 	
**

*################################	
*-- CLEAN QUARTERLY DATA SECTION 
*################################

if "${qclean}" == "yes"{

*-- Load data 
	use "${dfolder}/Q_CRSP_CSTAT_1961_2018.dta", clear
	
	tostring fyearq fqtr, replace
	gen date = fyearq+"q"+fqtr
	destring gvkey fyearq fqtr, replace	
	sort gvkey fyearq fqtr	
	
*-- Cleaning repeated data, non-positive sales, incorporated out of the US
	gen indica = .
	gen indica2 = .
	by gvkey: replace indica= 1 if date == date[_n-1]
	drop if indica == 1
	drop if saleq < 0 | saleq == . 
	keep if inlist(fic,"USA")
	
*-- Generating quaters 
	gen qtr=yq(fyearq,fqtr)
	format qtr %tq	
	sort gvkey fyearq fqtr	
	
*-- Merge data CPI 
	merge m:1 qtr using "${adata}/CPIAUCSL_Q.dta",keep(3) nogenerate			

*-- Merge with Employment and Naics Data
	sort gvkey fyearq fqtr
	merge m:1 gvkey fyearq using "${cdata}/SBC_A_CSTAT_1961_2018_clean.dta", ///
		keep(3 1) nogenerate keepusing(sale naics emp)
			
*-- Create measure of real salesq and sale
	gen saleqr = saleq*(${basecpi}/cpi)
	gen saler = sale*(${basecpi}/cpi)

*-- Generating a measure of Operational Profits which is Sales minus the cost of goods 
	replace cogsq  = . if cogsq < 0
	gen opeprof = saleq - cogsq 

*-- Putting in missing inventories which are negative	
	replace invtq = . if invtq < 0	
	
*-- SIC classification: 	
	gen sic2 = substr(sic,1,2)
	destring sic2, replace	
	gen sicb = . 
	replace sicb = 1 if sic2 <= 14			// Agriculture, Forestry, & Fishing - Mining
	replace sicb = 2 if sic2 <=17 & sicb == .	// Contruction
	replace sicb = 3 if sic2 <=39 & sicb == .	// Manufacturing 
	replace sicb = 4 if sic2 <=49 & sicb == .	// Transportation 
	replace sicb = 5 if sic2 <=59 & sicb == .	// Wholesale and Retail Trade 
	replace sicb = 6 if sic2 <=69 & sicb == .	// FIRE
	replace sicb = 7 if sic2 <=89 & sicb == .	// Services 
	replace sicb = 8 if sic2 <=99 & sicb == .	// Public Administrations non classified firms	
	drop if sicb == 8				// Drop Public Administration	
	
*-- NAICS classification 
	gen naics2 = substr(naics,1,2)
	destring naics2,replace force
	bys gvkey: egen mnaics = max(naics2)
	replace naics2 = mnaics if naics2 ==. 
	levelsof naics2, local(naicl) clean
	gen naiclab = ""
	foreach nn of local naicl{
		replace naiclab = "naic`nn'" if naiclab == "" & naics2 == `nn'
	}
	
/*
Creating the selection. I create a dummy for firms present for years>=25 (100 quarters),
one for firms present for years>=10 (40 quarters)
and all those firms present for less than 2 years (8 quarters)
*/
	sort gvkey	
	by gvkey: egen count_number = count(saleq)	
	by gvkey: gen identifica = 1 if count_number>=100
	by gvkey:replace identifica =  2 if count_number>=40 & identifica==.
	by gvkey:replace identifica =  3 if count_number>=8 & identifica==.
	by gvkey:replace identifica =  4 if count_number<8 & identifica==.		
	
	
/*
Creating selection for Balanced Panel: Firms with full info of sales between 1990q1 to 2013q4.
This will solve the problem of result driven by exit of firms 
*/
	gen saux = saleqr if saleq > 0
	gen pinic_iden = 1 if fyearq == 1990 & fqtr == 1		// Identifies firms present in 1990q1
	by gvkey: egen bp_count = count(saux) if fyearq >= 1990  & fqtr >= 1 & fyearq <= 2013 & fqtr <= 4
	gen bp = 0 
	replace bp = 1 if bp_count == 96				// 24 years times 4 quarter = 96
	drop bp_count	
	
/*
Measuring Annual Sales - to - Employment 
*/
	gen lsaletoemp = log((1000000*sale/cpi)/(1000*emp))
	
*#############################################
*-- CREATING GROWTH RATES VARIABLES
*#############################################
	set more off
	tsset gvkey qtr
	tsfill, full							// To calculate with entry and exit
	gen yearaux = yofd(dofq(qtr))
	replace fyearq = yearaux if fyearq == . 
	
*-- Log values 
	gen saleqrz = saleqr 				// Saleq qith zeros when is empty 
	replace saleqrz = 0 if saleqrz == .		// replace by 0 to account for entry and exit	
	
	replace sale = . if sale <=0			// replace annual sales
	gen salez = sale			
	replace salez = 0 if salez == .
	
	by gvkey: gen l_saleq = log(saleqr)		// log-level of sales
	by gvkey: gen l_emp = log(emp)			// log-level of sales

*-- Sales Zero
	by gvkey: gen g_saleqrz_acb = (saleqrz  - L4.saleqrz)/(0.5*(saleqrz  + L4.saleqrz))		
	by gvkey: gen g_saleqrz_ac = (F4.saleqrz - saleqrz )/(0.5*(F4.saleqrz  + saleqrz))	

*-- Sales Real
	by gvkey: gen g_saleqr_acb = (saleqr  - L4.saleqr)/(0.5*(saleqr  + L4.saleqr))	
	by gvkey: gen g_saleqr_ac = (F4.saleqr - saleqr )/(0.5*(F4.saleqr  + saleqr))	
	
	by gvkey: gen g_saleqr_ll = log(F4.saleqr) - log(saleqr)
	by gvkey: gen g_saleqr_llb = log(saleqr) - log(L4.saleqr)
	
*-- Different Horizons
	*forvalues ff = 1(1)20{
	foreach ff in 12 20{
		gen g_saleqr_ac`ff' =  (F`ff'.saleqr - saleqr )/(0.5*(F`ff'.saleqr  + saleqr))	
		gen g_saleqr_ll`ff' =  log(F`ff'.saleqr) - log(saleqr )
		gen g_saleqrz_ac`ff' =  (F`ff'.saleqrz - saleqrz )/(0.5*(F`ff'.saleqrz  + saleqrz))
		
		gen g_saleqr_acb`ff' =  (saleqr - L`ff'.saleqr )/(0.5*(saleqr  + L`ff'.saleqr))	
		gen g_saleqr_llb`ff' =  log(saleqr) - log(L`ff'.saleqr) 
		gen g_saleqrz_acb`ff' =  (saleqrz - L`ff'.saleqrz )/(0.5*(saleqrz  + L`ff'.saleqrz))	

	}
			
*-- Sales Nominal
	by gvkey: gen g_saleq_acb = (saleq  - L4.saleq )/(0.5*(saleq  + L4.saleq ))	
	by gvkey: gen g_saleq_ac = (F4.saleq  - saleq )/(0.5*(F4.saleq  + saleq ))	
	by gvkey: gen g_saleq_ll = log(F4.saleq ) - log(saleq)	
	by gvkey: gen g_saleq_llb = log(saleq ) - log(L4.saleq)	
				
*-- Operational Profits
	by gvkey: gen g_opeprof_acb = (opeprof   - L4.opeprof  )/(0.5*(opeprof   + L4.opeprof  ))	
	by gvkey: gen g_opeprof_ac = (F4.opeprof   - opeprof  )/(0.5*(F4.opeprof   + opeprof  ))
	by gvkey: gen g_opeprof_llb = log(opeprof) - log(L4.opeprof)		
	by gvkey: gen g_opeprof_ll = log(F4.opeprof) - log(opeprof)			

*-- Inventories
	by gvkey: gen g_invtq_acb = (invtq  - L4.invtq)/(0.5*(invtq  + L4.invtq))	
	by gvkey: gen g_invtq_ac = (F4.invtq  - invtq)/(0.5*(F4.invtq  + invtq))	
	by gvkey: gen g_invtq_llb = log(invtq) - log(L4.invtq)	
	by gvkey: gen g_invtq_ll = log(F4.invtq) - log(invtq)	

*-- Employment 	
	by gvkey: gen g_emp_acb = (emp  - L4.emp )/(0.5*(emp  + L4.emp ))	
	by gvkey: gen g_emp_ac = (F4.emp - emp )/(0.5*(F4.emp  + emp))
	by gvkey: gen g_emp_llb = log(emp) - log(L4.emp)	
	by gvkey: gen g_emp_ll = log(F4.emp) - log(emp)	
	
*-- Annual Sales	
	by gvkey: gen g_sale_acb = (sale  - L4.sale )/(0.5*(sale  + L4.sale))	
	by gvkey: gen g_sale_ac = (F4.sale - sale )/(0.5*(F4.sale  + sale))
	
	by gvkey: gen g_sale_acb12 = (sale  - L12.sale )/(0.5*(sale  + L12.sale))	
	by gvkey: gen g_sale_ac12 = (F12.sale - sale )/(0.5*(F12.sale  + sale))

	by gvkey: gen g_sale_acb20 = (sale  - L20.sale )/(0.5*(sale  + L20.sale))	
	by gvkey: gen g_sale_ac20 = (F20.sale - sale )/(0.5*(F20.sale  + sale))

	by gvkey: gen g_sale_llb20 = log(sale)  - log(L20.sale)
	by gvkey: gen g_sale_ll20 = log(F20.sale) - log(sale)
	
	by gvkey: gen g_sale_llb = log(sale) - log(L4.sale)	
	by gvkey: gen g_sale_ll = log(F4.sale) - log(sale)

*-- Stock Prices 
	by gvkey: gen g_prccq_ll = log(F4.prccq ) - log(prccq)	
	by gvkey: gen g_prccq_llb = log(prccq ) - log(L4.prccq)
	
	by gvkey: gen g_prccq_ll12 = log(F12.prccq ) - log(prccq)	
	by gvkey: gen g_prccq_ll20 = log(F20.prccq ) - log(prccq)	
	  
*-- Sales over Employment 
	by gvkey: gen g_sale2emp_llb = lsaletoemp - L4.lsaletoemp
	by gvkey: gen g_sale2emp_ll = F4.lsaletoemp - lsaletoemp

*-- Adjusting the measure of sales growth for exits
	by gvkey: gen iaux = 1 if g_saleqrz_acb == -2
	replace iaux = 0 if iaux == .
	replace iaux = 0 if iaux == .
	gen g_saleqrz_acb2 = g_saleqrz_acb
	 by gvkey: gen siaux = iaux +  iaux[_n-1] 
	replace g_saleqrz_acb2 = . if siaux == 2
	drop iaux siaux
				
*-- Preparing for saving 	
	compress 
	saveold "${cdata}/SBC_Q_CRSP_CSTAT_1961_2018_clean.dta", replace
}	// END of cleaning quarterly data 	
**
	
*#############################	
*-- ANNUAL MOMENTS DATA SECTION 
*#############################

if "${amomnt}" == "yes"{
	
*-- Load data and defines locals for loop 
	set more off
	use "${cdata}/SBC_A_CSTAT_1961_2018_clean.dta", clear
	global iyear = 1970					// Inic years
	global eyear = 2017					// End years
	local bases "o10"				
		// Choose the size of the sample. Three bases: 
		//all: all firms in the sample
		//o10: firms with at least 10 years of data 
		//o25: firms with at least 25 years of data 
	local wbases "uw"
		// Choose whether moments will be weigthed. Two cases wbases:w, uw
	
	levelsof naiclab, local(nlab) clean	
	local subgp = "all `nlab'"		
	disp("`subgp'") 				
		// Creates the local for the groups for which moments will be calculated
		// here is all sample and within industry

	*Variables 
	local variables "g_saler_ll g_emp_ll"
	disp("`variables'")
	
*-- Starts the main loop to calculate moments 

	foreach ww of local wbases{
	foreach vv of local variables{
	disp "Working on wei `ww' for variable `vv'"
	qui{
		forvalues yy = $iyear(1)$eyear{
			foreach bb of local bases {
			foreach sg of local subgp{
			
			preserve 
			*Select variables
			keep saler emp ave_emp* ave_saler* ave_atr* identifica gvkey fyearq naiclab cat_lev_tot `vv'
			drop if `vv' == . 
			 
			*Select year
			keep if fyearq == `yy'
			
			*Select base
			if "`bb'" == "o10" {
				keep if identifica<=2 
			}
			if "`bb'" == "o25" {
				keep if identifica<=1
			}
			
			*Select subgroup 
			if (substr("`sg'",1,4) == "naic"){
				keep if naiclab == "`sg'"
			}
			if (substr("`sg'",1,3) == "cat"){
				local auxi = substr("`sg'",-1,.)
				keep if cat_lev_tot == `auxi'
			}
			
			*Select w-var (When employment series start, replace the wbar)
			*One year
			local wvar = "ave_saler1"
			if inlist("`vv'","g_saler_ll","g_saler_ac","g_saler_pp","g_lsaler_res_ll","lsaler_res","g_saler2emp_ll"){
				local wvar = "ave_saler1"
			}
			if inlist("`vv'","g_emp_ll","g_emp_ac","g_emp_pp"){
				local wvar = "ave_emp1"
			}
			if inlist("`vv'","g_prcc_cr_ll"){
				local wvar = "ave_atr1"
			}
			*Three years
			if inlist("`vv'","g_saler_ll3","g_saler_ac3"){
				local wvar = "ave_saler3"
			}
			if inlist("`vv'","g_emp_ll3","g_emp_ac3"){
				local wvar = "ave_emp3"
			}
			if inlist("`vv'","g_prcc_cr_ll3"){
				local wvar = "ave_atr3"
			}			
			*Five years
			if inlist("`vv'","g_saler_ll5","g_saler_ac5"){
				local wvar = "ave_saler5"
			}
			if inlist("`vv'","g_emp_ll5","g_emp_ac5"){
				local wvar = "ave_emp5"
			}			
			if inlist("`vv'","g_prcc_cr_ll5"){
				local wvar = "ave_atr5"
			}			
				
			*Calculating the moments 
			*Trimm some outliers using winsor2
			if "`ww'" == "uw" { 
				if inlist("`vv'","g_saler_ll","g_saler_ll3","g_saler_ll5","g_saler_ll10", ///
					"g_saler_llb","g_saler_llb3","g_saler_llb5","g_saler_llb10") | ///
					 inlist("`vv'","g_emp_ll","g_emp_ll3","g_emp_ll5","g_emp_ll10", ///
					"g_emp_llb","g_emp_llb3","g_emp_llb5","g_emp_llb10") | ///
					inlist("`vv'","inv_rate","xrd_sale","g_saler_pp","lsaler_res","g_saler2emp_ll"){
					cap: winsor2 `vv', by(fyearq) cuts(1 99) trim replace
					sum `vv' , d	
				}
				else{
					sum `vv' , d
				}
			}
			if "`ww'" == "w" { 
				if inlist("`vv'","g_saler_ll","g_saler_ll3","g_saler_ll5","g_saler_ll10", ///
					"g_saler_llb","g_saler_llb3","g_saler_llb5","g_saler_llb10") | ///
					 inlist("`vv'","g_emp_ll","g_emp_ll3","g_emp_ll5","g_emp_ll10", ///
					"g_emp_llb","g_emp_llb3","g_emp_llb5","g_emp_llb10") | ///
					 inlist("`vv'","g_prcc_cr_ll","g_prcc_cr_ll3","g_prcc_cr_ll5","g_saler_pp"){
					cap: winsor2 `vv', by(fyearq) cuts(1 99) trim replace
					sum `vv' [aw  = `wvar'], d	
				}
				else{
					sum `vv' [aw  = `wvar'], d
				}
			}
				
						
				gen num = r(N)
				gen me = r(mean)
				gen sd = r(sd)
				gen sk = r(skewness)
				gen ku = r(kurtosis)
				gen min = r(min)
				gen max = r(max)
				
				gen p05 = r(p5)
				gen p95 = r(p95)
				
				*Jut for the wegths
				sum `wvar'
				gen t`wvar' = r(sum)
				gen me`wvar' = r(mean)
				
				if "`ww'" == "uw" { 
					_pctile   `vv',  ///
						percentiles(2.5 10 12.5 25 37.5 50 62.5 75 87.5 90 97.5)
				}
				if "`ww'" == "w" { 
					_pctile   `vv' [aw = `wvar'],  ///
						percentiles(2.5 10 12.5 25 37.5 50 62.5 75 87.5 90 97.5)
				}
				
				gen p025 = r(r1)
				gen p10 = r(r2)
				gen p125 = r(r3)
				gen p25 = r(r4)
				gen p375 = r(r5)
				
				gen p50 = r(r6)
				
				gen p625 = r(r7)
				gen p75 = r(r8)
				gen p875 = r(r9)
				gen p90 = r(r10)
				gen p975 = r(r11)
				
				gen p9010 = p90 - p10
				gen p7525 = p75 - p25
				gen p9050 = p90 - p50
				gen p5010 = p50 - p10
				
				gen ksk = (p90 + p10 - 2*p50)/p9010
				gen ksk2 = (p95 + p05 - 2*p50)/(p95 - p05)
				gen ksk3 = (p975 + p025 - 2*p50)/(p975 - p025)
				
				gen mku = ((p875 - p625) + (p375 - p125))/(p75 - p25)
				gen cku = (p975 - p025)/(p75 - p25)
			
				keep fyearq num* me* sd* sk* ku* p975* p95* p90* p75* p50* p25* ///
					p10* p05* p025* p9010* p7525* p9050* p5010* ksk* mku* cku* min* max* t`wvar' me`wvar'
				keep if _n == 1
				compress 
				save "${cdata}/outa_`bb'_`vv'_`yy'_`ww'_`sg'.dta", replace 	
			restore
			
			} 	// END loop of sub groups
			
			}	// END loop of bases
		}	// END loop over years 
	}	// END of qui statement
	
	}	// END loop over variables
	}	// END of loop over wbases
	
*-- Merging the data 
	set more off	
	clear 
	foreach ww of local wbases{
	foreach vv of local variables{
	 forvalues yy = $iyear(1)$eyear{
	  foreach bb of local bases {
	  
	  foreach sg of local subgp{
	  
	  append using "${cdata}/outa_`bb'_`vv'_`yy'_`ww'_`sg'.dta"
	  cap: gen vari = "`vv'"
	  cap: gen base = "`bb'"
	  cap: gen wei = "`ww'"
	  cap: gen subgroup = "`sg'"
	  cap: replace vari = "`vv'" if vari == ""
	  cap: replace base = "`bb'" if base == ""
	  cap: replace wei = "`ww'" if wei == ""
	  cap: replace subgroup = "`sg'" if subgroup == ""
	  erase "${cdata}/outa_`bb'_`vv'_`yy'_`ww'_`sg'.dta"
	  }	// END loop ove subgroups
	  
	  } // END variables
	 } // END years
	} // END bases
	}	// END of loop over wbases
*-- Save for results 	
	compress
	order base wei subgroup vari fyear
	saveold "${cdata}/SBC_TimeSeries_CSTAT_ANNUAL_DEC2019.dta", replace 	
} // END OF THE ANNUAL MOMENTS SECTION
**

*#########################################################################
*CREATING THE PERCENTILES AND OTHER CROSS SECTIONAL MOMENTS -- QUARTERLY
*#########################################################################

if "${qmomnt}" == "yes"{

*-- Load data and defines locals for loop 
	set more off
	global iyear = 1970				// Inic years
	global eyear = 2018				// End years
	local bases "o10"				// Choose te size of the sample. Three bases: all, o10, and o25
							// Choose the variables ober which u want to calculate the moments
	local wbases "uw"				// No wheiths = uw,  employment = w, sales = s
	local subgp "all naic11 naic21 naic22 naic23 naic31 naic32 naic33 naic42 naic44 naic45 naic48 naic49 naic51 naic52 naic53 naic54 naic56 naic61 naic62 naic71 naic72 naic81 naic99"
	disp ("`subgp'")

	local variables = "g_saleqr_ll g_prccq_ll"
	disp ("`variables'")

*-- Main loop 	
	foreach bb of local bases {
	foreach gg of local subgp{
		
	foreach vv of local variables {
		*Selecting the base 	
			
		*O25 sample 
		if "`bb'" == "o25" {			
			use if identifica == 1 & `vv' != . using "${cdata}/SBC_Q_CRSP_CSTAT_1961_2018_clean.dta", clear 						
		}		
		*O10 sample 
		if "`bb'" == "o10" {
			use if identifica <=2 & `vv' != . using  "${cdata}/SBC_Q_CRSP_CSTAT_1961_2018_clean.dta", clear
		}
		*-- All Sample 	
		if "`bb'" == "all" {
			use if `vv' != . using "${cdata}/SBC_Q_CRSP_CSTAT_1961_2018_clean.dta", clear 
		}	
		
		*Select subgroup 
		if (substr("`gg'",1,4) == "naic"){
			keep if naiclab == "`gg'"
		}				
		
		*If the variable is log, do standard winsorization
		if inlist("`vv'","g_saleqr_ll","g_saleqr_ll12","g_saleqr_ll20", ///
		"g_saleqr_llb","g_saleqr_llb12","g_saleqr_llb20","g_saleqrz_acb2") {
			winsor2 `vv', cuts(1 99) replace trim
		}
		
		*Loop to calculate the moments of the cross sectional distribution
		foreach ww of local wbases {
		forvalues yy = $iyear (1) $eyear{
		di "Working on var `vv' of group `gg' in year `yy'. Measures are `ww'"
		qui{
		forvalues qq = 1(1)4{
			preserve 
			
			*-- Applying the criterias			
			if "`ww'" == "w"{
				drop if emp == . 	// IF the series are going to be w, then drop no employment to have a smaller sample
				drop if emp < 0 
				local wvar = "emp"
			}
			if "`ww'" == "s"{
				drop if saler == . 	// IF the series are going to be w, then drop observatiosn without sales
				drop if saler < 0 
				local wvar = "saler"							
			}
			
			*-- Keep the/year quarter under analysis								
			keep if fyearq == `yy' 
			keep if fqtr == `qq'								
					
			*-- Calculating the moments
			
			*Weigthed
			if "`ww'" == "w" | "`ww'" == "s"{ 	
				*-- Total employment
				
				gen tot_emp = sum(emp)
				
				*-- Sales 		
				sum `vv' [aw = `wvar'], d
				
				gen num_`vv' = r(N)
				gen me_`vv' = r(mean)			
				gen sd_`vv' = r(sd)
				gen sk_`vv' = r(skewness)
				gen ku_`vv' = r(skewness)
				
				qui: _pctile   `vv' [aw = `wvar'],  percentiles(2.5 10 12.5 25 37.5 50 62.5 75 87.5 90 97.5)
				
				gen p025_`vv' = r(r1)				
				gen p10_`vv' = r(r2)
				gen p125_`vv' = r(r3)
				gen p25_`vv' = r(r4)
				gen p375_`vv' = r(r5)
				
				gen p50_`vv' = r(r6)
				
				gen p625_`vv' = r(r7)
				gen p75_`vv' = r(r8)
				gen p875_`vv' = r(r9)
				gen p90_`vv' = r(r10)
				gen p975_`vv' = r(r11)
				
				gen p9010_`vv' = p90_`vv' - p10_`vv'
				gen p7525_`vv' = p75_`vv' - p25_`vv'
				gen p9050_`vv' = p90_`vv' - p50_`vv'
				gen p5010_`vv' = p50_`vv' - p10_`vv'
				
				gen ksk_`vv' = (p90_`vv' + p10_`vv' - 2*p50_`vv')/p9010_`vv'	
				gen mku_`vv' = ((p875_`vv' - p625_`vv') + (p375_`vv' - p125_`vv' ))/(p75_`vv' - p25_`vv')
				gen cku_`vv' = (p975_`vv' - p025_`vv')/(p75_`vv' - p25_`vv')
			} // END if wheigths 
			
			*Unweigthed
			if "`ww'" == "uw" { 	
				*-- Total employment
				
				gen tot_emp = sum(emp)
				
				*-- Sales 	
				qui: sum `vv' , d	
					
				gen num_`vv' = r(N)
				gen me_`vv' = r(mean)
				gen sd_`vv' = r(sd)
				gen sk_`vv' = r(skewness)
				gen ku_`vv' = r(kurtosis)
				
				qui: _pctile   `vv',  percentiles(2.5 10 12.5 25 37.5 50 62.5 75 87.5 90 97.5)
				
				gen p025_`vv' = r(r1)				
				gen p10_`vv' = r(r2)
				gen p125_`vv' = r(r3)
				gen p25_`vv' = r(r4)
				gen p375_`vv' = r(r5)
				
				gen p50_`vv' = r(r6)
				
				gen p625_`vv' = r(r7)
				gen p75_`vv' = r(r8)
				gen p875_`vv' = r(r9)
				gen p90_`vv' = r(r10)
				gen p975_`vv' = r(r11)
				
				gen p9010_`vv' = p90_`vv' - p10_`vv'
				gen p7525_`vv' = p75_`vv' - p25_`vv'
				gen p9050_`vv' = p90_`vv' - p50_`vv'
				gen p5010_`vv' = p50_`vv' - p10_`vv'
				
				gen ksk_`vv' = (p90_`vv' + p10_`vv' - 2*p50_`vv')/p9010_`vv'	
				gen mku_`vv' = ((p875_`vv' - p625_`vv') + (p375_`vv' - p125_`vv' ))/(p75_`vv' - p25_`vv')
				gen cku_`vv' = (p975_`vv' - p025_`vv')/(p75_`vv' - p25_`vv')
				
			} // END if NO wheigths 
			***
					
			*Saving
			keep fyearq fqtr qtr tot_* num_* me_* sd_* sk_* ku_* p975_* p90_* p75_* ///
				p50_* p25_* p10_* p025_* p9010_* p7525_* p9050_* p5010_* ksk_* mku_* cku_*
			keep if _n == 1
			compress 
			save "${cdata}/out_`bb'_`vv'_`yy'_`qq'_`ww'.dta", replace 
			
			restore 
		} // END of loop over quarters
		} // END of qui statement
		} // END of loop over years
		
		} // END of loop over w and uw
		} // END of loop over variables
		
		
	*-------------------------------
	*-- PUTTING PIECES TOGETHER 
	*-------------------------------
		*-- Append 
				
		foreach vv of local variables {
		foreach ww of local wbases {
		clear 
		forvalues yy = $iyear (1) $eyear{
		di "Working on year `yy'"	
		forvalues qq = 1(1)4{
		
			append using "${cdata}/out_`bb'_`vv'_`yy'_`qq'_`ww'.dta"
			erase "${cdata}/out_`bb'_`vv'_`yy'_`qq'_`ww'.dta"
		
		} // END of loop over quarters	
		} // END of loop over years
		
			tempfile temp_`bb'_`vv'_`ww'
			tsset qtr 
			save "${cdata}/temp_`bb'_`vv'_`ww'.dta", replace
		
		} // END of loop over w and uw
		} // END of loop over variables

		
		
		*-- Merge 	
		clear 	
		foreach ww of local wbases {			
		use "${cdata}/temp_`bb'_g_saleqr_ll_`ww'.dta", clear
		foreach vv of local variables {	
			merge 1:1 qtr using "${cdata}/temp_`bb'_`vv'_`ww'.dta", nogenerate			
			erase "${cdata}/temp_`bb'_`vv'_`ww'.dta"
		} // END of loop over variables	
		compress 
		save "${cdata}/ts_`bb'_`ww'_`gg'.dta", replace 	
		
	} // END of loop over w and uw		
	} // END of loop ver the groups
	} // END of loop over the data bases

*-- Putting the variables
	clear 

	foreach bb of local bases {
	foreach gg of local subgp{
	foreach ww of local wbases{
		append using "${cdata}/ts_`bb'_`ww'_`gg'.dta"
		erase "${cdata}/ts_`bb'_`ww'_`gg'.dta"
		cap: gen base = "`bb'"
		cap: gen subgroup = "`gg'"
		cap: gen wei = "`ww'"
		cap: replace base = "`bb'" if base == ""
		cap: replace subgroup = "`gg'" if subgroup == ""
		cap: replace wei = "`ww'" if wei == ""
	}
	}
	} 

*-- Save data 
	order base wei subgroup fyear fqtr qtr
	saveold "${cdata}/SBC_TimeSeries_CSTAT_QTRLY_DEC2019.dta", replace 	

} // END OF THE QUARTERLY MOMENTS SECTION
 	 
*############################################################
*-- END OF THE CODE 
*############################################################
capture log close

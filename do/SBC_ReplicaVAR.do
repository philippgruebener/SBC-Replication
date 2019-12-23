/*
	
	This file replicates the VAR results for 
	Skewed Business Cycles by Salgado, Guvenen, and Bloom 
	First version Jun, 06, 2019
	This  version Dec, 06, 2019
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado
	ssalgado@wharton.upenn.edu
	https://sergiosalgadoi.wordpress.com/
	
	The SBC_VAR.xls contains following variables
	
	year            
	month           
	nstock         S&P500 stock market index (closing value of last trading date of the month)
	fedfunds       FRED variable FEDFUNDS
	wage           FRED variable AHETPI
	cpi            FRED variable CPIAUCSL
	hours          FRED variable AWHMAN
	empm           FRED variable PAYEMS
	ipm            FRED variable INDPRO
	p9010m         90th-to-10th percentiles spread of monthly stock returns constructed from CRSP
	kskm           Kelley Skewness of monthly stock returns constructed from CRSP
	p9010d         90th-to-10th percentiles spread of daily stock returns constructed from CRSP
	kskd           Kelley Skewness of monthly stock returns constructed from CRSP
*/

clear all
set more off
set matsize 3000
cd "../SBC-Replication/"
	// Main location

*##################################################		
*BASELINE VAR ESTIMATION
*##################################################			
	
	*Load data	
		import excel using "replicationxls/SBC_VAR.xls", ///
			cellrange(A1:M1104) clear case(lower) first
		gen mt = ym(year,month)
		format %tm mt
		keep if year >= 1964 & year <= 2014			// These are the limis of Stock Prices Data
		tsset mt 
		
		*Transform data into logs
		gen lipm=log(ipm)
		gen lcpi=log(cpi)
		gen infl=cpi-cpi[_n-1]
		gen lempm=log(empm)
		gen lnstock=log(nstock)			// This is the time series of the stock coming for long time series. 
		
		gen lhoursm=log(hours)
		gen lwage=log(wage)
		
		replace kskd = 100*kskd
		replace p9010d = 100*p9010d
		
		
		*Filtering 
		foreach var of varlist lipm fedfunds infl lempm lnstock hours  lhoursm lwage lcpi p9010d kskd  p9010m kskm{
			*Standard HP filtering
			qui hprescott `var',stub(hp) smooth(129600)
			qui gen c`var'=`var'-hp_`var'_sm_1

			*Alternative 10 smoothing
			cap qui hprescott `var',stub(hp2) smooth(1296)
			qui gen hf`var'=`var'-hp2_`var'_sm_1

			*Alternative linear detrend smoothing
			cap qui hprescott `var',stub(hp3) smooth(99999999)
			qui gen ld`var'=`var'-hp3_`var'_sm_1
		}
		
	*Define the variables for re scalling 			
	qui: sum kskd
	global sd_kskd_long = r(sd)			
	
	qui: sum p9010d
	global sd_p9010d_long = r(sd)
	
	qui: sum clnstock
	global sd_clnstock_long = r(sd)
		
	*Running teh VARs	
	var clnstock  p9010d kskd fedfunds   clwage clcpi chours clempm clipm,lags(1(1)12)
	irf create tt_p9010d_vol, nose step(36) set(out/irf_baseline) replace		// Drop nose option to get standard CIs. 

*#####################################				
*BASELINE VAR ESTIMATION
*#####################################
		use "out/irf_baseline.irf", clear
		sort irfname response impulse  step
		sum oirf if  impulse == "p9010d" & response == "p9010d" & step ==0 & irfname == "tt_p9010d_vol"
		gen voirf = 100*(2*${sd_p9010d_long}*oirf/r(mean) )			// Positive P9010d shock of ~2std
		gen sd_voirf = 100*(2*${sd_p9010d_long}*stdoirf/r(mean) )	    //
		gen up_voirf = voirf + sd_voirf
		gen lo_voirf = voirf - sd_voirf
		
		sum oirf if  impulse == "kskd" & response == "kskd" & step ==0  & irfname == "tt_p9010d_vol"
		gen koirf = 100*(-2*${sd_kskd_long}*oirf/r(mean) )
		gen sd_koirf = 100*(-2*${sd_kskd_long}*stdoirf/r(mean))
		gen up_koirf = koirf + sd_koirf
		gen lo_koirf = koirf - sd_koirf
		
		sum oirf if  impulse == "clnstock" & response == "clnstock" & step ==0  & irfname == "tt_p9010d_vol"
		gen soirf = 100*(-1*${sd_clnstock_long}*oirf/r(mean))
		gen sd_soirf = 100*(-1*(1/2)*${sd_clnstock_long}*stdoirf/r(mean))		// Impact of 1/2 sp500 shock which is ~5% as in Bloom 2009 
		gen up_soirf = soirf + sd_soirf
		gen lo_soirf = soirf - sd_soirf
		
		sum oirf if  impulse == "fedfunds" & response == "fedfunds" & step ==0  & irfname == "tt_p9010d_vol"
		gen roirf = 100*(oirf/r(mean))			// Increase of r of 1%
		
			
		tw (connected koirf up_koirf lo_koirf step if impulse == "kskd" & response == "clipm"  & irfname == "tt_p9010d_vol" & step <= 24, ///
			msymbol(S none none)  msize(medlarge) lpattern(solid dash dash) color(red gray gray)  mfcolor(red*0.25 gray gray)) ///
			(connected voirf up_voirf lo_voirf step if impulse == "p9010d" & response == "clipm"  & irfname == "tt_p9010d_vol" & step <= 24, ///
			msymbol(O none none) msize(medlarge)  lpattern(solid dash_dot dash_dot) color(blue gray gray)  mfcolor(blue*0.25 gray gray))  , xlabel(0(4)24,grid) ///						
		xtitle("Months After Shock",size(medlarge))  plotregion(lcolor(black)) ///
		ytitle("% Impact on Industrial Production", color(black) size(medlarge))  ///
		graphregion(color(white))  ///
		ylabel(, labsize(medlarge)) xlabel(, labsize(medlarge) grid) graphregion(color(white)) ///
		legend(size(medlarge) ring(0) position(11) rows(2) order( 1 "Skewness" 4 "Volatility") region(color(none) lcolor(white))) ///
			title(, size(large) color(blue))  name(ksk_df, replace)
			graph export "figs/SBC_KSK_IND_4DF_st.pdf", replace 

	
		tw (connected koirf up_koirf lo_koirf step if impulse == "kskd" & response == "clempm"  & irfname == "tt_p9010d_vol" & step <= 24, ///
			msymbol(S none none)  msize(medlarge) lpattern(solid dash dash) color(red gray gray)  mfcolor(red*0.25 gray gray)) ///
			(connected voirf up_voirf lo_voirf step if impulse == "p9010d" & response == "clempm"  & irfname == "tt_p9010d_vol" & step <= 24, ///
			msymbol(O none none) msize(medlarge)  lpattern(solid dash_dot dash_dot) color(blue gray gray)  mfcolor(blue*0.25 gray gray))  , xlabel(0(4)24,grid) ///						
		xtitle("Months After Shock",size(medlarge))  plotregion(lcolor(black)) ///
		ytitle("% Impact on Employment", color(black) size(medlarge))  ///
		graphregion(color(white))  ///
		ylabel(, labsize(medlarge)) xlabel(, labsize(medlarge) grid) graphregion(color(white)) ///
		legend(size(medlarge) ring(0) position(11) rows(2) order( 1 "Skewness" 4 "Volatility") region(color(none) lcolor(white))) ///
			title(, size(large) color(blue)) name(vol_df, replace)
			graph export "figs/SBC_KSK_EMP_4DF_st.pdf", replace 

	
*######################################################################	
*ROBUSTNESS 
*###################################################################### 	

	*Load data 
	set more off
	import excel using "replicationxls/SBC_VAR.xls", ///
			cellrange(A1:M1104) clear case(lower) first
	gen mt = ym(year,month)
	format %tm mt
	keep if year >= 1964 & year <= 2014			// These are the limis of Stock Prices Data
	tsset mt 
		
	*Tranform data
	gen lipm=log(ipm)
	gen lcpi=log(cpi)
	gen infl=cpi-cpi[_n-1]
	gen lempm=log(empm)
	gen lnstock=log(nstock)	
	
	gen lhoursm=log(hours)
	gen lwage=log(wage)
	
	replace kskd = 100*kskd
	replace p9010d = 100*p9010d	
	
	replace kskm = 100*kskm
	replace p9010m = 100*p9010m
	
	
	*Filtering 
	foreach var of varlist lipm fedfunds infl lempm lnstock hours  lhoursm lwage lcpi p9010d kskd  p9010m kskm{
		*Standard HP filtering
		qui hprescott `var',stub(hp) smooth(129600)
		qui gen c`var'=`var'-hp_`var'_sm_1

		*Alternative 10 smoothing
		cap qui hprescott `var',stub(hp2) smooth(1296)
		qui gen hf`var'=`var'-hp2_`var'_sm_1

		*Alternative linear detrend smoothing
		cap qui hprescott `var',stub(hp3) smooth(99999999)
		qui gen ld`var'=`var'-hp3_`var'_sm_1
	}
	
	*Define the variables for re scalling 				
		qui: sum kskd
		global sd_kskd_long = r(sd)			
		
		qui: sum p9010d
		global sd_p9010d_long = r(sd)		
		
		qui: sum kskm
		global sd_kskm_long = r(sd)			
		
		qui: sum p9010m
		global sd_p9010m_long = r(sd)
		

	*VARS		
	*Drop nose option to get standard errors
	var clnstock p9010d kskd fedfunds clwage clcpi chours clempm clipm ,lags(1(1)12)
	irf create baseline, step(36) set(out/irf_robust) replace nose
	
	var clnstock p9010m kskm fedfunds clwage clcpi chours clempm clipm ,lags(1(1)12)
	irf create monthly, step(36) set(out/irf_robust) replace nose
	
	var clnstock p9010d kskd fedfunds clwage clcpi chours clempm clipm if year <= 2008 ,lags(1(1)12)
	irf create noGR, step(36) set(out/irf_robust) replace nose
	
	var clnstock  kskd fedfunds   clwage clcpi chours clempm clipm,lags(1(1)12)
	irf create only_skew, step(36) set(out/irf_robust) replace nose
	
	var clnstock  p9010d fedfunds   clwage clcpi chours clempm clipm,lags(1(1)12)
	irf create only_vol, step(36) set(out/irf_robust) replace nose
	
	var kskd p9010d clnstock fedfunds clwage clcpi chours clempm clipm ,lags(1(1)12)
	irf create reverse, step(36) set(out/irf_robust) replace nose
	
	var clnstock p9010d kskd clipm ,lags(1(1)12)
	irf create qvar_ip, step(36) set(out/irf_robust) replace nose
	
	var clnstock p9010d kskd clempm ,lags(1(1)12)
	irf create qvar_em, step(36) set(out/irf_robust) replace nose

	var clnstock p9010d kskd clempm clipm,lags(1(1)12)
	irf create fvar, step(36) set(out/irf_robust) replace nose
	
	var clnstock cp9010d ckskd fedfunds clwage clcpi chours clempm clipm ,lags(1(1)12)
	irf create hpfilter, step(36) set(out/irf_robust) replace nose

*ROBUSTNESS PLOTS 
		use "out/irf_robust.irf", clear
		local rirfs = "baseline fvar qvar_em qvar_ip noGR only_skew only_vol reverse"
		
		*Transform the IRFs in meaningful units
		foreach vv of local rirfs{
			sort irfname response impulse  step
			sum oirf if  impulse == "p9010d" & response == "p9010d" & step ==0 & irfname == "`vv'"
			gen voirf_`vv' = 100*(2*${sd_p9010d_long}*oirf/r(mean) )			// Positive P9010d shock of ~2std
			gen sd_voirf_`vv' = 100*(2*${sd_p9010d_long}*stdoirf/r(mean) )	    //
			gen up_voirf_`vv' = voirf_`vv' + sd_voirf_`vv'
			gen lo_voirf_`vv' = voirf_`vv' - sd_voirf_`vv'
			
			sum oirf if  impulse == "kskd" & response == "kskd" & step ==0  & irfname == "`vv'"
			gen koirf_`vv' = 100*(-2*${sd_kskd_long}*oirf/r(mean) )
			gen sd_koirf_`vv' = 100*(-2*${sd_kskd_long}*stdoirf/r(mean))
			gen up_koirf_`vv' = koirf_`vv' + sd_koirf_`vv'
			gen lo_koirf_`vv' = koirf_`vv' - sd_koirf_`vv'
			
			sum oirf if  impulse == "fedfunds" & response == "fedfunds" & step ==0  & irfname == "`vv'"
			gen roirf_`vv' = 100*(oirf/r(mean))			// Increase of r of 1%	
			
			sum oirf if  impulse == "clnstock" & response == "clnstock" & step ==0  & irfname == "`vv'"
			gen spoirf_`vv' = 100*(oirf/r(mean))			// Increase of r of 1%
		}
		
		local vv = "idex"
		sum oirf if  impulse == "ikskd" & response == "ikskd" & step ==0  & irfname == "`vv'"
		gen koirf_`vv' = 100*(oirf)
		gen sd_koirf_`vv' = 100*(stdoirf)
		gen up_koirf_`vv' = koirf_`vv' + sd_koirf_`vv'
		gen lo_koirf_`vv' = koirf_`vv' - sd_koirf_`vv'
		
		
		sum oirf if  impulse == "ip9010d" & response == "ip9010d" & step ==0  & irfname == "`vv'"
		gen voirf_`vv' = 100*(oirf)
		gen sd_voirf_`vv' = 100*(stdoirf)
		gen up_voirf_`vv' = voirf_`vv' + sd_voirf_`vv'
		gen lo_voirf_`vv' = voirf_`vv' - sd_voirf_`vv'
		
		local vv = "monthly"
		sum oirf if  impulse == "kskm" & response == "kskm" & step ==0  & irfname == "`vv'"
		gen koirf_`vv' = 100*(-2*${sd_kskm_long}*oirf/r(mean))
		gen sd_koirf_`vv' = 100*(-2*${sd_kskm_long}*stdoirf)
		gen up_koirf_`vv' = koirf_`vv' + sd_koirf_`vv'
		gen lo_koirf_`vv' = koirf_`vv' - sd_koirf_`vv'
		
		
		sum oirf if  impulse == "p9010m" & response == "p9010m" & step ==0  & irfname == "`vv'"
		gen voirf_`vv' = 100*(2*${sd_p9010m_long}*oirf/r(mean))
		gen sd_voirf_`vv' = 100*(2*${sd_p9010m_long}*stdoirf)
		gen up_voirf_`vv' = voirf_`vv' + sd_voirf_`vv'
		gen lo_voirf_`vv' = voirf_`vv' - sd_voirf_`vv'
		
		
		local vv = "hpfilter"
		sum oirf if  impulse == "ckskd" & response == "ckskd" & step ==0  & irfname == "`vv'"
		gen koirf_`vv' = 100*(-2*${sd_kskd_long}*oirf/r(mean))
		gen sd_koirf_`vv' = 100*(-2*${sd_kskd_long}*stdoirf)
		gen up_koirf_`vv' = koirf_`vv' + sd_koirf_`vv'
		gen lo_koirf_`vv' = koirf_`vv' - sd_koirf_`vv'
		
		
		sum oirf if  impulse == "cp9010d" & response == "cp9010d" & step ==0  & irfname == "`vv'"
		gen voirf_`vv' = 100*(2*${sd_p9010d_long}*oirf/r(mean))
		gen sd_voirf_`vv' = 100*(2*${sd_p9010d_long}*stdoirf)
		gen up_voirf_`vv' = voirf_`vv' + sd_voirf_`vv'
		gen lo_voirf_`vv' = voirf_`vv' - sd_voirf_`vv'
		
		
		*FOR PAPER 
 		*Industrial Production
		tw (connected koirf_baseline  step if impulse == "kskd" & response == "clipm"  & irfname == "baseline", ///
			msymbol(s none none) msize(large) lpattern(solid dash dash) color(red gray gray) mfcolor(red*0.25 gray gray)) ///
			(connected koirf_noGR  step if impulse == "kskd" & response == "clipm"  & irfname == "noGR", ///
			msymbol(dh none none) lpattern(solid dash dash) color(blue gray gray)) ///
				(connected koirf_only_skew  step if impulse == "kskd" & response == "clipm"  & irfname == "only_skew", ///
			msymbol(x none none) lpattern(solid dash dash) color(navy gray gray)) ///
				(connected koirf_reverse  step if impulse == "kskd" & response == "clipm"  & irfname == "reverse", ///
			msymbol(th none none) lpattern(solid dash dash) color(green gray gray))  ///
				(connected koirf_qvar_ip  step if impulse == "kskd" & response == "clipm"  & irfname == "qvar_ip", ///
			msymbol(oh none none) lpattern(solid dash dash) color(magenta gray gray))  ///
				(connected koirf_fvar  step if impulse == "kskd" & response == "clipm"  & irfname == "fvar", ///
			msymbol(+ none none) lpattern(solid dash dash) color(black gray gray)) ///
			(connected koirf_monthly  step if impulse == "kskm" & response == "clipm"  & irfname == "monthly", ///
			msymbol(sh none none) lpattern(solid dash dash) color(maroon gray gray)) ///
			(connected koirf_hpfilter  step if impulse == "ckskd" & response == "clipm"  & irfname == "hpfilter", ///
			msymbol(v none none) lpattern(solid dash dash) color(purple gray gray)), xlabel(0(4)36,grid) ///						
			xtitle("Months after shock",size(large))  plotregion(lcolor(black)) ///
			ytitle("% Impact on Inudstrial Production", color(black) size(large))  ///
			graphregion(color(white))  ///
			ylabel(, labsize(large)) xlabel(, labsize(medlarge) grid) graphregion(color(white)) ///
			legend(ring(0) position(5) cols(1) ///
			order( 1  "Baseline" 2 "Pre 2008" 3 "Only Skewness" 4 "Reverse" 5 "Four Variables" 6 "Five Variables" 7 "Monthly" 8 "HP Filtered") ///
			region(lcolor(white))) name(rob_ip, replace)
			graph export "figs/SBC_KSK_IP_ROBU.pdf", replace 
		
		*Employment 
		tw (connected koirf_baseline  step if impulse == "kskd" & response == "clempm"  & irfname == "baseline", ///
			msymbol(s none none) msize(large) lpattern(solid dash dash) color(red gray gray) mfcolor(red*0.25 gray gray)) ///
			(connected koirf_noGR  step if impulse == "kskd" & response == "clempm"  & irfname == "noGR", ///
			msymbol(dh none none) lpattern(solid dash dash) color(blue gray gray)) ///
				(connected koirf_only_skew  step if impulse == "kskd" & response == "clempm"  & irfname == "only_skew", ///
			msymbol(x none none) lpattern(solid dash dash) color(navy gray gray)) ///
				(connected koirf_reverse  step if impulse == "kskd" & response == "clempm"  & irfname == "reverse", ///
			msymbol(th none none) lpattern(solid dash dash) color(green gray gray))  ///
				(connected koirf_qvar_em  step if impulse == "kskd" & response == "clempm"  & irfname == "qvar_em", ///
			msymbol(oh none none) lpattern(solid dash dash) color(magenta gray gray))  ///
				(connected koirf_fvar  step if impulse == "kskd" & response == "clempm"  & irfname == "fvar", ///
			msymbol(+ none none) lpattern(solid dash dash) color(black gray gray)) ///
			(connected koirf_monthly  step if impulse == "kskm" & response == "clempm"  & irfname == "monthly", ///
			msymbol(sh none none) lpattern(solid dash dash) color(maroon gray gray)) ///
			(connected koirf_hpfilter  step if impulse == "ckskd" & response == "clempm"  & irfname == "hpfilter", ///
			msymbol(v none none) lpattern(solid dash dash) color(purple gray gray)), xlabel(0(4)36,grid) ///						
			xtitle("Months after shock",size(large))  plotregion(lcolor(black)) ///
			ytitle("% Impact on Employment", color(black) size(large))  ///
			graphregion(color(white))  ///
			ylabel(, labsize(large)) xlabel(, labsize(medlarge) grid) graphregion(color(white)) ///
			legend(off ring(0) position(11)  rows(3) order( 1  "Baseline" 2 "No Great Recession" 3 "Only Skewness" 4 "Reverse" ///
				5 "Four Variables" 6 "Five Variables"  7 "Monthly" 8 "HP Filtered") region(lcolor(white))) ///
				name(rob_em, replace)
			graph export "figs/SBC_KSK_EM_ROBU.pdf", replace 
		
		
*##################################################		
*ROBUSTNESS: LOCAL PROJECTION METHOD
*##################################################	

	*Keep the period 		
		set more off
		import excel using "replicationxls/SBC_VAR.xls", ///
			cellrange(A1:M1104) clear case(lower) first
		gen mt = ym(year,month)
		format %tm mt
		keep if year >= 1964 & year <= 2008			// We drop periods after Great Recessions
		tsset mt 
		
	*Apply same transformations done by Nick 
		gen lipm=log(ipm)
		gen lcpi=log(cpi)
		gen infl=cpi-cpi[_n-1]
		gen lempm=log(empm)
		gen lnstock=log(nstock)			
		
		gen lhoursm=log(hours)
		gen lwage=log(wage)
		
		replace kskd = 100*kskd
		replace p9010d = 100*p9010d		
		
		replace kskm = 100*kskm
		replace p9010m = 100*p9010m

		
		qui: sum kskm
		global sd_kskd = -r(sd)				// The negative is to put the plot in the correct space (a decline in skewness)	
		
		qui: sum p9010m
		global sd_p9010d = r(sd)
		
	*Filtering 
		foreach var of varlist lipm fedfunds infl lempm lnstock hours  lhoursm lwage lcpi{
			*Standard HP filtering
			qui hprescott `var',stub(hp) smooth(129600)
			qui gen c`var'=`var'-hp_`var'_sm_1

			*Alternative 10 smoothing
			cap qui hprescott `var',stub(hp2) smooth(1296)
			qui gen hf`var'=`var'-hp2_`var'_sm_1

			*Alternative linear detrend smoothing
			cap qui hprescott `var',stub(hp3) smooth(99999999)
			qui gen ld`var'=`var'-hp3_`var'_sm_1
		}
	
	*Regressions
		foreach vv in clipm clempm{
			preserve
			forvalues ff = 0(1)$steps{
				reg F`ff'.`vv'  clnstock p9010m kskm fedfunds clwage clcpi chours  L1.`vv'
				local be`ff'_k = _b[kskm] 
				local se`ff'_k = _se[kskm] 			
				
				local be`ff'_p =  _b[p9010m] 
				local se`ff'_p =  _se[p9010m] 
			}

			clear 
			set obs 1
			gen i = 1
			forvalues ff = 0(1)$steps{
				gen bek`ff' = 100*(2*${sd_kskd}*`be`ff'_k')
				gen bek_ciu`ff' = 100*2*(${sd_kskd}*`be`ff'_k' + 1.96*`se`ff'_k')
				gen bek_cid`ff' = 100*2*(${sd_kskd}*`be`ff'_k' - 1.96*`se`ff'_k')
				
				gen bep`ff' = 100*(2*${sd_p9010d}*`be`ff'_p')
				gen bep_ciu`ff' = 100*2*(${sd_p9010d}*`be`ff'_p' + 1.96*`se`ff'_p')
				gen bep_cid`ff' = 100*2*(${sd_p9010d}*`be`ff'_p' - 1.96*`se`ff'_p')
				
				
			}
			reshape long bek bek_ciu bek_cid bep bep_ciu bep_cid, i(i) j(step)
			gen consu = "`vv'"
			
			save "out/sbc_lp_res_`vv'.dta", replace
			restore
		}
		clear 
		foreach vv in clipm clempm{
			append using "out/sbc_lp_res_`vv'.dta"
		}
		
	*Plots 
	tw (connected bek bek_ciu bek_cid step if consu == "clipm", ///
			msymbol(Dh none none) lpattern(solid dash dash) color(red gray gray)), xlabel(0(2)16,grid) ///						
		xtitle("Months After the Shock",size(medlarge))  plotregion(lcolor(black)) ///
		ytitle("% Impact on Production", color(black) size(large))  ///
		graphregion(color(white))  ///
		ylabel(-0.8(0.2)0, labsize(medlarge)) xlabel(, labsize(medlarge) grid) graphregion(color(white)) ///
		legend(off ring(0) position(2) rows(2) order( 1 "Skewness") region(lcolor(white)))
			graph export "figs/SBC_LP_IND_K.pdf", replace 

			
	tw (connected bek bek_ciu bek_cid step if consu == "clempm", ///
			msymbol(Dh none none) lpattern(solid dash dash) color(red gray gray)), xlabel(0(2)16,grid) ///						
		xtitle("Months After the Shock",size(medlarge))  plotregion(lcolor(black)) ///
		ytitle("% Impact on Employment", color(black) size(large))  ///
		graphregion(color(white))  ///
		ylabel(-0.3(0.1)0, labsize(medlarge)) xlabel(, labsize(medlarge) grid) graphregion(color(white)) ///
		legend(off ring(0) position(2) rows(2) order( 1 "Skewness") region(lcolor(white))) 
			graph export "figs/SBC_LP_EMP_K.pdf", replace 
				
*########################		
*END OF THE CODE	
*########################

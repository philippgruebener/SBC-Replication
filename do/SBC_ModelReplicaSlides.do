
*##############################################################
* THIS FILE PRODUCES THE PLOTS FOR THE VERSION OF THE PAPER 
* OF MAY 2019. THIS IS A SIMPLIFIED VERSION OF PLOTS_CHECKS10 
* TO REPRODUCE ONLY THE FIGURES IN THE PAPER. MORE DETAILS IN 
* PLOTS_CHECKS10.DO
* THIS PRODUCES THE PLOTS FOR THE SLIDES. FEW CHANGES FROM 
* VERSION 10SIMPLE
*##############################################################
set more off
clear all

	*Last edition 
	*MAY/09/2019
	*This code is a further iteration of the code 
	*in SavesSlides_Jan29 in the server. 

	*First version 
	*Check v1


global pfolder = "/Users/sergiosalgado/Dropbox/FIRM_SKEWNESS_205/Data/PlotsSep2018/ShareData/figs_slide"
cd "/Users/sergiosalgado/Dropbox/FIRM_SKEWNESS_205/Model/Model_TesAsym_v11/"
local fls = "34005 33005 31005 35005"		
local shockper = 150

foreach ver of  local fls{
	
	insheet using "BYC_TimeSeries_Simu_AGG_LOG_CH_v`ver'.txt", comma clear nonames
	destring v*, force replace
	
	if `ver' == 9901 |  `ver' == 9901 |  `ver' == 9903 |  `ver' == 12004 |  ///
		`ver' == 31001|  `ver' == 11010|  `ver' == 30006 {
		drop if _n < 500
	}
	else{
		drop if _n < 50
	}
	gen ind = _n
	
	rename v2 GDP_CH
	rename v3 CAP_CH
	rename v4 LAB_CH
	rename v5 CON_CH
	rename v17 CONe_CH
	gen CONw_CH = CON_CH - CONe_CH
	gen Y2L_CH = GDP_CH/LAB_CH
	gen TFP_CH = GDP_CH/((LAB_CH^0.5)*(CAP_CH^0.3))

	rename v6 INV_CH
	rename v8 SHOCK
	rename v14 WAG_CH
	rename v18 HAP_CH
	rename v22 HNV_CH
	rename v25 MPK_CH
	replace MPK_CH = MPK_CH - 1
	
	cap: rename v30 sdMPK_CH
	cap: replace sdMPK_CH = 100*sdMPK_CH

	*Sales Growth
	
	cap: rename v28 AVE_CH
	cap: replace AVE_CH = 100*AVE_CH
	
	cap: rename v29 p50_CH
	cap: replace p50_CH = 100*p50_CH
	
	rename v9 KSK_CH
	rename v15 KSK3_CH
	rename v16 KSK5_CH
	replace KSK_CH = 100*KSK_CH
	replace KSK3_CH = 100*KSK3_CH
	replace KSK5_CH = 100*KSK5_CH
	
	rename v12 p9010_CH
	replace p9010_CH = 100*p9010_CH
	
	rename v20 p5010_CH
	replace p5010_CH = 100*p5010_CH
	
	rename v21 p9050_CH
	replace p9050_CH = 100*p9050_CH
	
	*Labor growth 
	cap: rename v33 p9010_CH_LAB 
	cap: replace p9010_CH_LAB = 100*p9010_CH_LAB
	
	cap: rename v34 KSK_CH_LAB 
	cap: replace KSK_CH_LAB = 100*KSK_CH_LAB
	
	*Shocks
	rename v10 kskz_CH
	rename v11 avez_CH
	rename v13 p9010z_CH 
	rename v19 kskz_lev_CH
	
	rename v23 ave_L_CH
	rename v24 p50_L_CH
	replace ave_L_CH = 100*ave_L_CH
	gen ave_L_CH_dev = ave_L_CH - ave_L_CH[`shockper']
	replace p50_L_CH = 100*p50_L_CH
	
	replace kskz_CH = 100*kskz_CH
	gen kskz_CH_dev = (kskz_CH) - (kskz_CH[`shockper'])
	
	replace p9010z_CH = 100*p9010z_CH
	gen p9010z_CH_dev = (p9010z_CH) - (p9010z_CH[`shockper'])	
	
	*Hp filtering
	tsset ind

	gen lGDP_CH = log(GDP_CH)
	cap: tsfilter hp GDP_CH_cyc = lGDP_CH,  smooth(1600)  
	
	gen lCON_CH = log(CON_CH)
	cap: tsfilter hp CON_CH_cyc = lCON_CH,  smooth(1600) 
	
	gen lCONe_CH = log(CONe_CH)
	cap: tsfilter hp CONe_CH_cyc = lCONe_CH,  smooth(1600) 
	
	gen lINV_CH = log(INV_CH)
	cap: tsfilter hp INV_CH_cyc = lINV_CH,  smooth(1600) 
	
	gen lLAB_CH = log(LAB_CH)
	cap: tsfilter hp LAB_CH_cyc = lLAB_CH,  smooth(1600) 
	
	gen lHAP_CH = log(HAP_CH)
	regress lHAP_CH ind
	predict rHAP_CH if e(sample) == 1, resid 
	
	
	*IRFs
	gen GDP_CH_dev = 100*(log(GDP_CH) - log(GDP_CH[`shockper']))
	gen LAB_CH_dev = 100*(log(LAB_CH) - log(LAB_CH[`shockper']))
	gen CON_CH_dev = 100*(log(CON_CH) - log(CON_CH[`shockper']))
	gen CAP_CH_dev = 100*(log(CAP_CH) - log(CAP_CH[`shockper']))
	gen CONe_CH_dev = 100*(log(CONe_CH) - log(CONe_CH[`shockper']))
	gen CONw_CH_dev = 100*(log(CONw_CH) - log(CONw_CH[`shockper']))
	gen INV_CH_dev = 100*(log(INV_CH) - log(INV_CH[`shockper']))
	gen WAG_CH_dev = 100*(log(WAG_CH) - log(WAG_CH[`shockper']))
	*gen HAP_CH_dev = 100*(log(HAP_CH) - log(HAP_CH[`shockper']))
	gen HAP_CH_dev = 100*(rHAP_CH - rHAP_CH[`shockper'])
	gen HNV_CH_dev = ((HNV_CH) - (HNV_CH[`shockper']))
	gen Y2L_CH_dev = 100*(log(Y2L_CH) - log(Y2L_CH[`shockper']))
	gen TFP_CH_dev = 100*(log(TFP_CH) - log(TFP_CH[`shockper']))
	gen MPK_CH_dev = 100*(log(MPK_CH) - log(MPK_CH[`shockper']))
	gen sdMPK_CH_dev = 100*(log(sdMPK_CH) - log(sdMPK_CH[`shockper']))
	

	replace SHOCK = 100*SHOCK
	gen AVE_CH_dev = (AVE_CH - AVE_CH[`shockper'])
	
	gen p50_CH_dev = (p50_CH - p50_CH[`shockper'])
	
	gen KSK_CH_dev = (KSK_CH - KSK_CH[`shockper'])
	gen KSK3_CH_dev = (KSK3_CH - KSK3_CH[`shockper'])
	gen KSK5_CH_dev = (KSK5_CH - KSK5_CH[`shockper'])

	sum p9010_CH
	gen p9010_CH_dev = (p9010_CH -p9010_CH[`shockper'])
	
	gen p9050_CH_dev = (p9050_CH -p9050_CH[`shockper'])
	
	gen p5010_CH_dev = (p5010_CH -p5010_CH[`shockper'])
	
	cap: gen p9010_CH_LAB_dev = p9010_CH_LAB - p9010_CH_LAB[`shockper']
	cap: gen KSK_CH_LAB_dev = KSK_CH_LAB - KSK_CH_LAB[`shockper']

	sort ind 
	
	*Growth Rates of the Aggregates 
	tsset ind
	gen g1_GDP = (log(GDP_CH) - log(L1.GDP_CH))
	gen g4_GDP = (log(GDP_CH) - log(L4.GDP_CH))
	
	gen g1_CON = log(CON_CH) - log(L1.CON_CH)
	gen g4_CON = log(CON_CH) - log(L4.CON_CH)
	
	gen g1_LAB = log(LAB_CH) - log(L1.LAB_CH)
	gen g4_LAB = log(LAB_CH) - log(L4.LAB_CH)
	
	keep ind *_CH* SHOCK lGDP_CH ksk* p50* g1_* g4_*
	gen ind0 = ind - `shockper'
	
	*Saving 
	gen ver = `ver'
	save "BOS_`ver'.dta", replace 
	
}	// END of ver 
**	

clear 
set more off
local fls = "30005 31005 32005 33005 34005 35005 30006 9801"			// These are the results in the EZ

foreach ver of  local fls{
	append using "BOS_`ver'.dta"
}

save "BOS_ALL.dta", replace

sum *_cyc if ver == 30006
gen eqprem = MPK_CH - 0.005 

gen eqprem_annual = ((MPK_CH+1)^4 - 1) - ((1+0.005)^4 - 1) 

sum eqprem eqprem_annual if ver == 30006
corr  *_cyc if ver == 30006
*STOP
*#####################	
*EZ Results 	
*######################
			
*Model Figure 1 and 2 of Slides
	*Average
	tw (connected  p50_L_CH ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  p50_L_CH ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  p50_L_CH ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18, grid labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("", size(large))  ///
	ytitle("", size(large)) ///
	graphregion(color(white))  ///
	title("Average", color(black)  size(vlarge))  plotregion(lcolor(black))  ///
	legend(symxsize(7.0) size(medium) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Dispersion Only")  region(lcolor(white))    ///
	col(1) position(5) ring(0)) graphregion(color(white))  ylabel(-3(1)1, labsize(large))  name(zp50, replace)
	*graph export ${pfolder}/MODEL_FIG1a.pdf, replace 
	
	tw (connected  AVE_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005,  lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  AVE_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  AVE_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18, grid labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("", size(large))  ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Average", color(black)  size(vlarge))  plotregion(lcolor(black))  ///
	legend(symxsize(7.0) size(medium) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Dispersion Only")  region(lcolor(white))    ///
	col(1) position(5) ring(0)) graphregion(color(white)) ylabel(-3(1)1, labsize(large))  name(p50, replace)
	*graph export ${pfolder}/MODEL_FIG1b.pdf, replace 

	*Dispersion
	tw (connected  p9010z_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005,  lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  p9010z_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  p9010z_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("", size(large))  ///
	ytitle("", size(large)) ///
	graphregion(color(white))  ///
	title("P90-P10", color(black)  size(vlarge)) plotregion(lcolor(black))   ///
	legend(off symxsize(5.0) size(medium) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Dispersion Only")  region(lcolor(white))    ///
	col(1) position(1) ring(0)) graphregion(color(white)) ylabel(,labsize(large)) name(zp9010, replace) 
	*graph export ${pfolder}/MODEL_FIG1c.pdf, replace 
		
	tw (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("", size(large))  ///
	ytitle("",  size(medlarge)) ///
	graphregion(color(white))  ///
	title("P90-P10", color(black)  size(vlarge))  plotregion(lcolor(black))  ///
	legend( off size(medlarge) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Dispersion Only")  region(lcolor(white))   ///
	col(1) position(1) ring(0)) graphregion(color(white)) ylabel(0(5)15,labsize(large)) name(p9010, replace) 
	*graph export ${pfolder}/MODEL_FIG1d.pdf, replace 


	*Skewness 	
	tw (connected  kskz_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005,  lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  kskz_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  kskz_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("", size(large))  ///
	ytitle("", size(large)) ///
	graphregion(color(white))  ///
	title("Kelley Skewness", color(black)  size(vlarge)) plotregion(lcolor(black))   ///
	legend( off symxsize(5.0) size(medium) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Dispersion Only")  region(lcolor(white))    ///
	col(1) position(5) ring(0)) graphregion(color(white)) ylabel(-20(10)0,labsize(large))  name(zksk, replace) 
	*graph export ${pfolder}/MODEL_FIG1e.pdf, replace 

	
	tw (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005,  lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("", size(large))  ///
	ytitle("",  size(medlarge)) ///
	graphregion(color(white))  ///
	title("Kelley Skewness", color(black)  size(vlarge))  plotregion(lcolor(black))  ///
	legend( off size(medlarge) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Dispersion Only")  region(lcolor(white))   ///
	col(1) position(5) ring(0)) graphregion(color(white)) ylabel(-30(10)10,labsize(large))  name(ksk, replace) 
	*graph export ${pfolder}/MODEL_FIG1f.pdf, replace 


	***
	*This plots combines the previos plots
	graph combine zp50 zp9010 zksk, graphregion(color(white)) ///
	l2title("Deviation from Value in Quarter 0 (%)", size(medlarge)) ///
		b1title("Quarters (risk shock in quarter 1)", size(medlarge))  ///
		ysize(3)
	graph export ${pfolder}/MODEL_FIG1.pdf, replace 
	
	*This plots combines the previos plots
	graph combine p50 p9010 ksk, graphregion(color(white)) ///
	l2title("Deviation from Value in Quarter 0 (%)", size(medlarge)) ///
		b1title("Quarters (risk shock in quarter 1)", size(medlarge))  ///
		ysize(3)
	graph export ${pfolder}/MODEL_FIG2.pdf, replace 
	


*-- Appendix Model Figure 3A and 3B of Slides
	tw (connected  p9050_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  p9050_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  p9050_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(2)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("Quarters (risk shock in quarter 1)", size(large)) ///
	ytitle("Deviation from Value in Quarter 0",  size(large)) ///
	graphregion(color(white)) ylabel(,labsize(large))  ///
	title("P90-P50", color(black)  size(huge))    ///
	legend( symxsize(7.0) size(medlarge) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	col(1) position(1) ring(0)) plotregion(lcolor(black)) graphregion(color(white))  
	graph export ${pfolder}/MODEL_FIG3A.pdf, replace
		
	tw (connected  p5010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  p5010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  p5010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(2)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("Quarters (risk shock in quarter 1)", size(large)) ///
	ytitle("",  size(medlarge)) ///
	graphregion(color(white)) ylabel(,labsize(large)) ///
	title("P50-P10", color(black)  size(huge))    ///
	legend( off size(medlarge) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	col(1) position(1) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) 
	graph export ${pfolder}/MODEL_FIG3B.pdf, replace
	
*Model Figure 4
	tw (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, ///
	lcolor(black) mcolor(black) msize(large) msymbol(O) mfcolor(black*0.25) lwidth(medthick) ), ///
	xlabel(-2(2)18,grid labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("Quarters (risk shock in quarter 1)", size(large)) ///
	ytitle("Log Deviation from Value in Quarter 0 (%)", size(medlarge)) ///
	graphregion(color(white))  ///
	legend(order(1 "Variance and Skewness"  2 "Skewness Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-2.0(0.5)0.5, labsize(medlarge))
	graph export ${pfolder}/MODEL_FIG4.pdf, replace 
	
	
*Model Figure 5	
	tw (connected  LAB_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, ///
	lcolor(black) mcolor(black) msize(large) msymbol(O) mfcolor(black*0.25) lwidth(medthick) ), ///
	xlabel(-2(2)18,grid labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Hours", color(black)  size(vlarge))   ///
	legend(order(1 "Var+Skew"  2 "Skew")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-2.0(0.5)0.5, labsize(medlarge)) name(lab,replace)
	
	tw (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, ///
	lcolor(black) mcolor(black) msize(large) msymbol(O) mfcolor(black*0.25) lwidth(medthick) ), ///
	xlabel(-2(2)18,grid labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Consumption", color(black)  size(vlarge))   ///
	legend(order(1 "Var+Skew"  2 "Skew")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-2.0(0.5)0.5, labsize(medlarge))  name(con,replace)
	 
	tw (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, ///
	lcolor(black) mcolor(black) msize(large) msymbol(O) mfcolor(black*0.25) lwidth(medthick) ), ///
	xlabel(-2(2)18,grid labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Capital Investment", color(black)  size(vlarge))   ///
	legend(order(1 "Var+Skew"  2 "Skew")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-20(5)5, labsize(medlarge))  name(inv,replace)
	
	tw (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, ///
	lcolor(black) mcolor(black) msize(large) msymbol(O) mfcolor(black*0.25) lwidth(medthick) ), ///
	xlabel(-2(2)18,grid labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Risk Free Asset", color(black)  size(vlarge))   ///
	legend(order(1 "Var+Skew"  2 "Skew")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))  name(hap,replace)
	
	graph combine lab inv con hap, graphregion(color(white)) l1title("Log Deviation from Value in Quarter 0 (%)") ///
		b1title("Quarters (risk shock in quarter 1)") ysize(3)
	graph export ${pfolder}/MODEL_FIG5.pdf, replace 

*Model Figure 6
	tw  ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-3(1)2,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Output", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) ///
	order(1 "Skewness Only" 2 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge)) name(gdp, replace)
	
	
	tw  ///
	   (connected  LAB_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  LAB_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-3(1)2,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Hours", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))  name(lab, replace)
	
	
	tw  ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-3(1)2,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Consumption", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))   name(con, replace)
	
	
	tw   ///
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-40(10)10,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Capital Investment", color(black)  size(vlarge) )   ///
	legend(size(medium) symxsize(7.0)  ///
	order(1 "Skewness Only" 2 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))  name(inv, replace)
	

	tw ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Risk Free Asset", color(black)  size(vlarge))   ///
	legend( off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge)) name(hap, replace)
	
	graph combine gdp inv con hap, graphregion(color(white)) l1title("Log Deviation from Value in Quarter 0 (%)") ///
		b1title("Quarters (risk shock in quarter 1)") ysize(3)
	graph export ${pfolder}/MODEL_FIG6.pdf, replace 


*Model Figure 7
	tw (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-3(1)2,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Output", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge)) name(gdp, replace)
	
	
	tw (connected  LAB_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  LAB_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  LAB_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-3(1)2,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Labor", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))  name(lab, replace)
	
	
	tw (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-3(1)2,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Consumption", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))   name(con, replace)
	
	
	tw (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(-40(10)10,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Capital Investment", color(black)  size(vlarge) )   ///
	legend(size(medium) symxsize(7.0)  ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge))  name(inv, replace)
	
	
	tw (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)), ///
	xlabel(-2(4)18,grid  labsize(medlarge)) ///
	ylabel(,grid  labsize(medlarge)) ///
	xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Risk Free Asset", color(black)  size(vlarge))   ///
	legend( off size(medlarge) ///
	order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge)) name(hap, replace)
	
	graph combine gdp inv con hap, graphregion(color(white)) l1title("Log Deviation from Value in Quarter 0 (%)") ///
		b1title("Quarters (risk shock in quarter 1)") ysize(3)
	graph export ${pfolder}/MODEL_FIG7.pdf, replace 

	
		
*Model Figure 8: Robustness
	tw (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 34005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick)) ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 33005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick))  ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)) ///
	   (connected  GDP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 35005, lcolor(green) mcolor(green) msize(medlarge) msymbol(S) mfcolor(green*0.25) lwidth(medthick)) ///
	,xlabel(-2(2)18,grid  labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Output", color(black)  size(vlarge) )   ///
	legend(off size(medlarge) order(1 "Baseline"  2 "News Shock" 3 "Low Risk Aversion" 4 "High EIS")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-2.0(0.5)0.5, labsize(medlarge)) name(gdp,replace)
	*graph export ${pfolder}/GDP_NEWS_CALI15_DFT_EZ.pdf, replace 
	
	tw (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 34005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick)) ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 33005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick))   ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)) ///
	   (connected  CON_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 35005, lcolor(green) mcolor(green) msize(medlarge) msymbol(S) mfcolor(green*0.25) lwidth(medthick)) ///
	,xlabel(-2(2)18,grid  labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Consumption", color(black)  size(vlarge) )   ///
	legend(off size(small) order(1 "Baseline"  2 "News Shock" 3 "Low RA" 4 "High EIS")  region(lcolor(white))   ///
	rows(2) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-2.0(0.5)0.5, labsize(medlarge)) name(con,replace)
	*graph export ${pfolder}/CON_NEWS_CALI15_DFT_EZ.pdf, replace 
	
	tw (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 34005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick)) ///
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 33005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick))   ///	   
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)) ///
	   (connected  INV_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 35005, lcolor(green) mcolor(green) msize(medlarge) msymbol(S) mfcolor(green*0.25) lwidth(medthick)) ///
	,xlabel(-2(2)18,grid  labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Capital Investment", color(black)  size(vlarge) )   ///
	legend(size(small) symxsize(5.0) order(1 "Baseline"  2 "News Shock" 3 "Low RA" 4 "High EIS")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-30(10)10, labsize(medlarge)) name(inv,replace)
	*graph export ${pfolder}/INV_NEWS_CALI15_DFT_EZ.pdf, replace 
	
	
	tw (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 34005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick)) ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 33005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)) ///
	   (connected  HAP_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 35005, lcolor(green) mcolor(green) msize(medlarge) msymbol(S) mfcolor(green*0.25) lwidth(medthick)) ///	   
	,xlabel(-2(2)18,grid  labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) xtitle("", size(medlarge)) ///
	ytitle("", size(medlarge)) ///
	graphregion(color(white))  ///
	title("Risk Free Asset", color(black)  size(vlarge))   ///
	legend(off size(medlarge) order(1 "Baseline"  2 "News Shock" 3 "Low Risk Aversion" 4 "High EIS")  region(lcolor(white))   ///
	rows(7) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(, labsize(medlarge)) name(hap,replace)
	
	graph combine gdp inv con hap, graphregion(color(white)) l1title("Log Deviation from Value in Quarter 0 (%)") ///
		b1title("Quarters (risk shock in quarter 1)") ysize(3)
	graph export ${pfolder}/MODEL_FIG8.pdf, replace 
	
	
*Model Figure 9: Robustness
	tw (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)) ///
	   (connected  p9010_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 9801,  lcolor(green) mcolor(green) msize(medlarge) msymbol(S) mfcolor(green*0.25) lwidth(medthick)), ///
	xlabel(-2(2)18, grid  labsize(medlarge)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("Quarters (risk shock in quarter 1)", size(large)) ///
	ytitle("Deviation from Value in Quarter 0",  size(large)) ///
	graphregion(color(white))  ///
	title("P90-P10", color(black)  size(huge))    ///
	legend( symxsize(7.0) size(medlarge) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only" 4 "Mean Only")  region(lcolor(white))   ///
	col(1) position(1) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) 
	graph export ${pfolder}/MODEL_FIG9A.pdf, replace 

	tw (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 30005, lcolor(blue) mcolor(blue) msize(medlarge) msymbol(O) mfcolor(blue*0.25) lwidth(medthick))  ///
	   (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 31005, lcolor(black) mcolor(black) msize(medlarge) msymbol(D) mfcolor(black*0.25) lwidth(medthick)) ///
	   (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 32005, lcolor(red) mcolor(red) msize(medlarge) msymbol(T) mfcolor(red*0.25) lwidth(medthick)) ///
	   (connected  KSK_CH_dev ind0 if ind0 >= -2 & ind0 <= 18 & ver == 9801,  lcolor(green) mcolor(green) msize(medlarge) msymbol(S) mfcolor(green*0.25) lwidth(medthick)), ///
		xlabel(-2(2)18, grid  labsize(large)) xline(0, lp(longdash) lcolor(black)) ///
	xtitle("Quarters (risk shock in quarter 1)", size(large)) ///
	ytitle("",  size(medlarge)) ///
		graphregion(color(white))  ///
		title("Kelley Skewness", color(black)  size(vlarge))    ///
		legend( off size(medlarge) order(1 "Variance and Skewness"  2 "Skewness Only" 3 "Variance Only" 4 "Mean Only")  region(lcolor(white))   ///
		col(1) position(5) ring(0)) plotregion(lcolor(black)) graphregion(color(white)) ylabel(-25(5)5,labsize(large))
		graph export ${pfolder}/MODEL_FIG9B.pdf, replace
 		


*END OF THE CODE	

/*
	This do-files is called by SBC_Clean_BvDAmadeus.do 
	First version April, 12, 2019
	This  version May, 16, 2019	
	
	In case of any suggestions/questions, please contact 
	Sergio Salgado I.
	ssalgado@wharton.upenn.edu
	https://sergiosalgadoi.wordpress.com/
*/

capture program drop sumdetail tailpar

*This program calculate the tail parameter for three thresholds 

program tailpar
	
	local vari = "`1'"
	local wei = "`2'"
	if "`wei'" != ""{
		local wei = "[aw=`wei']"
	}
	local cate = "`3'"
	local cvate = `4'
	local kpoint = `5'
	local ofolder = "`6'"


	preserve 
	keep if `vari' != . & `cate' == `cvate'


	kdensity `vari' `wei', generate(var_x var_d) n(`kpoint') nograph
	gen lvar_d = log(var_d)
	
	*Percentiles 
	_pctile `vari' `wei', p(95 98 99) 
	local t1 = r(r1)
	local t2 = r(r2)
	local t3 = r(r3)
	
	*Slope regressision
	reg lvar_d var_x if var_x >= `t1' & var_x != . 
	local bet95 = _b[var_x]
	
	reg lvar_d var_x if var_x >= `t2' & var_x != . 
	local bet98 = _b[var_x]
	
	reg lvar_d var_x if var_x >= `t3' & var_x != . 
	local bet99 = _b[var_x]
	
	clear 
	set obs 1
	gen `cate' = `cvate' 
	gen bet95 = `bet95'
	gen bet98 = `bet98'
	gen bet99 = `bet99'
	
	save "`ofolder'/slope_`vari'_`cate'_`cvate'.dta", replace
	
	
	restore  


end 


*This program calculates some summary stats within at most two categories 					
program sumdetail

	local vari = "`1'"
	local wei = "`2'"
	if "`wei'" != ""{
		local wei = "[aw=`wei']"
	}
	
	*First cat
	local cate1 = "`3'"
	local cvate1 = `4'
	
	*Second cat
	local cate2 = "`5'"
	if "`cate2'" != ""{
		local cvate2 = `6'
		local addcat = "& `cate2' == `cvate2'"
	}
	
	local ofolder = "`7'"
	
	preserve 
	
	keep if `vari' != . & `cate1' == `cvate1' `addcat'
	
	sum `vari' `wei',d
	
	clear 
	set obs 1
	
	gen `cate1' = `cvate1' 
	if "`cate2'" != ""{
		gen `cate2' = `cvate2' 
	}
	gen no = r(N)
	gen me = r(mean)
	gen sd = r(sd)
	gen sk = r(skewness)
	gen ku = r(kurtosis)
	gen p1 = r(p1)
	gen p5 = r(p5)
	gen p10 = r(p10)
	gen p25 = r(p25)
	gen p50 = r(p50)
	gen p75 = r(p75)
	gen p90 = r(p90)
	gen p95 = r(p95)
	gen p99 = r(p99)
	
	gen ksk = (p90 + p10 - 2*p50)/(p90-p10)
	gen p9010 = p90 - p10
	
	if "`cate2'" != ""{
		save "`ofolder'/sumstat_`vari'_`cate1'_`cvate1'_`cate2'_`cvate2'.dta", replace
	}
	else{
		save "`ofolder'/sumstat_`vari'_`cate1'_`cvate1'.dta", replace
	}
	restore 
	
end

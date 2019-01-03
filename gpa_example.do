// This comes from Example 1a in the ERM Manual

clear
set more off
version 15.1
capture log close
log using gpa_example, replace

set seed 15
global Width16x9 = 1920*2
global Height16x9 = 1080*2



use gpa.dta, clear

describe

summarize

tab graduate

tab program

#delimit ;
graph pie, over(program) sort 
		   plabel(_all percent, color(white) size(huge)) 
		   title(Study Skills Program Participation) 
		   legend(order(2 1))
;
#delimit cr
graph export pie_program.png, as(png) width($Width4x3) height($Height4x3) replace


tab program graduate, row

#delimit ;
graph hbar (mean) graduate, 
	  over(program, label(labsize(large))) 
	  blabel(bar, size(large) format(%9.2f)) 
	  ytitle("Percent Graduating") ylabel(0(0.2)1) 
	  title("Percentage of Students Graduating") 
	  subtitle("by Program Participation")
;
#delimit cr
graph export bar_graduate_program.png, as(png) width($Width16x9) height($Height16x9) replace


histogram gpa, normal
graph export histo_gpa.png, as(png) width($Width16x9) height($Height16x9) replace

histogram hsgpa, normal
graph export histo_hsgpa.png, as(png) width($Width16x9) height($Height16x9) replace


correlate gpa hsgpa income

graph matrix gpa hsgpa income
graph export scaterplot_matrix.png, as(png) width($Width16x9) height($Height16x9) replace


tabstat gpa, statistics( count mean sd min max ) by(program)

graph hbox gpa, over(program) title(College GPA by Program Participation) aspectratio(0.2)
graph export box_gpa_program.png, as(png) width($Width16x9) height($Height16x9) replace

tabstat hsgpa, statistics( count mean sd min max ) by(program)

graph hbox hsgpa, over(program) title(High School GPA by Program Participation) aspectratio(0.2)
graph export box_hsgpa_program.png, as(png) width($Width16x9) height($Height16x9) replace


tabstat hsgpa, statistics( count mean sd min max ) by(graduate)

graph hbox hsgpa, over(graduate) title(High School GPA by Graduation Status) aspectratio(0.2)
graph export box_hsgpa_graduate.png, as(png) width($Width16x9) height($Height16x9) replace




// UNIVARIATE MODEL
regress gpa i.program
estimates store univar

// hsgpa MODEL
regress gpa i.program hsgpa 
estimates store hsgpa
estimates table univar hsgpa, stats(N) equations(1) keep(#1:) b(%9.4f)

// ENDOGENOUS COVARIATE
eregress gpa income,                            ///
             endogenous(hsgpa = hs_comp income) nolog
estimates store endog
estimates table univar hsgpa endog, stats(N) equations(1) keep(#1:)  b(%9.4f)

// ENDOGENOUS COVARIATE AND ENDOGENOUS TREATMENT
eregress gpa income,                                           ///
             endogenous(hsgpa = hs_comp income)                ///
			 entreat(program = income scholarship, nointeract)  nolog 
estimates store entreat
estimates table univar hsgpa endog entreat, stats(N) equations(1) keep(#1:) b(%9.4f)


// ENDOGENOUS COVARIATE AND ENDOGENOUS TREATMENT WITH SELECTION
eregress gpa income,                                           ///
             endogenous(hsgpa = hs_comp income)                ///
			 entreat(program = income scholarship, nointeract) ///
			 select(graduate = income roommate)  nolog
estimates store endsel

estimates table univar hsgpa endog entreat endsel, stats(N) equations(1) keep(#1:) b(%9.4f)

// TRUE MODEL
// gpa   = -0.6 + 0.8*x2 + 0.9*hsgpa + 0.3*treatment

estat teffects
estat teffects, atet

/* OLD EXAMPLE
generate programT = program
margins r(0 1).program if program,        ///
        predict(base(program=programT))   ///
        contrast(effects nowald)

marginsplot, horizontal aspectratio(0.2)
*/
margins i.program, at(hsgpa=(1.5(0.5)4)) predict(fix(hsgpa program)) vsquish
marginsplot
graph export marginsplot.png, as(png) width($Width16x9) height($Height16x9) replace


// ENDOGENOUS COVARIATE AND ENDOGENOUS TREATMENT WITH SELECTION
// WITH ROBUST SEs
eregress gpa income,                                           ///
             endogenous(hsgpa = hs_comp income)                ///
			 entreat(program = income scholarship, nointeract) ///
			 select(graduate = income roommate)                ///
			 vce(robust)  nolog

estat teffects
estat teffects, atet			 


log close


translate "gpa_example.smcl" "gpa_example.log", replace linesize(120) translator(smcl2log)



//sembuilder ./images/syntax6.stsem                     
//graph export ./images/syntax6.png, as(png) replace width($Width16x9) height($Height16x9)


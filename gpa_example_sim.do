

clear
version 15.1
capture cd "$GoogleDriveWork"
capture cd "$GoogleDriveLaptop"
capture cd ".\Talks\2018\Webinar_ERMs\examples\"
set seed 12321
set obs 1000

// ADD CORRELATED ERRORS
//local rho = 0.7
//matrix C = J(4,4,`rho') + (1-`rho')*I(4) 
//matlist C	
matrix C = ( 1.0, 0.8, 0.5, 0.5 \     ///
             0.8, 1.0, 0.5, 0.7 \     ///    
             0.5, 0.5, 1.0, 0.8 \     ///
  		     0.5, 0.7, 0.8, 1.0)
matrix S = (0.2,0.2,1,1)
drawnorm e_y1 e_y2 e_y3 e_y4, sd(S) corr(C)

// ADD EXOGENOUS DATA
gen x1 = runiform()
gen x2 = runiform()
gen x3 = rnormal()>0.5
gen x4 = rnormal()>0.5


// ADD ENGOGENOUS TREATMENT
gen treatment = (1 - 5*x2 + 1.5*x3 + e_y3) > 0

// ADD ENDOGENOUS COVARIATES
gen hsgpa = 1 + 1.5*x1 + 1.1*x2                    + e_y1
//gen gpa   = 1 + 0.2*x2 + 0.3*hsgpa + 1.2*treatment + e_y2
gen gpa   = -0.6 + 0.8*x2 + 0.9*hsgpa + 0.3*treatment + e_y2

// ADD ENDOGENOUS SELECTION
gen graduate = (-1 + 1.5*x4 + 4*x2 + e_y4) > 0
gen gpa2 = gpa if graduate

eregress gpa2 x2,                                 ///
              endogenous(hsgpa = x1 x2)           ///
			  entreat(treatment = x2 x3, nointeract) ///
			  select(graduate = x2 x4)   
			  
summ hsgpa gpa gpa2

drop e_y1 e_y2 e_y3 e_y4

rename x1 hs_comp
label var hs_comp "High School Competitiveness"

rename x2 income
label var income "Parent's Income (x $100,000)"

rename x3 scholarship
label var scholarship "Student received scholarship funds?"
label define YesNo 0 "No" 1 "Yes"
label values scholarship YesNo

rename x4 roommate
label var roommate "Students's roommate is also a student?"
label values roommate YesNo

rename treatment program
label var program "Student participated in the study skills program?"
label values program YesNo

label var hsgpa "High School Grade Point Average"

drop gpa
rename gpa2 gpa
label var gpa "Final College Grade Point Average"

label var graduate "Did the student graduate college?"
label values graduate YesNo

gen id = _n
label var id "Student Identification Number"

order id gpa hsgpa program graduate income hs_comp roommate scholarship

compress
sort id

label data "Simulated GPA Dataset for ERMs seminars"

notes _dta : These data were simulated by Chuck Huber for ERMs examples
notes _dta : The data were simulated using these equations:
notes _dta : hsgpa = 1 + 1.5*hs_comp + 1.1*income + e1
notes _dta : gpa = 1 + 0.2*income + 0.3*hsgpa + 1.2*program + e2
notes _dta : treatment = (1 - 5*income + 1.5*scholarship + e3) > 0
notes _dta : graduate = (-1 + 1.5*roommate + 4*income + e4) > 0

save gpa.dta, replace

// FIT THE NAIVE MODEL
regress gpa program hsgpa income

// FIT THE ERM MODEL
eregress gpa income,                                           ///
             endogenous(hsgpa = hs_comp income)                ///
			 entreat(program = income scholarship, nointeract) ///
			 select(graduate = income roommate) 



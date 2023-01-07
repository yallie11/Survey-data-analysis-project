/*
Assignment 1: Analysing South Africa’s Free Basic Electricity Grant Policy 

Due Date	: 2 September 2022
Author  	: Yaseen Alli
Student No	: AllMOH024
Course Code	: ECO4027S
Data Source	: General Household Survey for 2018 

University	: UCT Economics Department
*/


clear all
set more off
capture log close
log using "C:\Users\user\Desktop\assignment1.log", replace
use "C:\Users\user\Downloads\zaf-statssa-ghs-2018-v1.0-stata11\Stata 11\household.dta", clear
numlabel, add

*------------------------------------------------------------------------------*
* i. Preliminary
*------------------------------------------------------------------------------*

*** Describe the data
describe
lookfor "electricity"
lookfor "weight"
lookfor "Stratum"
lookfor "household"


*** Set the Complex Survey Design
svyset PSU [pweight=house_wgt], strata(Stratum) vce(linearized) singleunit(missing)
svydescribe house_wgt
*------------------------------------------------------------------------------*


*------------------------------------------------------------------------------*
*  Question 2
*------------------------------------------------------------------------------*

lookfor FBE

cap drop house_fbe
clonevar house_fbe= Q528cFBE 
codebook house_fbe, tab(100)

/*
             tabulation:  Freq.   Numeric  Label
                         4,054         1  1. Yes
                        12,836         2  2. No
                           418         3  3. Do not know
                         2,888         8  8. Not Applicable
                           712         9  9. Unspecified

2 888 registered as NOT applicable
*/

svy: tab house_fbe , se
/* 15.39% registered as NOT APPLICABLE 
   17.92% registered as Recipients of FBE
   60.58% registered as Non-receipients of FBE
*/

*** create dummy
gen hfbe=0
replace hfbe=1 if Q528cFBE==1
svy: tab hfbe , se

*number of households recieving FBE*

di 0.1792*16670854

*** Totals
svy: tabulate hfbe, count format(%17.0f)
/*2987126 is the total number of households receiving FBE in 2018 */

*------------------------------------------------------------------------------*
*Question 3
*------------------------------------------------------------------------------*

lookfor income
codebook totmhinc 

*** A- Two Old pensioners cap
cap drop ispoor
gen ispoor=0
replace ispoor=1 if totmhinc<=3500
replace ispoor=. if totmhinc==9999999
svy: tab ispoor , se
tab ispoor,m 
di .3751126*15206538

label define ispoor 0 "No" 1 "Yes", replace
label values ispoor ispoor

*** Totals
svy: tabulate ispoor, count format(%17.0f)
/*5 704 165 is the total number of poor households in South Africa in 2018 */

*** B- Four Old Pensioners Cap
cap drop hinc2
gen hinc2=0
replace hinc2=1 if totmhinc<=7000
replace hinc2=. if totmhinc==9999999
svy: tab hinc2 , se
tab hinc2,m 
di 0.5590 *15206538

*** Totals
svy: tabulate hinc2, count format(%17.0f)
/*5 704 165 is the total number of poor households in South Africa in 2018 */
*------------------------------------------------------------------------------*
*Question 4
*------------------------------------------------------------------------------*


cap drop hhincome
clonevar hhincome= totmhinc
gen dum_missinc=0
replace dum_missinc=1 if hhincome==9999999
*replace totmhinc=. if totmhinc==9999999.
*codebook totmhinc 

svy: tab dum_missinc, se
svy: proportion dum_missinc
*8.78% of households in the sample that have missing income in 2018*

replace hhincome=. if hhincome==9999999


* Check the independent variables)
lookfor sex
***Head Sex
codebook head_sex
recode head_sex (2=1) (1=0), gen(female)
tab female head_sex

*** Head Age
lookfor age
codebook head_age 
clonevar age=head_age

*** Head Population group
lookfor "Pop"
codebook head_popgrp 
recode head_popgrp (1= 0 "African") (2=1 "Coloured") ///
(3= 2 "Indian") (4= 3 "White"), gen(race)
tab head_popgrp  race

*** Province
lookfor prov
codebook prov  
recode prov (1= 0 "WC") (2=1 "EC") (3= 2 "NC") (4=3 "FS") (5=4 "KZN") ///
(6=5 "NW") (7=6 "GP") (8=7 "MP") (9=8 "LMP"), gen(province)
tab prov province

*** Household Size
lookfor size
codebook hholdsz 
clonevar hh_size=hholdsz 

*** regression imputation
gen loghhi=log(hhincome)
reg loghhi i.province i.race i.female age hh_size
predict loghhi_predicted 
gen hhincome_predicted=exp(loghhi_predicted)

*** Impute the predicted for missing
gen real_monthly_incomeimp=hhincome if hhincome!=.
replace real_monthly_incomeimp=hhincome_predicted if real_monthly_incomeimp==.
label var real_monthly_incomeimp "imputed household income"


*using new variable, what proportion of households are poor using the R3500 a month definition*
gen ispoor_imp=0
replace ispoor_imp=1 if real_monthly_incomeimp<=3500

*** Totals (Without imputation)
svy: tabulate ispoor, count format(%17.0f)
/* 5 704 165 households identified as poor in 2018*/


*** Totals (With imputation)
svy: tabulate ispoor_imp, count format(%17.0f)
/*6 056 106 households now identified as poor in 2018*/

*** Proportions (without imputations)
svy: proportion ispoor
/*37.51% of households identified as poor in 2018*/

*** Proportions (with imputations)
svy: tab ispoor_imp, se
svy: proportion ispoor_imp
/*36.33% of households now identified as poor in 2018*/

*** Contrast confidence intervals

*** Totals
svy: tabulate ispoor_imp, count ci format(%17.0f)
/*
REMARK: Since the lower bound of total is 5 914 583. At the 5% significance level 
the Totals are statistically different
*/
*** Proportions
svy: tabulate ispoor_imp, ci

/*
----------------------------------------------
ispoor_im |
p         | proportion          lb          ub
----------+-----------------------------------
        0 |      .6367       .6293       .6441
        1 |      .3633       .3559       .3707
          | 
    Total |          1                        
----------------------------------------------
  Key:  proportion  =  cell proportion
        lb          =  lower 95% confidence bound for cell proportion
        ub          =  upper 95% confidence bound for cell proportion
		
REMARK: Since the upper bound is 37.07%. At the 5% significance level 
the proportions are statistically different
*/

*------------------------------------------------------------------------------*
*Question 5
*------------------------------------------------------------------------------*
*** Use scaled single unit for computing standard errors
svyset PSU [pweight=house_wgt], strata(Stratum) singleunit(scaled)

*using your new poverty measure with imputed income: 
svy: tab ispoor_imp Q528cFBE,row

***What proportion of poor households recieved FBE?
svy: tab hfbe if ispoor_imp==1, ci se

*REMARK: 18.77% of poor household received the FBE

***what proportion of non-poor households recieved FBE?*
svy: tab hfbe if ispoor_imp==0, se
*REMARK: 17.43% of NON-POOR household received the FBE


*** What proportion of those recieving FBE are poor?*
*gen hinc2fbe=0
*replace hinc2fbe=1 if real_monthly_incomeimp<=3500&Q528cFBE==1
*svy: tab hinc2fbe,se
svy: tab Q528cFBE ispoor_imp ,row


svy: tab ispoor_imp if hfbe==1, se
*REMARK: 38.06% of those receiving FBE are POOR

***Re-estimating proportions limiting households that have reported having mains connections*
lookfor "main"
codebook Q528aMains

lookfor "access"
codebook Q527Access 

tab Q527Access Q528aMains

*In sample
gen insample=0
* Have Mains connection and Access to electricity
replace insample=1 if Q528aMains==1 & Q527Access==1
tab insample
*8  didn't specifify if they had access to electricity even though they have mains connection
* REMARK:  18 012 households have Mains connection and Access to electricity
*------------------------------------------------------------------------------*
*RE-ESTIMATING
*------------------------------------------------------------------------------*

*gen hinc3fbe=0
*replace hinc3fbe=1 if hhincome_predicted<=3500&Q527Access==1
*svy: tab hinc3fbe Q528cFBE,row

***What proportion of poor households recieved FBE?
svy: tab hfbe if ispoor_imp==1 & insample==1, se
   *REMARK: 22.94% of poor household received the FBE
   
***what proportion of non-poor households recieved FBE?*
	svy: tab hfbe if ispoor_imp==0 & insample==1, se
	*REMARK: 20.24% of NON-POOR household received the FBE

svy: tab ispoor_imp if hfbe==1 & insample==1, se
*REMARK: 38.06% of those receiving FBE are POOR

***Estimating total number of poor households that have accessed FBE using new poverty measure*

di   .045*16670854

svy: tabulate hfbe if ispoor_imp==1, count format(%17.0f)

*Totals
svy: tabulate ispoor_imp if hfbe==1 & insample==1, count format(%17.0f)
/* REMARK: 1 136 833 is the total number of POOR households receiving FBE in 2018 */

*---------------------------------------------------------------------*

*** close the Log File
log close

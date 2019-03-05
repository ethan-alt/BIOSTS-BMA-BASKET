%macro design_cbhm;

proc IML;
 call streaminit(&seed.);
 call randseed(&seed.);

 reset storage=BMAMod.BMAMod;  /* set location for storage */
  load module=Enrollment;
  load module=simBin;
 reset storage=work.IMLSTOR;

  ** number of simulations;
  nSims = &nSims.;

  ** set response rates;
  respProb = round({&responseRates.},0.00001);

  ** set number of baskets;
  K0 = ncol(respProb); call symput('K0',strip(char(K0)));

  piNull      = round(&PiNull.,0.00001);

  ** identify which baskets are null and which are alternative;
  loc_null = loc(respProb<=piNull);
  loc_alt  = loc(respProb >piNull);

  ** target sample size for each stage;
  AveNBound   = {&AveNBound.};
  TotalNBound = AveNBound*K0;
  
  ** minimum/maximum sample size in basket stage;
  nBasketMin = {&nBasketMin.};
  nBasketMax = {&nBasketMax.};

  ** set the value used for the hypothesis test;
  pMid   = &PiNull.*0.5 + &PiAlt.*0.5; call symput('pMid', char(pMid));
  pFinal = &PiNull.;                   call symput('pFinal',char(pFinal));

  ** early stopping critical values;
  ppEffCrit            = {&ppEffCrit.};
  ppFutCrit            = {&ppFutCrit.};

  ** containers for simulation results;
  yHat       = J(nSims,K0,0);
  finalSS    = J(nSims,K0,0);
  finalTotSS = J(nSims,1,0);
  nFirstInt  = J(nSims,K0,0);

  finalpm    = J(nSims,K0,0);
  finalpp    = J(nSims,K0,0);

  erly_futility = J(nSims,K0,0);
  erly_efficacy = J(nSims,K0,0);
  erly_any      = J(nSims,K0,0);
  efficacy      = J(nSims,K0,0);

  trialLength   = J(nSims,1,0);
  FWER          = J(nSims,1,0);
  NERR          = J(nSims,1,0);  
  OvrPower      = J(nSims,1,0);
  nInterims     = J(nsims,1,0);
  nSimulations  = J(nsims,1,0);

  calledNegative = J(nSims,1,0);
  falsePositive  = J(nSims,1,0);
  trueNegative   = J(nSims,1,0);

  calledPositive = J(nSims,1,0);
  truePositive   = J(nSims,1,0);
  falseNegative  = J(nSims,1,0);

  mse            = J(nSims,K0,0);
  bias           = J(nSims,K0,0);
  iStop          = J(nSims,&maxInterim.,0);
  iStopN         = J(nSims,&maxInterim.,0);

** simulation study loop;
do replicate = 1 to nSims;

 ** enrollment rates;
 enrollmentRates = round({&enrollmentRates.},0.00001);

 ** container for response vector for each basket;
 y_current = J(1,K0,0);

 ** container for sample size for each basket;
 n_current = J(1,K0,0);

 ** container for final decision for each basket;
 decision = J(1,K0,0);

 ** container for early stoppage;
 stopearly = J(1,K0,0);

 ** indicator for trial stoppage;
 stop_trial = 0;

 ** container for the total length of the trial;
 elapsedTime = 0;

 ** analysis counter;
 interim = 0;
 do until (stop_trial = 1);
    interim = interim + 1;

	** simulate distribution to baskets for enrollment and responses;
	n_before = n_current; 
	
	TotalNBound[interim] = AveNBound[interim]*sum((enrollmentRates>1e-8));	
    run enrollment(n_current,elapsedTime,enrollmentRates,nBasketMin,nBasketMax,TotalNBound,interim);
    run simBin(y_current,n_before,n_current,respProb);


    yLab = "Y1":"Y&K0";
	nLab = "N1":"N&K0";

	d = y_current||n_current; 
	lab = yLab||nLab;
	create d from d[c=lab];
	 append from d;
	close d;

    ** fit model with BHM;
    %include "&mcmcPath.";

    use PM(keep=mean);
	read  all var _all_ into pMeanTreatBasket; pMeanTreatBasket = t(pMeanTreatBasket);
	close PM;


    if interim  = &maxInterim.  then stop_trial = 1;
  
   
   if stop_trial = 1 then do;
     use PFinal(keep=mean);
	 read  all var _all_ into ppTreatBasket; ppTreatBasket = t(ppTreatBasket);
	 close PFinal;
   end;
   else do;
    use PMid(keep=mean);
	read  all var _all_ into ppTreatBasket; ppTreatBasket = t(ppTreatBasket);
	close PMid;
   end;

 

   ** for each basket determine whether the basket should stop enrollment for futility or efficacy;
   do k = 1 to K0;

    ** efficacy will always be based on final data even if an arm is terminated early;
    if ( ppTreatBasket[k]  >= ppEffCrit[1] ) & (stop_trial=1) & (decision[k] = 0) then decision[k] =  1;

	** futility will always be based on final data even if an arm is terminated early;
    if ( ppTreatBasket[k]  <= ppFutCrit[1] ) & (stop_trial=0) then decision[k] = -1;

	** if a decision is ever made, set the enrollment rate to something 
	   such that no subjects will ever be enrolled in that arm;   
    if decision[k] ^= 0 then enrollmentRates[k] = 1e-12; 

   end;
  
   ** set reason for early stoppage;
   do k = 1 to K0;
    if (enrollmentRates[k] < 1e-8) & (interim < &maxInterim.) & (stopearly[k] = 0) then stopearly[k] = decision[k];
   end;
   
	** determine if trial should be stopped;
	numberStopped = 0;
	do k = 1 to K0;
	  if enrollmentRates[k] < 1e-8 then numberStopped = numberStopped + 1;
	end;
	if numberStopped   =  K0           then stop_trial = 1;  
   
    if interim = 1 then nFirst = n_current;
 end;

  ** fix up n and y for cases with zero enrollment;
  n0 = n_current;
  y0 = y_current;
  loc_n0 = loc(n0=0);

  if isEmpty(loc_n0)=0 then do;
    n0[loc_n0] = .A;
	y0[loc_n0] = .B;
  end;

		
   ** sample mean proportion;
   yHat[replicate,] = (y0/n0); 

   ** number of interims;
   nInterims[replicate] = interim;
   nSimulations[replicate] = 1;
   iStop[replicate,interim]  = 1; 
   iStopN[replicate,interim] = n_current[+];
   

		
   ** posterior mean treatment effect;
   finalpm[replicate,] =  pMeanTreatBasket;

   ** final posterior probability of treatment effect;
   finalpp[replicate,] =  ppTreatBasket;

   ** final sample size;
   finalSS[replicate,] =  n_current;

   ** sample size for first Interim;
   nFirstInt[replicate,] = nFirst;

   ** final total sample size;
   finaltotSS[replicate] =  n_current[+];

   ** early futility stoppage;
   erly_futility[replicate,] = (stopearly  = -1);

   ** early efficacy stoppage;
   erly_efficacy[replicate,] = (stopearly  =  1);

   ** any early stoppage;
   erly_any[replicate,] =  (stopearly^=0);

   ** final efficacy decision;
   efficacy[replicate,] = (decision =  1);

   ** mean trial length;
   trialLength[replicate] = elapsedTime;

   ** mse;
   mse[replicate,]  = ( pMeanTreatBasket - respProb   )##2;
   bias[replicate,] = ( pMeanTreatBasket - respProb   );

 
   ** final FWER;
   if isEmpty(loc_null)=1 then temp =  0;
   else temp = (max(decision[loc_null])=1);
   FWER[replicate] = temp;

   if isEmpty(loc_null)=1 then temp =  0;
   else temp = sum(decision[loc_null]=1);   
   
   NERR[replicate] = temp;   
   
   ** final overall power;
   if isEmpty(loc_alt)=1 then temp = 0;
   else temp = (max(decision[loc_alt])=1);
   OvrPower[replicate] = temp;

   ** final decisions;
   calledNegative[replicate]  = sum( (decision<1));
   calledPositive[replicate]  = sum( (decision=1) );

   trueNegative[replicate]   = sum( ( round(respProb,0.000001)<=round(&piNull.,0.000001) ) # ( decision<1 )  );
   falsePositive[replicate]  = sum( ( round(respProb,0.000001)<=round(&piNull.,0.000001) ) # ( decision=1 )  );

   truePositive[replicate]    = sum( (round(respProb,0.000001) >round(&piNull.,0.000001) ) # ( decision=1)  );
   falseNegative[replicate]   = sum( (round(respProb,0.000001) >round(&piNull.,0.000001) ) # ( decision<1)  );
 
    %include "&savePath.";
 
 
 end;

 numNull = sum(( round(respProb,0.000001)<=round(&piNull.,0.000001) ));
 numAlt  = sum(( round(respProb,0.000001) >round(&piNull.,0.000001) ));


  yHat     = yHat[:,];
  finalpm  = finalpm[:,];
  finalpp  = finalpp[:,];

  minSS         = finalSS[><,];
  maxSS         = finalSS[<>,];
  finalSS       = finalSS[:,];
  nFirstInt     = nFirstInt[:,];

  finaltotSS    = finaltotSS[:];

  iStop  = iStop[:,];
  iStopN = iStopN[:,];
  do j = 1 to &maxInterim.;
    if iStop[j]>0 then iStopN[j] = iStopN[j]/ iStop[j];
  end;
  
  nInterims = nInterims[:];
  nSimulations = nSimulations[+];

  erly_futility = erly_futility[:,];
  erly_efficacy = erly_efficacy[:,];
  erly_any      = erly_any[:,];
  efficacy      = efficacy[:,];
  
  trialLength = trialLength[:];

  FWER         = FWER[:];
  NERR          = NERR[:];
  if FWER > 0  then NERR          = NERR / FWER; else NERR = .;  
  OvrPower     = OvrPower[:];

  if numAlt >= 1 then sensitivity = sum(truePositive) / (sum(truePositive) + sum(falseNegative));
  else sensitivity = .;

  if numNull >= 1 then specificity = sum(trueNegative) / (sum(trueNegative) + sum(falsePositive));
  else specificity = .;

  if  sum(calledPositive) > 0 then ppv = sum(truePositive) / sum(calledPositive); else ppv = .;
  if  sum(calledNegative) > 0 then npv = sum(trueNegative) / sum(calledNegative); else npv = .;

  accuracy    = ( sum(truePositive) + sum(trueNegative)                                           ) / 
                ( sum(truePositive) + sum(trueNegative) + sum(falseNegative) + sum(falsePositive) );
  mse         = mse[:,];
  bias        = bias[:,];


   numActive = sum( ( round(respProb,0.000001) > round(&piNull.,0.000001) )  )
            + sum( ( round(respProb,0.000001) = 0.45 )  )/10
            + sum( ( round(respProb,0.000001) = 0.30 )  )/100
			+ sum( ( round(respProb,0.000001) = 0.15 )  )/1000;
  dat0 = numActive||nInterims||nSimulations||yHat||finalpm||finalpp||mse||bias;

  c1 = "sampProp1":"sampProp&K0.";
  c2 = "pm1":"pm&K0.";
  c3 = "pp1":"pp&K0.";
  c4 = "mse1":"mse&K0.";
  c5 = "bias1":"bias&K0.";

  colnames = "numActive"||"nInterims"||"nSimulations"||c1||c2||c3||c4||c5;

  create dat0 from dat0[c=colnames];
   append from dat0;
  close dat0;


  dat1 = numActive||erly_efficacy||erly_futility||iStop||iStopN||finalSS||minSS||maxSS||nFirstInt||finaltotSS||trialLength;

  c1 = "eeff1":"eeff&K0.";
  c2 = "efut1":"efut&K0.";
  c3a = "iStop1":"iStop&MaxInterim.";
  c3b = "iStopN1":"iStopN&MaxInterim.";
  c4 = "ss1":"ss&K0.";
  c5 = "mnss1":"mnss&K0.";
  c6 = "mxss1":"mxss&K0.";
  c7 = "fiss1":"fiss&K0.";
  colnames = "numActive"||c1||c2||c3a||c3b||c4||c5||c6||c7||"ovrSS"||"ovrLen";


  create dat1 from dat1[c=colnames];
   append from dat1;
  close dat1;

    c1 = "rr1":"rr&K0.";
	colnames  = "numActive"||"FWER"||"NERR"||"OvrPower"||c1||"Sens"||"Spec"||"ppv"||"npv"||"accuracy";
  dat2 = numActive||FWER||NERR||OvrPower||efficacy||sensitivity||specificity||ppv||npv||accuracy;
  create dat2 from dat2[c=colnames];
   append from dat2;
  close dat2;


  dat4    = numActive||respProb;
  colnames = "resp1":"resp&K0";
  colnames = "numActive"||colnames;
  create dat4 from dat4[c=colnames];
   append from dat4;
  close dat4;


quit;

data dat;
 merge dat0 dat1 dat2 dat4;
 by numActive;
run;


data dat;
length Scenario enrollmentRates $50. numActive 8.;
 set dat;

 length Scenario enrollmentRates respRates $50.;
 enrollmentRates = compbl("&enrollmentRates.");
 Scenario        = compbl("&scenario");
 respRates       = compbl("&responseRates.");
 
  array rr[&k0] _TEMPORARY_ (&responseRates.);
  
  n05 = 0;
  n15 = 0;
  n25 = 0;
  n30 = 0;
  n35 = 0;
  n45 = 0;

  
  do j = 1 to dim(rr);
   if rr[j] = 0.05 then n05+1;
   if rr[j] = 0.15 then n15+1;
   if rr[j] = 0.25 then n25+1;
   if rr[j] = 0.30 then n30+1;   
   if rr[j] = 0.35 then n35+1;
   if rr[j] = 0.45 then n45+1;
  end;


  stage1n = &s1n.;
  stage2n = &s2n.;
  ppEffCrit = &EffCrit.;
  ppFutCrit = &FutCrit.;


run;


proc append data = dat  base = allDat force;          run; quit;



%mend design_cbhm;

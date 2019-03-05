%macro design_s2stage;


option nonotes;
proc IML;

  reset storage=BMAMod.BMAMod;  /* set location for storage */
  load module=enrollment;
  load module=simBin;
  reset storage=WORK.IMLSTOR;

  call streaminit(&seed.);
  call randseed(&seed.);

  ** number of simulations;
  nSims = &nSims.;

  ** set the value used for the hypothesis test;
  PiNull   = round(&PiNull.,0.00001);   call symput('PiNull', char(PiNull));


  ** set in response rates;
  respProb = round({&responseRates.},0.00001);

  ** identify which baskets are null and whice are alternative;
  loc_null = loc(respProb <= PiNull);
  loc_alt  = loc(respProb  > PiNull);

  ** set number of baskets;
  K0 = ncol(respProb); call symput('K0',strip(char(K0)));

  ** sample sizes for stage 1;
  N1k = {&N1k.};

  ** sample sizes for stage 2;
  N2k = {&N2k.};


  ** containers for sample results;
  finalSS       = J(nSims,K0,0);
  finalTotSS    = J(nSims,1,0);
  yHat          = J(nSims,K0,0);

  trialLength   = J(nSims,1,0);
  FWER          = J(nSims,1,0);
  OvrPower      = J(nSims,1,0);
  nSimulations  = J(nsims,1,0);

  calledNegative = J(nSims,1,0);
  falsePositive  = J(nSims,1,0);
  trueNegative   = J(nSims,1,0);

  calledPositive = J(nSims,1,0);
  truePositive   = J(nSims,1,0);
  falseNegative  = J(nSims,1,0);

  efficacy      = J(nSims,K0,0);

  mse            = J(nSims,K0,0);
  bias           = J(nSims,K0,0);


  ** simulation study loop;
  do replicate = 1 to nSims;

     ** enrollment rates;
     enrollmentRates = round({&enrollmentRates.},0.00001);

     ** number of subjects enrolled;
     nEnrolled = 0;

	 ** current enrollment;
	 n_current = J(1,K0,0);
	 y_current = J(1,K0,0);

	 ** elapsed time fro simulated trial;
	 elapsedTime = 0;

      /******************************* Stage I ****************************************/
		decision = J(1,K0,0);
		eTime    = J(1,K0,0);

	     do k = 1 to K0;
	           ** generate interarrival times for baskets;
	           enr   = J(N1k[k],1,0);
	           call randgen(enr,'exponential',enrollmentRates[k]##-1); 	
	           eTime[k] = enr[+];

			   n_current[k] = N1k[k];
	           y_current[k] = rand('binomial',respProb[k],n1k[k]);

	           decision[k] = (y_current[k] >= &r_s1.);
		 end;

      /******************************* Stage II ****************************************/
		do k = 1 to K0;
           if y_current[k] >= &r_s1. then do;
	           ** generate interarrival times for baskets;
	           enr   = J(N2k[k],1,0);
	           call randgen(enr,'exponential',enrollmentRates[k]##-1); 	
	           eTime[k] = eTime[k] + enr[+];

			   n_current[k] = n_current[k] + n2k[k];
	           y_current[k] = y_current[k] + rand('binomial',respProb[k],n2k[k]);

	           decision[k] = (y_current[k] >= &r_s2.);
		   end;
		end;
		elapsedTime = max(eTime);


  finalSS[replicate,]     = n_current;
  finalTotSS[replicate]   = n_current[+];
  yHat[replicate,]        = y_current/n_current;
  trialLength[replicate]  = elapsedTime;
  nSimulations[replicate] = 1;
  mse[replicate,]         = ( yHat[replicate,]  - respProb   )##2;
  bias[replicate,]        = ( yHat[replicate,]  - respProb   );

   ** final FWER;
   if isEmpty(loc_null)=1 then temp =  0;
   else temp = (max(decision[loc_null])=1);
   FWER[replicate] = temp;

   ** final overall power;
   if isEmpty(loc_alt)=1 then temp = 0;
   else temp = (max(decision[loc_alt])=1);
   OvrPower[replicate] = temp;

   ** final efficacy decision;
   efficacy[replicate,] = (decision =  1);

   ** final decisions;
   calledNegative[replicate]  = sum( (decision<1));
   calledPositive[replicate]  = sum( (decision=1) );

   trueNegative[replicate]   = sum( ( round(respProb,0.000001)<=round(&piNull.,0.000001) ) # ( decision<1 )  );
   falsePositive[replicate]  = sum( ( round(respProb,0.000001)<=round(&piNull.,0.000001) ) # ( decision=1 )  );

   truePositive[replicate]    = sum( (round(respProb,0.000001) >round(&piNull.,0.000001) ) # ( decision=1)  );
   falseNegative[replicate]   = sum( (round(respProb,0.000001) >round(&piNull.,0.000001) ) # ( decision<1)  );
 
end;


  minSS         = finalSS[><,];
  maxSS         = finalSS[<>,];

  FWER          = FWER[:];
  OvrPower      = OvrPower[:];

  finalSS                 = finalSS[:,];
  finalTotSS              = finalTotSS[:];
  yHat                    = yHat[:,];
  trialLength             = trialLength[:];
  nSimulations            = nSimulations[+];

  numNull = sum(( round(respProb,0.000001)<=round(&piNull.,0.000001) ));
  numAlt  = sum(( round(respProb,0.000001) >round(&piNull.,0.000001) ));


  if numAlt >= 1 then sensitivity = sum(truePositive) / (sum(truePositive) + sum(falseNegative));
  else sensitivity = .;

  if numNull >= 1 then specificity = sum(trueNegative) / (sum(trueNegative) + sum(falsePositive));
  else specificity = .;

  if  sum(calledPositive) > 0 then ppv = sum(truePositive) / sum(calledPositive); else ppv = .;
  if  sum(calledNegative) > 0 then npv = sum(trueNegative) / sum(calledNegative); else npv = .;

  efficacy      = efficacy[:,];

  accuracy    = ( sum(truePositive) + sum(trueNegative)                                           ) / 
                ( sum(truePositive) + sum(trueNegative) + sum(falseNegative) + sum(falsePositive) );
  mse         = mse[:,];
  bias        = bias[:,];







   numActive = sum( ( round(respProb,0.000001) > round(&piNull.,0.000001) )  )
            + sum( ( round(respProb,0.000001) = 0.45 )  )/10
            + sum( ( round(respProb,0.000001) = 0.30 )  )/100
			+ sum( ( round(respProb,0.000001) = 0.15 )  )/1000;
  dat0 = numActive||nSimulations||yHat||mse||bias;

  c1 = "sampProp1":"sampProp&K0.";
  c4 = "mse1":"mse&K0.";
  c5 = "bias1":"bias&K0.";

  colnames = "numActive"||"nSimulations"||c1||c4||c5;

  create dat0 from dat0[c=colnames];
   append from dat0;
  close dat0;


  dat1 = numActive||finalSS||minSS||maxSS||finaltotSS||trialLength;
  c4 = "ss1":"ss&K0.";
  c5 = "mnss1":"mnss&K0.";
  c6 = "mxss1":"mxss&K0.";
  colnames = "numActive"||c4||c5||c6||"ovrSS"||"ovrLen";


  create dat1 from dat1[c=colnames];
   append from dat1;
  close dat1;

    c1 = "rr1":"rr&K0.";
	colnames  = "numActive"||"FWER"||"OvrPower"||c1||"Sens"||"Spec"||"ppv"||"npv"||"accuracy";
  dat2 = numActive||FWER||OvrPower||efficacy||sensitivity||specificity||ppv||npv||accuracy;
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
option notes;



data dat;
 merge dat0 dat1 dat2 dat4;
 by numActive;
run;


data dat;
 set dat;

 length Scenario enrollmentRates respRates $50.;
 enrollmentRates = "&enrollmentRates.";
 Scenario        = "&scenario";
 respRates       = "&responseRates.";
 
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

run;

proc append data = dat  base = res.&results._%sysfunc(putn(&sysparm.,z4.)) force;          run; quit;
proc sort data = res.&results._%sysfunc(putn(&sysparm.,z4.)); by Scenario enrollmentRates respRates ; run;


%mend design_s2stage;

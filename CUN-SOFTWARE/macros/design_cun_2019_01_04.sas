%macro design_cun;

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

  ** target sample size for each stage;
  AveNBound   = {&AveNBound.};
  TotalNBound = AveNBound*K0;
  
  ** sample sizes for stage 2 -- heterogeneous path;
  N2k = {&N2k.};

  ** minimum/maximum sample size in basket stage;
  nBasketMin = {&nBasketMin.};
  nBasketMax = {&nBasketMax.};

  ** heterogeneity test threshold;
  gamma = &gamma.;

  ** containers for sample results;
  finalSS       = J(nSims,K0,0);
  finalTotSS    = J(nSims,1,0);
  yHat          = J(nSims,K0,0);
  
  ssAddMax1        = J(nSims,K0,.);
  ssAddMin1        = J(nSims,K0,.);
  
  ssAddMax2        = J(nSims,K0,.);
  ssAddMin2        = J(nSims,K0,.); 
  
  trialLength   = J(nSims,1,0);
  FWER          = J(nSims,1,0);
  NERR          = J(nSims,1,0);  
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

  hdec = 0;
  
   STAGE1_N = J(nSims,K0,0);
   STAGE1_Y = J(nSims,K0,0);
   STAGE1_E = J(nSims,1,0);  

  /******************************* Stage I ****************************************/
  do replicate = 1 to nSims;

     ** enrollment rates;
     enrollmentRates = round({&enrollmentRates.},0.00001);

	 ** current enrollment;
	 n_current = J(1,K0,0);
	 y_current = J(1,K0,0);

	 ** elapsed time fro simulated trial;
	 elapsedTime = 0;

	 ** first stage;
	 interim = 1;   

	 ** simulate enrollment and response outcome;
	 n_before = n_current;

	 TotalNBound[interim] = AveNBound[interim]*sum((enrollmentRates>1e-8));
	 ** compute first stage enrollment;
     run enrollment(n_current,elapsedTime,enrollmentRates,nBasketMin,nBasketMax,TotalNBound,interim);

	 n1_add = n_current;
	 ** compute the first stage outcomes;
	 run simBin(y_current,n_before,n_current,respProb);
	 
	 STAGE1_N[replicate,] = n_current;
	 STAGE1_Y[replicate,] = y_current;
	 STAGE1_E[replicate]  = elapsedTime;
	 
   end;	 

    freq_data =  t(do(1,nSims,1))||STAGE1_N||STAGE1_Y;

	a="N1":"N&K0";
	b="Y1":"Y&K0.";
    lab = "id"||a||b;

	create freq_data from freq_data[c=lab];
	 append from freq_data;
	close freq_data;	
    freq_data = 0;	 
	 
    ** fit model with PROC FREQ;
    %include "&fetPath.";	

  	use FishersExact;
	  read all var {XP2_FISH} into fet_vector; 
	close FishersExact;
  
  
  
  /******************************* Stage II ****************************************/
  do replicate = 1 to nSims;

     ** enrollment rates;
     enrollmentRates = round({&enrollmentRates.},0.00001);

	 ** current enrollment;
	 n_current = STAGE1_N[replicate,];
	 y_current = STAGE1_Y[replicate,];
     n1_add    = n_current;

	 
	 ** elapsed time from simulated trial;
	 elapsedTime = STAGE1_E[replicate];

	 
	 ** Fishers Exact test;
	 pv = fet_vector[replicate];
   

      


	  /*********************** Homogeneous Path ****************************************/
	  if pv > gamma then do;  
	    interim = 2;
        homo    = 1;
		    if y_current[+] >= &r_c. then do;

			    ** simulate enrollment and response outcome;
	            n_before = n_current;

			    ** compute second stage enrollment;
	            run enrollment(n_current,elapsedTime, enrollmentRates,nBasketMin,nBasketMax,TotalNBound,interim);

		        ** compute the second stage outcomes;
		        run simBin(y_current,n_before,n_current,respProb);

	            ** cmpute exact p-value;
	            ytot = y_current[+];
			    ntot = n_current[+];

			    values = do(ytot,ntot,1);

			    pv  = pdf('binomial',values,piNull,ntot)[+];
		        pv  = J(1,K0,pv);
				decision = (pv<&alpha_c);
				n2_add = n_current - n1_add;
		    end;
			else do;
	          pv = J(1,K0,1);
			  decision = J(1,K0,0);
			  n2_add = J(1,K0,.);
			end;
			
		
      end;
	  /***************************     Hetergeneous path   ***********************************/
      else do;
        interim = 2;
        homo    = 0;

		pv       = J(1,K0,0);
		decision = J(1,K0,0);
		eTime    = J(1,K0,0);
		
		
		** get every basket to the minimum sample size;
		do k = 1 to K0;
			if n_current[k] < AveNBound[1] then do;
			   delta_s1 = AveNBound[1]-n_current[k];
	           enr   = J(delta_s1,1,0);
	           call randgen(enr,'exponential',enrollmentRates[k]##-1); 	
	           eTime[k] = eTime[k] + enr[+];			   
			   n_current[k] = n_current[k] + delta_s1;
	           y_current[k] = y_current[k] + rand('binomial',respProb[k],delta_s1);			
			end;		
		end;

		KStar = 0;
		do k = 1 to K0;
		  if y_current[k] >= &r_s. then KStar = KStar + 1;
		end;		
		
		do k = 1 to K0;
           if y_current[k] < &r_s. then do;
            pv[k]          = 1;
			decision[k]    = 0;
			eTime[k]       = eTime[k] + 0;
		   end;
		   else do;
		   
		       add_n = N2k[k];

			   if n_current[k] > AveNBound[1] then add_n = add_n - (n_current[k]-AveNBound[1]);
			   if add_n >0 then do;
	             ** generate interarrival times for baskets;
	             enr   = J(add_n,1,0);
	             call randgen(enr,'exponential',enrollmentRates[k]##-1); 	
	             eTime[k] = eTime[k] + enr[+];

			     n_current[k] = n_current[k] + add_n;
	             y_current[k] = y_current[k] + rand('binomial',respProb[k],add_n);
               end;
			   
			   values = do(y_current[k],n_current[k],1);
	           pv[k]       = pdf('binomial',values,piNull,n_current[k])[+];
	           decision[k] = (pv[k]<(&alpha_s./KStar));
		   end;
		end;
		elapsedTime = elapsedTime + max(eTime);
		n2_add = J(1,K0,.);
	  end;


	  

  finalSS[replicate,]     = n_current;
  finalTotSS[replicate]   = n_current[+];
  if homo = 0 then yHat[replicate,] = y_current/n_current;
  else             yHat[replicate,] = J(1,K0,y_current[+]/n_current[+]);
  trialLength[replicate]  = elapsedTime;
  nSimulations[replicate] = 1;
  hdec = hdec + homo;
  mse[replicate,]         = ( yHat[replicate,]  - respProb   )##2;
  bias[replicate,]        = ( yHat[replicate,]  - respProb   );

  
    ssAddMax1[replicate,] = n1_add; 
	ssAddMin1[replicate,] = n1_add;
	
    ssAddMax2[replicate,] = n2_add; 
	ssAddMin2[replicate,] = n2_add;
  
  
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
  
  ssAddMin1     = ssAddMin1[><,];
  ssAddMax1     = ssAddMax1[<>,];

  ssAddMin2     = ssAddMin2[><,];
  ssAddMax2     = ssAddMax2[<>,]; 
  
  FWER          = FWER[:];
  NERR          = NERR[:];
  if FWER > 0  then NERR          = NERR / FWER; else NERR = .;
  OvrPower      = OvrPower[:];

  finalSS                 = finalSS[:,];
  finalTotSS              = finalTotSS[:];
  yHat                    = yHat[:,];
  trialLength             = trialLength[:];
  nSimulations            = nSimulations[+];
  hdec = hdec / nSims;

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

  dat1 = numActive||finalSS||minSS||maxSS||finaltotSS||trialLength||ssAddMin1||ssAddMax1||ssAddMin2||ssAddMax2||hdec;
  c4  = "ss1":"ss&K0.";
  c5  = "mnss1":"mnss&K0.";
  c6  = "mxss1":"mxss&K0.";
  c7  = "mn1ss1":"mn1ss&K0.";
  c8  = "mx1ss1":"mx1ss&K0.";  
  c9  = "mn2ss1":"mn2ss&K0.";
  c10 = "mx2ss1":"mx2ss&K0.";   
  colnames = "numActive"||c4||c5||c6||"ovrSS"||"ovrLen"||c7||c8||c9||c10||{"ProbHomo"};


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
   
 
	s1n     = &s1n.;
	s2n     = &s2n.;
	s2k     = &s2k.;
	r_s     = &r_s.;
	r_c     = &r_c.;
	alpha_s = &alpha_s.;
	alpha_c = &alpha_c.;
	gamma   = &gamma.;
 
	

run;


proc append data = dat  base = allDat   force; run; quit;

proc contents data = allDat out = cont(keep=name) noprint; run;
proc sort nodupkey; by name; run;


data _null_;
 set cont;
 where find(name,'NUMACTIVE','i')=0 and find(name,'NSIMULATIONS','i')=0
 and upcase(NAME) not in ('S2N' 'S1N' 'S2K' 'GAMMA' 'ALPHA_S' 'ALPHA_C' 'R_S' 'R_C')
    and upcase(name) not in ( "N05" "N15" "N25" "N35" "N45" "N30" "ENROLLMENTRATES" "SCENARIO" "RESPRATES");
 call symput('v'||strip(put(_n_,best.)),strip(name) );
 call symput('vNum',strip(put(_n_,best.))           );
run;

%macro process;
 proc means data = allDat nway noprint ;
  class SCENARIO enrollmentRates RESPRATES  s1n s2n s2k alpha_s alpha_c r_s r_c gamma numActive n05 n15 n25 n30 n35 n45;
   freq nSimulations;
   var %do j = 1 %to &vNum.; &&v&j.. %end;;
   output out = allDat(drop=_type_ _freq_) mean = %do j = 1 %to &vNum.; &&v&j.. %end; n(&v1.)=nSimulations;
 run;
 
 data &results._%sysfunc(putn(&sysparm.,z4.));
  set allDat;
 run; 
 
%mend; %process;



%mend design_cun;

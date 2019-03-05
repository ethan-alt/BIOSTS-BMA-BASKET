%macro setup(PRG);
ods html close;
ods listing close;
%global root;
  data te;
   set sashelp.vextfl;
   where find(upcase(xPath),upcase("&PRG."));
   spt = index(upcase(xPath),upcase("PROGRAMS"));
   root = substr(xPath,1,spt-2);
   call symput('root',strip(root));
  run;

	%if &SYSSCP = WIN %then %do;
	   libname bmamod "&root.\modules\win";
	%end;
	%else %do;
	  libname bmamod "&root./modules/unix";
	%end;

	proc datasets library=bmamod noprint kill; run; quit;

%mend setup;
%setup(00-IML-modules.sas);



proc IML;

start simBin(y_current,n_before,n_current,respProb);

 K0 = ncol(y_current);
 ** trick to avoid n=0 for rand('Binomial',...);
  temp_n         = n_current-n_before;
  temp_p         = respProb;
  temp_l         = loc(temp_n=0);

  if isempty(temp_l)=0 then do;
	 temp_n[temp_l] = 1;
	 temp_p[temp_l] = 1e-30;
  end;
  y_current = y_current + rand('binomial',temp_p,temp_n);

finish;

start enrollment(n_current,elapsedTime,enrollmentRates,nBasketMin,nBasketMax,TotalNBound,interim);
 K0 = ncol(n_current);
 n_increment = n_current*0;


 ** generate interarrival times for baskets;
 eTimes   = J(10*TotalNBound[interim],K0,0);
 eBaskets = repeat(1:K0,10*TotalNBound[interim],1); 
 call randgen(eTimes,'exponential',enrollmentRates##-1); 	

 ** compute enrollment times;
 do k = 1 to K0;
  eTimes[,k] = cusum(eTimes[,k]);
 end;
 
 eTimes  = eTimes#(enrollmentRates>1e-8) + J(10*TotalNBound[interim],K0,1e10)#(enrollmentRates<=1e-8); 
 

 locOpen = loc(enrollmentRates>1e-8);

 ** vectorize enrollment times;
 eBaskets = shapecol(eBaskets,0,1);
 eTimes   = shapecol(eTimes,0,1);
 
 /*
 ** remove times from baskets that are not active;
 do k = 1 to K0;
   if enrollmentRates[k] < 1e-8 then do;
    locS = loc(eBaskets^=k);
	eBaskets = eBaskets[locS,];
	eTimes   = eTimes[locS,];
   end;
 end;
 */
 ** concatenate long vectors;
 eDat = eBaskets||eTimes;

 ** sort the rows by enrollment times;
 call sort(eDat,2);

 eBaskets = eDat[,1];
 eTimes   = eDat[,2];

 stop = 0;
 i    = 1;

   do until(stop=1);
	 if (n_increment[eBaskets[i]] < nBasketMax[interim]) then n_increment[eBaskets[i]] = n_increment[eBaskets[i]] + 1;
	 if min(n_increment[locOpen]) >= nBasketMin[interim] & sum(n_increment) >= TotalNBound[interim]           then     stop = 1;
	 if min(n_increment[locOpen])  = nBasketMax[interim]                                                      then     stop = 1;	 
	 
	 numberStopped = 0;
	 do k = 1 to K0;
	   if round(n_increment[k]) >= round(nBasketMax[interim]) |  enrollmentRates[k] < 1e-8 then numberStopped = numberStopped + 1;
	 end;
	 if numberStopped = K0 then stop = 1;
	  
	 if stop = 0 then i = i+1;
	 
		if i > nrow(eTimes) then do;
			print eTimes eBaskets ,enrollmentRates, numberStopped n_current n_increment nBasketMax interim i;
			abort;
		end;   	 
   end;

   n_current   = n_current + n_increment;
   elapsedTime = elapsedTime + eTimes[i];
 

finish;
	 

reset storage=BMAMod.BMAMod;  /* set location for storage */
store module=simBin;
store module=enrollment;
quit;


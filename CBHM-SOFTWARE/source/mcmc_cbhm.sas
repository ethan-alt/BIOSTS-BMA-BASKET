    submit;

data d2;
	 set d;
	  array y[*] y:;
	  array n[*] n:;

	   n1tot = 0;
	   n0tot = 0;
	   ntot  = 0;

	  do basket = 1 to dim(y);
	   n1tot = n1tot + y[basket];
	   n0tot = n0tot + n[basket]-y[basket];
	   ntot  = ntot  + n[basket];
	  end;

	  T = 0;
	  if n0tot < ntot and n1tot < ntot then do basket = 1 to dim(y);
		E0 = n[basket]*n0tot/ntot;
		E1 = n[basket]*n1tot/ntot;

        if n[basket]>0 then T = T + (y[basket]-E1)**2/E1;
		if n[basket]>0 then T = T + (n[basket]-y[basket]-E0)**2/E0;
	  end;
	  else T = 0.005;
	  if T = 0 then T = 0.005;
	   
	   var = max(exp(&a0. + &b0.*log(T)),1e-2);
       call symput('var',strip(put(var,best.)));
run;

	
     ods select none;
  	 ods output PostSumInt = PSI;
     proc mcmc data = d plots=none nmc=20000 nbi=200 ntu=2000 nthin=1 mintune=4 monitor=(pi1-pi&K0. sigInt1-sigInt&K0. sigFinal1-sigFinal&K0. mu ) DIAG=NONE propcov=quanew;


	  array theta[&K0.];
	  array pi[&K0.];
	  array sigInt[&K0.];
	  array sigFinal[&K0.];	  
	  
	  array y[&K0.];
	  array n[&K0.];

	  array mn[&K0.];
	  array cv[&K0.,&K0.];

	  begincnst;
        do k = 1 to &K0.;
         mn[k] = log(&piNull. / (1-&piNull.));
		end;

		do r = 1 to &K0.;
		do c = 1 to &K0.;
          if r=c then cv[r,c]=1000+&var.;
		  else cv[r,c]=1000;
		end;
		end;
	  endcnst;

	  parms theta;
	  prior theta ~ mvn(mn,cov=cv);

      beginnodata;
       do k = 1 to &K0.;
	     pi[k] = logistic(theta[k]);
		 sigInt[k]   = (pi[k]>&pMid.);
		 sigFinal[k] = (pi[k]>&pFinal.);
	   end;
	  endnodata;

	  lp = 0;
	  do k = 1 to &K0.;
	    lp = lp + y[k]*log(pi[k]) + (n[k]-y[k])*log(1-pi[k]);
	  end;

	  model general(lp);

	 run;
	 
	 data PMid;
	  set PSI;
	  where find(parameter,'sigInt','i')>0;
	 run;
	 
	 data PFinal;
	  set PSI;
	  where find(parameter,'sigFinal','i')>0;
	 run;	 
	 
	 data PM;
	  set PSI;
	  where find(parameter,'pi','i')>0;
	 run;	 

	 proc datasets library=work noprint;
	  delete PSI;
	 run;quit;
	 
	 ods select all;
	 
	 /*
	 %let numbSims = %eval(&numbSims+1);
	 %put DONE &numbSims.;
	  */
	endsubmit;
	 

%macro setup(PRG);
ods html close;
ods listing close;

%global root macroPath mcmcPath savePath outPath print;
  data te;
   set sashelp.vextfl;
   where find(upcase(xPath),upcase("&PRG."));
   spt = index(upcase(xPath),upcase("PROGRAMS"));
   root = substr(xPath,1,spt-2);
   call symput('root',strip(root));
  run;

%if &SYSSCP = WIN %then %do;
   %let sysparm    = 1;
   %let macroPath  = &root.\macros;
   %let mcmcPath   = &root.\source\mcmc_cbhm.sas;
   %let savePath   = &root.\source\save.sas;
   libname bmamod "&root.\modules\win" access=read;
   libname res "&root.\results";

   %include "&macroPath\design_cbhm_2019_01_04.sas";
   %include "&macroPath\cbhm_ab_calc.sas";
   %include "&macroPath\rr.sas";
%end;
%else %do;
   %let macroPath  = &root./macros;
   %let mcmcPath   = &root./source/mcmc_cbhm.sas;
   %let savePath   = &root./source/save.sas;

   libname bmamod "&root./modules/unix" access=read;
   libname res "&root./results";

   %include "&macroPath/design_cbhm_2019_01_04.sas";
   %include "&macroPath/cbhm_ab_calc.sas";
   %include "&macroPath/rr.sas";
%end;

proc datasets library=work kill noprint; run; quit;

%mend setup;
%setup(01-IML-CBHM.sas);


data scenarios;
 call streaminit(&sysparm.);

  array seed[14];

  array _s1n[4] _temporary_ ( 7    8   9  10   11  12   );
  array _s2n[5] _temporary_ ( 10  11  12   13  14 15    );

  do r1 = 1 to dim(_s1n);
  do r2 = 1 to dim(_s2n);
    s1n = _s1n[r1];
    s2n = _s2n[r2];

	if 20 <= s1n + s2n <= 24 then do;

		 do ppEffCrit = 0.975 to 0.990 by 0.0025;
		 do ppFutCrit = 0.10 to 0.40 by 0.025;
		 do repeat = 1 to 4;
		     
			do j = 1 to dim(seed);
			 seed[j] = round(1 + rand('uniform')*2**26);
			end;
			order = rand('uniform');
			output;

		 end;
		 end;
		 end;
		 end;
		 end;

	end;

 drop repeat j r1 r2 ;
run; 
proc sort; by order; run;

data scenarios;
 set scenarios;
 retain node 1;
 if mod(_n_,5)=0 then node+1;
run;


data scenarios;
 set scenarios;
 where node = &sysparm.;
 rep+1;

 call symput('nRep',strip(put(_n_,best.)));
run;


%let nSims                = 2500;
%let results              = CBHM;
proc datasets library=res noprint nowarn;
 delete &results._%sysfunc(putn(&sysparm.,z4.)); 
run;
quit;

%macro loopit;

%do r = 1 %to &nRep.;
 %put &=r of &nRep.;

data _null_;
 set scenarios;
 where rep = &r.;

	 call symput('s1n',strip(put(s1n,best.)));
	 call symput('s2n',strip(put(s2n,best.)));
	 call symput('effcrit',strip(put(ppEffCrit,best.)));
	 call symput('futcrit',strip(put(ppFutCrit,best.)));

	 call symput('seed1',strip(seed1));
	 call symput('seed2',strip(seed2));
	 call symput('seed3',strip(seed3));
	 call symput('seed4',strip(seed4));
	 call symput('seed5',strip(seed5));
	 call symput('seed6',strip(seed6));
	 call symput('seed7',strip(seed7));
	 call symput('seed8',strip(seed8));
	 call symput('seed9',strip(seed9));
	 call symput('seed10',strip(seed10));
	 call symput('seed11',strip(seed11));
	 call symput('seed12',strip(seed12));
	 call symput('seed13',strip(seed13));
	 call symput('seed14',strip(seed14));



run;


%let maxInterim           =     2;
%let AveNBound            =   &s1n.             &s2n. ;
%let nBasketMin           =     4                4    ; 
%let nBasketMax           =   10000             10000 ;

%let piNull               = 0.15;
%let piAlt                = 0.45;

%let ppEffCrit            = &effcrit.;

%let ppFutCrit            = &futcrit.;

%let enrollmentRates = 2.00 2.00 2.00 2.00 2.00;
%cbhm_ab_calc(K0=5,rr=0.45 0.45 0.45 0.45 0.45,
             target=0.15,N=%eval(&s1n. + (&maxInterim.-1)*&s2n.),
             s2_b=1,s2_bb=80);



    %let Scenario         = Equal Enrollment;
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed1.;
	%let responseRates    = %rr(0.45|0.30|0.15,0|0|5);
	%design_cbhm;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed2.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_cbhm;
    
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed3.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_cbhm;
    /*
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed4.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_cbhm;
    
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed5.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_cbhm;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed6.;
	%let responseRates    = %rr(0.45|0.30|0.15,5|0|0);
	%design_cbhm;
*/
    
	****;
	%let Scenario         = Slow Active;
	%let enrollmentRates  = 1.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed7.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_cbhm;
	

    /*
	%let enrollmentRates  = 1.00 1.00 2.00 2.00 2.00;
	%let seed             = &seed8.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_cbhm;
    
	%let enrollmentRates  = 1.00 1.00 1.00 2.00 2.00;
	%let seed             = &seed9.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_cbhm;
    
	%let enrollmentRates  = 1.00 1.00 1.00 1.00 2.00;
	%let seed             = &seed10.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_cbhm;
    
	****;
	%let Scenario         = Fast Active;
	%let enrollmentRates  = 2.00 1.00 1.00 1.00 1.00;
	%let seed             = &seed11.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_cbhm;
    
	%let enrollmentRates  = 2.00 2.00 1.00 1.00 1.00;
	%let seed             = &seed12.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_cbhm;

	%let enrollmentRates  = 2.00 2.00 2.00 1.00 1.00;
	%let seed             = &seed13.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_cbhm;
    
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 1.00;
	%let seed             = &seed14.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_cbhm;
    */
%end;
  data res.&results._%sysfunc(putn(&sysparm.,z4.));
   set allDat;
  run;
%mend loopit;



option nonotes;
%loopit;
option notes;










%macro setup(PRG);
ods html close;
ods listing close;
%global root macroPath fetPath ;


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
   %let fetPath    = &root.\source\fet_cun.sas;

   libname bmamod "&root.\modules\win" access=read;
   libname res "&root.\results";

   %include "&macroPath\design_cun_2019_01_04.sas";
   %include "&macroPath\rr.sas"; 
%end;
%else %do;
   %let macroPath   = &root./macros;
   %let fetPath     = &root./source/fet_cun.sas;

   libname bmamod "&root./modules/unix" access=read;
   libname res    "&root./results";

   %include "&macroPath/design_cun_2019_01_04.sas";
   %include "&macroPath/rr.sas";

%end;
	proc datasets library=work kill noprint; run; quit;
%mend setup;
%setup(01-IML-CUN.sas);


data scenarios;
 call streaminit(&sysparm);

  retain node 1 idx 0;
  array seed[14];

  array _s1n[3] _temporary_ (  7  8  9    );
  array _s2n[4] _temporary_ (  4  5  6 7  );
  array _s2k[3] _temporary_ ( 15 16 17    );
 do r1 = 1 to dim(_s1n);
 do r2 = 1 to dim(_s2n);
 do r3 = 1 to dim(_s2k);

    s1n = _s1n[r1];
    s2n = _s2n[r2];
    s2k = _s2k[r3];


 

 do r_s = 1 to 2; 
 do mod = 4 to 5;
    r_c = mod*r_s;
 do alpha_s = 0.010 to 0.060 by 0.005;
 do alpha_c = 0.025 to 0.070 by 0.005;
 do gamma   = 0.500 to 0.750 by 0.025;


	  idx+1;
	  if idx = 251 then do;
	   node+1;
	   idx=0;
	  end;
	   do j = 1 to dim(seed);
	     seed[j] = round(1 + rand('uniform')*2**26);
	   end;
	   output;


 end;
 end;
 end;
 end;
 end;
 end;
 end;
 end;

run; 



data scenarios;
 set scenarios;
 where node = &sysparm.;
 rep+1;

 call symput('nRep',strip(put(_n_,best.)));
run;


%let nSims                = 25000;
%let results              = CUN;
proc datasets library=res noprint;
 delete &results._%sysfunc(putn(&sysparm.,z4.)); 
run;
quit;


%macro loop;
 %do r = 1 %to &nRep.;
  %put &=r of &nRep.;

	data _null_;
	 set scenarios;
	 where rep = &r.;

	 call symput('s1n',strip(put(s1n,best.)));
	 call symput('s2n',strip(put(s2n,best.)));
	 call symput('s2k',strip(put(s2k,best.)));
	 call symput('r_s',strip(put(r_s,best.)));
	 call symput('r_c',strip(put(r_c,best.)));
	 call symput('alpha_s',strip(put(alpha_s,best.)));
	 call symput('alpha_c',strip(put(alpha_c,best.)));
	 call symput('gamma',strip(put(gamma,best.)));

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


    %let AveNBound       =  &s1n. &s2n.;  

	%let nBasketMin      =    4         1; 
	%let nBasketMax      =  100       100;
	%let N2k             = &s2k. &s2k. &s2k. &s2k. &s2k.; 

	%let piNull          = 0.15;


	%let Scenario         = Equal Enrollment;
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed1.;
	%let responseRates    = %rr(0.45|0.30|0.15,0|0|5);
	%design_cun;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed2.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_cun;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed3.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_cun;
/*
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed4.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_cun;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed5.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_cun;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed6.;
	%let responseRates    = %rr(0.45|0.30|0.15,5|0|0);
	%design_cun;
*/

	****;
	%let Scenario         = Slow Active;
	%let enrollmentRates  = 1.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed7.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_cun;
	/*
	%let enrollmentRates  = 1.00 1.00 2.00 2.00 2.00;
	%let seed             = &seed8.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_cun;

	%let enrollmentRates  = 1.00 1.00 1.00 2.00 2.00;
	%let seed             = &seed9.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_cun;
	
	%let enrollmentRates  = 1.00 1.00 1.00 1.00 2.00;
	%let seed             = &seed10.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_cun;

	****;
	%let Scenario         = Fast Active;
	%let enrollmentRates  = 2.00 1.00 1.00 1.00 1.00;
	%let seed             = &seed11.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_cun;
	/*
	%let enrollmentRates  = 2.00 2.00 1.00 1.00 1.00;
	%let seed             = &seed12.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_cun;

	%let enrollmentRates  = 2.00 2.00 2.00 1.00 1.00;
	%let seed             = &seed13.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_cun;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 1.00;
	%let seed             = &seed14.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_cun;
*/
%end;

  data res.&results._%sysfunc(putn(&sysparm.,z4.));
   set &results._%sysfunc(putn(&sysparm.,z4.));
  run;
%mend;

option nonotes;
%loop;
option notes;

/*
ods html file="test.html";
 %let k0 = 5;
proc sort data = &results._%sysfunc(putn(&sysparm.,z4.));
 by s1n s2n s2k alpha_s alpha_c r_s r_c gamma Scenario enrollmentRates set n45;
run;
proc print data = &results._%sysfunc(putn(&sysparm.,z4.));
 by s1n s2n s2k alpha_s alpha_c r_s r_c gamma Scenario ;
  pageby gamma;
  format n15 n30 n45 3. FWER NERR OvrPower rr1-rr5 6.3 ovrLen ovrSS 6.2 mnSS1-mnSS&K0. mxSS1-mxSS&K0. 6.2 ProbHomo 6.3 ;
  var  enrollmentRates set nSimulations n15 n30 n45     FWER NERR OvrPower rr1-rr5     ovrLen ovrSS mnSS1-mnSS&K0. mxSS1-mxSS&K0. ProbHomo;
run;


ods html close;
*/

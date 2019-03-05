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

   libname bmamod "&root.\modules\win" access=read;
   libname res "&root.\results";

   %include "&macroPath\design_s2stage.sas";
   %include "&macroPath\rr.sas"; 
%end;
%else %do;
   %let macroPath   = &root./macros;

   libname bmamod "&root./modules/unix" access=read;
   libname res    "&root./results";

   %include "&macroPath/design_s2stage.sas";
   %include "&macroPath/rr.sas";

%end;
	proc datasets library=work kill noprint; run; quit;
%mend setup;
%setup(01-IML-simon.sas);



%let N1k             =  9  9  9  9  9;
%let N2k             = 18 18 18 18 18;

%let r_s1            = 3;
%let r_s2            = 9;


%let responseRates   = 0.15 0.15 0.15 0.15 0.15;
%let enrollmentRates = 2.00 2.00 2.00 2.00 2.00;

%let piNull = 0.15;

%let nSims   = 200000;
%let results = S2Opt;


proc datasets library=res noprint;
 delete &results._%sysfunc(putn(&sysparm.,z4.)); 
run;
quit;



data _null_;
  call streaminit(&sysparm);
   do j = 1 to 21;
    call symput('seed'||strip(put(j,best.)),strip(put(round(1 + rand('uniform')*2**26),best.)));
   end;
run; 




	%let Scenario         = Equal Enrollment;
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed1.;
	%let responseRates    = %rr(0.45|0.30|0.15,0|0|5);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed2.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed3.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed4.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed5.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed6.;
	%let responseRates    = %rr(0.45|0.30|0.15,5|0|0);
	%design_s2stage;


	****;
	%let Scenario         = Slow Active;
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed7.;
	%let responseRates    = %rr(0.45|0.30|0.15,0|0|5);
	%design_s2stage;
	
	%let enrollmentRates  = 1.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed8.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_s2stage;
	
	%let enrollmentRates  = 1.00 1.00 2.00 2.00 2.00;
	%let seed             = &seed9.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_s2stage;

	%let enrollmentRates  = 1.00 1.00 1.00 2.00 2.00;
	%let seed             = &seed10.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_s2stage;
	
	%let enrollmentRates  = 1.00 1.00 1.00 1.00 2.00;
	%let seed             = &seed11.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_s2stage;

	%let enrollmentRates  = 1.00 1.00 1.00 1.00 1.00;
	%let seed             = &seed12.;
	%let responseRates    = %rr(0.45|0.30|0.15,5|0|0);
	%design_s2stage;

	****;
	%let Scenario         = Fast Active;
	%let enrollmentRates  = 1.00 1.00 1.00 1.00 1.00;
	%let seed             = &seed13.;
	%let responseRates    = %rr(0.45|0.30|0.15,0|0|5);
	%design_s2stage;

	%let enrollmentRates  = 2.00 1.00 1.00 1.00 1.00;
	%let seed             = &seed14.;
	%let responseRates    = %rr(0.45|0.30|0.15,1|0|4);
	%design_s2stage;
	
	%let enrollmentRates  = 2.00 2.00 1.00 1.00 1.00;
	%let seed             = &seed15.;
	%let responseRates    = %rr(0.45|0.30|0.15,2|0|3);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 1.00 1.00;
	%let seed             = &seed16.;
	%let responseRates    = %rr(0.45|0.30|0.15,3|0|2);
	%design_s2stage;
	
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 1.00;
	%let seed             = &seed17.;
	%let responseRates    = %rr(0.45|0.30|0.15,4|0|1);
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed18.;
	%let responseRates    = %rr(0.45|0.30|0.15,5|0|0);
	%design_s2stage;


	%let Scenario         = Equal Enrollment - Heterogeneous;
	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed19.;
	%let responseRates    = 0.05  0.15  0.25  0.35  0.45;
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed20.;
	%let responseRates    = 0.15  0.15  0.30  0.30  0.45;
	%design_s2stage;

	%let enrollmentRates  = 2.00 2.00 2.00 2.00 2.00;
	%let seed             = &seed21.;
	%let responseRates    = 0.15  0.30  0.30  0.30  0.45;
	%design_s2stage;


	data res.SOPT_OPTIMAL;
	 set res.&results._%sysfunc(putn(&sysparm.,z4.));
	run;

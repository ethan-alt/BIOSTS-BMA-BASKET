%macro cbhm_ab_calc(K0=4,rr=0.45 0.45 0.45 0.45 0.45,target=0.15,N=30,s2_b=1.0,s2_bb=100);


data sim(keep=scenario replicate T) ;
  call streaminit(1542541);
   n=&n.;
  array rr[&K0.] (&rr.);
  array n1[&K0.];
  array n0[&K0.];

  do scenario = 0 to %sysevalf(&K0.-1);

   if scenario > 0 then rr[scenario]=&target.;

  do replicate = 1 to 250000;

   n1tot = 0;
   n0tot = 0;
   ntot  = 0;

  do basket = 1 to dim(rr);
   n1[basket] = rand('binomial',rr[basket],n);
   n0[basket] = n-n1[basket];

   n1tot = n1tot + n1[basket];
   n0tot = n0tot + n0[basket];
   ntot  = ntot + n;
  end;

  if n0tot < ntot and n1tot < ntot then do;
	  E0 = n*n0tot/ntot;
	  E1 = n*n1tot/ntot;

	  T = 0;
	  do basket = 1 to dim(rr);
		 T = T + (n1[basket]-E1)**2/E1 + (n0[basket]-E0)**2/E0;
	  end;
  end;
  else T = 0;
  
  output sim;

  end;
  end;

  
 run;

 proc means data = Sim noprint;
  by scenario;
  var T;
  output out = summary median=med;
 run;

 data summary2;
  set summary end=last;

  if _n_ = 1 then do;
   H_bb = 100000000000;
   H_b  = 100000000000;
  end;

   retain H_bb h_b;

   if scenario = 0 then H_b = med;
   else do;
     if med < H_bb then H_bb = med;
   end;

   if last;

   keep H_b H_bb;
run;

%global a0 b0;
data cbhm_values;
 set summary2;
   s2_b  = &s2_b.;
   s2_bb = &s2_bb.;


   b = (log(s2_bb) - log(s2_b))/(log(h_bb)- log(h_b));

   a = log(s2_b) -  b*log(h_b);

   call symput('a0',strip(put(a,best.)));
   call symput('b0',strip(put(b,best.)));
run;



%put &=a0 &=b0;

%mend;

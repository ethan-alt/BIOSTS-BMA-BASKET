/*

	      submit;
	 	   proc freq data = freq_data noprint;
		    weight n;
		    table response*basket / fisher chisq(WARN=NONE);
			output fisher out = FishersExact;
		   run;
	   	  endsubmit;
*/


	      submit;
		  
		  data ID;
		   set freq_data;
		   keep ID;
		  run; 
		  
			 data freq_data;
			  set freq_data;
			  array _n[&K0.]n1-n&K0.;
			  array _y[&K0.]y1-y&K0.;
			  do basket = 1 to &K0.;
				resp = 1; wgt = _y[basket];            output;
				resp = 0; wgt = _n[basket]-_y[basket]; output;   
			  end;
			  drop n1-n&K0. y1-y&K0.;
			run;

			 proc freq data = freq_data noprint;
			  by id;
			  weight wgt;
			  table resp*basket / fisher chisq(WARN=NONE);
			  output fisher out = FishersExact;
			 run;
			 
			 data FishersExact;
			  merge ID(in=a) FishersExact(in=b);
			  by ID;
			   if a and not b then XP2_FISH = 1.0;
			 run;
	   	  endsubmit;
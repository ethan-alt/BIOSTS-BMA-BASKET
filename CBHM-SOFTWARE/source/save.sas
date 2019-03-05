   submit;
 
     proc datasets library=work noprint NOWARN;
	  save scenarios alldat;
	 run;
	 quit;
	  
   
   endsubmit;
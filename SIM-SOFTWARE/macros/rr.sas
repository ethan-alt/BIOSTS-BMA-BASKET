%macro rr(vList,nList);
 %let vCnt = %eval(%sysfunc(count(&vList.,|))+1);
 %do j = 1 %to &vCnt.;
 %do k = 1 %to %scan(&nList.,&j,|);
   %scan(&vList.,&j,|)  
 %end;
 %end;
%mend;
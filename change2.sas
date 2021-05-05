/*takes a data set and removes trailing blanks, shortening the fields, making the dataset smaller*/
%macro change
	(dsnin,   /*name of the input dataset*/
	dsnout);  /*name of the output dataset*/

*proc contents data=&dsnin;
*run;

data _null_;
  set &dsnin;
  array qqq(*) _character_;
  call symput('siz',put(dim(qqq),5.-L));
  stop;
run;

data _null_;
  set &dsnin end=done;
  array qqq(&siz) _character_;
  array www(&siz.);
  if _n_=1 then do i= 1 to dim(www);
    www(i)=0;
  end;
  do i = 1 to &siz.;
    www(i)=max(www(i),length(qqq(i)));
  end;
  retain _all_;
  if done then do;
    do i = 1 to &siz.;
      length vvv $50;
      vvv=catx(' ','length',vname(qqq(i)),'$',www(i),';');
      fff=catx(' ','format ',vname(qqq(i))||' '||
          compress('$'||put(www(i),3.)||'.;'),' ');
      call symput('lll'||put(i,3.-L),vvv) ;
      call symput('fff'||put(i,3.-L),fff) ;
    end;
  end;
run;

data &dsnout.;
  %do i = 1 %to &siz.;
    &&lll&i
    &&fff&i
  %end;
  set &dsnin;
run;
*proc contents data=&dsnout order=varnum; 
*run;
%mend;

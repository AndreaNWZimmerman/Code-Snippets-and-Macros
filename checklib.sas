/*
to clear a libref, pass just the name of the library and leave libpath blank

to assign a libref pass both the name of the libref and the path
it will not assign the libref if it already exists

If SAS can not assign the libref it will provide a warning in the log and the reason

*/
%macro checklib(libref=,  /**/
               libpath=); /**/
%local rc;
   %if &libpath= %then %do;
   %* Clear this libref;
      %let rc=%sysfunc(libname(&libref));
   %end;
   %else %if %sysfunc(libref(&libref)) ne 0 %then %do;
   %* Establish this libref;
      %let rc=%sysfunc(libname(&libref,&libpath));
      %put %sysfunc(sysmsg());
   %end;
   %else %do;
      %sysfunc(sysmsg());
      %put WARNING: LIBREF not reassigned;
   %end;
%mend checklib;


%macro chisq_tests(chisq_tests_dsn=, /*data set that contains the data*/
                   controlVar=,      /*the first field that you want compare everything to*/
                   testVars=);       /*space delim list of fields to compare to controlVar*/
    %if %sysfunc(indexc(&chisq_tests_dsn,'.'))>0 %then %do;
       %let lib=%scan(&chisq_tests_dsn,1,'.');
       %let dsn=%scan(&chisq_tests_dsn,2,'.');
    %end;/*&indsn contains '.'*/
    %else %do;
       %let lib=WORK;
       %let dsn=&chisq_tests_dsn;
    %end;/*&indsn does not contain '.'*/

%let testVarCnt=%sysfunc(countw(&testVars.,' '));

%do i=1 to &testVarCnt;

   %let testVar=%scan(&testVars,&i,' ');

   proc sql noprint;
      select upcase(substr(type,1,1)) into :type
      from sashelp.vcolumn
      where libname="%upcase(&lib)" and
      memname="%upcase(&dsn)" and
      upcase(name)="%upcase(&testVar)";
   quit;

   %if &type=C %then %let f=$;
   %else             %let f=;

   %new_sheet(&testVar);
   title "Chi Square Test for &test_var";
   proc freq data=&chisq_tests_dsn  ;
    table &controlVar*&testVar/ chisq;
    format &testVar &f.&testVar._.;
   run;
%end;
%mend chisq_tests;

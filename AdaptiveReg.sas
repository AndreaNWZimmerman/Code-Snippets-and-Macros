/*This asumes that it is running inside an ODS Excel block, it will create a new tab for the output of the AdaptiveReg procedure

It also needs an OUTPUT folder to have been created inside the path defined by the FOLDER macro paramter. It will write a text file there with
the SAS code to produce the predicted score

There needs to have been a macro variable called NOW established outside this macro. It establishes the date and time so all output of this 
run can be tied by this value, and each run of your code will have a new NOW value generated so nothing is overwritten.

I recommend the line:
%let now=%sysfunc(datetime(),B8601DT15.);

*/

%macro adaptiveReg(
dsn=,          /*data set to use for Adaptive Reg proc*/
mtrc=,         /*name of the variable you are trying to predict*/
mtrclbl,       /*english label for metric*/
dep_var=&mtrc, /*dependant variable for the AR proc; this may be "&mtrc./base" OPTIONAL*/
actual=,       /*name of the actual variable so we can compare the predicted values to it*/
var_list=,     /*space delim list of indep vars*/
class_vars=,   /*space delim list of class vars OPTIONAL*/
cohort=,       /*variable that defines your cohorts such as cohort_mth*/
rel_num=,      /*variable that is an integer indicating the amount of intervals that have passed whether days, months, etc.*/
lag_var=,      /*name of the lag variable being used, minus the number which should be at the end following an _*/
lag_num=1,     /*how much of a lag are you using, if you leave this blank it is assumed to be 1 and your lag_var should be ending with _1  OPTIONAL*/

armodelops=,   /*any AR model options you want OPTIONAL*/
folder=,       /*path to the output folder where the code text file will be written so it can be %inlcuded later*/
pred=N,        /*Y if you want a dataset scored with the model OPTIONAL*/
pred_dsn=,     /*data set to score the model against if you set pred=Y OPTIONAL*/
where=1);      /*where clause to limit the data you bring into adaptivereg OPTIONAL*/

%global method;
%let method=adaptiveReg;
%New_Sheet(&method)

proc adaptivereg data=&dsn(where=(&where))  details=bases plots = all namelen=30;
  ODS OUTPUT BASES=bases BWDPARAMS=parms;
  %if %symexist(class_vars)%then %do;
     %if %length(&class_vars)>0 %then %do;
        class &class_vars; /*there is a bug in SAS 9.4 SP3, class vars don't work well, should be fixed in SP4*/
     %end;
  %end;/*if macro var class_vars exists*/
  model &dep_var=&var_list &armodelops;
  output out = adaptivereg predicted = predicted;
  partition rolevar=group (train = 'T' validate='V');
run;

data adaptivereg;
set adaptivereg;
actual=&actual;       /* for each one we need the correct actual field for graphing  */
run;

/*create text files with scoring code*/
data bases2;
set bases;
length transformation2 $55. trans $500.;
   Transformation=TRANSTRN(COMPRESS(Transformation),"Basis0*",TRIMN(''));   /*remove basis0* since that's just multiplying by 1*/
   Transformation=TRANSTRN(Transformation,"--",'- -');                      /*Put a space back in when subtracting a negative for readability*/
   Transformation2=TRANSTRN(Transformation,"Basis",TRIMN('&Basis'));        /*make all other bases macros for the upcoming RESOLVE function*/
   call symput(name,strip(transformation2));                                /*store the code for each basis as a macro var*/
   trans=resolve(transformation2);                                          /*resolve all those macro vars*/
run;

DATA _NULL_;
     SET bases2 END=eof;
     FILE "&FOLDER.\output\&dsn._ARbases_&mtrclbl._&now..sas";
     PUT NAME '= ' trans '; '  ' LABEL '  NAME ' = "' TRANSFORMATION '";';  /*keeping original label due to 256 char limit*/
RUN;

PROC SORT DATA=bases2; 
          BY NAME; 
RUN;
PROC SORT DATA=parms; 
          BY NAME; 
RUN;

DATA _NULL_;
     MERGE bases2 parms(IN=parms); BY NAME; IF parms;
     FILE "&FOLDER.\OUTPUT\&dsn._ARscores_&mtrclbl._&now..sas";
     IF _N_ = 1 THEN PUT "predicted = 0;";
     PUT "predicted + " COEFFICIENT BEST16. ' * ' trans +(-1) ';';
RUN;

%if &pred=Y %then %do;
proc sort data=&pred_dsn;
by &cohort &rel_num;
run;

/*call that scoring code*/
data scored;
set   &pred_dsn;
by &cohort &rel_num;
retain pred_cum_&mtrc._rate;
if _n_=1 then do;
   declare hash coh(dataset: "&pred_dsn(where=(base=.))", 
                    ordered:'yes');/*may not need but can't hurt*/
   coh.definekey("&cohort","&rel_num");
   coh.definedata("&lag_var._&lag_num");/*DO NOT INCLUDE KEY, we don't want to overwrite &rel_num in our dataset*/
   coh.definedone();
end;/*if _n_=1*/

actual=&actual;       /* for each one we need the correct actual field for graphing  */

if first.&cohort then pred_cum_&mtrc._rate=0;

if &lag_var._&lag_num=. then do;/*only pull from HASH if not already filled in*/
   if &rel_num ne . then do;
      rc=coh.find(key: &cohort, key: &rel_num-1);/*pull from previous row*/
   end;
   else do;
      &lag_var._&lag_num=0;
   end;/*else do*/
end;/*if lag=.*/

/*%include scoring code*/
%inc "&FOLDER.\output\&dsn._ARbases_&mtrclbl._&now..sas";
%inc "&FOLDER.\OUTPUT\&dsn._ARscores_&mtrclbl._&now..sas";

/*fill in HASH object so the next obs can pull from it*/
if base=. then do;
   /*calculate rates and odds*/

   /*lag_&mtrc._rate*/
   if &mtrc._rate=. then &mtrc._rate=1/(1+exp(-predicted));

   /*lag_log_&mtrc._odds*/
   if log_&mtrc._odds=. then log_&mtrc._odds=predicted;

   /*lag_cum_&mtrc._rate*/
   pred_cum_&mtrc._rate=pred_cum_&mtrc._rate+&mtrc._rate;
   if cum_&mtrc._rate=. then cum_&mtrc._rate=pred_cum_&mtrc._rate;

   /*lag_log_cum_&mtrc._odds*/
   if log_cum_&mtrc._odds=. and 0<cum_&mtrc._rate<1 then log_cum_&mtrc._odds=log(cum_&mtrc._rate/(1-cum_&mtrc._rate));

   /*load rates and odds for this row to the hash object so they can be pulled for the next row*/
   rc=coh.replace(key: &cohort.,key: &rel_num, data: &mtrc._rate);
end;/*if base=.*/
else do;
   pred_cum_&mtrc._rate=pred_cum_&mtrc._rate+&mtrc._rate;
end;/*base ne .*/

drop rc pred_cum_&mtrc._rate basis:;
run;
%end;

%mend;

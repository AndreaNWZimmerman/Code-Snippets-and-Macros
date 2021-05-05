/*Sampling macro
takes a random sample from &inDSN and produces a new dataset called &outDSN that
has a new field group which will take on the values T for those rows in the training
data and V for those rows in the validation data*/

%macro sampling(
inDSN=,    /*starting dataset*/
outDSN=,   /*dataset to be created*/
binary=0,  /*set to 1 if the dependant var is binary and you want to sample down non events*/
dep_var=,  /*dependant variable; required only if you are sampling down non events*/
sampfrac=1,/*sampling rate for non events; value between 0 and 1; only used if binary=1*/
split=.5,  /*what ratio of the population (after sampling down non events) should be in the training data*/
seed=123); /*if you prefer a different seed, specify it here*/

data &outDSN;
  set &inDSN;
  %if &binary=1 %then %do;
   if &dep_var = 0 then do;
      if ranuni(&seed)<&sampfrac;
   end;/*if &dep_var=0*/
  %end;/*if &binary=1*/
    if ranuni(&seed)<&split then group='T';/*Train*/
      else group='V';/*validate*/
run;
%mend;

/*graphing the samples allows you to check for irregularities in the data*/

%macro sample_graph_summarized(
sampDSN=,   /*dataset with a field called GROUP that indicates the different samples and contains the dep_var and all ind_vars*/
dep_var=,   /*dependant variable*/
ind_var=all,/*space delim list of independant variables, if you want all fields other than the dep_var, leave it set as 'all'*/
var_excl=,  /*if in_var=all, this will a space delim list of fields to ignore, such as a key*/
path=,      /*path for the Excel output*/
file=);     /*name of the excel document*/

ods excel file="&path.\&file." options(sheet_name="Proc Freq");

proc freq data = &sampDSN;
tables group * &dep_var/missing list;*/chisq;
run;

%New_Sheet(Proc Means)

proc means data =&sampDSN nway noprint;
var  &dep_var;
class group;
output out=temp mean= ;
run;

proc print data=temp noobs;
run;

%New_Sheet(Scatter Plots)

%if "&ind_var"="all" %then %do;
/*check &outdsn to see if there is a . so I know if it is WORK or perm*/
    %if %sysfunc(indexc(&sampdsn,'.'))>0 %then %do;
       %let lib=%scan(&sampdsn,1,'.');
       %let dsn=%scan(&sampdsn,2,'.');
    %end;/*&outdsn contains '.'*/
    %else %do;
       %let lib=WORK;
       %let dsn=&sampdsn;
    %end;/*&outdsn does not contain '.'*/

%if %length(&var_excl)>0 %then %do;
   %let ex_cnt=%sysfunc(countw(&var_excl.,' '));
%end;

proc sql noprint;
select name into :ind_var
separated by ' '
from sashelp.vcolumn
where libname="%upcase(&lib)" and
memname="%upcase(&mem)"
%if %length(&var_excl)>0 %then %do;
   and
   upcase(name) not in (
   %do e=1 %to &ex_cnt;
      "%upcase(%scan(&var_excl,&e,' '))"
   %end;
)
%end;/*if len(var_excl)>0*/
;
quit;
%end;/*ind_var=all*/

/*loop over each var in ind_var list*/

%let var_cnt=%sysfunc(countw(&ind_var.,' '));

%do i=1 %to &var_cnt;
   proc sgplot data=&sampdsn;
      scatter x=%scan(&ind_var.,&i,' ') y=&dep_var./group=group transparency=.5 markerattrs=(symbol=circlefilled);
      reg x=%scan(&ind_var.,&i,' ') y=&dep_var./group=group nomarkers lineattrs=(thickness=2) cli clm;
         keylegend / title="Train vs Valid";
         xaxis grid;
         yaxis grid;
   run;
%end;/*i=1 to var_cnt*/

ods excel close;

%mend;

%macro new_sheet(name);
/* Add dummy table */

/*only needed in SP3, should go away with SP 4 if they add NEW_SHEET= functionality*/

ods excel options(sheet_name="&name" sheet_interval="table");

ods exclude all;
  data _null_;
    file print;
   put _all_;
run;
ods select all;

ods excel options(sheet_interval="none");
%mend;

/*   INCOMLETE CODE   */
/*we changed direction and wanted to sample the summarized data instead of the individual data
so I am setting this aside to work on that instead*/


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

%macro sample_graph_individual(
outDSN=,/*dataset created by sampling macro*/
dep_var=,/*dependant variable*/
ind_var=all,/*list of independant variables, if you want all fields other than the dep_var, leave it set as 'all'*/
path=,/*path for the Excel output*/
file=);/*name of the excel document*/

ods excel file="&path.\&file." options(sheet_name="Proc Freq");
proc freq data = &outDSN;
tables group * &dep_var/chisq;
run;

%New_Sheet(Proc Means)

proc means data =&outDSN nway noprint;
var  &dep_var;
class group;
output out=temp mean= ;
run;

proc print data=temp noobs;
run;

%New_Shet(Scatter Plots)
%if &ind_var=all %then %do;
/*code to generate list of all vars other than dep_var*/
%end;/*ind_var=all*/
/*loop over each var in ind_var list*/

proc sgplot;
   %do i=1 %to %num_vars;
      /*code to generate all the scatter plots*/
   %end;/*i=1 to num_vars*/
run;
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

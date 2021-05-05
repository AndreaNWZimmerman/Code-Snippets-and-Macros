/*** graphs a horizontal bar chart with reference lines for upper CI, lower CI, and the average. This was being used to compare test results to control ***/

%macro hbar_plot(
dsn=,       /*data set name*/
mtrclbl=,   /*label for the titles of the metric being plotted*/
mtrc=,      /*variable name of the metric being plotted*/
ctrl_lcl=,  /*field name in &dsn that contains the lcl for the control group*/
ctrl_avg=,  /*field name in &dsn that contains the avg for the control group*/
ctrl_ucl=,  /*field name in &dsn that contains the ucl for the control group*/
by=,        /*by variable*/
byformat=,  /*format to apply to the by variable OPTIONAL*/
y_var=,     /*the variable for the y axis*/
alpha=.05,  /*alpha for the confidence intervals OPTIONAL*/
value=,     /*value of the by variable*/
where=1,    /*where clause to limit the data for this graph OPTIONAL*/
integer=0,  /*set to 1 if you aren't working with percents and you want the x axis ticks to be integer values OPTIONAL*/
min=,       /*the min value for the x axis OPTIONAL*/
max=);      /*the max value for the x axis OPTIONAL*/

ods graphics / imagename="HBAR_Treat_Control_&mtrc.";

proc sgplot data=&dsn(where=(&where.));
title "&mtrclbl Rates by Message";
title2 "&by.=&value";
  hbar &y_var / response=&mtrc stat=mean limits=both alpha=&alpha categoryorder=respdesc name='trt';* baseline=.2;
  refline &ctrl_lcl./axis=x legendlabel='Control 95% Confidence Intervals of &mtrclbl' lineattrs=(color=red pattern=dot) name='lcl';
  refline &ctrl_avg./axis=x legendlabel='Control Avg. &mtrclbl' lineattrs=(color=red) name='cont';
  refline &ctrl_ucl./axis=x  lineattrs=(color=red pattern=dot) ;
  keylegend 'trt' 'cont' 'lcl' /across=1;
  yaxis display=(NOLABEL);
  xaxis %if &integer %then %do; integer %end;
    %if %length(&min)>0 %then %do;
       min=&min
    %end;
    %if %length(&max)>0 %then %do;
       max=&max
    %end;
       display=(NOLABEL) THRESHOLDMIN=0.5 THRESHOLDMAX=0;
    %if %length(&byformat)>0 %then %do;
       format &by &byformat;
    %end;
  run;

%mend;

/*** Calculated min and max for the axis so more detail could be seen ***/
%macro hbar_plot_min_max(
dsn=,       /*data set name*/
mtrclbl=,   /*label for the titles of the metric being plotted*/
mtrc=,      /*variable name of the metric being plotted*/
ctrl_lcl=,  /*field name in &dsn that contains the lcl for the control group*/
ctrl_avg=,  /*field name in &dsn that contains the avg for the control group*/
ctrl_ucl=,  /*field name in &dsn that contains the ucl for the control group*/
by=,        /*by variable*/
byformat=,  /*format to apply to the by variable OPTIONAL*/
y_var=,     /*the variable for the y axis*/
alpha=.05,  /*alpha for the confidence intervals OPTIONAL*/
integer=0,  /*set to 1 if you aren't working with peercents and you want the x axis ticks to be integer values OPTIONAL*/
round_to=1, /*only considered if integer=0, power of 10 that you want rounding to (10, 100, .1, .01,etc) OPTIONAL*/
min_cal=1,  /*If you want to calculate the min rather than let SAS do the default, set this to 1*/
max_cal=1); /*If you want to calculate the max rather than let SAS do the default, set this to 1*/

proc sort data=&dsn out=sorted;
by &by &y_var;
run;

proc summary data=sorted nway alpha=&alpha;
   by &by &y_var; /*get upper and lower limits*/
   var &mtrc;
   output out=_summ(drop=_TYPE_ _FREQ_) lclm=lcl uclm=ucl;
run;

/*for each value of by get the min_lcl, max_ucl and the value*/
proc sql noprint;
select unique &by, min(lcl), max(ucl)
into :by_val1-, :by_min1-, :by_max1-
from _summ
group by &by;
%let num_by=&sqlobs;
quit;

%do i=1 %to &num_by;

%if &integer %then %do;

   %if &min_cal %then %do;
      %let min=%sysfunc(floor(&&by_min&i));
   %end;
   %else %do;
      %let min=;%put min=&min;
   %end;

   %if &max_cal %then %do;
      %let max=%sysfunc(ceil(&&by_max&i));
   %end;
   %else %do;
      %let max=;
   %end;
%end;/*if integer*/
%else %do;/*calculate so we can round to decimal places or multiples of 10*/
   %if &min_cal %then %do;
      %let min=%sysevalf(%sysfunc(floor(%sysevalf(&&by_min&i/&round_to)))*&round_to);%put min=&min;
   %end;
   %else %do;
      %let min=;%put min=&min;
   %end;

   %if &max_cal %then %do;
      %let max=%sysevalf(%sysfunc(ceil(%sysevalf(&&by_max&i/&round_to)))*&round_to);%put max=&max;
   %end;
   %else %do;
      %let max=;%put max=&max;
   %end;
%end;/*if not integer*/

%hbar_plot(dsn=&dsn,mtrclbl=&mtrclbl,mtrc=&mtrc,ctrl_lcl=&ctrl_lcl,ctrl_avg=&ctrl_avg,ctrl_ucl=&ctrl_ucl,y_var=&y_var,by=&&by_val&i,byformat=&byformat,value=&&by_val&i, where=&by="&&by_val&i",  min=&min, max=&max)

%end;/*i=1 to num_by*/
%mend;

/*** example macro call ***/
%hbar_plot_min_max(
dsn=combined,
mtrclbl=Cum Churn,
mtrc=cum_churn,
ctrl_lcl=control_cum_churn_lcl,
ctrl_avg=control_cum_churn_avg,
ctrl_ucl=control_cum_churn_ucl,
by=tenure_days_form,
y_var=offer,
alpha=.05,
integer=0,
round_to=.01,
min_cal=1,
max_cal=1)


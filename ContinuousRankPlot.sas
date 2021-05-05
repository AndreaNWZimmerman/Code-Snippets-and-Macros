/* Rank and Plot Macro */
%macro ContinuousRankPlot(
I_VAR,    /*Independant Variable (X axis)*/
GROUPS,   /*How many groups? Higher numbers make mean more granularity; OPTIONAL but you must have this or a format*/
FORMAT,   /*name of the format to apply to the I_VAR to determine the number of GROUPS; OPTIONAL but you must have GROUPS or FORMAT; if you provide both FORMAT will be used instead*/
DEP_VAR,  /*Dependant Variable (Y axis)*/
IND_OUT,  /*Input Data set name*/
grp,      /*Variable name for where statement (where &grp=&val)*/
val,      /*Value to go with the above variable (where &grp=&val)*/
off,      /*Variable name for where statement (where &off in (0,&val_off))*/
val_off,  /*Value to go with the above variable (where &off in (0,&val_off))*/
whisk=N,  /*N gets a band plot, Y gets whisker plot instead OPTIONAL*/
alph=.05);/*alpha for proc summary OPTIONAL*/
  %LOCAL I_VAR GROUPS DEP_VAR IND_OUT;
  %if %length(&format)=0 %then %do;
     ** Run PROC RANK on I_VAR, sort, summarize data and calculate log odds                                                     ;
     PROC RANK DATA=&IND_OUT.(KEEP=&I_VAR. &DEP_VAR. &grp. &off. offer trtmnt_ctrl_ind where=(&grp = &val and &off in (0, &val_off))) GROUPS=&groups OUT=RANK ties=/*dense*/ low /*high*/;
     TITLE2 "&I_VAR. GROUPED BY PROC RANK";
          VAR &I_VAR.;
          RANKS r&I_VAR.;
     RUN;
  %end;
  %else %do;
     data RANK;
     set &IND_OUT.(KEEP=&I_VAR. &DEP_VAR. &grp. &off. offer trtmnt_ctrl_ind where=(&grp = &val and &off in (0, &val_off)));
     r&I_VAR=put(&I_VAR,&FORMAT..);
     run;
  %end;
  PROC SORT DATA=RANK;
  BY trtmnt_ctrl_ind r&I_VAR.;
  RUN;

  proc sql noprint;
  select offer into :_offer_text
  from rank
  where offer ne "Control";
  quit;

  PROC SUMMARY DATA=RANK alpha=&alph.;
  VAR &DEP_VAR. &I_VAR.;
  BY trtmnt_ctrl_ind r&I_VAR.;
  OUTPUT OUT=TEMP(DROP=_TYPE_ _FREQ_) N(&I_VAR.)= N(&DEP_VAR.)= LCLM(&DEP_VAR.)= MEAN(&DEP_VAR.)= UCLM(&DEP_VAR.)= MEAN(&I_VAR.)=  MIN(&I_VAR.)=  MAX(&I_VAR.)=/AUTONAME ;
  RUN;

     ** Define GTL graph template for scatter plots with distributions and PROC SGSCATTER for general spline fit                ;
  PROC TEMPLATE;
    Define StatGraph PointEstScatter;
      Dynamic I_VAR;
      BeginGraph /;
      %if %length(&format)=0 %then %do;
         EntryTitle eval(propcase(colLabel(&DEP_VAR._Mean))) " by " eval(upcase(&I_VAR.)) " GROUPS=&GROUPS. / Offer = &_offer_text.";
      %end;
      %else %do;
         EntryTitle eval(propcase(colLabel(&DEP_VAR._Mean))) " by " eval(upcase(&I_VAR.)) " Proposed Cuts / Offer = &_offer_text.";
      %end;
        Layout Lattice  /
                         Columns=2
                         Rows=2
                         ColumnWeights=(0.8 0.2)
                         RowWeights=(0.8 0.2)
                         ColumnDataRange=Union
                         RowDataRange=Union;
           ColumnAxes;
                   ColumnAxis / GridDisplay = on;
                   ColumnAxis /Label = '' GridDisplay = on;
           EndColumnAxes;
           RowAxes;
                   RowAxis /GridDisplay = on;
                   RowAxis /Label = '' GridDisplay = on;
           EndRowAxes;
          Layout Overlay;
           %if &whisk=N %then %do;
              ModelBand "clmband" /  display=all datatransparency=0.7;
              ScatterPlot X=I_VAR Y=&DEP_VAR._Mean / MARKERATTRS=(WEIGHT=BOLD) group=trtmnt_ctrl_ind name="s";
              LoessPlot   X=I_VAR Y=&DEP_VAR._Mean/clm="clmband" smooth = 1 group=trtmnt_ctrl_ind;
           %end;/*whisk=N*/
           %else %do;
              ScatterPlot X=I_VAR Y=&DEP_VAR._Mean /YERRORLOWER=&DEP_VAR._LCLM YERRORUPPER=&DEP_VAR._UCLM 
                                                    XERRORLOWER=&I_VAR._Min    XERRORUPPER=&I_VAR._Max
                                                    ERRORBARCAPSHAPE=NONE 
                                                    DATATRANSPARENCY=0.2
                                                    MARKERATTRS=(WEIGHT=BOLD) group=trtmnt_ctrl_ind name="s";
           %end;/*whisk ne N*/
           discretelegend "s"/location= inside title="TvC:" autoalign=(topleft);
          EndLayout;
          Histogram &DEP_VAR._Mean/freq=&dep_VAR._N datatransparency=0.7 group=trtmnt_ctrl_ind orient = horizontal;
          Histogram I_VAR         /freq=&I_VAR._N   datatransparency=0.7 group=trtmnt_ctrl_ind;
        EndLayout;
      EndGraph;
   End;
  RUN;
  PROC SGRENDER DATA=TEMP TEMPLATE=PointEstScatter; 
                DYNAMIC  I_VAR="&I_VAR._Mean" ;
  RUN;
%mend ContinuousRankPlot;

/*only needed in SP 3, should go away with SP 4 if they add NEW_SHEET= functionality*/

%macro new_sheet(name,color);
/*name is the name of the new tab (no quotes needed)
color is the color of the tab OPTIONAL*/

ods excel options(sheet_name="&name" sheet_interval="table"
%if %length(&color)>0 %then %do;
tab_color="&color"
%end;

);
/* Add dummy table */
ods exclude all;
  data _null_;
    file print;
   put _all_;
run;
ods select all;

ods excel options(sheet_interval="none");
%mend;
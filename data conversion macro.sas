/*This macro takes an input dataset, examine all fields stored as char, examines the to see if there are chars other than digits,
  then converts fields that are only numbers to true numeric fields, with the same fiel name
  It also converts fields that are just Y/N/missing to 1/0/. so they too are numeric and can be examined as numbers*/

%macro conversion(lib,dsn);

data temp_vars;
   set sashelp.vcolumn(keep=libname memname type length name);
   if libname=upcase("&lib") and memname=upcase("&dsn") and type='char';;
run;

proc sql noprint;
   select count(name) into :num_char from temp_vars;
   select name into :c_var1 thru :c_var9999999 from temp_vars;
quit;

data temp_char;/*only char vars here*/
set &lib..&dsn(keep=
%do i=1 %to &num_char;
   &&c_var&i
%end;
);
/*first pass, look for fields that are all numbers*/

/*create a 1/0 indicator as to if the record contains a letter or not*/
%do i=1 %to &num_char;
   &&c_var&i.._i=anyalpha(&&c_var&i);
%end;
run;

/*sum the columns*/
proc sql noprint;
create table char_sums as
select 
%do i=1 %to &num_char;
   sum(&&c_var&i.._i) as &&c_var&i,
%end;
1 as junk
from temp_char;
quit;

proc transpose data=char_sums out=temp_names;
run;
/*sort out those that are all num from those that need more work*/
data num_names char_names;
set temp_names;
if _name_ ne 'junk';
if col1=0 then output num_names;
else output char_names;
drop col1;
run;

/*for those that are char, find the ones that are only Y/N/null*/
proc sql noprint;
   select count(_name_) into :num_tchar from char_names;
   select _name_ into :tc_var1 thru :tc_var9999999 from char_names;
quit;

data temp_YNs;
set temp_char(keep=
%do i=1 %to &num_tchar;
&&tc_var&i
%end;
);

%do i=1 %to &num_tchar;
&&tc_var&i.._i=&&tc_var&i not in ('Y', 'N', '');/*if it is Y/N/null I want 0 so I can sum up and find columns that total 0*/
%end;

run;

proc sql noprint;
create table YN_sums as
select
%do i=1 %to &num_tchar;
sum(&&tc_var&i.._i) as &&tc_var&i,
%end;
1 as junk
from temp_yns;
quit;

proc transpose data=YN_sums out=temp_names;
run;

/*sort out those that are all num from those that need more work*/
data YN_names char_names;
set temp_names;
if _name_ ne 'junk';
if col1=0 then output YN_names;
else output char_names;
drop col1;
run;

/*see if there are any fields that are really unexpected*/
proc sql noprint;
   select count(_name_) into :issues from char_names;
   select _name_ into :f_var1 thru :f_var9999999 from char_names;
quit;

%if &issues %then %do;
   data _null_;
   put '*******************************';
   put '*******************************';
   put '*******************************';
   put 'there are issues with char data';
     %do i=1 %to &issues;
   put "&&f_var&i";
     %end;
   put '*******************************';
   put '*******************************';
   put '*******************************';
   run;
%end;


proc sort data=temp_vars;
by name;
run;

proc sort data=num_names;
by _name_;
run;

data temp;
merge num_names (in=want rename=(_name_=name))
      temp_vars (keep=name length);
if want;
by name;
run;

proc sql noprint;
   select count(name) into :num_c2n from temp;
   select name   into :c2n_var1 thru :c2n_var9999999 from temp;
   select length into :c2n_len1 thru :c2n_len9999999 from temp;

   select count(_name_) into :num_yn from yn_names;
   select _name_ into :yn_var1 thru :yn_var9999999 from yn_names;

quit;

/*convert char to numeric where applicable*/
data &lib..&dsn;
set &lib..&dsn (rename=(
%do i=1 %to &num_c2n;
  &&c2n_var&i = temp&i
%end;

/*y/n's*/
%do i=1 %to &num_yn;
  &&yn_var&i = temp_yn_&i
%end;
));


%do i=1 %to &num_c2n;
   &&c2n_var&i = input(temp&i,&&c2n_len&i...);
%end;

/*y/n's*/

%do i=1 %to &num_yn;
        if temp_yn_&i="Y" then &&yn_var&i =1;
   else if temp_yn_&i="N" then &&yn_var&i =0;
   else if temp_yn_&i=""  then &&yn_var&i =.;
%end;

drop temp:;
run;

%mend;

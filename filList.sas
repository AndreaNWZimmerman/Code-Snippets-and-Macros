/*might not be usable in this form, but if you want to do something to every file in a folder, this is the template you would use

at present it makes a list of all .sas files in the folder but this could be easily changed*/

%macro filList(filerf=);
%local rc fid i fname;
%let fid = %sysfunc(dopen(&filerf));
%if &fid %then %do i = 1 %to %sysfunc(dnum(&fid));
   %let fname= %sysfunc(dread(&fid,&i));
   %if %upcase(%qscan(&fname,-1,.))=SAS %then %put &fname;
%end;
%let fid = %sysfunc(dclose(&fid));
%mend fillist;


filename saspgms 'c:\temp';
%fillist(filerf=saspgms)
filename saspgms clear;

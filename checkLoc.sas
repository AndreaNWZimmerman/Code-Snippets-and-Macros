/*
this macro will see if the DirName is a folder in DirLoc and will create it if it doesn't exist.

This macro passes back the full path in either case so it can be used inside code where you would normally put a path 

example:
libname temtest "%checkloc(dirloc=c:\temp, dirname=test)";

*/
%macro CheckLoc(DirLoc=,   /*path before the final folder*/
                DirName=); /*name of the final folder*/

%* if the directory does not exist, make it;
%if %sysfunc(fileexist("&dirloc\&dirname"))=0 %then %do;
   %put Create the directory: "&dirloc\&dirname";
   %* Create the directory;
   %sysfunc(dcreate(&dirname,&dirloc))
%end;
%else %do;
   %put The directory "&dirloc\&dirname" already exists;
   &dirloc\&dirname
%end;
%mend checkloc;

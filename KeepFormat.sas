/*To use, put the following SAS line in your very next dataset to keep only those records where
the key field has a value also found in the dsn_key dataset

(can be a WHERE clause on a SET statement or an IF statement within a datastep)
WHERE=((put(key_field,$key.)='Y'))

substituting your key for the key_field inside the inner most ()

Pleae note you can call this macro several times but it will get replaced each time so call it, 
then use it before calling it again*/
%macro KeepFormat(
dsn_key=, /*SAS dataset that contains only the rows of the key field that*/
          /*you want to keep*/
key=,     /*field in dsn_key that is unique and identifies the rows*/
sample=1) /*if you wish to take a random sample, give the proportion between 0 and 1*/
          /*if you provide no parameter it will default to the whole file*/
 / store source;

DATA _fmt(RENAME=(&key=start))/VIEW=_fmt;
 RETAIN fmtname 'key'
        type 'C'
        label 'Y';
 SET &dsn_key(KEEP=&key) END=eof;
 BY &key;
 %* Selection criteria,random, unique, etc.;
 IF FIRST.&key;
 IF RANUNI(0)<=&sample
    THEN OUTPUT;
 IF eof THEN DO;
  HLO='O';
  label='N';
  OUTPUT;
 END;
RUN;

PROC FORMAT CNTLIN=_fmt(obs=max);
RUN;
%mend;

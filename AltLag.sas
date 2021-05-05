/*this needs to be run inside a datastep and the data needs to have been sorted by the time variable*/

%macro AltLag(
var=,    /*name of variable that is being lagged*/
trans=,  /*value at which the transition happens*/
timeVar=,/*name of variable that */
f=,      /*lag amount before timeVar=trans (and when it equals it)*/
l=);     /*lag amount after timeVar=trans*/

_1stlag&var=lag&f(&var);
_2ndlag&var=lag&l(&var);

if &timeVar<=&trans then 
     AltLag&var=_1stlag&var;
else AltLag&var=_2ndlag&var;

%mend;

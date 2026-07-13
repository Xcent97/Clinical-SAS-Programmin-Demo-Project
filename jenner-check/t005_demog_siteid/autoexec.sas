/* cap input rows for the captured run */
options obs=100;

/* Stand-in for RAW.DEMOGRAPHIC: the demog derivation reads only the numeric
   SUBJECT column, so a small sample of subject numbers across sites is enough
   to exercise the SITEID / SUBJID / USUBJID logic. */
data raw_demographic;
	input Subject;
	datalines;
101
102
205
310
407
;
run;

/* cap input rows for the captured run */
options obs=100;

/* Stand-in for RAW.DOSING: the dosedt_fix step reads a full date plus its
   day/month/year parts for start and end, to recover partial dates. The four
   sample rows cover a complete date, a year-only partial, a year+month partial,
   and a fully missing date. */
data raw_dosing;
	informat startdt enddt yymmdd10.;
	input subject startdt startdd startmm startyy enddt enddd endmm endyy;
	format startdt enddt yymmdd10.;
	datalines;
101 2021-01-15 15 1 2021 2021-03-20 20 3 2021
102 . . . 2021 . . . 2021
205 . . 6 2020 . . 9 2020
310 . . . . . . . .
;
run;

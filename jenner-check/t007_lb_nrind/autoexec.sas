/* cap input rows for the captured run */
options obs=100;

/* Stand-in for the standardized lab rows the LB derivation works on: the
   LBNRIND rule reads LBTESTCD, LBCAT, LBORRES and the standardized numeric
   result/limits. The sample rows cover a positive and a negative urine glucose,
   a below-range hemoglobin, an above-range albumin, and an in-range AST. */
data lb_std;
	length LBTESTCD $8 LBCAT $40 LBORRES $200;
	input LBTESTCD $ LBCAT $ LBORRES $ LBSTRESN LBSTNRLO LBSTNRHI;
	datalines;
GLUC URINALYSIS POSITIVE . . .
GLUC URINALYSIS NEGATIVE . . .
HGB CHEMISTRY 11.2 11.2 13.5 17.5
ALB CHEMISTRY 5.6 5.6 3.5 5.0
AST CHEMISTRY 25 25 10 40
;
run;

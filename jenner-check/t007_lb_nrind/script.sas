/* From SAS_Project.sas: the LBNRIND (Reference Range Indicator) derivation
   from the SDTM LB domain. Urine glucose is graded by its POSITIVE/NEGATIVE
   result; every other analyte is compared against its standardized low/high
   limits (rounded to 1e-7) to flag LOW, HIGH or NORMAL. The nested if/else
   chain is unchanged; the standardized lab rows are supplied from the autoexec
   as lb_std. */

data lb_ind;
	set lb_std;
	if LBTESTCD = 'GLUC' and LBCAT = 'URINALYSIS' and LBORRES = 'POSITIVE' then LBNRIND = 'HIGH';
	else if LBTESTCD = 'GLUC' and LBCAT = 'URINALYSIS' and LBORRES = 'NEGATIVE' then LBNRIND = 'NORMAL';
	else if LBSTNRLO ne . and LBSTRESN ne . and round(LBSTRESN,.0000001) < round(LBSTNRLO,.0000001) then LBNRIND = 'LOW';
	else if LBSTNRHI ne . and LBSTRESN ne . and round(LBSTRESN,.0000001) > round(LBSTNRHI,.0000001) then LBNRIND = 'HIGH';
	else if LBSTNRHI ne . and LBSTRESN ne . then LBNRIND = 'NORMAL';
run;

proc print data=lb_ind;
	var lbtestcd lbcat lborres lbstresn lbstnrlo lbstnrhi lbnrind;
run;

/* From SAS_Project.sas: the dosedt_fix DATA step that builds character
   START/LAST dosing dates able to hold both complete and partial dates. When
   the full date is present it renders yymmdd10.; when only the year is present
   it keeps the 4-digit year; when year and month are present it renders
   YYYY-MM with z2. zero-padding. The conditional logic is unchanged; RAW.DOSING
   is supplied from the autoexec as raw_dosing. */

proc sort data=raw_dosing out=dose_sort;
	by subject;
run;

/* Created "startdate" and "lastdate" character columns to capture both Complete and Partial Dates */
data dosedt_fix;
	set dose_sort;
	by subject;
	length startdate lastdate $16;
	/* The "if-then, else if-then" conditional statement is used to capture the Partial Dates */
	if ^missing(startdt) then startdate=put(startdt, yymmdd10.);
	else if missing(startdt) and missing(startdd) and missing(startmm) and missing(startyy) then startdate=" ";
	else if missing(startdt) and missing(startdd) and missing(startmm) then startdate=put(startyy, 4.);
	else if missing(startdt) and missing(startdd) then startdate=cats(put(startyy, 4.), '-', put(startmm, z2.));
	else startdate=" ";
	if ^missing(enddt) then lastdate=put(enddt, yymmdd10.);
	else if missing(enddt) and missing(enddd) and missing(endmm) and missing(endyy) then lastdate=" ";
	else if missing(enddt) and missing(enddd) and missing(endmm) then lastdate=put(endyy, 4.);
	else if missing(enddt) and missing(enddd) then lastdate=cats(put(endyy, 4.), '-', put(endmm, z2.));
	else startdate=" ";
run;

proc print data=dosedt_fix;
	var subject startdate lastdate;
run;

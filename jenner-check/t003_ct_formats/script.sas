/* From SAS_Project.sas: the custom numeric formats that decode the coded
   demographics and treatment-arm values for the SDTM DM domain. The source
   stores these permanently in the CTFMT library (lib=ctfmt); here they build
   in WORK and FMTLIB prints the definitions so the run is self-contained.
   The VALUE definitions are unchanged. */

/* Used 'PROC FORMAT' statement with 'FMTLIB' option to create and check the custom formats */
/* Created Custom Formats for variables SEX, RACE, ARM and ARMDC */
proc format fmtlib;
	value sex 1="M" 2="F" .="U";
	value race 1="WHITE" 2="BLACK OR AFRICAN AMERICAN" 3="ASIAN";
	value arm 1="Analgezia HCL 30 mg" 0="Placebo";
	value armcd 1="ALG123" 0="PLACEBO";
run;

/* Apply the formats to a few coded values the way the DM step does with PUT() */
data dm_decoded;
	length raw_sex 8 raw_race 8 raw_trt 8;
	input raw_sex raw_race raw_trt;
	SEX=put(raw_sex, sex.);
	RACE=put(raw_race, race.);
	ARM=put(raw_trt, arm.);
	ARMCD=put(raw_trt, armcd.);
	datalines;
1 1 1
2 3 0
. 2 1
;
run;

proc print data=dm_decoded;
	var raw_sex sex raw_race race raw_trt arm armcd;
run;

/* From SAS_Project.sas: the empty-shell DATA step for the SDTM EX (Exposure)
   domain. This one uses the ATTRIB statement to declare each column's length
   and label in a single pass, then STOP to emit the structure with no rows.
   The empshell library is written to WORK so the step is self-contained;
   the attribute list is unchanged from the source. */

/* Empty shell "empty_ex" was created for the structure of "EX" dataset as per CDISC guidelines */
data empty_ex;
	attrib
		STUDYID		length=$15	label="Study Identifier"
		DOMAIN 		length=$2	label="Domain Abbreviation"
		USUBJID 	length=$25	label="Unique Subject Identifier"
		EXSEQ 		length=8	label="Sequence Number"
		EXTRT 		length=$200 label="Name of Actual Treatment"
		EXDOSE 		length=8 	label="Dose"
		EXDOSU 		length=$40 	label="Dose Units"
		EXDOSFRM	length=$80 	label="Dose Form"
		EPOCH 		length=$40 	label="Epoch"
		EXSTDTC 	length=$16	label="Start Date/Time of Treatment"
		EXENDTC		length=$16	label="End Date/Time of Treatment"
		EXSTDY 		length=8 	label="Study Day of Start of Treatment"
		EXENDY 		length=8 	label="Study Day of End of Treatment";
	stop;
run;

/* Confirm the shell has the expected column structure */
proc contents data=empty_ex;
run;

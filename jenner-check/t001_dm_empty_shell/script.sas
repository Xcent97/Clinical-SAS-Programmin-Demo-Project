/* From SAS_Project.sas: the empty-shell DATA step for the SDTM DM domain.
   Built with LENGTH + LABEL + STOP so it produces the domain structure with
   zero rows. The empshell library is written to WORK so the step is
   self-contained; the variable list, lengths and labels are unchanged. */

/* Created Empty Shell "EMPTY_DM" for "DM" domain using "LENGTH" and "LABEL" Statement */
data empty_dm;
	length
		STUDYID $15 DOMAIN $2 USUBJID $25 SUBJID $7 RFSTDTC $16 RFENDTC $16
		RFXSTDTC $16 RFXENDTC $16 RFICDTC $16 RFPENDTC $16 DTHDTC $16 DTHFL $2
		SITEID $7 BRTHDTC $16 AGE 8 AGEU $10 SEX $2 RACE $80 ARMCD $8 ARM $40
		ACTARMCD $8 ACTARM $40 ARMNRS $40 ACTARMUD $40 COUNTRY $3;
	label
		STUDYID="Study Identifier"
		DOMAIN="Domain Abbreviation"
		USUBJID="Unique Subject Identifier"
		SUBJID="Subject Identifier for the Study"
		RFSTDTC="Subject Reference Start Date/Time"
		RFENDTC="Subject Reference End Date/Time"
		RFXSTDTC="Date/Time of First Study Treatment"
		RFXENDTC="Date/Time of Last Study Treatment"
		RFICDTC="Date/Time of Informed Consent"
		RFPENDTC="Date/Time of End of Participation"
		DTHDTC="Date/Time of Death"
		DTHFL="Subject Death Flag"
		SITEID="Study Site Identifier"
		BRTHDTC="Date/Time of Birth"
		AGE="Age"
		AGEU="Age Units"
		SEX="Sex"
		RACE="Race"
		ARMCD="Planned Arm Code"
		ARM="Description of Planned Arm"
		ACTARMCD="Actual Arm Code"
		ACTARM="Description of Actual Arm"
		ARMNRS="Reason Arm and/or Actual Arm is Null"
		ACTARMUD="Description of Unplanned Actual Arm"
		COUNTRY="Country";
	stop; /* Used "STOP" statement to stop the execution of the Data Step and creation of a blank data row */
run;

/* Confirm the shell has the expected column structure */
proc contents data=empty_dm;
run;

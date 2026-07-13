/* From SAS_Project.sas: the demog DATA step that derives SITEID, SUBJID and
   USUBJID from the raw SUBJECT number. The SITEID logic divides SUBJECT by 100
   (one site per 100 participants), keeps the quotient and appends "00"; USUBJID
   is the concatenation of STUDYID + SITEID + SUBJID. The derivation is
   unchanged; RAW.DEMOGRAPHIC is supplied from the autoexec as raw_demographic. */

/* Created "SITEID" and "SUBJID" from "Subject" column using specific logic */
data demog;
	set raw_demographic;
	length StudyID $15 SiteID $7 SUBJID $7 USUBJID $25;
	StudyID="XYZ123";
	SUBJID=put(Subject, 3.);
	if ^missing(subject) then SiteID=cats(substr((put(int(subject/100), 7.)), 1), '00');
	else SiteID="NA";
	/* This method divides the subject value by 100 (each site has 100 participants) */
	/* the quotient is converted to character and "00" is appended to form SITEID */
	USUBJID=cats(STUDYID, SITEID, SUBJID);
run;

proc print data=demog;
	var subject studyid siteid subjid usubjid;
run;

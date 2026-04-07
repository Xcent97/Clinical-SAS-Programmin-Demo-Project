/* The path for the physical location or folder of the raw data will depend on the folders' location of the system */
/* Used %LET macro statement to create a Universal Macro Variable "pathcl" which contains the Project Path as Value  */
%let pathcl=/home/u63717639/SAS_Project/Clinical_Trials;


/*************************************    SDTM Part ***********************************************/


/* Created LIBRARY "RAW" to access the RAW SAS datasets for the Clinical Trial using "LIBNAME" statement */
libname raw "&pathcl/Raw_Data";

/* Created LIBRARY "EMPSHELL" to access the "Empty Shells" for "SDTM" Domains for the Clinical Trial using "LIBNAME" statement */
libname empshell "&pathcl/SDTM/empty_shells";

/* Created LIBRARY "SDTM" to access the "SDTM" Domains datasets for the Clinical Trial using "LIBNAME" statement */
libname SDTM "&pathcl/SDTM";

/* Created LIBRARY "CTFMT" to store custom formats permanently in Formats folder */
libname ctfmt "&pathcl/formats";

/* Used "Options FMTSEARCH=" global statement to direct SAS to seach other libraries for formats */
options fmtsearch=(ctfmt);

/* Used "PROC CONTENTS" to explore and understand the contents of source datasets or table */
proc contents data=raw.demographic;
run;
proc contents data=raw.adverse;
run;
proc contents data=raw.dosing;
run;
proc contents data=raw.labs;
run;

/* Used "PROC SORT" with "NODUPKEY option" to check duplicate records as only ONE RECORD is permitted for each patient in 'SDTM.DM' Domain */
proc sort data=raw.demographic out=demo_check nodupkey dupout=demo_dup;
	by _all_;
run;

/* Created Empty Shell "EMPTY_DM" for "DM" domain using "LENGTH" and "LABEL" Statement */
data empshell.empty_dm;
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

/* Used 'PROC FORMAT' statement with 'LIB=' and 'FMTLIB' options to create, check and save the custom formats in a folder permanently  */
/* Created Custom Formats for variables SEX, RACE, ARM and ARMDC */
proc format lib=ctfmt fmtlib;
	value sex 1="M" 2="F" .="U";
	value race 1="WHITE" 2="BLACK OR AFRICAN AMERICAN" 3="ASIAN";
	value arm 1="Analgezia HCL 30 mg" 0="Placebo";
	value armcd 1="ALG123" 0="PLACEBO";
run;

/* Created "SITEID" and "SUBJID" from "Subject" column of "RAW.DEMOGRAPHIC" table using specific logic */
data demog;
	set raw.demographic;
	length StudyID $15 SiteID $7 SUBJID $7 USUBJID $25;
	StudyID="XYZ123";
	SUBJID=put(Subject, 3.);
	if ^missing(subject) then SiteID=cats(substr((put(int(subject/100), 7.)), 1), '00');
	else SiteID="NA";
	/* This method is dividing the subject value with 100 considering each site is having 100 participants */
	/* and the quotient is converted to Character and "00" is added behind to create the "SiteID" variable */
	
	/* OR Other Method is taking the value and replacing the last two digits/characters with "00" */
	/* 		if ^missing(subject) then SiteID= cats(substr(put(subject,7.),1,length(put(subject,7.))-2),'00'); */
	/* 		else SiteID='NA'; */
	
	/* OR Other method is Hard Coding the values */
	/* if SUBJID >= 700 then SiteID="700"; */
	/* else if Subject >= 600 then SiteID="600"; */
	/* else if Subject >= 500 then SiteID="500"; */
	/* else if Subject >= 400 then SiteID="400"; */
	/* else if Subject >= 300 then SiteID="300"; */
	/* else if Subject >= 200 then SiteID="200"; */
	/* else if Subject >= 100 then SiteID="100"; */
	/* else SiteID="NA"; */
	USUBJID=cats(STUDYID, SITEID, SUBJID);
run;

/* Created Dosing Start Date as "FirstDoseDt" and End Date as "LastDoseDt" from RAW.DOSING dataset to fix missing and partial dates */
proc sort data=raw.dosing out=dose_sort;
	by subject;
run;

/* Created "startdate" and "lastdate" character columns to capture both Complete and Partial Dates in Character data type */
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

/* Used "PROC SQL" to create single record per subject for variables "RFENDTC, RFXSTDTC, RFENDTC and RFXENDTC" */
proc sql;
	create table dose_dates as 
		select subject, min(startdate) as FirstDoseDt, max(lastdate) as LastDoseDt 
		from dosedt_fix 
	group by subject;
quit;

/* Merged 'demog' and 'dose_dates' Datasets using Data Step "MERGE" */
data demog_dosing;
	merge demog(in=a) dose_dates(in=b);
		by subject;
	if a;
run;

/* Created temporary dataset 'DM' to finalize the 'SDTM.DM' domain variable mapping and derivation from RAW data */
data DM(keep=STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC 
		RFICDTC RFPENDTC DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ARMCD ARM 
		ACTARMCD ACTARM ARMNRS ACTARMUD COUNTRY);
	set empshell.empty_dm demog_dosing(rename=(race=demo_race));
		DOMAIN="DM";
		RFSTDTC=put(randdt, yymmdd10.);
		RFENDTC=lastdosedt;
		RFXSTDTC=firstdosedt;
		RFXENDTC=lastdosedt;
		RFICDTC=put(icdate, yymmdd10.);
		RFPENDTC=put(lastdoc, yymmdd10.);
		DTHDTC=" ";
		DTHFL=" ";
		BRTHDTC=put(dob, yymmdd10.);
			if length(rfstdtc)=10 then AGE=int((input(rfstdtc, yymmdd10.)-input(brthdtc, yymmdd10.))/365.25);
	/* Older Clinical Records or Any Clinical Record coming from different organization */
	/* where only YEAR is caputed in CRFs, then the RFSTDTC variable will have only 4 digit YEAR value in character format */
	/* and we have calculated the AGE by SUBSTRACTING the YEAR of BRTHDTC from RFSTDTC YEAR VALUE */
	/* NOTE: The Computation method may vary based on Organizations. This method is used for this Demo Project */
			else if length(rfstdtc)=4 then AGE=int(input(rfstdtc, 4.)-year(input(brthdtc, yymmdd10.)));
			else AGE=.;
		AGEU="YEARS";
		SEX=put(gender, sex.);
		RACE=put(demo_race, race.);
		ARMCD=put(trt, armcd.);
		ARM=put(trt, arm.);
		ACTARMCD=put(trt, armcd.);
		ACTARM=put(trt, arm.);
		ARMNRS=" ";
		ACTARMUD=" ";
		COUNTRY="USA";
run;

/* Sorted Final Dataset based on DM Domain Final Submission Regulatory requirement */
/* Sorting Order - Primary Key Variables - STUDYID, USUBJID */
proc sort data=dm out=sdtm.dm;
	by studyid usubjid;
run;

/* Output Table of the empty_suppdm code was saved in Empty_Shell_Domains Folder for QC */
/* Empty shell "empty_suppdm" was created to for the structure of "SUPPDM" dataset as per CDISC guidelines */
data empshell.empty_suppdm;
	attrib /* Used "ATTRIB" statement to create Columns with additional attribures like "LENGTH" and "LABEL" */
		STUDYID 	length=$15 		label="Study Identifier" 
		RDOMAIN 	length=$2 		label="Related Domain Abbreviation" 
		USUBJID 	length=$25 		label="Unique Subject Identifier" 
		IDVAR 		length=$8 		label="Identifying Variable" 
		IDVARVAL 	length=$200 	label="Identifying Variable Value" 
		QNAM 		length=$8 		label="Qualifier Variable Name" 
		QLABEL 		length=$40 		label="Qualifier Variable Label" 
		QVAL 		length=$200 	label="Data Value" 
		QORIG 		length=$20 		label="Origin" 
		QEVAL 		length=$8 		label="Evaluator";
	stop; /* Used "STOP" statement to stop the execution of the DataStep which will create a blank row of data */
run;

/* Created "SUPPDM" dataset to capture all non-standard variables from  */
/* "Raw.Demographic" dataset which can not be stored in "DM" domain as per CDISC standards */
data suppdm (keep=STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG QEVAL);
	set empshell.empty_suppdm raw.demographic;
		STUDYID="XYZ123";
		RDOMAIN="DM";
			if ^missing(subject) then SiteID=cats(substr((put(int(subject/100), 7.)), 1), '00');
			else SiteID="NA";
		USUBJID=cats(studyid, siteid, put(subject, 3.));
		IDVAR=" ";
		IDVARVAL=" ";
		QORIG="CRF";
		QEVAL=" ";
			if ^missing(orace) then do;
				QNAM="ORACE";
				QLABEL="Other Race";
				QVAL=trim(orace);
				output;
			end;
			if ^missing(randdt) then do;
				QNAM="RANDDTC";
				QLABEL="Randomization Date";
				QVAL=put(randdt, yymmdd10.);
				output;
			end;
run;

/* Sorted 'SUPPDM' Domain based on the Sorting Order of Parent Domain 'DM' as we need to Merge 'DM' and 'SUPPDM' while creating ADaM Dataset */
proc sort data=suppdm out=sdtm.suppdm(label='Supplimental Qualifiers for Demographics');
	by STUDYID USUBJID;
run;

/* Empty shell "empty_ex" was created for the structure of "EX" dataset as per CDISC guidelines */
data empshell.empty_ex;
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

/* Created "EXSEQ" valriable using the "dosedt_fix" dataset */
data ex_seq;
	set dosedt_fix;
	by subject;
	length SITEID $7 USUBJID $25 STUDYID $15;
		if first.subject then EXSEQ=.;
			EXSEQ+1; /* Used "SUM" statement to increase "EXSEQ" variable value 1 with each passing record untill new Subject Group starts */
		if ^missing(subject) then SiteID=cats(substr((put(int(subject/100), 7.)), 1), '00');
		else SiteID="NA";
/* Created "SiteID" variable with same logic used previously to create "USUBJID" variable */
	studyid="XYZ123";
	usubjid=cats(studyid, siteid, put(subject, 3.));
run;

/* Merged "ex_seq" with "sdtm.dm" to capture "actarm" variable which contains the study drug name */
data dosing_dm;
	merge ex_seq(in=a) sdtm.dm(keep=usubjid actarm rfstdtc);
	by usubjid;
		if a;
	/* Subsetting data which is from "ex_seq" dataset derived from "Raw.Dosing" raw dataset */
	/* By Subsetting, we are not capturing any extra data from "Raw.Demographics" raw data which might not be present in "Raw.Dosing" raw data  */
	/* as we are creating "EX" domain and we do not need unnecessary data to be captured */
run;

/* Created "EX" Domain variables based on CDISC Stadards */
data EX(keep=STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM EPOCH 
		EXSTDTC EXENDTC EXSTDY EXENDY);
	set empshell.empty_ex dosing_dm;
		DOMAIN="EX";
			if trim(actarm)="Analgezia HCL 30 mg" then do;
				EXTRT="ANALGEZIA HCL";
				EXDOSE=dailydose*30;
			end;
			else do;
				EXTRT="PLACEBO";
				EXDOSE=dailydose*0;
			end;
		EXDOSEU="mg";
		EXDOSFRM="TABLET,COATED";
		EPOCH="TREATMENT";
		EXSTDTC=STARTDATE;
		EXENDTC=LASTDATE;
			if length(exstdtc)=10 then EXSTDY=input(exstdtc, yymmdd10.)-input(rfstdtc, yymmdd10.)+1;
			else EXSTDY=.;
			if length(exendtc)=10 then EXENDY=input(exendtc, yymmdd10.)-input(rfstdtc, yymmdd10.)+1;
			else EXENDY=.;
run;

/* Created Final "SDTM.EX" SDTM Domain which is sorted based on CDISC Standard for "SDTM.EX" submission	 */
proc sort data=ex out=sdtm.ex(label='Exposure');
	by STUDYID USUBJID EXSEQ EXTRT EXSTDTC;
run;

/* Create Empty Shell "empshell.EMPTY_AE" to form the Structure of "SDTM.AE" Domain based on CDISC Guidelines */
data empshell.EMPTY_AE;
	attrib 
		STUDYID		length=$15		label='Study Identifier' 
		DOMAIN 		length=$2 		label='Domain Abbreviation' 
		USUBJID 	length=$25 		label='Unique Subject Identifier' 
		AESEQ 		length=8 		label='Sequence Number' 
		AETERM 		length=$200 	label='Reported Term for the Adverse Event' 
		AELLT 		length=$200 	label='Lowest Level Term' 
		AELLTCD 	length=8 		label='Lowest Level Term Code' 
		AEDECOD 	length=$200 	label='Dictionary-Derived Term' 
		AEPTCD 		length=8 		label='Preferred Term Code' 
		AEHLT 		length=$200 	label='High Level Term' 
		AEHLTCD 	length=8 		label='High Level Term Code' 
		AEHLGT 		length=$200 	label='High Level Group Term' 
		AEHLGTCD 	length=8 		label='High Level Group Term Code' 
		AEBODSYS 	length=$200 	label='Body System or Organ Class' 
		AEBDSYCD 	length=8 		label='Body System or Organ Class Code' 
		AESOC 		length=$200 	label='Primary System Organ Class' 
		AESOCCD 	length=8 		label='Primary System Organ Class Code' 
		AESEV 		length=$20 		label='Severity' 
		AESER 		length=$2 		label='Serious Event' 
		AEACN 		length=$40 		label='Action Taken with Study Treatment' 
		AEREL 		length=$40 		label='Causality' 
		AESLIFE 	length=$2 		label='Is Life Threatening' 
		EPOCH 		length=$40 		label='Epoch' 
		AESTDTC 	length=$16 		label='Start Date/Time of Adverse Event' 
		AEENDTC		length=$16 		label='End Date/Time of Adverse Event' 
		AESTDY 		length=8 		label='Study Day of Start of Adverse Event' 
		AEENDY 		length=8 		label='Study Day of End of Adverse Event';
	stop;
run;

/* Created Custom Formats for Variables 'AEREL','AESEV' and 'ACN' using the sponsor provided codelist  */
proc format lib=ctfmt fmtlib;
	value aerel 1='NOT RELATED' 2='POSSIBLY RELATED' 3='PROBABLY RELATED';
	value aesev 1='MILD' 2='MODERATE' 3='SEVERE';
	value acn 1='DRUG INTERRUPTED' 2='DOSE REDUCED' 3='DOSE INCREASED' 4='DOSE NOT CHANGED' 5='UNKNOWN';
run;

/* Created temporary dataset 'ae_seq' to create the variable 'AESEQ' */
data ae_seq;
	set raw.adverse;
	by subject;
	length studyid $15 siteid $7 usubjid $25;
		if ^missing(subject) then siteid=cats(substr(put(int(subject/100), 7.), 1), '00');
		else siteid='NA';
	studyid='XYZ123';
	usubjid=cats(studyid, siteid, put(subject, 3.));
		if first.subject then aeseq=.;
		aeseq+1;
run;

/* Merged datasets 'ae_seq' and 'SDTM.DM' to capture the variable 'RFSTDTC' which will be used for calculations later */
data ae_dm;
	merge ae_seq(in=a) sdtm.dm(keep=rfstdtc usubjid);
	by usubjid;
	if a;
run;

/* Created temporary dataset 'AE' to finalize the 'SDTM.AE' domain variable mapping and derivation from RAW data */
data AE (keep=STUDYID DOMAIN USUBJID AESEQ AETERM AELLT AELLTCD AEDECOD AEPTCD 
		AEHLT AEHLTCD AEHLGT AEHLGTCD AEBODSYS AEBDSYCD AESOC AESOCCD AESEV AESER 
		AEACN AEREL AESLIFE EPOCH AESTDTC AEENDTC AESTDY AEENDY);
	set empshell.empty_ae ae_dm(rename=(aesev=sev aerel=rel));
	/* Used 'RENAME=' option in 'SET statement' to rename variables 'AESEV' and 'AEREL' 
		as 'PUT or INPUT' function does not work when the source column and output column names are same */
	DOMAIN='AE';
	/* Used 'STRIP' function to remove Leading and Trailing Blanks or Spaces */
	/* Used 'INPUT' function with 'BEST.' Format to convert all MedDRA coded from character to numeric */
	AETERM=strip(aetext);
	AELLT=strip(llterm);
	AELLTCD=input(lltcode, best.);
	AEDECOD=strip(prefterm);
	AEPTCD=input(ptcode, best.);
	AEHLT=strip(hlterm);
	AEHLTCD=input(hltcode, best.);
	AEHLGT=strip(hlgterm);
	AEHLGTCD=input(hlgtcod, best.);
	AEBODSYS=strip(bodysys);
	AEBDSYCD=input(soccode, best.);
	AESOC=strip(bodysys);
	AESOCCD=input(soccode, best.);
	AESEV=put(sev, aesev.);
	AESER=upcase(strip(serious));
	AEACN=put(aeaction, acn.);
	AEREL=put(rel, aerel.);
		if AESER='Y' then AESLIFE='Y';
		else AESLIFE='N';
		if missing(aestart) then EPOCH=' ';
		else if aestart < input(rfstdtc, yymmdd10.) then EPOCH='SCREENING';
		else EPOCH='TREATMENT';
		if ^missing(aestart) then AESTDTC=put(aestart, yymmdd10.);
		else AESTDTC=' ';
		if ^missing(aeend) then AEENDTC=put(aeend, yymmdd10.);
		else AEENDTC=' ';
		if missing(AESTDTC) then AESTDY=.;
		else if input(AESTDTC, yymmdd10.) < input(rfstdtc, yymmdd10.) then AESTDY=input(AESTDTC, yymmdd10.) - input(rfstdtc, yymmdd10.);
		else AESTDY=input(AESTDTC, yymmdd10.) - input(rfstdtc, yymmdd10.) + 1;
		if missing(AEENDTC) then AEENDY=.;
		else if input(AEENDTC, yymmdd10.) < input(rfstdtc, yymmdd10.) then AEENDY=input(AEENDTC, yymmdd10.) - input(rfstdtc, yymmdd10.);
		else AEENDY=input(AEENDTC, yymmdd10.) - input(rfstdtc, yymmdd10.) + 1;
run;

/* Created Final 'SDTM.AE' Domain by sorting 'AE' dataset based on CDISC submission guidelines */
proc sort data=ae out=SDTM.AE(label='Adverse Events');
	by studyid usubjid aeseq aedecod aestdtc;
run;

/* Created Empty Shell 'empshell.empty_lb' to form the structure of 'SDTM.LB' Domain as per CDISC standard */
data empshell.empty_lb;
	attrib 
		STUDYID 	length=$15 		label='Study Identifier' 
		DOMAIN 		length=$2 		label='Domain Abbreviation' 
		USUBJID 	length=$25 		label='Unique Subject Identifier' 
		LBSEQ 		length=8 		label='Sequence Number' 
		LBTESTCD 	length=$8 		label='Lab Test or Examination Short Name' 
		LBTEST 		length=$40 		label='Lab Test or Examination Name' 
		LBCAT 		length=$40 		label='Category for Lab Test' 
		LBORRES 	length=$200 	label='Result or Finding in Original Units' 
		LBORRESU 	length=$40 		label='Original Units' 
		LBORNRLO 	length=$40 		label='Reference Range Lower Limit in Orig Unit' 
		LBORNRHI 	length=$40 		label='Reference Range Upper Limit in Orig Unit' 
		LBSTRESC 	length=$200 	label='Character Result/Finding in Std Format' 
		LBSTRESN 	length=8 		label='Numeric Result/Finding in Standard Units' 
		LBSTRESU 	length=$40 		label='Standard Units' 
		LBSTNRLO 	length=8 		label='Reference Range Lower Limit-Std Units' 
		LBSTNRHI 	length=8 		label='Reference Range Upper Limit-Std Units' 
		LBNRIND 	length=$20 		label='Reference Range Indicator' 
		LBBLFL 		length=$2 		label='Baseline Flag' 
		LBLOBXFL 	length=$1 		label='Last Observation before Exposure Flag' 
		VISITNUM 	length=8 		label='Visit Number' 
		VISIT 		length=$40 		label='Visit Name' 
		EPOCH 		length=$40 		label='Epoch' 
		LBDTC 		length=$16 		label='Date/Time of Specimen Collection' 
		LBDY 		length=8 		label='Study Day of Specimen Collection';
	stop;
run;

/* Sorted 'RAW.LABS' dataset based on variables 'subject, labcat, labtest and month' to help creation of 'LBSEQ' variable */
proc sort data=raw.labs out=lab_sort;
	by subject labcat labtest month;
run;

/* Created variable 'LBSEQ' to capture the unique sequence number for each labtest performed on each subject */
data lb_seq;
	set lab_sort;
	by subject labcat labtest month;
	length studyid $15 siteid $7 usubjid $25;
		if ^missing(subject) then siteid=cats(substr(put(int(subject/100), 7.), 1), '00');
		else siteid='NA';
	studyid='XYZ123';
	usubjid=cats(studyid, siteid, put(subject, 3.));
		if first.labtest=1 then LBSEQ=.;
		LBSEQ+1;
run;

/* Created custom formats '$lbtestcd and $lbtest' for variables 'LBTESTCD and LBTEST' */
proc format lib=ctfmt fmtlib;
	value $lbtestcd 
					'ALBUMIN'='ALB' 
					'ALK. PHOS.'='ALP' 
					'ALT (SGPT)'='ALT' 
					'AST (SGOT)'='AST' 
					'DIRECT BILI'='BILDIR' 
					'TOTAL BILI'='BILI' 
					'GGTP'='GGT' 
					'HEMATOCRIT'='HCT' 
					'HEMOGLOBIN'='HGB' 
					'TOTAL PROT'='PROT' 
					'GLUCOSE'='GLUC';
	value $lbtest 
				'ALBUMIN'='Albumin; Microalbumin' 
				'ALK. PHOS.'='Alkaline Phosphatase' 
				'ALT (SGPT)'='Alanine Aminotransferase; SGPT' 
				'AST (SGOT)'='Aspartate Aminotransferase; SGOT' 
				'DIRECT BILI'='Direct Bilirubin' 
				'TOTAL BILI'='Bilirubin; Total Bilirubin' 
				'GGTP'='Gamma Glutamyl Transferase' 
				'HEMATOCRIT'='Hematocrit' 
				'HEMOGLOBIN'='Hemoglobin' 
				'TOTAL PROT'='Protein' 
				'GLUCOSE'='Glucose';
	value visit 
				0='Baseline' 1='Month 3' 2='Month 6';
run;

/* Created temporary dataset 'lb_dm' to capture variable 'rfstdtc' from 'SDTM.DM' dataset */
data lb_dm;
	merge lb_seq(in=a) SDTM.DM(keep=usubjid rfstdtc rfxstdtc);
	by usubjid;
	if a;
run;

/* Created temporary dataset 'LB' to finalize the 'SDTM.LB' domain variable mapping and derivation from RAW data */
data LB(keep=STUDYID DOMAIN USUBJID LBSEQ LBTESTCD LBTEST LBCAT LBORRES 
		LBORRESU LBORNRLO LBORNRHI LBSTRESC LBSTRESN LBSTRESU LBSTNRLO LBSTNRHI 
		LBNRIND LBBLFL LBLOBXFL VISITNUM VISIT EPOCH LBDTC LBDY);
	set empshell.empty_lb lb_dm;
		DOMAIN='LB';
		LBTESTCD=put(strip(labtest),$lbtestcd.);
		LBTEST=put(strip(labtest),$lbtest.);
		LBCAT=strip(labcat);
		LBORRES=put(nresult,best.);
		LBORRESU=strip(colunits);
		LBORNRLO=put(lownorm,best.);
		LBORNRHI=put(highnorm,best.);
		LBSTRESC=put(nresult,best.);
		LBSTRESN=nresult;
		LBSTRESU=strip(colunits);
		LBSTNRLO=lownorm;
		LBSTNRHI=highnorm;
		if LBTESTCD = 'GLUC' and LBCAT = 'URINALYSIS' and LBORRES = 'POSITIVE' then LBNRIND = 'HIGH';
 		else if LBTESTCD = 'GLUC' and LBCAT = 'URINALYSIS' and LBORRES = 'NEGATIVE' then LBNRIND = 'NORMAL';
 		else if LBSTNRLO ne . and LBSTRESN ne . and round(LBSTRESN,.0000001) < round(LBSTNRLO,.0000001) then LBNRIND = 'LOW';
    	else if LBSTNRHI ne . and LBSTRESN ne . and round(LBSTRESN,.0000001) > round(LBSTNRHI,.0000001) then LBNRIND = 'HIGH';
    	else if LBSTNRHI ne . and LBSTRESN ne . then LBNRIND = 'NORMAL';
		if ^missing(month)=0 then LBBLFL='Y';
		else LBBLFL=' ';
		if ^missing(labdate) then LBDTC=put(labdate,yymmdd10.);
		else LBDTC=' ';
		
		if missing(rfxstdtc) or length(rfxstdtc)<10 or missing(labdate) then LBLOBXFL=' ';
		else if labdate <= input(rfxstdtc,yymmdd10.) then LBLOBXFL='Y';
		else LBLOBXFL=' ';
		VISITNUM=month;
		VISIT=put(month,visit.);
		
		if missing(lbdtc) or length(lbdtc)<10 or missing(rfstdtc) or length(rfstdtc)<10 then EPOCH=' ';
		else if input(lbdtc,yymmdd10.) < input(rfstdtc,yymmdd10.) then EPOCH='SCREENING';
		else EPOCH='TREATMENT';
		
		if missing(lbdtc) or length(lbdtc)<10 or missing(rfstdtc) or length(rfstdtc)<10 then LBDY=.;
		else if input(lbdtc,yymmdd10.) < input(rfstdtc,yymmdd10.) then LBDY=input(lbdtc,yymmdd10.) - input(rfstdtc,yymmdd10.);
		else LBDY=input(lbdtc,yymmdd10.) - input(rfstdtc,yymmdd10.) + 1;
run;

/* Created Final 'SDTM.LB' Domain by sorting 'LB' dataset based on CDISC submission guidelines */
proc sort data=LB out=SDTM.LB(label='Laboratory Test Results');
	by STUDYID USUBJID LBTESTCD VISITNUM;
run;

/* Created Empty Shell 'empshell.EMPTY_XP' to form the structure of 'SDTM.XP' Domain as per CDISC standard */
data empshell.EMPTY_XP;
	attrib
		STUDYID		length=$15		label='Study Identifier'
		DOMAIN		length=$2		label='Domain Abbreviation'
		USUBJID		length=$25		label='Unique Subject Identifier'
		XPSEQ		length=8		label='Sequence Number'
		XPTESTCD	length=$8		label='Pain Test Short Name'
		XPTEST		length=$40		label='Pain Test Name'
		XPORRES		length=$200		label='Result or Finding in Original Units'
		XPSTRESC	length=$200		label='Character Result/Finding in Std Format'
		XPSTRESN	length=8		label='Numeric Result/Finding in Std Format'
		EPOCH		length=$40		label='Epoch'
		VISITNUM	length=8		label='Visit Number'
		VISIT		length=$40		label='Visit Name'
		XPBLFL		length=$2		label='Baseline Flag'
		XPDTC		length=$16		label='Date/Time of  Collection'
		XPDY		length=8		label='Study Day of  Collection';
	stop;
run;

/* OR */
/* Alternate method of creating emptyshell using 'PROC SQL' is like: */

/* proc sql; */
/* 	create table empshell.EMPTY_XP  */
/* 		(STUDYID		CHAR(15)	label='Study Identifier', */
/* 			DOMAIN		CHAR(2)		label='Domain Abbreviation', */
/* 			USUBJID		CHAR(25)	label='Unique Subject Identifier', */
/* 			XPSEQ		INT			label='Sequence Number', */
/* 			XPTESTCD	CHAR(8)		label='Pain Test Short Name', */
/* 			XPTEST		CHAR(40)	label='Pain Test Name', */
/* 			XPORRES		CHAR(200)	label='Result or Finding in Original Units', */
/* 			XPSTRESC	CHAR(200)	label='Character Result/Finding in Std Format', */
/* 			XPSTRESN	INT			label='Numeric Result/Finding in Std Format', */
/* 			EPOCH		CHAR(40)	label='Epoch', */
/* 			VISITNUM	INT			label='Visit Number', */
/* 			VISIT		CHAR(40)	label='Visit Name', */
/* 			XPBLFL		CHAR(2)		label='Baseline Flag', */
/* 			XPDTC		CHAR(16)	label='Date/Time of  Collection', */
/* 			XPDY		INT			label='Study Day of  Collection'); */
/* quit; */

/* Created custom formats 'pscore and pvisit' for variables 'XPSTRESC and VISIT' */
proc format lib=ctfmt fmtlib;
	value pscore 0='none' 1='mild' 2='moderate' 3='severe';
	value pvisit 0='Baseline' 1='Month 3' 2='Month 6';
run;
/* Sorted 'RAW.PAIN' source data by 'subject' for ease of variable creation for final 'SDTM.XP' domain */
proc sort data=raw.pain out=pain_sort;
	by subject;
run;

/* Created temporary dataset 'pain' to finalize the 'SDTM.XP' domain variable mapping and derivation from RAW data */
data pain (drop=randomizedt month3dt month6dt painbase pain3mo pain6mo i);
	set pain_sort;
		by subject;
			length studyid $15 siteid $7 usubjid $25;
				if ^missing(subject) then siteid=cats(substr(put(subject,7.),1,5),'00');
				else siteid='NA';
			studyid='XYZ123';
			usubjid=cats(studyid,siteid,put(subject,3.));		
array dates{3} randomizedt month3dt month6dt;
array pchkdur{3} painbase pain3mo pain6mo; 
	do i=1 to 3;
		visitnum=i-1;
		visit=put(visitnum,pvisit.);
			if visitnum=0 then XPBLFL='Y';
			else XPBLFL=' ';
		if ^missing(dates{i}) and ^missing(pchkdur{i}) then do;
			_xporres=pchkdur{i};
			_xpstresc=put(_xporres,pscore.);
			_xpstresn=_xporres;
			_xpdtc=put(dates{i},yymmdd10.);
		output;
		end;		
	end;	
run;

/* Used PROC SQL to merge data from 'pain' and 'SDTM.DM' datasets to bring 'RFSTDTC' and calculate 'XPDY' variable */

proc sql;	
	create table pain_dm as	
		select p.*, d.rfstdtc
			from pain as p left join sdtm.dm as d 
				on p.USUBJID = d.USUBJID
		order by usubjid, _xpdtc;
quit;
	
/* Created temporary dataset 'XP' to finalize the 'SDTM.XP' domain variable mapping and derivation from RAW data */

data XP (keep=STUDYID DOMAIN USUBJID XPSEQ XPTESTCD XPTEST XPORRES XPSTRESC XPSTRESN EPOCH 
				VISITNUM VISIT XPBLFL XPDTC XPDY);
	set empshell.empty_xp pain_dm;
		by usubjid;
	if first.usubjid then XPSEQ+1;
DOMAIN = 'XP';
XPTESTCD = 'XPAIN';
XPTEST = 'Pain Score';
XPORRES = put(_xporres,1.);
XPSTRESC = _xpstresc;
XPSTRESN = _xpstresn;		
XPDTC = _xpdtc;

if input(xpdtc,yymmdd10.) < input(rfstdtc,yymmdd10.) then do;
	EPOCH = 'Screening';
	XPDY = input(xpdtc,yymmdd10.)-input(rfstdct,yymmdd10.);
end;
else if input(xpdtc,yymmdd10.) >= input(rfstdtc,yymmdd10.) then do;
	EPOCH = 'Treatment';
	XPDY = input(xpdtc,yymmdd10.)-input(rfstdtc,yymmdd10.)+1;
end;
else do;
	EPOCH = ' ';
	XPDY = .;
end;
run;
	
/* Sorted 'XP' to create final 'SDTM.XP' domain as per CDISC SDTM Submission standard */
	
proc sort data=xp out=SDTM.XP (label='Pain Scores for each subject');
	by studyid usubjid xptestcd xpdtc;
run;
	


/************************************* ADAM Part ***********************************************/

/* Created LIBRARY "EMPADAM" to access the "Empty Shells" for "ADaM" Datasets for the Clinical Trial using "LIBNAME" statement */
libname empadam "&pathcl/ADAM/empty_adams";

/* Created LIBRARY "ADAM" to access the "ADaM" datasets for the Clinical Trial using "LIBNAME" statement */
libname ADAM "&pathcl/ADAM";

/* Created 'EMPADAM.EMPTY_ADSL' to pre-fix the structure of Final 'ADAM.ADSL' dataset for mapping of raw data */
data empadam.empty_adsl;
	attrib
		STUDYID		length=$15		label='Study Identifier'
		USUBJID		length=$25		label='Unique Subject Identifier'
		SUBJID		length=$7		label='Subject Identifier for the Study'
		SITEID		length=$7		label='Study Site Identifier'
		COUNTRY		length=$3		label='Country'
		BRTHDT		length=8		label='Date of Birth'
		AGE			length=8		label='Age'
		AGEU		length=$5		label='Age Units'
		AGEGR1		length=$40		label='Pooled Age Group 1'
		AGEGR1N		length=8		label='Pooled Age Group 1 (N)'
		SEX			length=$1		label='Sex'
		RACE		length=$40		label='Race'
		RACEOTH		length=$40		label='Race, Other, Specify'
		RANDDT		length=8		label='Date of Randomization'
		TRTSDT		length=8		label='Date of First Exposure to Treatment'
		TRTEDT		length=8		label='Date of Last Exposure to Treatment'
		ARM			length=$40		label='Description of Planned Arm'
		TRT01P		length=$40		label='Planned Treatment for Period 01'
		TRT01A		length=$40		label='Actual Treatment for Period 01'
		TRT01PN		length=8		label='Planned Treatment for Period 01 (N)'
		TRT01AN		length=8		label='Actual Treatment for Period 01 (N)'
		ITTFL		length=$1		label='Intent-To-Treat Population Flag'
		SAFFL		length=$1		label='Safety Population Flag'
		RESPFL		length=$1		label='Efficacy Responder Flag'
		TRTSDTF		length=$1		label='Date of First Exposure Imput. Flag'
		TRTEDTF		length=$1		label='Date of Last Exposure Imput. Flag'
		RANDFL		length=$1		label='Randomized Population Flag';
	stop;
run; 

/* Used 'PROC TRANSPOSE' to capture data from 'SDTM.SUPPDM' */
proc transpose data=sdtm.suppdm out=supp_trans;
	by usubjid;
		var Qval;
		id Qnam;
			idlabel qlabel;
run;

/* Used 'PROC TRANSPOSE' to capture data from 'SDTM.XP' */
proc transpose data=sdtm.xp out=xp_trans;
	by usubjid;
		var xpstresn;
		id visit;
			idlabel visit;
run;

/* Temporary dataset 'chg_base' is created to 'MAP' the 'RESPFL' variable from RAW data  */
data chg_base;
	set xp_trans;
		if ^missing('Month 6'n) and ^missing(baseline) then do;
			if 'Month 6'n - Baseline <= -2 then RESPFL='Y';
			else RESPFL='N';
		end;
		else do;
			if missing('Month 6'n) or missing(baseline) then RESPFL=' ';
		end;
run;

/*************************************************************************************************** 
Created a 'MACRO' program to do the transpose and create the datasets 
And can be used in different scenarios.

%macro trans_chg(lib=, dsn=);
proc transpose data=&lib..&dsn out=&dsn._trans;
	by usubjid;
		var &dsn.stresn;
		id visit;
			idlabel visit;
run;
data chg_base;
	set &dsn._trans;
		if ^missing('Month 6'n) and ^missing(baseline) then do;
			if 'Month 6'n - Baseline <= -2 then RESPFL='Y';
			else RESPFL='N';
		end;
		if missing('Month 6'n) or missing(baseline) then RESPFL=' ';
run;
%mend;

%trans_chg(lib=sdtm,dsn=xp);

This code is included for future use cases but is not being used for this code now 
****************************************************************************************************/

/* Used 'PROC SQL' to create temporary dataset 'suppdm_dm_xp' by doing 'LEFT JOIN' from 3 different datasets */
proc sql;
	create table suppdm_dm_xp as 
		select d.*, t.randdtc, t.orace, c.RESPFL
			from sdtm.dm as d left join supp_trans as t 
				on d.usubjid=t.usubjid left join chg_base as c 
					on d.usubjid=c.usubjid;
quit;

/* Created temporary dataset 'ADSL' to finalize the 'MAPPING' of variables from data sources */
data adsl (keep=STUDYID USUBJID SUBJID SITEID COUNTRY BRTHDT AGE AGEU AGEGR1 AGEGR1N SEX RACE 
	RACEOTH RANDDT TRTSDT TRTEDT ARM TRT01P TRT01A TRT01PN TRT01AN ITTFL SAFFL 
	RESPFL TRTSDTF TRTEDTF RANDFL);
		set empadam.empty_adsl suppdm_dm_xp(rename=(ageu=_ageu sex=_sex race=_race));
		
		ageu=_ageu;
		sex=_sex;
		race=_race;
		
		if length(BRTHDTC) = 10 then BRTHDT = input(BRTHDTC,yymmdd10.);
		else BRTHDT = .;
		
		if age=. then AGEGR1=' ';
		else if age<55 then AGEGR1='<55 YEARS';
		else AGEGR1='>=55 YEARS';
		
		if age=. then AGEGR1N=.;
		else if age<55 then AGEGR1N=1;
		else AGEGR1N=2;

		RACEOTH=trim(orace);
		
		if length(randdtc) = 10 then RANDDT = input(randdtc,yymmdd10.);
		else RANDDT = .;
		
		if length(rfxstdtc) = 10 then do;
		TRTSDT = input(rfxstdtc,yymmdd10.);
		TRTSDTF = ' ';
		end;
		else do;
		TRTSDT = input(rfstdtc,yymmdd10.);			
		if find(rfxstdtc,'-',1)=1 or missing(rfxstdtc) then TRTSDTF = 'Y';
		else if substr(rfxstdtc,6,1)='-' or find(rfxstdtc,'-',1)=0 then TRTSDTF = 'M';
		else TRTSDTF = 'D';
		end;
		
		if length(rfxendtc) = 10 then do;
		TRTEDT = input(rfxendtc,yymmdd10.);
		TRTEDTF = ' ';
		end;
		else do;
		TRTEDT = input(rfpendtc,yymmdd10.);			
		if find(rfxendtc,'-',1)=1 or missing(rfxendtc) then TRTEDTF = 'Y';
		else if substr(rfxendtc,6,1)='-' or find(rfxendtc,'-',1)=0 then TRTEDTF = 'M';
		else TRTEDTF = 'D';
		end;
		
		if trim(arm) = ' ' then do;
			TRT01P=' ';
			TRT01PN=.;
		end;
		else do;
			if trim(arm) = 'Placebo' then do;
				TRT01P=trim(arm);
				TRT01PN=0;
			end;
			else do;
				TRT01P=trim(arm);
				TRT01PN=1;
			end;
		end;
		
		if trim(actarm) = ' ' then do;		
			TRT01A=trim(actarm);
			TRT01AN=.;
		end;
		else do;
			if trim(actarm) = 'Placebo' then do;
				TRT01A=trim(actarm);
				TRT01AN=0;
			end;
			else do;
				TRT01A=trim(actarm);
				TRT01AN=1;
			end;
		end;
		
		if ^missing(randdt) then ITTFL = 'Y';
		else ITTFL = 'N';
		
		if ^missing(TRTSDT) then SAFFL = 'Y';
		else SAFFL = 'N';
		
		if ^missing(randdt) then RANDFL = 'Y';
		else RANDFL = 'N';
	format RANDDT TRTSDT TRTEDT BRTHDT yymmdd10.;
run;

/* Used 'PROC SORT' to sort the 'ADSL' dataset and create FINAL 'ADAM.ADSL' dataset as per CDISC Submission standards */
proc sort data=adsl out=ADAM.ADSL (label='Subject Level Analysis Dataset');
	by studyid usubjid;
run;

/* Created 'EMPADAM.EMPTY_ADAE' to pre-fix the structure of Final 'ADAM.ADAE' dataset for mapping of raw data */
data empadam.empty_adae;
	attrib
		STUDYID		length=$15		label='Study Identifier'
		USUBJID		length=$25		label='Unique Subject Identifier'
		SITEID		length=$7		label='Study Site Identifier'
		COUNTRY		length=$3		label='Country'
		AESEQ		length=8		label='Sequence Number'
		AGE			length=8		label='Age'
		AGEGR1N		length=8		label='Pooled Age Group 1 (N)'
		AGEGR1		length=$20		label='Pooled Age Group 1'
		SEX			length=$1		label='Sex'
		TRTAN		length=8		label='Actual Treatment (N)'
		TRTA		length=$40		label='Actual Treatment'
		AETERM		length=$200		label='Reported Term for the Adverse Event'
		AEDECOD		length=$200		label='Dictionary-Derived Term'
		AEBODSYS	length=$200		label='Body System or Organ Class'
		ASTDT		length=8		label='Start Date/Time of Adverse Events'
		AENDT		length=8		label='End Date/Time of Adverse Events'
		ASTDY		length=8		label='Study Day of Start of Adverse Event'
		AENDY		length=8		label='Study Day of End of Adverse Event'
		AESEV		length=$40		label='Severity/Intensity'
		AESEVN		length=8		label='Severity/Intensity (N)'
		AESER		length=$40		label='Serious Event'
		AEACN		length=$40		label='Action Taken with Study Treatment'
		AEREL		length=$40		label='Causality'
		AERELN		length=8		label='Causality (N)'
		CQ01NAM		length=$200		label='CQ 01 Name'
		RELGR1		length=$15		label='Pooled Causality Group 1'
		RELGR1N		length=8		label='Pooled Causality Group 1 (N)'
		TRTEMFL		length=$1		label='Treatment Emergent Flag'
		SAFFL		length=$1		label='Safety Population Flag';
	stop;
run;

/* Created temporary dataset 'var_adsl' to fetch necessary variables from 'ADAM.ADSL' needed for Final 'ADAM.ADAE' dataset */
data var_adsl(keep=STUDYID USUBJID SITEID COUNTRY AGE AGEGR1N AGEGR1 SEX SAFFL TRTEDT TRTSDT TRTAN TRTA);
	set adam.adsl;
		TRTAN=TRT01AN;
		TRTA=trim(TRT01A);
run;

/* Created formats to use for the creation of variables of 'ADAM.ADAE' dataset */
proc format lib=ctfmt fmtlib;
	invalue $sev 'MILD'=1 'MODERATE'=2 'SEVERE'=3 other=.;
	invalue $rel 'NOT RELATED'=0 'POSSIBLY RELATED'=1 'PROBABLY RELATED'=2 other=.;
	invalue $relgrn 'Not related'=0 'Related'=1 other=.;
run;

/* Created temporary dataset 'adae' to finalize the MAPPING and DERIVATION of Final 'ADAM.ADAE' dataset */
data adae(keep=STUDYID USUBJID SITEID COUNTRY AESEQ AGE AGEGR1N AGEGR1 SEX TRTAN TRTA AETERM 
	AEDECOD AEBODSYS ASTDT AENDT ASTDY AENDY AESEV AESEVN AESER AEACN AEREL AERELN 
	CQ01NAM RELGR1 RELGR1N TRTEMFL SAFFL);
	merge var_adsl sdtm.ae(keep=USUBJID AESEQ AETERM AEDECOD AEBODSYS AESTDTC AEENDTC AESEV AESER AEACN AEREL);
		by usubjid;
			if ^missing(AESTDTC) or length(AESTDTC)=10 then ASTDT=input(AESTDTC,yymmdd10.);
			else ASTDT=.;
			
			if ^missing(AEENDTC) or length(AEENDTC)=10 then AENDT=input(AEENDTC,yymmdd10.);
			else AENDT=.;
			
			if ^missing(ASTDT) or ^missing(TRTSDT) then do;
				if ASTDT>=TRTSDT then ASTDY=ASTDT-TRTSDT+1;
				else ASTDY=ASTDT-TRTSDT;
			end;
			else do;
				ASTDY=.;
			end;
			
			if ^missing(AENDT) or ^missing(TRTEDT) then do;
				if AENDT>=TRTEDT then AENDY=AENDT-TRTEDT+1;
				else AENDY=AENDT-TRTEDT;
			end;
			else do;
				AENDY=.;
			end;

			AESEVN=input(trim(AESEV),$sev.);
			
			AERELN=input(trim(AEREL),$rel.);
			
			if ^missing(AEREL) then do;
				if AEREL='NOT RELATED' then RELGR1='Not related';
				else RELGR1='Related';
			end;
			else do;
			RELGR1='';
			end;

			RELGR1N=input(trim(RELGR1),$relgrn.);
			
			if ^missing(TRTSDT) or ^missing(ASTDT) or ^missing(TRTEDT) then do;
				if TRTSDT<=ASTDT<=TRTEDT then TRTEMFL='Y';
				else TRTEMFL='N';
			end;
			else do;
				TRTEMFL='';
			end;
			
			if index(aedecod, 'PAIN')>0 or index(aedecod, 'ACHE')>0  then CQ01NAM='PAIN EVENT';
			else CQ01NAM=' ';
run;

/* Used 'PROC SORT' to create Final 'ADAM.ADAE' dataset and do the sorting of data as per CDISC Submission standards  */
proc sort data=adae out=ADAM.ADAE(label='Adverse Event Analysis Dataset');
	by STUDYID USUBJID AEDECOD ASTDT;
run;


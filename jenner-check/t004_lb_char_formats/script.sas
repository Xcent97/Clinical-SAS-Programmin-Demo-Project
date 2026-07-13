/* From SAS_Project.sas: the character formats that map raw lab-test names to
   CDISC LBTESTCD short names and LBTEST long names, plus the numeric VISIT
   format. The source stores them permanently (lib=ctfmt); here they build in
   WORK and FMTLIB prints them. The mapping data step reproduces how the LB
   domain applies them with PUT(STRIP(labtest), $lbtestcd.). Definitions are
   unchanged. */

/* Created custom formats '$lbtestcd and $lbtest' for variables 'LBTESTCD and LBTEST' */
proc format fmtlib;
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

/* Map raw lab-test names to CDISC codes the way the LB domain derivation does */
data lb_map;
	length labtest $20 LBTESTCD $8 LBTEST $40;
	input labtest $ month;
	LBTESTCD=put(strip(labtest),$lbtestcd.);
	LBTEST=put(strip(labtest),$lbtest.);
	VISIT=put(month,visit.);
	datalines;
GLUCOSE 0
HEMOGLOBIN 1
ALBUMIN 2
;
run;

proc print data=lb_map;
	var labtest lbtestcd lbtest visit;
run;

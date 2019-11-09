
/********* SQL DOCUMENTATION *****
Creates the table for the VLE Features table
	b4_sum_clicks - this is the number of clicks on the vle before the class started
	q1_sum_clicks - this is the number clicks during the first quarter of the class defines as the first 60 days
	q2_sum_clicks - this is the number clicks during the second quarter of the class defines as the first 60 - 120 days
	q3_sum_clicks - this is the number clicks during the third quarter of the class defines as the first 121 - 180 days
	q4_sum_clicks - this is the number clicks during the fourth quarter of the class defines as anything between day 181 and the end of class 
*********** SQL DOCUMENTATION ***** */
CREATE TABLE public."studentVleFeatures"
  AS (
select id_student, code_module, code_presentation,
sum(CASE
    		WHEN date_iact < 0 THEN sum_click
    		ELSE 0
		END) as b4_sum_clicks,	
sum(CASE
    		WHEN date_iact between 0 and 60 THEN sum_click
    		ELSE 0
		END) as q1_sum_clicks,
sum(CASE
    		WHEN date_iact between 61 and 120 THEN sum_click
    		ELSE 0
		END) as q2_sum_clicks,
sum(CASE
    		WHEN date_iact between 121 and 180 THEN sum_click
    		ELSE 0
		END) as q3_sum_clicks,
sum(CASE
    		WHEN date_iact > 180 THEN sum_click
    		ELSE 0
		END) as q4_sum_clicks	
from public."studentVleFULLSTG" as vle
group by id_student, code_module, code_presentation
order by id_student, code_module, code_presentation
);


/********* SQL DOCUMENTATION *****

Jinna to add comment

Creates the table for the studentAssessment Features table
TMA_CMA_assmt_score : The percentage of TMA score and CMA score
TMA_assmt_score : The percentage of CMA score
CMA_assmt_score : The percentage of CMA score
total_weight : The combinded weight of CMA and TMA
final_exam : 1 mean students have final exam 
is_reenrolled : 1 mean students re-enrolled, 0 mean students do not re-enrolled


*********** SQL DOCUMENTATION ***** */


Create table public."studentAssessmentFeatures"
as(
SELECT csrt.id_student,csrt.code_module,csrt.code_presentation,csrt.final_result,TMA_CMA_assmt_score,total_weight,
final_exam,TMA_assmt_score,CMA_assmt_score,is_reenrolled
FROM public."studentCourseRegistrationFULLSTG" as csrt LEFT OUTER JOIN

(SELECT id_student,
sum(case when assessment_type in('CMA','TMA') then (weight*score)/100 else 0 end) as TMA_CMA_assmt_score,
sum(case when assessment_type in ('TMA') then (weight*score)/100 else 0 end) as TMA_assmt_score,
sum(case when assessment_type in('CMA') then (weight*score)/100 else 0 end) as CMA_assmt_score,
sum(case when assessment_type in('CMA','TMA') then weight else 0 end) as total_weight,
count(case when assessment_type = 'Exam' then 1 else NULL end) as final_exam,
count(case when is_banked = '1' then 1 else NULL end) as is_reenrolled
FROM public."studentAssessmentFULLSTG"
-- ON assmt.id_student = csrt.id_student
where id_student not in (select id_student from public."studentAssessmentFULLSTG" 
where is_banked = 1)
group by id_student,code_module,code_presentation

union 
-- query student whos assessment result has been transferred
SELECT id_student,
sum(case when assessment_type in('CMA','TMA') then (weight*score)/100 else 0 end) as TMA_CMA_assmt_score,
sum(case when assessment_type in ('TMA') then (weight*score)/100 else 0 end) as TMA_assmt_score,
sum(case when assessment_type in('CMA') then (weight*score)/100 else 0 end) as CMA_assmt_score,
sum(case when assessment_type in('CMA','TMA') then weight else 0 end) as total_weight,
count(case when assessment_type = 'Exam' then 1 else NULL end) as final_exam,
count(case when is_banked = '1' then 1 else NULL end) as is_reenrolled
FROM public."studentAssessmentFULLSTG"
-- ON assmt.id_student = csrt.id_student
where id_student in (select id_student from public."studentAssessmentFULLSTG" 
where is_banked = 1)
group by id_student,code_module) as assmtSTG


ON assmtSTG.id_student = csrt.id_student
order by 
-- final_result desc, 
csrt.id_student
);

/********* SQL DOCUMENTATION *****
Creates the table for the Student Course Registration Features table
	module_presentation_length - length of the class by days; integer
	Year - the class was taken (2013 or 2014)	
	Term - B means February and J means October
	start_month - translated from term; FEB means February and OCT mean October
	pass_fail_ind - pass fail indicator where NULL means withdrawn and PASS means either pass or distinction
	reg_period - registration period
						WEEKB4 - students registered within a week (0-7 days) before the class started
						MONTHB4 - students registered greater than a week and a month (30 days) before the class started 	
						QUARTERB4 - students registered greater than a month and a quarter (90 days) before the class started
						LONGB4 - students registered greater than 90 days before the class started
	module_domain - group of the type of class from Martin (dataset owner)
						Social Science courses are defined as AAA, BBB, and GGG
    					STEM courses are defined as CCC, DDD, EEE, FFF
	 
*********** SQL DOCUMENTATION ***** */

CREATE TABLE public."studentCourseRegistrationFeatures"
  AS (
	SELECT 
		crse.module_presentation_length,
		SUBSTRING(crse.code_presentation, 1, 4) as YEAR,
		SUBSTRING(crse.code_presentation, 5, 1) as TERM,
		CASE
    		WHEN SUBSTRING(crse.code_presentation, 5, 1) = 'B' THEN 'FEB'
    		WHEN SUBSTRING(crse.code_presentation, 5, 1) = 'J' THEN 'OCT'
    		ELSE NULL
		END AS start_month,
		stdt.*,
		CASE
    		WHEN UPPER(final_result) = 'FAIL' THEN 'FAIL'
    		WHEN UPPER(final_result) = 'PASS' THEN 'PASS'
    		WHEN UPPER(final_result) = 'DISTINCTION' THEN 'PASS'
    		ELSE NULL
		END AS pass_fail_ind,
	    stdtreg.date_registration, stdtreg.date_unregistration,
	    CASE
    		WHEN stdtreg.date_registration between -7 and 0 THEN 'WEEKB4'
    		WHEN stdtreg.date_registration between -30 and -8 THEN 'MONTHB4'
    		WHEN stdtreg.date_registration between -90 and -31 THEN 'QUARTERB4'
    		WHEN stdtreg.date_registration < -91 THEN 'LONGB4'
    		WHEN stdtreg.date_registration between 0 and 7 THEN 'WEEKAFTER'
    		WHEN stdtreg.date_registration between 8 and 30 THEN 'MONTHAFTER'
    		WHEN stdtreg.date_registration between 31 and 90 THEN 'QUARTERAFTER'
    		WHEN stdtreg.date_registration > 91 THEN 'LONGAFTER'
    		ELSE NULL
		END AS reg_period,
		CASE
    		WHEN stdt.code_module in ('AAA','BBB','GGG') THEN 'SocialScience'
    		WHEN stdt.code_module in ('CCC','DDD','EEE','FFF') THEN 'STEM'
    		ELSE NULL
		END AS module_domain
	FROM
		public."studentInfoSTG" as stdt,
		public."coursesSTG" as crse,
		public."studentRegistrationSTG" as stdtreg
	WHERE
		stdt.id_student = stdtreg.id_student and stdt.code_presentation = stdtreg.code_presentation and stdt.code_module = stdtreg.code_module
		AND crse.code_presentation = stdtreg.code_presentation and crse.code_module = stdtreg.code_module
	ORDER BY stdtreg.id_student, stdtreg.code_module, stdtreg.code_presentation
  );

/********* SQL DOCUMENTATION *****

	Combining all the feature datasets to create one table at the student, module, and presentation level

*********** SQL DOCUMENTATION ***** */

Create table public."analysisDataset"
as (
select stdtreg.id_student, stdtreg.code_module, stdtreg.code_presentation, stdtreg.module_domain, stdtreg.module_presentation_length,
        stdtreg.term, stdtreg.year, stdtreg.num_of_prev_attempts,
	   vle.b4_sum_clicks, vle.q1_sum_clicks, vle.q2_sum_clicks, vle.q3_sum_clicks, vle.q4_sum_clicks,
	   asmt.cma_assmt_score, asmt.tma_assmt_score, asmt.tma_cma_assmt_score, asmt.final_exam, asmt.total_weight, stdtreg.final_result, stdtreg.pass_fail_ind,
	   stdtreg.reg_period, stdtreg.date_registration, stdtreg.date_unregistration,
	   stdtreg.disability, stdtreg.gender, stdtreg.age_band, stdtreg.region, stdtreg.highest_education,
	     stdtreg.imd_band, stdtreg.studied_credits
	   
from
	public."studentCourseRegistrationFeatures" stdtreg,
	public."studentVleFeatures" vle,
	public."studentAssessmentFeatures" asmt
where stdtreg.id_student = asmt.id_student AND stdtreg.code_module = asmt.code_module AND stdtreg.code_presentation = asmt.code_presentation
  AND stdtreg.id_student = vle.id_student AND stdtreg.code_module = vle.code_module AND stdtreg.code_presentation = vle.code_presentation
);

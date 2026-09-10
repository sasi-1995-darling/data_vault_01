    select * from ({{ data_exist('hub_question','US.SIMPLESAT.QUESTION')}}) 
    union all
    select * from ({{ data_exist('hub_question','US.SIMPLESAT_YALE.QUESTION')}}) 
    union all
    select * from ({{ data_exist('hub_response','US.SIMPLESAT.RESPONSE')}}) 
    union all
    select * from ({{ data_exist('hub_response','US.SIMPLESAT_YALE.RESPONSE')}}) 
    union all
    select * from ({{ data_exist('hub_survey','US.SIMPLESAT.SURVEY')}}) 
    union all
    select * from ({{ data_exist('hub_survey','US.SIMPLESAT_YALE.SURVEY')}})
    union all
    select * from ({{ data_exist('lnk_survey_question_response_answer','US.SIMPLESAT.ANSWER')}}) 
    union all
    select * from ({{ data_exist('lnk_survey_question_response_answer','US.SIMPLESAT_YALE.ANSWER')}}) 
    union all
    select * from ({{ data_exist('lsat_survey_question_response_answer','US.SIMPLESAT.ANSWER')}})
    union all
    select * from ({{ data_exist('sat_question_rules__simplesat','US.SIMPLESAT.QUESTION_RULE')}})
    union all
    select * from ({{ data_exist('sat_question_details__simplesat','US.SIMPLESAT.QUESTION')}})
    union all
    select * from ({{ data_exist('sat_response_details__simplesat','US.SIMPLESAT.RESPONSE')}})
    union all
    select * from ({{ data_exist('sat_survey_details__simplesat','US.SIMPLESAT.SURVEY')}})
    union all
    select * from ({{ data_exist('lmsat_survey_question_response_answer__simplesat_yale','US.SIMPLESAT_YALE.ANSWER')}})
    union all
    select * from ({{ data_exist('msat_question_details__simplesat_yale','US.SIMPLESAT_YALE.QUESTION')}})
    union all
    select * from ({{ data_exist('msat_question_rules__simplesat_yale','US.SIMPLESAT_YALE.QUESTION_RULE')}})
    union all
    select * from ({{ data_exist('msat_response_details__simplesat_yale','US.SIMPLESAT_YALE.RESPONSE')}})
    union all
    select * from ({{ data_exist('msat_survey_details__simplesat_yale','US.SIMPLESAT_YALE.SURVEY')}})
SELECT * FROM (
    {{ check_not_null_v2(
        'fact_survey_response',
        [
            'FORM_BK',
            'PROJECT_BK',
            'REC_SRC',
            'BKCC',
            'SOURCE',
            'QUESTION_NAME'
        ],
        'BKCC',
        'Filling_Survey'
    ) }}
)
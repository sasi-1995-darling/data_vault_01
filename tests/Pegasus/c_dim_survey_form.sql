SELECT * FROM (
    {{ check_not_null_v2(
        'dim_survey_form',
        [
            'FORM_BK',
            'BKCC',
            'REC_SRC',
            'FORM_TYPE'
        ],
        'BKCC',
        'Filling_Survey'
    ) }}
)
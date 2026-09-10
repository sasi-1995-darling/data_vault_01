SELECT * FROM (
    {{ check_not_null_v2(
        'dim_survey_project',
        [
            'PROJECT_BK',
            'BKCC',
            'REC_SRC'
        ],
        'BKCC',
        'Filling_Survey'
    ) }}
)
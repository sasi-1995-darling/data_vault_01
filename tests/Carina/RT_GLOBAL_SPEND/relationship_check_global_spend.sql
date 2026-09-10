{{check_relation_exists('fact_global_spend_detail','po_header_id','dim_po_header','po_header_bk'
,'bkcc',["'Hiding_Tiger','Crouching_Dragon','Swimming_Ocean','Jumping_River','Diving_Sea','Kicking_Panda'"],
'BKCC',["'Hiding_Tiger','Crouching_Dragon','Swimming_Ocean','Jumping_River','Diving_Sea','Kicking_Panda'"])}}
union all
{{check_relation_exists('fact_global_spend_detail','legal_entity_bk','dim_legal_entity','legal_entity_bk'
,'bkcc',["'Hiding_Tiger','Crouching_Dragon','Swimming_Ocean','Jumping_River','Diving_Sea','Kicking_Panda'"],
'BKCC',["'Hiding_Tiger','Crouching_Dragon','Swimming_Ocean','Jumping_River','Diving_Sea','Kicking_Panda'"])}}


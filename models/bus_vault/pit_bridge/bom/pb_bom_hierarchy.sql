
{{
    config(
        cluster_by=['bkcc', 'assembly_item_hk', 'assembly_alt_bom']
    )
}}


with cte_sat_bom_header__ml_ebs as (select * from {{ ref('sat_bom_header__ml_ebs') }})

, cte_sat_bom_header__ml_ebs_latest as (
    {{ generate_cte_satellite_latest('cte_sat_bom_header__ml_ebs','bom_hk') }}
)

, cte_lsat_bom_item__ml_ebs_latest as (
    select
        *        
        , row_number() over (partition by lnk_bom_item_hk order by implementation_date desc, load_dts desc) as row_num -- only the lastest items/bill sequence id combination
    from {{ ref('lsat_bom_item__ml_ebs') }}
    qualify row_num = 1
)

, cte_lmsat_item_version__winn_sap as (
	SELECT DISTINCT 
         plant_item_hk
		,matnr
		,werks
		,verid
		,bdatu
		,adatu
		,stlal
		,stlan
		,glchangetime
		,psa_load_dts
	FROM  {{ ref('lmsat_item_version__winn_sap') }} -- Z_MKAL, Only latest version (snapshot)
	WHERE Regexp_like(verid, '^[0-9]+$') and bdatu >= to_char(CURRENT_DATE, 'YYYYMMDD') and adatu <= to_char(CURRENT_DATE, 'YYYYMMDD')
    qualify row_number() OVER (PARTITION BY matnr,werks ORDER BY verid ASC) = 1 -- only production - VERID with NUMERIC values
)

, cte_lmsat_bom_plant_item__winn_sap as (
	SELECT *
	FROM  {{ ref('lmsat_bom_plant_item__winn_sap') }} -- Z_MAST, Only latest version (snapshot)
		qualify row_number() OVER (PARTITION BY matnr,werks,stlan,stlnr,stlal ORDER BY andat DESC) = 1
)

, cte_msat_bom_header__winn_sap as (
	SELECT *
	FROM  {{ ref('msat_bom_header__winn_sap') }}  -- Z_STKO, Only latest version (snapshot)
	WHERE datuv <= to_char(CURRENT_DATE, 'YYYYMMDD') qualify row_number() OVER (PARTITION BY stlty,stlnr,stlal ORDER BY stkoz DESC) = 1
)

, cte_msat_bom_component_selection__winn_sap
AS (
	SELECT *
	FROM  {{ ref('msat_bom_component_selection__winn_sap') }}  -- Z_STAS, Only latest version (snapshot)
	WHERE datuv <= to_char(CURRENT_DATE, 'YYYYMMDD') qualify row_number() OVER (PARTITION BY stlty,stlnr,stlal,stlkn ORDER BY stasz DESC) = 1
	)

, cte_lmsat_bom_component_item__winn_sap as (
	SELECT *exclude(menge), menge ::float as menge
	FROM  {{ ref('lmsat_bom_component_item__winn_sap') }}  -- Z_STPO, Only latest version (snapshot)
	WHERE datuv <= to_char(CURRENT_DATE, 'YYYYMMDD') qualify row_number() OVER (PARTITION BY stlty,stlnr,stlkn ORDER BY stpoz DESC) = 1
)

, cte_sat_item_plant_special_procurement__winn_sap as (
	SELECT *
	FROM {{ ref('lsat_item_plant_special_procurement__winn_sap') }}
	qualify row_number() OVER (PARTITION BY matnr,werks,sobsl ORDER BY load_dts DESC) = 1
    
)


, cte_special_procurement as (
    select marc.sobsl,pt.wrk02,psp.matnr,psp.werks,marc.*exclude(sobsl)
    from {{ ref('lnk_item_plant_special_procurement') }} marc
    inner join {{ ref('lnk_same_as_plant_transfer') }} t460a
    on marc.plant_hk=t460a.plant_hk
    and marc.sobsl=t460a.sobsl
    left join {{ ref('lsat_same_as_plant_transfer__winn_sap') }} pt
    on t460a.slnk_lnk_same_as_plant_transfer_hk=pt.slnk_lnk_same_as_plant_transfer_hk
    left join cte_sat_item_plant_special_procurement__winn_sap psp
    on marc.lnk_item_plant_special_procurement_hk=psp.lnk_item_plant_special_procurement_hk

)


---- BASE LAYER ----

, base_tmlc as (
    select
        hi.item_hk as assembly_item_hk
        , hi.item_bk as assembly_item_bk
        , to_char(bhdr.assembly_item_id) as assembly_item_id
        , hp.plant_hk as assembly_plant_hk
        , hp.plant_bk as assembly_plant_bk
        , to_char(bhdr.organization_id) as assembly_plant_id
        , hb.bom_hk as assembly_bom_hk
        , hb.bom_bk as assembly_bom_bk
        , to_char(bhdr.bill_sequence_id) as assembly_bom_id
        , to_char(bhdr.structure_type_id) as assembly_bom_category
        , to_char(bhdr.assembly_type) as assembly_bom_usage
        , coalesce(bhdr.alternate_bom_designator, 'PRIMARY') as assembly_alt_bom  --adopted from existing ML business logic
        , bhdr.is_preferred as bom_is_preferred
        , bhdr.implementation_date as bom_implementation_date
        , null as bom_change_notice
        , hichild.item_hk as component_item_hk
        , hichild.item_bk as component_item_bk
        , to_char(bitm.component_item_id) as component_item_id
        , bitm.component_quantity ::float as component_quantity
        , null as component_uom
        , to_char(bitm.item_num) as component_item_num
        , to_char(bitm.operation_seq_num) as component_operation_sequence_num
        , to_char(bitm.component_sequence_id) as component_sequence_id
        , null as component_item_node_num
        , to_char(bitm.bom_item_type) as component_bom_item_type
        , bitm.supply_subinventory as component_supply_subinventory
        , to_char(bitm.wip_supply_type) as component_wip_supply_type
        , to_char(bitm.mutually_exclusive_options) as component_mutually_exclusive_options
        , to_char(bitm.optional) as component_optional
        , to_char(bitm.include_in_cost_rollup) as include_component_in_cost_rollup
        , bitm.change_notice as component_change_notice
        , bitm.implementation_date as component_effective_from
        , bitm.disable_date as component_effective_to
        , null as special_procurement_type
        , null as wrk02_transfer_plant
		, null AS item_bom_id
		, null AS item_load_dts
		, null AS header_bom_id
		, null AS header_load_dts		
        , hb.bkcc
        , hb.rec_src
    from {{ ref('lnk_bom_plant_item_hierarchical') }} as hlnk
        inner join {{ ref('hub_bom') }} as hb
            on hlnk.bom_hk = hb.bom_hk
                and hb.bkcc = 'Crouching_Dragon'
                --avoid null values from left join on satellite due to deleted records
                and hb.bom_hk not in (
                    select bom_hk from cte_sat_bom_header__ml_ebs_latest where _fivetran_deleted = true
                )
        inner join {{ ref('hub_item_v1') }} as hi
            on hlnk.assembly_item_hk = hi.item_hk
                and hi.bkcc = 'Crouching_Dragon'
        inner join {{ ref('hub_plant_v1') }} as hp
            on hlnk.plant_hk = hp.plant_hk
                and hp.bkcc = 'Crouching_Dragon'
        inner join {{ ref('lnk_bom_item') }} as lnkbi
            on hb.bom_hk = lnkbi.bom_hk
                and hlnk.component_item_hk = lnkbi.item_hk
                --avoid null values from left join on satellite due to deleted records
                and lnkbi.lnk_bom_item_hk not in (
                    select lnk_bom_item_hk from cte_lsat_bom_item__ml_ebs_latest where _fivetran_deleted = true
                )
        left join {{ ref('hub_item_v1') }} as hichild
            on lnkbi.item_hk = hichild.item_hk
                and hichild.bkcc = 'Crouching_Dragon'
        left join cte_sat_bom_header__ml_ebs_latest as bhdr
            on hb.bom_hk = bhdr.bom_hk
                and bhdr._fivetran_deleted = false
        left join cte_lsat_bom_item__ml_ebs_latest as bitm
            on lnkbi.lnk_bom_item_hk = bitm.lnk_bom_item_hk
                and bitm._fivetran_deleted = false
)

, base_winnsap as (
	SELECT DISTINCT bpihlnk.assembly_item_hk
		,ihub.item_bk AS assembly_item_bk
		,mast.matnr AS assembly_item_id
		,phub.plant_hk AS assembly_plant_hk
		,phub.plant_bk AS assembly_plant_bk
		,mast.werks AS assembly_plant_id
		,bhub.bom_hk AS assembly_bom_hk
		,bhub.bom_bk AS assembly_bom_bk
		,mast.stlnr AS assembly_bom_id
		,stko.stlty AS assembly_bom_category
		,mast.stlan AS assembly_bom_usage
		,mast.stlal AS assembly_alt_bom
		,null as bom_is_preferred
		,to_date(stko.datuv,'YYYYMMDD') AS bom_implementation_date
		,stko.aennr AS bom_change_notice
		,ihubchild.item_hk AS component_item_hk
		,ihubchild.item_bk AS component_item_bk
		,stpo.idnrk AS component_item_id
		,stpo.menge as component_quantity
		,stpo.meins AS component_uom
		,stpo.posnr AS component_item_num 
		,stpo.sortf AS component_operation_sequence_num
		,stpo.stpoz AS component_sequence_id
		,stpo.stlkn AS component_item_node_num
		,stpo.objty AS component_bom_item_type
		,NULL AS component_supply_subinventory
		,NULL AS component_wip_supply_type
		,NULL AS component_mutually_exclusive_options
		,NULL AS component_optional
		,stpo.sanka AS include_component_in_cost_rollup
		,stpo.aennr AS component_change_notice
		,to_date(stpo.datuv,'YYYYMMDD') AS component_effective_from
		,to_date(CASE 
			WHEN lead(stpo.datuv) OVER (
					PARTITION BY stpo.stlty
					,stpo.stlnr
					,stpo.posnr ORDER BY stpo.datuv
					) IS NOT NULL
				THEN lead(stpo.datuv) OVER (
						PARTITION BY stpo.stlty
						,stpo.stlnr
						,stpo.posnr ORDER BY stpo.datuv
						)
			ELSE '99991231'
			END,'YYYYMMDD') AS component_effective_to -- effective end_date by setting it to the next version's within the same BOM item slot, based on its original STPO 
        , sp.sobsl AS special_procurement_type
        , sp.wrk02 AS wrk02_transfer_plant
		,stpo.stlnr 	AS item_bom_id
		,stpo.load_dts 	AS item_load_dts
		,stko.stlnr 	AS header_bom_id
		,stko.load_dts 	AS header_load_dts
        ,bhub.bkcc
		,bhub.rec_src		
	FROM {{ ref('lnk_bom_plant_item_hierarchical') }} bpihlnk
	INNER JOIN {{ ref('hub_bom') }} bhub 
        ON bpihlnk.bom_hk = bhub.bom_hk
		AND bhub.bkcc = 'Hiding_Tiger'	
	INNER JOIN {{ ref('hub_item_v1') }} ihub 
        ON bpihlnk.assembly_item_hk = ihub.item_hk
		AND ihub.bkcc = 'Hiding_Tiger'
	INNER JOIN {{ ref('hub_plant_v1') }} phub 
        ON bpihlnk.plant_hk = phub.plant_hk
		AND phub.bkcc = 'Hiding_Tiger'
	INNER JOIN {{ ref('lnk_bom_item') }} bilnk 
        ON bhub.bom_hk = bilnk.bom_hk
		AND bpihlnk.component_item_hk = bilnk.item_hk
		AND bilnk.lnk_bom_item_hk NOT IN (
			SELECT lnk_bom_item_hk
			FROM cte_lmsat_bom_component_item__winn_sap
			WHERE psa_delete_ind = 'Y') 
	INNER JOIN {{ ref('hub_item_v1') }} ihubchild 
        ON bilnk.item_hk = ihubchild.item_hk
		AND ihubchild.bkcc = 'Hiding_Tiger'
	INNER JOIN {{ ref('lnk_bom_plant_item') }} lbpi 
        ON lbpi.bom_hk = bpihlnk.bom_hk
		AND lbpi.item_hk = bpihlnk.assembly_item_hk
		AND lbpi.plant_hk = bpihlnk.plant_hk
	INNER JOIN cte_lmsat_bom_plant_item__winn_sap mast 
        ON lbpi.lnk_bom_plant_item_hk = mast.lnk_bom_plant_item_hk
	INNER JOIN cte_msat_bom_header__winn_sap stko 
        ON mast.stlnr = stko.stlnr
		AND mast.stlal = stko.stlal
	INNER JOIN cte_msat_bom_component_selection__winn_sap stas 
        ON stko.stlnr = stas.stlnr
		AND stko.stlal = stas.stlal
		AND stko.stlty = stas.stlty
	INNER JOIN cte_lmsat_bom_component_item__winn_sap stpo 
        ON stas.stlnr = stpo.stlnr
		AND stas.stlkn = stpo.stlkn
		AND stas.stlty = stpo.stlty
		AND stpo.lnk_bom_item_hk = bilnk.lnk_bom_item_hk
    LEFT JOIN cte_special_procurement sp
        ON sp.matnr = component_item_bk
        AND sp.werks = assembly_plant_bk
	WHERE 1 = 1
        AND (exists(select 1 from cte_lmsat_item_version__winn_sap mkal where
         mkal.matnr = mast.matnr
		 AND mkal.werks = mast.werks
		 AND mkal.stlan = mast.stlan
		 AND mkal.stlal = mast.stlal) or (mast.stlal = '01' and not exists(select 1 from cte_lmsat_item_version__winn_sap mkal where
         mkal.matnr = mast.matnr) ) )
		AND stko.lkenz <> 'X' -- exclude any logically deleted BOM parts (header, selection, or item)
		AND stas.lkenz <> 'X'
		AND stpo.lkenz <> 'X'
		AND STPO.IDNRK <> ''  -- exclude any items lacking a specified component material.
	
	UNION ALL
	
	SELECT 
         bpihlnk.assembly_item_hk
		,ihub.item_bk AS assembly_item_bk
		,mast.matnr AS assembly_item_id
		,phub.plant_hk AS assembly_plant_hk
		,phub.plant_bk AS assembly_plant_bk
		,mast.werks AS assembly_plant_id
		,bhub.bom_hk AS assembly_bom_hk
		,bhub.bom_bk AS assembly_bom_bk
		,mast.stlnr AS assembly_bom_id
		,stko.stlty AS assembly_bom_category
		,mast.stlan AS assembly_bom_usage
		,mast.stlal AS assembly_alt_bom
		,null as bom_is_preferred
		,to_date(stko.datuv,'YYYYMMDD') AS bom_implementation_date
		,stko.aennr AS bom_change_notice
		,ihubchild.item_hk AS component_item_hk
		,ihubchild.item_bk AS component_item_bk
		,stpo.idnrk AS component_item_id
		,stpo.menge AS component_quantity
		,stpo.meins AS component_uom
		,stpo.posnr AS component_item_num 
		,stpo.sortf AS component_operation_sequence_num
		,stpo.stpoz AS component_sequence_id
		,stpo.stlkn AS component_item_node_num
		,stpo.objty AS component_bom_item_type
		,NULL AS component_supply_subinventory
		,NULL AS component_wip_supply_type
		,NULL AS component_mutually_exclusive_options
		,NULL AS component_optional
		,stpo.sanka AS include_component_in_cost_rollup
		,stpo.aennr AS component_change_notice
		,to_date(stpo.datuv,'YYYYMMDD') AS component_effective_from
		,to_date(CASE 
			WHEN lead(stpo.datuv) OVER (
					PARTITION BY stpo.stlty
					,stpo.stlnr
					,stpo.posnr ORDER BY stpo.datuv
					) IS NOT NULL
				THEN lead(stpo.datuv) OVER (
						PARTITION BY stpo.stlty
						,stpo.stlnr
						,stpo.posnr ORDER BY stpo.datuv
						)
			-- ELSE '99991231'
			END,'YYYYMMDD') AS component_effective_to -- effective end_date by setting it to the next version's within the same BOM item slot, based on its original STPO 
        , sp.sobsl AS special_procurement_type
        , sp.wrk02 AS wrk02_transfer_plant
		,stpo.stlnr 	AS item_bom_id
		,stpo.load_dts 	AS item_load_dts
		,stko.stlnr 	AS header_bom_id
		,stko.load_dts 	AS header_load_dts		
        ,bhub.bkcc
		,bhub.rec_src        
	FROM {{ ref('lnk_bom_plant_item_hierarchical') }} bpihlnk 
	INNER JOIN {{ ref('hub_bom') }} bhub 
        ON bpihlnk.bom_hk = bhub.bom_hk
		AND bhub.bkcc = 'Hiding_Tiger'	
	INNER JOIN {{ ref('hub_item_v1') }} ihub 
        ON bpihlnk.assembly_item_hk = ihub.item_hk
		AND ihub.bkcc = 'Hiding_Tiger'
	INNER JOIN {{ ref('hub_plant_v1') }} phub 
        ON bpihlnk.plant_hk = phub.plant_hk
		AND phub.bkcc = 'Hiding_Tiger'
	INNER JOIN {{ ref('lnk_bom_item') }} bilnk 
        ON bhub.bom_hk = bilnk.bom_hk
		AND bpihlnk.component_item_hk = bilnk.item_hk 	
	INNER JOIN {{ ref('hub_item_v1') }} ihubchild 
        ON bilnk.item_hk = ihubchild.item_hk
		AND ihubchild.bkcc = 'Hiding_Tiger'
	INNER JOIN {{ ref('lnk_bom_plant_item') }} lbpi 
        ON lbpi.bom_hk = bpihlnk.bom_hk
		AND lbpi.item_hk = bpihlnk.assembly_item_hk
		AND lbpi.plant_hk = bpihlnk.plant_hk
	INNER JOIN cte_lmsat_bom_plant_item__winn_sap mast 
        ON lbpi.lnk_bom_plant_item_hk = mast.lnk_bom_plant_item_hk
	INNER JOIN cte_msat_bom_header__winn_sap stko 
        ON mast.stlnr = stko.stlnr
		AND mast.stlal = stko.stlal
	INNER JOIN cte_msat_bom_component_selection__winn_sap stas 
        ON stko.stlnr = stas.stlnr
		AND stko.stlal = stas.stlal
		AND stko.stlty = stas.stlty
	INNER JOIN cte_lmsat_bom_component_item__winn_sap stpo 
        ON stas.stlnr = stpo.stlnr
		AND stas.stlkn = stpo.stlkn
		AND stas.stlty = stpo.stlty
		AND stpo.lnk_bom_item_hk = bilnk.lnk_bom_item_hk
    LEFT JOIN cte_special_procurement sp
        ON sp.matnr = component_item_bk
        AND sp.werks = assembly_plant_bk

	WHERE not exists(select 1 from {{ ref('lmsat_item_version__winn_sap') }} mkal where
          mkal.matnr = mast.matnr
		AND mkal.werks = mast.werks
		AND mkal.stlan = mast.stlan
		AND mkal.stlal = mast.stlal)
        AND 1 = 1
        AND mast.stlan not in ( '1','4')
		AND stko.lkenz <> 'X'
		AND stas.lkenz <> 'X'
		AND stpo.lkenz <> 'X'
		AND STPO.IDNRK <> ''
	)

---- FILTER LAYER ----
, filter_tmlc as (
    select
        assembly_item_hk
        , assembly_item_bk
        , assembly_item_id
        , assembly_plant_hk
        , assembly_plant_bk
        , assembly_plant_id
        , assembly_bom_hk
        , assembly_bom_bk
        , assembly_bom_id
        , assembly_bom_category
        , assembly_bom_usage
        , assembly_alt_bom
        , bom_is_preferred
        , bom_implementation_date
        , bom_change_notice
        , component_item_hk
        , component_item_bk
        , component_item_id
        , component_quantity
        , component_uom
        , component_item_num
        , component_operation_sequence_num
        , component_sequence_id
        , component_item_node_num
        , component_bom_item_type
        , component_supply_subinventory
        , component_wip_supply_type
        , component_mutually_exclusive_options
        , component_optional
        , include_component_in_cost_rollup
        , component_change_notice
        , component_effective_from
        , component_effective_to
        , special_procurement_type
        , wrk02_transfer_plant
		, item_bom_id
		, item_load_dts
		, header_bom_id
		, header_load_dts
        , bkcc
        , rec_src
    from base_tmlc
    where 
    /* the following filter is diabled to track the expired/disabled componenets */ 
    -- coalesce(component_effective_to, current_date) >= current_date -- only components that have not been disabled
    -- and 
        coalesce(component_effective_from, bom_implementation_date) <= current_date -- no components/assembly with future implementation dates
    and assembly_alt_bom = 'PRIMARY'
    and assembly_plant_bk in ('ML', 'NG')

)

, filter_winnsap as (
    select distinct
        assembly_item_hk
        , assembly_item_bk
        , assembly_item_id -- mast.matnr
        , assembly_plant_hk
        , assembly_plant_bk
        , assembly_plant_id -- mast.werks
        , assembly_bom_hk
        , assembly_bom_bk
        , assembly_bom_id
        , assembly_bom_category
        , assembly_bom_usage
        , assembly_alt_bom
        , bom_is_preferred
        , bom_implementation_date
        , bom_change_notice
        , component_item_hk
        , component_item_bk
        , component_item_id
        , component_quantity
        , component_uom
        , component_item_num
        , component_operation_sequence_num
        , component_sequence_id
        , component_item_node_num
        , component_bom_item_type
        , component_supply_subinventory
        , component_wip_supply_type
        , component_mutually_exclusive_options
        , component_optional
        , include_component_in_cost_rollup
        , component_change_notice
        , component_effective_from
        , component_effective_to
        , special_procurement_type
        , wrk02_transfer_plant
		, item_bom_id -- stpo.stlnr
		, item_load_dts -- stpo.load_dts
		, header_bom_id -- stko.stlnr
		, header_load_dts -- stko.load_dts 	
        , bkcc
        , rec_src
    from base_winnsap   
    qualify row_number() OVER (PARTITION BY assembly_item_bk,assembly_plant_bk,component_item_bk ORDER BY assembly_bom_usage,assembly_alt_bom ASC) = 1 
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    select * from filter_tmlc
    UNION ALL
    select * from filter_winnsap
)

---- FINAL LAYER ----
select 
 assembly_item_hk
        , assembly_item_bk
        , assembly_item_id -- mast.matnr
        , assembly_plant_hk
        , assembly_plant_bk
        , assembly_plant_id -- mast.werks
        , assembly_bom_hk
        , assembly_bom_bk
        , assembly_bom_id
        , assembly_bom_category
        , assembly_bom_usage
        , assembly_alt_bom
        , bom_is_preferred
        , bom_implementation_date
        , bom_change_notice
        , component_item_hk
        , component_item_bk
        , component_item_id
        , component_quantity
        , component_uom
        , component_item_num
        , component_operation_sequence_num
        , component_sequence_id
        , component_item_node_num
        , component_bom_item_type
        , component_supply_subinventory
        , component_wip_supply_type
        , component_mutually_exclusive_options
        , component_optional
        , include_component_in_cost_rollup
        , component_change_notice
        , component_effective_from
        , component_effective_to
        , special_procurement_type
        , wrk02_transfer_plant
		, item_bom_id 
		, item_load_dts 
		, header_bom_id 
		, header_load_dts 
        , bkcc
        , rec_src    
        , greatest_ignore_nulls( header_load_dts, item_load_dts, component_effective_from, iff(component_effective_to > current_date, null , component_effective_to))::date drvd_bom_explosion_cdc_dt
from   JOIN_RESULT 
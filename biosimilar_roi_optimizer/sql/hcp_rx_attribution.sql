--adding dates to the tables
update hcp
set CLM_FROM_DT_NEW = (strptime(cast(CLM_FROM_DT as varchar),'%Y%m%d'))::date
where CLM_FROM_DT is not null;

--event level pde_attribute table
create or replace table pde_attributes as
    with temp_pde as(
        select 
            a.*, 
            b."PRF_PHYSN_NPI_1" PROVIDER_NPI, 
            b."CLM_FROM_DT_NEW",
            abs(datediff('day',"CLM_FROM_DT_NEW","PDE_DATE")) DIFF, 
            if(abs(datediff('day',"CLM_FROM_DT_NEW","PDE_DATE"))<= 60, 1, 0) as PROX_FLAG 
        from pde_trim a left join hcp b
            on a."DESYNPUF_ID" = b."DESYNPUF_ID"
            where "PRF_PHYSN_NPI_1" is not null and a."DESYNPUF_ID" in (select distinct "DESYNPUF_ID" from crc_patients) 
    )
    , a as(
        select row_number() over( partition by "PDE_EVENT_ID" order by diff asc, "PDE_DATE" asc) rank_a, * from temp_pde where prox_flag = 1
    )
    select a."PDE_EVENT_ID", a."DESYNPUF_ID", a."PDE_DATE", a."PROD_SRVC_ID", a."QTY_DSPNSD_NUM", a."DAYS_SUPLY_NUM", a."PTNT_PAY_AMT", a."TOT_RX_CST_AMT", a."PROVIDER_NPI" from a where rank_a = 1;

--primary hcp table
create or replace table primary_hcp AS
with a as(
    select 
        "DESYNPUF_ID", 
        "PRF_PHYSN_NPI_1", 
        count(distinct "CLM_ID") CLM_CT, 
        min("CLM_FROM_DT_NEW") MIN_CLM_DT
    from hcp 
        where "DESYNPUF_ID" in (select "DESYNPUF_ID" from crc_patients) and "PRF_PHYSN_NPI_1" is not null
        group by 1,2
), b as(
    select 
        a."DESYNPUF_ID", 
        a."PRF_PHYSN_NPI_1",
        row_number() over( partition by "DESYNPUF_ID" order by clm_ct desc, "MIN_CLM_DT" asc) HCP_RANK
    from a 
)
select b."DESYNPUF_ID", b."PRF_PHYSN_NPI_1" PRIMARY_NPI from b where hcp_rank=1;

--hcp segmentation table
create or replace table hcp_final AS
with a as(
    select a.*, b.drug_class from pde_attributes a left join drug_class_map b on a.prod_srvc_id = b.prod_srvc_id  
), b as(
    SELECT
        b."PRIMARY_NPI" PROVIDER_NPI,
        count(distinct a."DESYNPUF_ID") CRC_PT_COUNT,
        count(*) filter(where drug_class = 'originator') as originator_rx_events,
        sum(TOT_RX_CST_AMT) filter(where drug_class = 'originator') as originator_rx_spend,
        count(*) filter(where drug_class = 'biosimilar') as biosimilar_rx_events,
        sum(TOT_RX_CST_AMT) filter(where drug_class = 'biosimilar') as biosimilar_rx_spend,
        count(*) total_rx_events,
        sum(TOT_RX_CST_AMT) total_rx_spend
    from a join primary_hcp b on a."DESYNPUF_ID"=b."DESYNPUF_ID"
    group by 1
) select * from b;

--drug_class table
create or replace table drug_class_map AS
select * from (values
('00002840001', 'originator'),
('54868540600', 'originator'),
('62381840001', 'originator'),
('62381897101', 'originator'),
('00002897101', 'originator'),
('00002840099', 'originator'),
('62381840009', 'originator'),
('00115107103', 'biosimilar'),
('00814260614', 'biosimilar'),
('42291052610', 'biosimilar'),
('51079006840', 'biosimilar'),
('47679029035', 'biosimilar'),
('00781189010', 'biosimilar'),
('00597001810', 'biosimilar'),
('00405435103', 'biosimilar'),
('60491050730', 'biosimilar'),
('00349235310', 'biosimilar'),
('54269012301', 'biosimilar'),
('60491050730', 'biosimilar'),
('00406218901', 'biosimilar')
) as t(prod_srvc_id,drug_class);

select * from hcp_final;
-- comp_summary.sql 
-- put together for the dept reporting ask - jm 
-- TODO: check with payroll on the 2023 backfill, OT numbers looked off 
 
{{ config(materialized='table') }} 
 
with comp as ( 
  select * from {{ ref('stg_comp') }} 
  where fiscal_year >= 2019 and fiscal_year <= 2025 
), 
 
-- benefits_adj as ( 
--     select employee_id, fiscal_year, benefits * 1.08 as benefits_loaded 
--     from comp 
-- ), 
 
dedup as ( 
    select * 
    from comp 
    qualify row_number() over (partition by employee_id, fiscal_year order by 1) = 1 
), 
 
final as ( 
select 
  d.employee_id, 
  d.emp_name, 
  d.fiscal_year, 
  dl.dept_name, 
  d.job_title, 
  d.fte_pct, 
  cast(d.base_pay as float) as base_pay, 
  cast(d.overtime_pay as float) as overtime_pay, 
  coalesce(cast(d.other_pay as float), 0) as other_pay, 
  cast(d.benefits as float) as benefits, 
  cast(d.base_pay as float) + cast(d.overtime_pay as float) + coalesce(cast(d.other_pay as float),0) + cast(d.benefits as float) as total_comp, 
      cast(d.overtime_pay as float) / nullif(cast(d.base_pay as float),0) as ot_ratio 
from dedup d 
left join {{ ref('department_lookup') }} dl on d.dept_id = dl.dept_id 
where d.fiscal_year >= 2021 
) 
 
select *, 
    case when ot_ratio > .5 then 'High' else 'Normal' end as ot_flag 
from final 

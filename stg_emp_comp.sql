-- stg_emp_comp.sql
-- Staging table for compensation data. Cleans and deduplicates the data before it is used in other models.
-- This model is materialized as a table to improve performance for downstream models.

with raw_comp as (
    select * from {{ source('payroll', 'compensation') }}
),

--select the least amount of PII possible and cast the numeric columns to float for consistency
columns_cleaned as (
    select
        employee_id,
        fiscal_year,
        dept_id,
        zeroifnull(cast(fte_pct as float)) as fte_pct,
        zeroifnull(cast(base_pay as float)) as base_pay,
        zeroifnull(cast(overtime_pay as float)) as overtime_pay,
        zeroifnull(cast(other_pay as float)) as other_pay,
        zeroifnull(cast(benefits as float)) as benefits
    from raw_comp
),

--remove any duplicate rows
final_select as (
    select distinct *
    from columns_cleaned
)
-- Make generated native IG natural primary keys visible/editable.
--
-- ID-style primary keys stay hidden. Natural keys such as STATUS_NAME, RU,
-- HOLIDAY_DATE, and NOTE_KEY are meaningful application values and should show
-- in the grid.
--
-- Usage:
--   @repair_generated_ig_natural_keys.sql 101
--   @repair_generated_ig_natural_keys.sql 100

set define on verify off feedback on serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

define HUB_APP_ID = &1

alter session set container=FREEPDB1;

declare
  l_count number;
begin
  update apex_260100.wwv_flow_region_columns rc
     set rc.item_type = case
                          when rc.data_type = 'DATE' then 'NATIVE_DATE_PICKER_APEX'
                          else 'NATIVE_TEXT_FIELD'
                        end,
         rc.is_visible = 'Y',
         rc.value_protected = 'N',
         rc.include_in_export = 'Y',
         rc.attribute_01 = case
                             when rc.data_type = 'DATE' then 'N'
                             else 'BOTH'
                           end,
         rc.attributes = case
                           when rc.data_type = 'DATE' then '{"show_time":"N","min_date":"NONE","max_date":"NONE","use_defaults":"Y"}'
                           else '{"trim_spaces":"BOTH"}'
                         end
   where rc.flow_id = &HUB_APP_ID
     and rc.page_id between 50 and 78
     and rc.is_primary_key = 'Y'
     and not (rc.data_type = 'NUMBER' or rc.name like '%\_ID' escape '\');

  l_count := sql%rowcount;
  dbms_output.put_line('Natural primary key columns repaired: ' || l_count);

  commit;
end;
/

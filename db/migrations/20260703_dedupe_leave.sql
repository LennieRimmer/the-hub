-- Remove exact duplicate leave facts and prevent them from being reloaded.
--
-- Keeps the lowest LEAVE_ID for each exact leave fact:
--   MEMBER_ID, LEAVE_DATE, HOURS, TIME_TYPE, STATUS, NOTES
--
-- The David Barth 2026-06-12 correction row is preserved because it has
-- different HOURS and NOTES from the regular leave entry.

set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

alter session set container=FREEPDB1;

declare
  l_duplicate_count number;
  l_deleted_count   number;
  l_backup_count    number;
  l_index_count     number;
begin
  select count(*)
    into l_duplicate_count
    from (
      select leave_id,
             row_number() over (
               partition by member_id,
                            leave_date,
                            hours,
                            nvl(time_type, '~'),
                            nvl(status, '~'),
                            nvl(notes, '~')
               order by leave_id
             ) rn
        from thehub.leave
    )
   where rn > 1;

  dbms_output.put_line('Exact duplicate leave rows found: ' || l_duplicate_count);

  begin
    execute immediate q'[
      create table thehub.leave_dedupe_backup (
        backup_at timestamp default systimestamp not null,
        leave_id number not null,
        member_id number not null,
        leave_date date not null,
        hours number(5,2) not null,
        time_type varchar2(50),
        status varchar2(50),
        notes varchar2(500)
      )
    ]';
    dbms_output.put_line('Created THEHUB.LEAVE_DEDUPE_BACKUP.');
  exception
    when others then
      if sqlcode = -955 then
        dbms_output.put_line('THEHUB.LEAVE_DEDUPE_BACKUP already exists.');
      else
        raise;
      end if;
  end;

  execute immediate q'[
    insert into thehub.leave_dedupe_backup (
      leave_id,
      member_id,
      leave_date,
      hours,
      time_type,
      status,
      notes
    )
    select leave_id,
           member_id,
           leave_date,
           hours,
           time_type,
           status,
           notes
      from (
        select l.*,
               row_number() over (
                 partition by member_id,
                              leave_date,
                              hours,
                              nvl(time_type, '~'),
                              nvl(status, '~'),
                              nvl(notes, '~')
                 order by leave_id
               ) rn
          from thehub.leave l
      )
     where rn > 1
  ]';

  l_backup_count := sql%rowcount;
  dbms_output.put_line('Duplicate rows backed up this run: ' || l_backup_count);

  delete from thehub.leave
   where leave_id in (
     select leave_id
       from (
         select leave_id,
                row_number() over (
                  partition by member_id,
                               leave_date,
                               hours,
                               nvl(time_type, '~'),
                               nvl(status, '~'),
                               nvl(notes, '~')
                  order by leave_id
                ) rn
           from thehub.leave
       )
      where rn > 1
   );

  l_deleted_count := sql%rowcount;
  dbms_output.put_line('Duplicate rows deleted: ' || l_deleted_count);

  select count(*)
    into l_index_count
    from all_indexes
   where owner = 'THEHUB'
     and index_name = 'LEAVE_UQ_MEMBER_DATE_FACT';

  if l_index_count = 0 then
    execute immediate q'[
      create unique index thehub.leave_uq_member_date_fact
        on thehub.leave (
          member_id,
          leave_date,
          hours,
          nvl(time_type, '~'),
          nvl(status, '~'),
          nvl(notes, '~')
        )
    ]';
    dbms_output.put_line('Created THEHUB.LEAVE_UQ_MEMBER_DATE_FACT.');
  else
    dbms_output.put_line('THEHUB.LEAVE_UQ_MEMBER_DATE_FACT already exists.');
  end if;

  commit;
end;
/

select count(*) as total_leave_rows
  from thehub.leave;

select count(*) as duplicate_leave_facts
  from (
    select member_id,
           leave_date,
           hours,
           nvl(time_type, '~') time_type_key,
           nvl(status, '~') status_key,
           nvl(notes, '~') notes_key,
           count(*) row_count
      from thehub.leave
     group by member_id,
              leave_date,
              hours,
              nvl(time_type, '~'),
              nvl(status, '~'),
              nvl(notes, '~')
    having count(*) > 1
  );

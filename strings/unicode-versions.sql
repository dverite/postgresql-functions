/* Return the Unicode version supported by each locale provider,
   by testing letters added to Unicode up to version 17. */
create function unicode_versions() returns table(provider text, u_version text)
as $$
declare
 check_query text;
 libc_collation text:= 'default';
 db_provider text;
 db_ctype text;
 query_template constant text := $query$
   select
   case
    when U&'\088F' ~ '\w' <col> then '>= 17'
    when U&'\1C89' ~ '\w' <col> then '16'
    when U&'\+01123F' ~ '\w' <col> then '15'
    when U&'\0870' ~ '\w' <col> then '14'
    when U&'\08BE' ~ '\w' <col> then '13'
    when U&'\0E86' ~ '\w' <col> then '12'
    when U&'\0560' ~ '\w' <col> then '11'
    when U&'\0860' ~ '\w' <col> then '10'
    when U&'\08B6' ~ '\w' <col> then '9'
    when U&'\08B3' ~ '\w' <col> then '8'
    when U&'\037F' ~ '\w' <col> then '7'
    when U&'\0526' ~ '\w' <col> then '6'
    when U&'\0524' ~ '\w' <col> then '5.2'
    when U&'\0370' ~ '\w' <col> then '5.1'
    when U&'\0252' ~ '\w' <col> then '5'
    when U&'\0237' ~ '\w' <col> then '4.1'
    when U&'\0221' ~ '\w' <col> then '4.0'
    when U&'\0220' ~ '\w' <col> then '3.2'
    when U&'\03F4' ~ '\w' <col> then '3.1'
    when U&'\01F6' ~ '\w' <col> then '3.0'
    else '< 3.0'    -- released before 1999
  end
 $query$;

begin
  if current_setting('server_encoding') <> 'UTF8' then
   raise exception 'can only be used only in UTF-8 databases';
  end if;

  if current_setting('server_version_num') >= '150000' then
    select datlocprovider from pg_database where datname=current_database()
      into db_provider;
  else
    db_provider:='c';
  end if;

  select datctype from pg_database where datname=current_database()
    into db_ctype;

  if db_provider <> 'c' or (db_provider='c' and db_ctype in ('C', 'POSIX')) then
    -- try to find a libc Unicode-aware collation when the default collation is not suitable
    select collname from pg_collation where collprovider='c' and collctype not in ('C', 'POSIX') and collencoding=6 limit 1
      into libc_collation;
    if not FOUND then
      raise exception 'cannot find a suitable libc collation to check code points';
    end if;
  end if;
  select replace(query_template, '<col>', format('COLLATE %I', libc_collation))
    into check_query;
  execute check_query
    into u_version;
  provider:='libc';
  return next;

  if exists (select 1 from pg_collation where collprovider='i' and collname='und-x-icu') then
    provider:='icu';
    select replace(query_template, '<col>', 'COLLATE "und-x-icu"')
      into check_query;
    execute check_query
      into u_version;
    return next;
  end if;

  if exists (select 1 from pg_collation where collprovider='b' and collname='pg_c_utf8') then
    provider:='builtin';
    select replace(query_template, '<col>', 'COLLATE "pg_c_utf8"')
      into check_query;
    execute check_query
      into u_version;
    return next;
  end if;
end
$$ language plpgsql;

/*
 * Truncate the UTF-8 string argument at the given number of bytes,
 * removing any additional bytes at the end that would otherwise
 * be part of an incomplete multibyte sequence.
 */
CREATE FUNCTION utf8_truncate(str text, len int) returns text
as $$
select case when octet_length(str) <= len then str
else (
   with bstr(s) as (select convert_to(str, 'UTF-8'))
   select
   case
   when len>=1 and (get_byte(s, len) & 192) <> 128
   then convert_from(substring(s, 1, len), 'UTF-8')
   else
     case
     when len>=2 and (get_byte(s, len-1) & 192) <> 128
     then convert_from(substring(s, 1, len-1), 'UTF-8')
     else
       case
       when len>=3 and (get_byte(s, len-2) & 192) <> 128
       then convert_from(substring(s, 1, len-2), 'UTF-8')
       else
         case
         when len>=4 and (get_byte(s, len-3) & 192) <> 128
         then convert_from(substring(s, 1, len-3), 'UTF-8')
         else ''
         end
       end
     end
   end
 from bstr)
   end;
$$ language sql strict immutable parallel safe;

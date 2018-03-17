/* Return the size (bigint) of the large object passed as parameter */
CREATE FUNCTION lo_size(oid) RETURNS bigint
AS $$
DECLARE
 fd integer;
 sz bigint;
BEGIN
 fd := lo_open($1, 262144); -- INV_READ
 if (fd < 0) then
   raise exception 'Failed to open large object %', $1;
 end if;
 sz := lo_lseek64(fd, 0, 2);
 if (lo_close(fd) <> 0) then
   raise exception 'Failed to close large object %', $1;
 end if;
 return sz;
END;
$$ LANGUAGE plpgsql VOLATILE;

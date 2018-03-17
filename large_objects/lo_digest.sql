/*
   Return the digest (hash output) of a large object for
   any hash algorithm supported by perl's Digest module.

   Input parameters:
   - name of hash as text (see https://perldoc.perl.org/Digest.html)
   - OID of large object to digest
   - optional chunk size as int. Contents are digested one chunk at a time.
*/
CREATE FUNCTION lo_digest(text, oid, int default 2048)
 RETURNS bytea AS
$$
  use Digest;
  use strict;

  my $ctxt = Digest->new($_[0]);
  my $sz=$_[2];
  elog(ERROR, "Invalid chunk size: $sz") if ($sz<=0);
  my $sth = spi_query("SELECT lo_open($_[1], 262144) as fd");
  my $row = spi_fetchrow($sth);
  spi_cursor_close($sth);

  if ($row) {
     my $fd = $row->{fd};
     my $bytes;
     my $plan = spi_prepare("SELECT loread($fd, $sz) as chunk");
     do {
       $sth = spi_query_prepared($plan);
       $row = spi_fetchrow($sth);
       $bytes = decode_bytea($row->{chunk});
       $ctxt->add($bytes);
       spi_cursor_close($sth);
     } while (length($bytes)>0);
     spi_exec_query("select lo_close($fd)");
     spi_freeplan($plan);
  }
  return encode_bytea($ctxt->digest);
$$ LANGUAGE plperlu;

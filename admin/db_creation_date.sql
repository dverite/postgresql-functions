CREATE FUNCTION db_creation_date(oid) RETURNS timestamptz as $$
  my $oid=shift;
  my $rv = spi_exec_query("SELECT setting FROM pg_settings WHERE name='data_directory'")
     or elog(ERROR, "cannot read 'data_directory' setting");
  my $datadir = $rv->{rows}[0]->{setting};
  my @info = stat("$datadir/base/$oid");
  if (!@info) {
     elog(ERROR, "cannot stat database directory: $!");
  }
  my $ctime = $info[10];
  $rv = spi_exec_query("SELECT to_timestamp($ctime) as t") or elog(ERROR, "query error");
  return $rv->{rows}[0]->{t};
$$ LANGUAGE plperlu;

/*
  Substitute substrings within a larger string, with Perl s// operator,
  in a single pass. Each element in @orig found in @string (scanned left
  to right) is replaced by the element at the same index in @repl.
  When multiple strings in the array match simultaneously, the longest one
  wins.
*/
CREATE OR REPLACE FUNCTION multi_replace(string text, orig text[], repl text[])
RETURNS text
AS $BODY$
  my ($string, $orig, $repl) = @_;
  my %subs;

  # Check that the arrays are of the same size, unidimensional,
  # and contain no null values.
  if (@$orig != @$repl) {
     elog(ERROR, "array sizes mismatch");
  }
  if (ref @$orig[0] eq 'ARRAY' || ref @$repl[0] eq 'ARRAY') {
     elog(ERROR, "multi-dimensional arrays are not allowed");
  }
  if (grep { !defined } (@$orig, @$repl)) {
     elog(ERROR, "null elements are not allowed");
  }

  # Each element of $orig is a key in %subs to the element at the same
  # index in $repl
  @subs{@$orig} = @$repl;

  # Build a regexp of the form (s1|s2|...)
  # with the substrings sorted to match longest first
  my $re = join "|", map quotemeta,
     sort { (length($b) <=> length($a)) } keys %subs;
  $re = qr/($re)/;

  # The order will be kept in matching because (from perlre):
  # "Alternatives are tried from left to right, so the first alternative
  # found for which the entire expression matches, is the one that is
  # chosen"

  $string =~ s/$re/$subs{$1}/g;
  return $string;

$BODY$ language plperl strict immutable;

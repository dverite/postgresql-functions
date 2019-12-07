/*
  Substitute strings by other strings within a larger string, with
  Perl s// operator, in a single pass.
  Each element in @orig is replaced by the element at the same index
  in @repl
  If multiple strings in the array match simultaneously, the smallest one
  wins, or, in the case of equal lengths, the string before in
  alphabetic order.
*/
CREATE OR REPLACE FUNCTION multi_replace(string text, orig text[], repl text[])
RETURNS text
AS $BODY$
  my ($string, $orig, $repl) = @_;
  my %subs;
  my $i=0;

  # Check that the arrays are of the same size, unidimensional,
  # and don't contain null values.
  if (@$orig != @$repl) {
     elog(ERROR, "array sizes mismatch");
  }
  if (ref @$orig[0] eq 'ARRAY' || ref @$repl[0] eq 'ARRAY') {
     elog(ERROR, "array dimensions mismatch");
  }

  if (grep { !defined } (@$orig, @$repl)) {
     elog(ERROR, "null elements are not allowed");
  }

  # Each element of $orig is a key in %subs to the element at the same
  # index in $repl
  @subs{@$orig} = @$repl;

  # Build a regexp of the form (s1|s2|...)
  # with the substrings sorted to have deterministic results
  # in the cases of multiple matches.
  my $re = join "|", map quotemeta,
     sort { (length($a) <=> length($b)) || $a cmp $b } keys %subs;
  $re = qr/($re)/;

  # The order will be used in the matching because (from perlre):
  # "Alternatives are tried from left to right, so the first alternative
  # found for which the entire expression matches, is the one that is
  # chosen"

  $string =~ s/$re/$subs{$1}/g;
  return $string;

$BODY$ language plperl strict immutable;

#!/bin/bash

# A custom editor for psql that pre-processes the query string
# to replace "* /* special comment */" with a list of columns.
# The columns are passed in a temporary file pointed to by
# the PSQL_TMP_STRUCT environment variable.

# Set up PSQL_EDITOR to point to that script.
# See the macro invocation in psqlrc-for-edit-replace

read -r line1 < "$1"
rx='\*\s*/\*(expand|except:|except-type:).*\*/'
if [[ $line1 =~ $rx && -r "$PSQL_TMP_STRUCT" ]]; then
  perl - $1 "$PSQL_TMP_STRUCT" << "EOP"
require 5.014;
use Text::CSV qw(csv);

sub expand {
  # filter and format the list of columns
  my ($cols,$filter_type,$filter) = @_;
  # filter_type => undef:none, 0:by name, 1: by type
  my $qi = 1; # quote the columns (for case sensitive names and reserved keywords)
  if (defined $filter_type) {
    my @xcols = split /,/, $filter;	# list of arguments inside the comment
    my %xhcols = map { $_=>1 } @xcols;
    $cols = [ grep { !defined $xhcols{$_->[$filter_type]} } @{$cols} ];
  }
  return join ",\n\t", (map { $qi?('"' . $_->[0]=~ s/"/""/r . '"') : $_->[0]}
  	      	        @{$cols});
}

my $cols = csv(in=>$ARGV[1], headers=>"skip", binary=>1);
open(my $fi, "<", $ARGV[0]) or die "cannot open $ARGV[0]: $!";
my $lines = <$fi>;   # 1st line of query

my $rx = qr{^(.*)\*\s*/\*expand\*/(.*)$};
if ($lines =~ $rx) {
  # expand to all columns
  $lines = "$1" . expand($cols, undef, undef) . "\n$2";
}
else {
  $rx = qr{^(.*)\*\s*/\*except:(.*)\*/(.*)$};
  if ($lines =~ $rx) {
    # expand to all columns except those listed
    $lines = "$1" . expand($cols, 0, $2) . "\n$3";
  }
  else {
    $rx = qr{^(.*)\*\s*/\*except-type:(.*)\*/(.*)$};
    if ($lines =~ $rx) {
      # expand to all column except for the types listed
      $lines = "$1" . expand($cols, 1, $2) . "\n$3";
    }
  }
}
# copy the rest of the lines
do {
  $lines .= $_;
} while (<$fi>);
close $fi;
# overwrite the file with the new query
open (my $fo, ">", $ARGV[0]) or die "cannot open $ARGV[0] for writing: $!";
print $fo $lines;
close $fo;
EOP

  # When the replacement in the query buffer occurred, we could
  # return into psql at this point rather than going into the actual
  # editor.
  # But before version 13, psql won't display the modified
  # query when returning at this point, so it might seem opaque.
  # Let's always call the actual editor, but you may uncomment
  # the line below to skip it.

  # rm -f "$PSQL_TMP_STRUCT" ; exit
fi
rm -f "$PSQL_TMP_STRUCT"
${EDITOR:-vi} $*

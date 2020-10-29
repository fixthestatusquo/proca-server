#!/usr/bin/perl -n

# pre grep with:
# grep -E '(OCT_COUNTRY_RULE|ValidationProperty|SKIP)' mysql.sql > rules.txt

/INSERT.*VALUES.*?'(\w{2,})'/                    && print "$1:\n";

/ValidationProp.*key == "([\w.]+)"/              && print "  $1:\n";
/value not matches "([^"]+)"/                    && print "    pattern: \"$1\"\n";
/value.toLowerCase\(\) +not +matches +"([^"]+)"/ && print "    pattern_i: \"$1\"\n";
/[.]SKIPPABLE/                                   && print "    skippable: true\n";
/NOT_SKIPPABLE/                                  && print "    skippable: false\n";
/isAbleToVoteByMS/                               && print "    age: true\n";
/value.empty == true/                            && print "    empty: false\n";
/value.length > ?(\d+)/                          && print "    lte: $1\n"

#!/usr/bin/perl
use utf8;
binmode STDOUT, ":encoding(UTF-8)";

open(FILE, '<', 'nvdadict.txt');

print "int ibs_word_begin = 0;\n";
print "int ibs_word_end = 65535;\n";
print "char* ibs_words[65535] = {\n";

#$i = 19968;
%chars = {};
while (($line = <FILE>)) {
  chomp($line);
  $line =~ s/^\s*//;
  $line =~ s/\s*$//;
  ($char, $word) = split(/\s+/, $line);
  utf8::decode($char);
  utf8::decode($word);
  $code = ord($char);
  $chars{$code} = $word;
  #print "$char: $word\n";
}
close(FILE);

$i = 0;
foreach $next_code (sort {$a <=> $b} (keys %chars)) {
  next if ($next_code < 48);
  while ($i < $next_code) {
    print '0,';
    $i++;
  }
  print '"', $chars{$i}, '",';
  $i++;
  print "\n" if ($i % 100 == 0);
}

while ($i < 65534) {
  print "0,";
  $i++;
}

print "0\n};\n";

package MT::Gizmos::Util;

use strict;

use base 'Exporter';

use vars qw( @EXPORT_OK );
@EXPORT_OK =
  qw( camel_case wiki_case encode_csv strip_whitespace real_spaces double_spaces
  plain_xml cpaned trim_to_proper dashify );

{
    my %puncs = (
        '.' => 'Dot',
        '@' => 'At',
        '+' => 'Plus',
        '-' => 'Minus',
        '#' => 'Sharp',
        '/' => 'Slash'
    );
    my $RE = '[' . join('', keys %puncs) . ']';
    sub camel_case { _wiki_camel(1, @_) }
    sub wiki_case  { _wiki_camel(0, @_) }

    sub _wiki_camel {
        my ($camel, $t) = @_;
        return '' unless $_[1];
        $t =~ s![^\s\w\.\@\+\-#/]+!!g;
        $t =~ s!($RE)! $puncs{$1} !g;
        my @words = map { ucfirst(lc($_)) } split /\s+/, $t;
        $words[0] = lc($words[0]) if $camel;
        join '', @words;
    }
}

sub encode_csv {
    return $_[0] unless $_[0] =~ /,/;
    my $t = $_[0];
    $t =~ s/"/\\"/g;
    "\"$t\"";
}

sub strip_whitespace {
    my $t = $_[0];
    $t =~ s/^(\s+)//;
    $t =~ s/(\s+)$//;
    $t;
}

sub real_spaces   { my $t = $_[0]; $t =~ s/_/ /g;        $t; }
sub double_spaces { my $t = $_[0]; $t =~ s|  | &nbsp;|g; $t; }

sub plain_xml {
    require MT::Util;
    MT::Util::encode_xml(MT::Util::remove_html($_[0]));
}

sub cpaned {
    my $t = $_[0];
    $t =~ s/(::|\s+)/-/g;
    $t =~ s/[^\w\.\-]//g;
    $t;
}

sub trim_to_proper {
    my ($str, $len, $ctx) = @_;
    if ($len && ($len < length($str))) {
        $str = substr $str, 0, $len;
        $str .= '...';
    }
    $str;
}

sub dashify {
    my $str = lc shift;
    $str =~ s{^\s+|\s$}{}g;
    $str =~ s{[\s_]+}{-}g;
    $str =~ s{[^\w-]}{}g;
    $str;
}

1;

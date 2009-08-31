package MT::Gizmos::TextFilters;

use strict;

#--- handlers

sub pre {
    require MT::Util;
    my $text = MT::Util::encode_html($_[0]);
    "<pre>\n$text\n</pre>";
}

1;

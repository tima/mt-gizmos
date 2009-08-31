#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 57;

use MT::Blog;

my $blog = MT::Blog->load;

my $entry_comment_count = qq{
<MTEntries lastn="4">
<MTTestListItem stash="ISZERO"><MTCountIsZero>TRUE<MTElse>FALSE</MTElse></MTCountIsZero></MTTestListItem>
<MTTestListItem stash="ISONE"><MTCountIsOne>TRUE<MTElse>FALSE</MTElse></MTCountIsOne></MTTestListItem>
<MTTestListItem stash="LABEL"><MTCountLabel></MTTestListItem>
<MTTestListItem stash="HEADING"><MTCountHeading></MTTestListItem>
</MTEntries>
};

my $entry_comment_count_deprecated = qq{
<MTEntries lastn="4">
<MTTestListItem stash="ISZERO"><MTEntryCommentCountIsZero>TRUE<MTElse>FALSE</MTElse></MTEntryCommentCountIsZero></MTTestListItem>
<MTTestListItem stash="ISONE"><MTEntryCommentCountIsOne>TRUE<MTElse>FALSE</MTElse></MTEntryCommentCountIsOne></MTTestListItem>
<MTTestListItem stash="LABEL"><MTEntryCommentCountLabel></MTTestListItem>
</MTEntries>
};

my $page_comment_count = qq{
<MTPages lastn="4">
<MTTestListItem stash="ISZERO"><MTCountIsZero>TRUE<MTElse>FALSE</MTElse></MTCountIsZero></MTTestListItem>
<MTTestListItem stash="ISONE"><MTCountIsOne>TRUE<MTElse>FALSE</MTElse></MTCountIsOne></MTTestListItem>
<MTTestListItem stash="LABEL"><MTCountLabel></MTTestListItem>
<MTTestListItem stash="HEADING"><MTCountHeading></MTTestListItem>
</MTPages>
};

my $blog_counts = qq {
<MTTestIs value="FALSE"><MTCountIsZero class_type="entry">TRUE<MTElse>FALSE</MTElse></MTCountIsZero></MTTestIs>
<MTTestIs value="FALSE"><MTCountIsOne class_type="entry">TRUE<MTElse>FALSE</MTElse></MTCountIsOne></MTTestIs>
<MTTestIs value="Entries"><MTCountLabel class_type="entry"></MTTestIs>
<MTTestIs value="FALSE"><MTCountIsZero class_type="page">TRUE<MTElse>FALSE</MTElse></MTCountIsZero></MTTestIs>
<MTTestIs value="FALSE"><MTCountIsOne class_type="page">TRUE<MTElse>FALSE</MTElse></MTCountIsOne></MTTestIs>
<MTTestIs value="Pages"><MTCountLabel class_type="page"></MTTestIs>
<MTTestIs value="TRUE"><MTCountIsZero class_type="ping">TRUE<MTElse>FALSE</MTElse></MTCountIsZero></MTTestIs>
<MTTestIs value="FALSE"><MTCountIsOne class_type="ping">TRUE<MTElse>FALSE</MTElse></MTCountIsOne></MTTestIs>
<MTTestIs value="TrackBacks"><MTCountLabel class_type="ping"></MTTestIs>
};

my $word_count = qq{
<MTEntries lastn="2" offset="2">
<MTTestListItem stash="WORDS"><MTWordCount></MTTestListItem>
</MTEntries>
<MTPages lastn="2" offset="2">
<MTTestListItem stash="WORDS"><MTWordCount></MTTestListItem>
</MTPages>
};

run_test_tmpl(sub {$entry_comment_count},            \&init_count); # 12 tests
run_test_tmpl(sub {$entry_comment_count_deprecated}, \&init_count); # 12 tests
run_test_tmpl(sub {$page_comment_count},             \&init_count); # 12 tests
run_test_tmpl(sub {$blog_counts}, \&init_ctx_blog);                 # 9 tests

# TO DO: NEED TO TEST @ENTRIES (ARCHIVE) FORM OF COUNTS
run_test_tmpl(sub {$word_count}, \&init_word_count);                # 4 tests

# TO DO: IMAGE COUNT (Switch to assets?)

sub init_ctx_blog {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', $blog->id);
}

sub init_count {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('ISZERO', [qw( TRUE FALSE FALSE TRUE )]);
    $ctx->stash('ISONE',  [qw( FALSE FALSE TRUE FALSE )]);
    $ctx->stash('LABEL',  [qw( Comments Comments Comment Comments )]);
    $ctx->stash('HEADING',
        ['0 Comments', '3 Comments', '1 Comment', '0 Comments']);
}

sub init_word_count {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('WORDS', [qw(25 17 25 17)]);
}


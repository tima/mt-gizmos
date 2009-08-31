#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 12;

use MT::Blog;
use MT::Entry;
use MT::Comment;
use MT::Util qw(epoch2ts ts2epoch);

my ($blog) = MT::Blog->load();

eval {

    MT::Comment->remove_all()
      or die MT::Comment->errstr;    # make sure the slate is clean.

    # sloppy but it just should work.
    my %tsi;
    my $i = 0;
    for my $id (qw(2 3 3 3 6 7 7 7)) {
        my $obj = MT::Entry->load($id);
        $tsi{$id} ||= 600;
        my $ts =
          epoch2ts($blog, ts2epoch($blog, $obj->authored_on) + $tsi{$id});
        my $c = MT::Comment->new;
        $c->blog_id($blog->id);
        $c->entry_id($id);
        $c->ip('127.0.0.1');
        $c->author("Commenter $i");
        $c->url("http://example.com/~${i}");
        $c->email("commenter${i}\@example.com");
        $c->text(<<BODY);
This is some text that is the body for test
comment $i. This comment left intentionally boring.
BODY
        $c->save or die $c->errstr;
        $c->approve();
        $c->modified_on($ts);    # can't override when first saved.
        $c->created_on($ts);     # ditto.
        $c->save or die $c->errstr;
        $i++;
        $tsi{$id} += 600;
    }
};
diag($@) if $@;
ok(!$@);                         # make sure test data correction worked

my $is_new = qq{
<MTComments sort_by="created_on" sort_order="descend" lastn="100">
<MTTestListItem stash="NEW"><MTCommentIsNew days="4">TRUE<MTElse>FALSE</MTElse></MTCommentIsNew></MTTestListItem>
</MTComments>
};

# determine atom id and other pieces for identifier tests.
my $blog_id = $blog->id;
my $t       = {blog_id => $blog_id};
my $a       = {
    direction => 'descend',
    sort      => 'created_on',
    limit     => 1,
};
my $lastc       = MT::Comment->load($t, $a) or die MT::Comment->errstr;
my $id          = $lastc->id;
my $year        = substr $lastc->created_on, 0, 4;
my $atom_id     = "tag:127.0.0.1,${year}://${blog_id}.#c${id}";
my $e_permalink = $lastc->entry->permalink;

my $identifiers = qq{
<MTComments lastn="1">
<MTTestIs value="$atom_id"><MTCommentAtomID></MTTestIs>
<MTTestIs value="#c${id}"><MTCommentIdentifier></MTTestIs>
<MTTestIs value="${e_permalink}#c${id}"><MTCommentPermalink></MTTestIs>
</MTComments>
};

run_test_tmpl(sub {$is_new},      \&init_is_new);      # 8 tests
run_test_tmpl(sub {$identifiers}, \&init_ctx_blog);    # 3 tests

sub init_ctx_blog {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', $blog->id);
}

sub init_is_new {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('NEW', [qw( TRUE TRUE TRUE TRUE TRUE TRUE FALSE FALSE)]);
}

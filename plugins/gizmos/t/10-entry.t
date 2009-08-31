#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 37;

use MT::Blog;
use MT::Entry;
use MT::Category;
use MT::Placement;
use MT::Author;
use MT::Util qw(epoch2ts);

my ($blog) = MT::Blog->load();

my @e;    # holds the entry objects we'll test on.

eval {    # initialize with test data.

    MT::Entry->remove_all() or die MT::Entry->errstr;

    my ($author) = MT::Author->load();    # not commenter
    $author->nickname('Melody Nelson');
    $author->url('http://example.com/serge');
    $author->save or die $author->errstr;

    my @cats;
    for my $i (0 .. 1) {
        my $cat = MT::Category->new;
        $cat->label('Category ' . $i);
        $cat->basename('cat' . $i);
        $cat->blog_id($blog->id);
        $cat->author_id($author->id);
        $cat->save or die $cat->errstr;
        push @cats, $cat;
    }

    # calculate timestamps
    my $time = time();
    my %on   = (
        0 => epoch2ts($blog, $time - 874800),    # 10 days, 3 hours
        1 => epoch2ts($blog, $time - 640800),    # 7 days, 10 hours
        2 => epoch2ts($blog, $time - 284400),    # 3 days, 7 hours
        3 => epoch2ts($blog, $time),             # now
    );

    for my $i (0 .. 3) {
        my $e = MT::Entry->new;
        $e->basename('entry' . $i);
        $e->blog_id($blog->id);
        $e->author_id($author->id);
        $e->title("This is entry $i");
        $e->text(<<BODY);
This is some text that is the body for test 
entry $i. This entry left intentionally boring.
BODY
        $e->excerpt('This is an entry with an excerpt')     if $i == 0;
        $e->text_more('This is an entry with more to say.') if $i == 1;
        $e->authored_on($on{$i});
        $e->status(MT::Entry::RELEASE);
        $e->save or die $e->errstr;
        $e->modified_on($on{$i});    # can't override this on initial save.
        $e->save or die $e->errstr;
        push @e, $e;
    }

    my $i = 0;
    for my $e (@e) {
        my $c = $i % 2 ? $cats[0] : $cats[1];    # alternate categories
        my $place = MT::Placement->new;
        $place->blog_id($blog->id);
        $place->entry_id($e->id);
        $place->category_id($c->id);
        $place->is_primary(1);
        $place->save or die $place->errstr;
        $i++;
    }

    # create a secondary category on one test entry.
    my $p = MT::Placement->new;
    $p->blog_id($blog->id);
    $p->entry_id($e[2]->id);
    $p->category_id($cats[0]);
    $p->is_primary(0);
    $p->save or die $p->errstr;

};
diag($@) if $@;
ok(!$@);    # make sure test data creation worked

my $updated1 = qq {
<MTEntriesUpdated days="1">
<MTTestIs value="This is entry 3"><MTEntryTitle></MTTestIs>
</MTEntriesUpdated>
};

my $updated6 = qq {
<MTEntriesUpdated days="6">
<MTTestListItem stash="TITLES"><MTEntryTitle></MTTestListItem>
</MTEntriesUpdated>
};

my $is_new = qq {
<MTEntries days="9">
<MTTestListItem stash="NEW"><MTEntryIsNew lastn_minutes="120">TRUE<MTElse>FALSE</MTElse></MTEntryIsNew></MTTestListItem>
</MTEntries>
};

my $is_new2 = qq {
<MTEntries days="9">
<MTTestListItem stash="NEW"><MTEntryIsNew days="2">TRUE<MTElse>FALSE</MTElse></MTEntryIsNew></MTTestListItem>
</MTEntries>
};

my $if = qq {
<MTEntries days="40">
<MTTestListItem stash="EXCERPT"><MTEntryIfExcerpt>TRUE<MTElse>FALSE</MTElse></MTEntryIfExcerpt></MTTestListItem>
</MTEntries>
};

my $more = qq {
<MTSetVarBlock name="output"><MTEntryBodyMore></MTSetVarBlock>
};

my $excerpt = qq {
<MTTestIs value="This is an entry with an excerpt"><MTEntrySmartBody></MTTestIs>
};

my $no_excerpt = qq {
<MTSetVarBlock name="BODY"><MTEntryBody></MTsetVarBlock>
<MTTestIs var="BODY"><MTEntrySmartBody></MTTestIs>
<MTTestIsNot blank="1"><MTEntrySmartBody></MTTestIsNot>
};

my $links0 = qq {
<MTTestIs value="http://127.0.0.1/cat0/"><MTEntryPrimaryCategoryLink></MTTestIs>
<MTSetVarBlock name="LINK"><a target="_blank" href="http://example.com/serge">Melody Nelson</a></MTSetVarBlock>
<MTTestIs var="LINK"><MTEntryAuthorNicknameLink></MTTestIs>
};

my $links1 = qq {
<MTTestIs value="http://127.0.0.1/cat1/"><MTEntryPrimaryCategoryLink></MTTestIs>
<MTSetVarBlock name="LINK"><a target="_blank" href="http://example.com/serge">Melody Nelson</a></MTSetVarBlock>
<MTTestIs var="LINK"><MTEntryAuthorNicknameLink></MTTestIs>
};

my $cat_is = qq {
<MTTestIs stash="cat_basename"><MTEntryCategoryIs basename="cat1">TRUE<MTELSE>FALSE</MTELSE></MTEntryCategoryIs></MTTestIs>
<MTTestIs stash="cat_id"><MTEntryCategoryIs id="2">TRUE<MTELSE>FALSE</MTELSE></MTEntryCategoryIs></MTTestIs>
<MTTestIs stash="cat_basename"><MTEntryCategoryIs label="Category 1">TRUE<MTELSE>FALSE</MTELSE></MTEntryCategoryIs></MTTestIs>
};

my $active_entry = qq {
<MTEntries lastn="10">
<MTTestListItem stash="ACTIVE_ENTRY"><MTEntryIsActive id="1">TRUE<MTElse>FALSE</MTElse></MTEntryIsActive></MTTestListItem>
</MTEntries>
};

my $active_cat = qq {
<MTEntries days="14">
<MTTestListItem stash="ACTIVE_CAT"><MTCategoryIsActive id="1">TRUE<MTElse>FALSE</MTElse></MTCategoryIsActive></MTTestListItem>
</MTEntries>
};


run_test_tmpl(sub {$updated1}, \&init_ctx_blog);
run_test_tmpl(sub {$updated6}, \&init_entries_updated_6days);    # 2 tests
run_test_tmpl(sub {$is_new},   \&init_is_new);                   # 3 tests
run_test_tmpl(sub {$is_new2},  \&init_is_new);                   # 3 tests
run_test_tmpl(sub {$if},       \&init_if);                       # 4 tests;
run_test_tmpl(sub {$more}, \&init_entry_more, \&eval_entry_more);
run_test_tmpl(sub {$more}, \&init_entry_no_more, \&eval_entry_no_more);
run_test_tmpl(sub {$excerpt},      \&init_entry_excerpt);
run_test_tmpl(sub {$no_excerpt},   \&init_entry_no_excerpt);
run_test_tmpl(sub {$links0},       \&init_entry_more);
run_test_tmpl(sub {$links1},       \&init_entry_no_more);
run_test_tmpl(sub {$cat_is},       \&init_cat_is);               # 3 tests
run_test_tmpl(sub {$cat_is},       \&init_cat_is_not);           # 3 tests
run_test_tmpl(sub {$active_entry}, \&init_active_entry);         # 4 tests
run_test_tmpl(sub {$active_cat},   \&init_active_cat);           # 2 tests

sub init_ctx_blog {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', $blog->id);
}

sub init_entries_updated_6days {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('TITLES', ['This is entry 3', 'This is entry 2']);
}

sub init_is_new {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('NEW', [qw( TRUE FALSE FALSE)]);
}

sub init_if {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('EXCERPT', [qw( FALSE FALSE FALSE TRUE )]);
}

sub init_entry_more {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('entry', $e[1]);
}

sub eval_entry_more {
    my $out = $_[1]->var('output');
    ok($out =~ m{<a id="more">});
}

sub init_entry_no_more {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('entry', $e[0]);
}

sub eval_entry_no_more {
    my $out = $_[1]->var('output');
    ok($out !~ m{<a id="more">});
}

sub init_entry_excerpt    { init_entry_no_more(@_); }
sub init_entry_no_excerpt { init_entry_more(@_); }

sub init_cat_is     { _init_cat_is_handler($e[0], 'TRUE',  @_) }
sub init_cat_is_not { _init_cat_is_handler($e[1], 'FALSE', @_) }

sub _init_cat_is_handler {
    my ($entry, $v, $cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    $ctx->stash('entry',        $entry);
    $ctx->stash('cat_basename', $v);
    $ctx->stash('cat_id',       $v);
    $ctx->stash('cat_label',    $v);
}

sub init_active_entry {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    $ctx->stash('ACTIVE_ENTRY', [qw(FALSE FALSE FALSE TRUE)]);
    $ctx->stash('entry', $e[0]);
    require MT::Callback;
    my $dummy  = MT::Callback->new;
    my %params = (
        context      => $ctx,
        archive_type => 'Individual',
        blog         => $blog,
    );
    require MT::Gizmos::Callbacks;
    MT::Gizmos::Callbacks::active_stash($dummy, %params);
}

sub init_active_cat {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    $ctx->stash('ACTIVE_CAT', [qw(FALSE TRUE FALSE TRUE)]);
    $ctx->stash('category', $e[0]->category);
    require MT::Callback;
    my $dummy  = MT::Callback->new;
    my %params = (
        context      => $ctx,
        archive_type => 'Category',
        blog         => $blog,
    );
    require MT::Gizmos::Callbacks;
    MT::Gizmos::Callbacks::active_stash($dummy, %params);
}

1;

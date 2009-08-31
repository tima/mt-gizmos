#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 35;

use MT::Blog;
use MT::Page;
use MT::Folder;
use MT::Placement;
use MT::Author;
use MT::Util qw(epoch2ts);

my ($blog) = MT::Blog->load();

my @p;    # holds the page objects we'll test on.

eval {    # initialize with test data.

    MT::Page->remove_all() or die MT::Page->errstr;

    my ($author) = MT::Author->load();    # not commenter

    my @folders;
    for my $i (0 .. 1) {
        my $f = MT::Folder->new;
        $f->label('Folder ' . $i);
        $f->basename('folder' . $i);
        $f->blog_id($blog->id);
        $f->author_id($author->id);
        $f->save or die $f->errstr;
        push @folders, $f;
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
        my $p = MT::Page->new;
        $p->basename('page' . $i);
        $p->blog_id($blog->id);
        $p->author_id($author->id);
        $p->title("This is page $i");
        $p->text(<<BODY);
This is some text that is the body for test 
page $i. This page left intentionally boring.
BODY
        $p->excerpt('This is a page with an excerpt')     if $i == 0;
        $p->text_more('This is a page with more to say.') if $i == 1;
        $p->authored_on($on{$i});
        $p->status(MT::Entry::RELEASE);
        $p->save or die $p->errstr;
        $p->modified_on($on{$i});    # can't override this on initial save.
        $p->save or die $p->errstr;
        push @p, $p;
    }

    my $i = 0;
    for my $p (@p) {
        my $c = $i % 2 ? $folders[0] : $folders[1];    # alternate categories
        my $place = MT::Placement->new;
        $place->blog_id($blog->id);
        $place->entry_id($p->id);
        $place->category_id($c->id);
        $place->is_primary(1);
        $place->save or die $place->errstr;
        $i++;
    }

    # create a secondary category on one test entry.
    my $pl = MT::Placement->new;
    $pl->blog_id($blog->id);
    $pl->entry_id($p[2]->id);
    $pl->category_id($folders[0]);
    $pl->is_primary(0);
    $pl->save or die $pl->errstr;

};
diag($@) if $@;
ok(!$@);    # make sure test data correction worked

my $updated1 = qq {
<MTPagesUpdated days="1">
<MTTestIs value="This is page 3"><MTPageTitle></MTTestIs>
</MTPagesUpdated>
};

my $updated6 = qq {
<MTPagesUpdated days="6">
<MTTestListItem stash="TITLES"><MTPageTitle></MTTestListItem>
</MTPagesUpdated>
};

my $is_new = qq {
<MTPages days="9">
<MTTestListItem stash="NEW"><MTPageIsNew lastn_minutes="120">TRUE<MTElse>FALSE</MTElse></MTPageIsNew></MTTestListItem>
</MTPages>
};

my $is_new2 = qq {
<MTPages days="9">
<MTTestListItem stash="NEW"><MTPageIsNew days="2">TRUE<MTElse>FALSE</MTElse></MTPageIsNew></MTTestListItem>
</MTPages>
};

my $if = qq {
<MTPages days="40">
<MTTestListItem stash="EXCERPT"><MTPageIfExcerpt>TRUE<MTElse>FALSE</MTElse></MTPageIfExcerpt></MTTestListItem>
</MTPages>
};

my $more = qq {
<MTSetVarBlock name="output"><MTPageBodyMore></MTSetVarBlock>
};

my $excerpt = qq {
<MTTestIs value="This is a page with an excerpt"><MTPageSmartBody></MTTestIs>
};

my $no_excerpt = qq {
<MTSetVarBlock name="BODY"><MTPageBody></MTsetVarBlock>
<MTTestIs var="BODY"><MTPageSmartBody></MTTestIs>
<MTTestIsNot blank="1"><MTPageSmartBody></MTTestIsNot>
};

my $links0 = qq {
<MTSetVarBlock name="LINK"><a target="_blank" href="http://example.com/serge">Melody Nelson</a></MTSetVarBlock>
<MTTestIs var="LINK"><MTPageAuthorNicknameLink></MTTestIs>
};

my $links1 = qq {
<MTSetVarBlock name="LINK"><a target="_blank" href="http://example.com/serge">Melody Nelson</a></MTSetVarBlock>
<MTTestIs var="LINK"><MTPageAuthorNicknameLink></MTTestIs>
};

my $folder_is = qq {
<MTTestIs stash="cat_basename"><MTPageFolderIs basename="folder1">TRUE<MTELSE>FALSE</MTELSE></MTPageFolderIs></MTTestIs>
<MTTestIs stash="cat_id"><MTPageFolderIs id="4">TRUE<MTELSE>FALSE</MTELSE></MTPageFolderIs></MTTestIs>
<MTTestIs stash="cat_basename"><MTPageFolderIs label="Folder 1">TRUE<MTELSE>FALSE</MTELSE></MTPageFolderIs></MTTestIs>
};

my $active_page = qq {
<MTPages lastn="10">
<MTTestListItem stash="ACTIVE_PAGE"><MTPageIsActive id="1">TRUE<MTElse>FALSE</MTElse></MTPageIsActive></MTTestListItem>
</MTPages>
};

my $active_folder = qq {
<MTPages days="14">
<MTTestListItem stash="ACTIVE_FOLDER"><MTFolderIsActive id="1">TRUE<MTElse>FALSE</MTElse></MTFolderIsActive></MTTestListItem>
</MTPages>
};

run_test_tmpl(sub {$updated1}, \&init_ctx_blog);
run_test_tmpl(sub {$updated6}, \&init_pages_updated_6days);         # 2 tests
run_test_tmpl(sub {$is_new},   \&init_is_new);                      # 3 tests
run_test_tmpl(sub {$is_new2},  \&init_is_new);                      # 3 tests
run_test_tmpl(sub {$if},       \&init_if);                          # 4 tests;
run_test_tmpl(sub {$more},     \&init_page_more, \&eval_page_more);
run_test_tmpl(sub {$more},       \&init_page_no_more, \&eval_page_no_more);
run_test_tmpl(sub {$excerpt},    \&init_page_excerpt);
run_test_tmpl(sub {$no_excerpt}, \&init_page_no_excerpt);
run_test_tmpl(sub {$links0},     \&init_page_more);
run_test_tmpl(sub {$links1},     \&init_page_no_more);
run_test_tmpl(sub {$folder_is},     \&init_folder_is);              # 3 tests
run_test_tmpl(sub {$folder_is},     \&init_folder_is_not);          # 3 tests
run_test_tmpl(sub {$active_page},   \&init_active_page);            # 4 tests
run_test_tmpl(sub {$active_folder}, \&init_active_folder);          # 4 tests

sub init_ctx_blog {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', $blog->id);
}

sub init_pages_updated_6days {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('TITLES', ['This is page 3', 'This is page 2']);
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

sub init_page_more {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('entry', $p[1]);
}

sub eval_page_more {
    my $out = $_[1]->var('output');
    ok($out =~ m{<a id="more">});
}

sub init_page_no_more {
    my ($cb, $ctx) = @_;
    init_ctx_blog(@_);
    $ctx->stash('entry', $p[0]);
}

sub eval_page_no_more {
    my $out = $_[1]->var('output');
    ok($out !~ m{<a id="more">});
}

sub init_page_excerpt    { init_page_no_more(@_); }
sub init_page_no_excerpt { init_page_more(@_); }

sub init_folder_is     { _init_folder_is_handler($p[0], 'TRUE',  @_) }
sub init_folder_is_not { _init_folder_is_handler($p[1], 'FALSE', @_) }

sub _init_folder_is_handler {
    my ($entry, $v, $cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    $ctx->stash('entry',        $entry);
    $ctx->stash('cat_basename', $v);
    $ctx->stash('cat_id',       $v);
    $ctx->stash('cat_label',    $v);
}

sub init_active_page {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    $ctx->stash('ACTIVE_PAGE', [qw(FALSE FALSE FALSE TRUE)]);
    $ctx->stash('entry', $p[0]);
    require MT::Callback;
    my $dummy  = MT::Callback->new;
    my %params = (
        context      => $ctx,
        archive_type => 'Individual',    # correct?
        blog         => $blog,
    );
    require MT::Gizmos::Callbacks;
    MT::Gizmos::Callbacks::active_stash($dummy, %params);
}

sub init_active_folder {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    $ctx->stash('ACTIVE_FOLDER', [qw(FALSE TRUE FALSE TRUE)]);
    $ctx->stash('category', $p[0]->category);
    require MT::Callback;
    my $dummy  = MT::Callback->new;
    my %params = (
        context      => $ctx,
        archive_type => 'Folder',    # correct?
        blog         => $blog,
    );
    require MT::Gizmos::Callbacks;
    MT::Gizmos::Callbacks::active_stash($dummy, %params);
}

1;

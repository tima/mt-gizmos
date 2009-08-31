#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 44;

use MT::Blog;
use MT::Entry;
use MT::Page;
use MT::Folder;
use MT::Category;
use MT::Comment;

# use MT::TBPing; # TrackBacks are dead! Long live TrackBacks!

my ($blog) = MT::Blog->load();

my $e   = MT::Entry->load;
my $cat = MT::Category->load;
my $p   = MT::Page->load({basename => 'page2'});      # why is this necessary?
my $f   = MT::Folder->load({basename => 'folder1'});  # ditto.
my $c   = MT::Comment->load;

my $e_id   = $e->id;
my $cat_id = $cat->id;
my $p_id   = $p->id;
my $f_id   = $f->id;
my $c_id   = $c->id;

my $e_title      = $e->title;
my $e_basename   = $e->basename;
my $cat_label    = $cat->label;
my $cat_basename = $cat->basename;
my $p_title      = $p->title;
my $p_basename   = $p->basename;
my $f_label      = $f->label;
my $f_basename   = $f->basename;
my $c_author     = $c->author;

# we're testing that things don't change despite the loop changing
# the underlying context.
# TO DO: need blog and ping tests.
my $index = qq{ 
<MTEntries><MTEntry id="$e_id"><MTTestIs value="$e_title"><MTEntryTitle></MTTestIs></MTEntry></MTEntries>
<MTEntries><MTEntry basename="$e_basename"><MTTestIs value="$e_title"><MTEntryTitle></MTTestIs></MTEntry></MTEntries>
<MTEntries><MTEntry title="$e_title"><MTTestIs value="$e_title"><MTEntryTitle></MTTestIs></MTEntry></MTEntries>
<MTCategories><MTCategory id="$cat_id"><MTTestIs value="$cat_label"><MTCategoryLabel></MTTestIs></MTCategory></MTCategories>
<MTCategories><MTCategory basename="$cat_basename"><MTTestIs value="$cat_label"><MTCategoryLabel></MTTestIs></MTCategory></MTCategories>
<MTCategories><MTCategory label="$cat_label"><MTTestIs value="$cat_label"><MTCategoryLabel></MTTestIs></MTCategory></MTCategories>
<MTPages><MTPage id="$p_id"><MTTestIs value="$p_title"><MTPageTitle></MTTestIs></MTPage></MTPages>
<MTPages><MTPage basename="$p_basename"><MTTestIs value="$p_title"><MTPageTitle></MTTestIs></MTPage></MTPages>
<MTPages><MTPage title="$p_title"><MTTestIs value="$p_title"><MTPageTitle></MTTestIs></MTPage></MTPages>
<MTFolders><MTFolder id="$f_id"><MTTestIs value="$f_label"><MTFolderLabel></MTTestIs></MTFolder></MTFolders>
<MTFolders><MTFolder basename="$f_basename"><MTTestIs value="$f_label"><MTFolderLabel></MTTestIs></MTFolder></MTFolders>
<MTFolders><MTFolder label="$f_label"><MTTestIs value="$f_label"><MTFolderLabel></MTTestIs></MTFolder></MTFolders>
<MTComments><MTComment id="$c_id"><MTTestIs value="$c_author"><MTCommentAuthor></MTTestIs></MTComment></MTComments>
};

run_test_tmpl(sub {$index}, \&init_ctx_blog);

sub init_ctx_blog {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', $blog->id);
}


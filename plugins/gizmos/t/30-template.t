#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 17;

use MT::Blog;
use MT::Template;

my ($blog) = MT::Blog->load();

my $index = qq{ 
<MTTestIs value="TRUE"><MTIndexIsActive template="Atom">TRUE<MTElse>FALSE</MTElse></MTIndexIsActive></MTTestIs>
<MTTestIs value="TRUE"><MTIndexIsActive template="atom">TRUE<MTElse>FALSE</MTElse></MTIndexIsActive></MTTestIs>
<MTTestIs value="TRUE"><MTIndexIsActive template="atom.xml">TRUE<MTElse>FALSE</MTElse></MTIndexIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTIndexIsActive template="Main Index">TRUE<MTElse>FALSE</MTElse></MTIndexIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTIndexIsActive template="main_index">TRUE<MTElse>FALSE</MTElse></MTIndexIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTIndexIsActive template="index.html">TRUE<MTElse>FALSE</MTElse></MTIndexIsActive></MTTestIs>
};

my $tmpl_active = qq{ 
<MTTestIs value="TRUE"><MTTemplateIsActive template="Atom">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="TRUE"><MTTemplateIsActive template="atom">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="TRUE"><MTTemplateIsActive template="atom.xml">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="TRUE"><MTTemplateIsActive id="7">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTTemplateIsActive template="Main Index">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTTemplateIsActive template="main_index">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTTemplateIsActive template="index.html">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTTemplateIsActive id="3">TRUE<MTElse>FALSE</MTElse></MTTemplateIsActive></MTTestIs>
};

my $archive_type = qq{
<MTTestIs value="TRUE"><MTArchiveTypeIsActive type="category">TRUE<MTElse>FALSE</MTElse></MTArchiveTypeIsActive></MTTestIs>
<MTTestIs value="TRUE"><MTArchiveTypeIsActive type="Category">TRUE<MTElse>FALSE</MTElse></MTArchiveTypeIsActive></MTTestIs>
<MTTestIs value="FALSE"><MTArchiveTypeIsActive type="Monthly">TRUE<MTElse>FALSE</MTElse></MTArchiveTypeIsActive></MTTestIs>
};

run_test_tmpl(sub {$index},        \&init_active_index);           # 6 tests
run_test_tmpl(sub {$tmpl_active},  \&init_active_template);        # 8 tests
run_test_tmpl(sub {$archive_type}, \&init_active_archive_type);    # 3 tests

sub init_ctx_blog {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', $blog->id);
}

sub init_active_index {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    my $t = MT::Template->load({identifier => 'atom'});
    require MT::Callback;
    my $dummy  = MT::Callback->new;
    my %params = (
        context      => $ctx,
        archive_type => 'index',
        blog         => $blog,
        template     => $t,
    );
    require MT::Gizmos::Callbacks;
    MT::Gizmos::Callbacks::active_stash($dummy, %params);
}

sub init_active_template {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
    my $t = MT::Template->load({identifier => 'atom'});
    $ctx->stash('template', $t);
}

sub init_active_archive_type {
    my ($cb, $ctx) = @_;
    init_ctx_blog($cb, $ctx);
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

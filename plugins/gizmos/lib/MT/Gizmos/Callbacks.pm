package MT::Gizmos::Callbacks;

use strict;

sub active_stash {    # needed for "active" conditionals tags.
    my ($cb, %args) = @_;
    my $ctx = $args{context};
    my $at  = $args{archive_type};
    $ctx->stash('archive_type',   $at);
    $ctx->stash('index_template', $args{template})
      if lc $args{archive_type} eq 'index' && $args{template};
    $ctx->stash('archive_entry', $ctx->stash('entry'))
      if $ctx->stash('entry');
    1;
}

1;

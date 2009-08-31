package MT::Gizmos::Tags;
use strict;

#--- id handler

sub by_id {
    my ($ctx, $args, $cond) = @_;
    my $type  = lc $ctx->stash('tag');
    my $class = MT->model($type);
    my $key   = $class->datasource;
    my $obj;
    if (my $id = $args->{id}) {
        $obj = $class->load($id);
    }
    else {    # alternate identifier
        my $t = {};
        for (qw(basename label title)) {
            $t->{$_} = $args->{$_} if $args->{$_} && $class->can($_);
        }
        return $ctx->error(
            "mt:${type} requires an 'id' argument")    # LOCALIZATION
          unless keys %$t;
        $t->{blog_id} = $ctx->stash('blog_id') if $ctx->stash('blog_id');
        ($obj) = $class->load($t);
    }
    return '' unless $obj;                             # complain?
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    local $ctx->{__stash}{$key} = $obj;
    local $ctx->{__stash}{"${key}_id"} = $obj->id;
    my $out = $builder->build($ctx, $tokens, $cond);
    return $ctx->error($builder->errstr) unless defined $out;
    return $out || '';
}

#--- is container handlers

sub folder_is {
    return unless _check_page(@_);
    cat_is(@_);
}

sub cat_is {
    my ($ctx, $args, $cond) = @_;
    my $tag = 'mt:' . lc $ctx->stash('tag');
    return $ctx->_no_entry_error($tag) unless $ctx->stash('entry');
    my $cat = $ctx->stash('entry')->category;
    return 0 unless $cat;
        $args->{label}    ? $cat->label    eq $args->{label}
      : $args->{id}       ? $cat->id == $args->{id}
      : $args->{basename} ? $cat->basename eq $args->{basename}
      : $ctx->error(
        "A 'label' 'basename' or 'id' argument must 
                        be specified for $tag"
      );    # LOCALIZATION!
}

#--- active handlers

sub archive_type_active {    # throw error if $args->{type} missing.
    return 0 unless $_[0]->stash('archive_type');
    lc $_[0]->stash('archive_type') eq lc $_[1]->{type};
}

sub folder_active {
    return unless $_[0]->_check_folder;
    category_active(@_);
}

sub category_active {
    my ($ctx, $args, $cond) = @_;
    my $tag = lc $ctx->stash('tag');
    return $ctx->error(
        MT->translate(
            "You used an [_1] tag outside of the proper context.",
            '<$mt:' . $tag . '$>'
        )
    ) unless defined($ctx->stash('category'));
    my $cat;
    if (defined($ctx->stash('entry'))) {
        $cat = $ctx->stash('entry')->category;
    }
    elsif (defined($ctx->stash('archive_category'))) {
        $cat = $ctx->stash('archive_category');
    }
    return 0 unless $cat;
    if ($tag eq 'categoryisactive') {
        return $cat->id == $ctx->stash('category')->id;
    }
    elsif ($tag eq 'categoryancestorisactive') {
        return $ctx->stash('category')->is_ancestor($cat);
    }
    elsif ($tag eq 'categorydescendantisactive') {
        return $ctx->stash('category')->is_descendant($cat);
    }
    return $ctx->error('<$mt:' 
          . $tag
          . '$> is not recognized by this handler: '
          . join(' ', caller()));    # should never happen.
}

sub page_active {
    return unless _check_page(@_);
    entry_active(@_);
}

sub entry_active {
    my $e = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error('mt:' . lc $_[0]->stash('tag'));
    return 0 unless $_[0]->stash('archive_entry');
    return $_[0]->stash('archive_entry')->id == $e->id;
}

sub index_active {
    my ($ctx, $args) = @_;
    return 0 unless my $tmpl = $ctx->stash('index_template');
    my $tmpl_name = $args->{template} || 'Main Index';    # use identifier
    my $identifier = $tmpl->identifier || '';   # avoid uninit value warnings.
    my $name       = $tmpl->name       || '';   # same
    my $outfile    = $tmpl->outfile    || '';   # same
    return $tmpl_name eq $identifier            # emulate mt:link (sort of)
      || $tmpl_name   eq $name
      || $tmpl_name   eq $outfile;
}

sub tmpl_active {
    my ($ctx, $args) = @_;
    my $tmpl = $ctx->stash('template') or return 0;
    return $tmpl->id == $args->{id} if $tmpl && defined $args->{id};
    my $tmpl_name  = $args->{template} || '';   # error?
    my $identifier = $tmpl->identifier || '';   # avoid uninit value warnings.
    my $name       = $tmpl->name       || '';   # same
    my $outfile    = $tmpl->outfile    || '';   # same
    return $tmpl_name eq $identifier            # emulate mt:link (sort of)
      || $tmpl_name   eq $name
      || $tmpl_name   eq $outfile;
}

#--- updated handlers

sub pages_updated {
    require MT::Page;
    $_[1]->{class_type} = MT::Page->properties->{class_type};
    entries_updated(@_);
}

sub entries_updated {
    my ($ctx, $args, $cond) = @_;
    my $class_type = $args->{class_type} || 'entry';
    my $class      = MT->model($class_type);
    my $blog_id    = $ctx->stash('blog_id');
    my $t          = {blog_id => $blog_id} if $blog_id;
    my $a          = {
        'sort'    => 'modified_on',
        direction => 'descend'
    };
    if (my $days = $args->{days}) {    # minutes???
        require MT::Util;
        my @ago = MT::Util::offset_time_list(time - 86400 * $days, $blog_id);
        my $ago = sprintf "%04d%02d%02d%02d%02d%02d", $ago[5] + 1900,
          $ago[4] + 1, @ago[3, 2, 1, 0];
        $t->{modified_on} = [$ago];
        $a->{range_incl} = {modified_on => 1};
    }
    $a->{limit} = $args->{lastn} if $args->{lastn};
    my @entries = $class->load($t, $a);
    my $res     = '';
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $i       = 0;
    local $ctx->{__stash}{entries} = \@entries;
    my $glue = $args->{glue};

    for my $e (@entries) {
        local $ctx->{__stash}{entry}         = $e;
        local $ctx->{current_timestamp}      = $e->authored_on;
        local $ctx->{modification_timestamp} = $e->modified_on;
        my $out = $builder->build(
            $ctx, $tokens,
            {   %$cond,
                EntriesHeader => !$i,
                EntriesFooter => !defined $entries[$i + 1],
            }
        );
        return $ctx->error($builder->errstr) unless defined $out;
        $res .= $glue if defined $glue && $i;
        $res .= $out;
        $i++;
    }
    $res;
}

#--- entry and page enhancers

sub more {
    my $type = lc $_[0]->stash('tag');
    $type =~ s{bodymore}{}i;
    return unless $type eq 'entry' || _check_page(@_);
    my $tag = 'mt:' . lc $_[0]->stash('tag');
    return $_[0]->_no_entry_error($tag) unless $_[0]->stash('entry');
    my $hdlr_body = $_[0]->handler_for("${type}body");
    my $body      = $hdlr_body->(@_) or return;
    my $hdlr_more = $_[0]->handler_for("${type}more");
    my $more      = $hdlr_more->(@_);
    $more ? "$body\n<a id=\"more\"></a>\n$more" : $body;
}

sub nick_link {
    my $tag = lc $_[0]->stash('tag');
    return unless $tag eq 'entryauthornicknamelink' || _check_page(@_);
    my $e = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error("mt:${tag}");
    my $a = $e->author;
    return '' unless $a;
    my $name = $a->nickname || '';
    $name = defined $name ? $name : $a->name;
    if ($a->url) {
        sprintf qq(<a target="_blank" href="%s">%s</a>), $a->url, $name;
    }
    elsif ($a->email) {
        my $str = "mailto:" . $a->email;
        require MT::Util;
        $str = MT::Util::spam_protect($str)
          if $_[1] && $_[1]->{'spam_protect'};
        sprintf qq(<a href="%s">%s</a>), $str, $name;
    }
    else {
        $name;
    }
}

sub smart_body {
    my $tag = lc $_[0]->stash('tag');
    return unless $tag eq 'entrysmartbody' || _check_page(@_);
    my $entry = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error("mt:${tag}");
    my $excerpt = $entry->excerpt;
    my $body =
      (defined $excerpt && length $excerpt) ? $excerpt : $entry->text;
    length $body ? $body : '';
}

sub if_excerpt {
    my $tag = lc $_[0]->stash('tag');
    return unless $tag eq 'entryifexcerpt' || _check_page(@_);
    my $entry = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error("mt:${tag}");
    defined($entry->excerpt) && length($entry->excerpt);
}

#--- entry enhancer

sub primary_cat_link {
    my $tag = lc $_[0]->stash('tag');
    my $e   = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error("mt:${tag}");
    my $blog = $_[0]->stash('blog');
    my $arch = $blog->archive_url;
    $arch .= '/' unless $arch =~ m!/$!;
    require MT::Util;
    $arch .= MT::Util::archive_file_for($e, $blog, 'Category');
    $arch = MT::Util::strip_index($arch, $blog) unless $_[1]->{with_index};
    $arch;
}

#--- is new handlers

sub page_is_new {
    return unless _check_page(@_);
    my $e = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error('mt:' . lc $_[0]->stash('tag'));
    is_new('entry', 10080, @_);
}    # default one week

sub entry_is_new {
    my $e = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error('mt:' . lc $_[0]->stash('tag'));
    is_new('entry', 10080, @_);
}    # default one week

sub comment_is_new {
    my $c = $_[0]->stash('comment')
      or return $_[0]->_no_comment_error('mt:' . lc $_[0]->stash('tag'));
    is_new('comment', 1440, @_);
}    # default one day

sub is_new {
    my ($key, $default, $ctx, $args) = @_;
    my $days    = $args->{days};
    my $min     = $days ? $days * 1440 : $args->{lastn_minutes} || $default;
    my $expires = time - ($min * 60);
    my $object  = $ctx->stash($key)
      or return $ctx->error(
        MT->translate(
            'mt:[_1] was not used in the proper context.',
            lc $ctx->stash('tag')
        )
      );
    my $blog = $ctx->stash('blog');
    require MT::Util;
    my $col = $object->can('authored_on') ? 'authored_on' : 'created_on';
    my $on = MT::Util::ts2epoch($blog, $object->$col);
    $on > $expires;
}

#--- commenter handlers

sub is_author {
    my $ctx = shift;
    my $c   = $ctx->stash('comment') or return $ctx->_no_comment_error;
    my $e   = $ctx->stash('entry') || $c->entry;
    my $a   = $e->author or return;
    $a->email && $c->email && lc($a->email) eq lc($c->email);
}

sub is_blog_author {
    my $ctx     = shift;
    my $a       = {};
    my $c       = $ctx->stash('comment') or return $ctx->_no_comment_error;
    my $blog_id = $ctx->stash('blog_id')
      || $ctx->stash('blog') ? $ctx->stash('blog')->id : 0;
    my $r   = MT->request;
    my $key = __PACKAGE__ . '::authors::' . $blog_id;
    unless ($a = $r->stash($key)) {
        require MT::Author;
        require MT::Permission;
        my @authors = MT::Author->load(
            {type => MT::Author::AUTHOR},
            {join => ['MT::Permission', 'author_id', {blog_id => $blog_id}]}
        );
        $a->{lc $_->email} = 1 for @authors;
        $r->stash($key, $a);
    }
    $c->email && $a->{lc($c->email)};
}

#--- counts

sub word_count {
    my $tag   = lc $_[0]->stash('tag');
    my $entry = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error("mt:${tag}");
    require MT::Util;
    my $text = MT::Util::remove_html($entry->text) || '';
    $text .= MT::Util::remove_html($entry->text_more) || '';
    my $count = $text =~ s{\b(\S+)\b}{}ig;
    $count || 0;
}

sub image_count {
    my $tag   = lc $_[0]->stash('tag');
    my $entry = $_[0]->stash('entry')
      or return $_[0]->_no_entry_error("mt:${tag}");
    my $text = '' . $entry->text . $entry->text_more;
    my $count = $text =~ s/(<img\s[^>]*>)/$1/ig;
    $count || 0;
}

sub smart_count {
    my ($ctx, $args, $cond) = @_;
    my $tag = lc $_[0]->stash('tag');
    if ($tag =~ s{^entrycomment}{}) {    # handle deprecated tag usage
        $args->{class_type} = 'comment';
    }
    my $type = $args->{class_type} || 'comment';
    my $class = MT->model($type);
    my $count;
    my $e = $_[0]->stash('entry');
    if ($e && $type ne 'entry' && $type ne 'page') {
        my $meth = "${type}_count";
        $count =
            $e->can($meth)
          ? $e->$meth()
          : $class->count({entry_id => $e->id});
    }
    elsif (my $entries = $_[0]->stash('entries')) {    # archives
        my @ids = map { $_->id } @$entries;
        my $t = {entry_id => \@ids};
        $count = $class->count($t);
    }
    else {                                             # blog or system
        my $blog_id =
            $_[0]->stash('blog')
          ? $_[0]->stash('blog')->id
          : $_[0]->stash('blog_id');
        my $t = {};
        $t->{blog_id} = $blog_id if defined $blog_id;
        $count = $class->count($t);
    }
    if ($tag eq 'countlabel' || $tag eq 'countheading') {
        my $singular = $_[1]->{singular} || $class->class_label();
        my $plural   = $_[1]->{plural}   || $class->class_label_plural();
        my $label = $count == 1 ? $singular : $plural;
        return $tag eq 'countlabel'    # needs 0 to No handler
          ? $label
          : "$count $label";
    }
    elsif ($tag eq 'countiszero') {
        return !$count;
    }
    elsif ($tag eq 'countisone') {
        return $count == 1;
    }
}

#--- comment handlers

sub comment_atom_id {    # adapted from MT::Entry::make_atom_id
    my ($ctx, $args, $cond) = @_;
    my $c = $ctx->stash('comment')
      or return $ctx->_no_comment_error('mt:' . lc $ctx->stash('tag'));
    my $blog = $c->blog;
    my ($host, $year, $path, $blog_id, $c_id);
    $blog_id = $blog->id;
    $c_id    = $c->id;
    my $url = $blog->site_url || '';
    return unless $url;
    $url .= '/' unless $url =~ m!/$!;

    if ($url && ($url =~ m!^https?://([^/:]+)(?::\d+)?(/.*)$!)) {
        $host = $1;
        $path = $2;
    }
    if ($c->created_on && ($c->created_on =~ m/^(\d{4})/)) {
        $year = $1;
    }
    return '' unless $host && $year && $path && $blog_id && $c_id;   # louder?
    qq{tag:$host,$year:$path/$blog_id.#c$c_id};
}

sub comment_link {
    my ($ctx, $args, $cond) = @_;
    my $c = $ctx->stash('comment')
      or return $ctx->_no_comment_error('mt:' . lc $ctx->stash('tag'));
    my $link = $c->entry->permalink;
    $link .= comment_identifier(@_);
    return $link;
}

sub comment_identifier {
    my ($ctx, $args, $cond) = @_;
    my $c = $ctx->stash('comment')
      or return $ctx->_no_comment_error('mt:' . lc $ctx->stash('tag'));
    return '#c' . $c->id;
}

#--- misc

sub archive_date_header {
    my ($ctx, $args, $cond) = @_;
    my $this_date = 0;
    defined(my $at = $ctx->{current_archive_type})
      or return $ctx->error(
        MT->translate(
            "You used an [_1] tag outside of the proper context.",
            '<$mt:' . lc $ctx->stash('tag') . '$>'
        )
      );
    my $ts = $args->{ts} || $_[0]->{current_timestamp};
    if (lc $at eq 'monthly') {
        $this_date = substr $ts, 0, 4;
    }
    elsif (lc $at eq 'weekly') {
        $this_date = substr $ts, 5, 6;
    }
    else {
        return '';
    }
    my $last_date = $ctx->{__stash}{archive_date_last_date} || 0;
    if ($this_date != $last_date) {
        $ctx->{__stash}{archive_date_last_date} = $this_date;
        my $builder = $ctx->stash('builder');
        my $tokens  = $ctx->stash('tokens');
        defined(my $out = $builder->build($ctx, $tokens, $cond))
          or return $ctx->error($builder->errstr);
        return $out;
    }
    '';
}

sub alternator {
    my ($ctx, $args) = @_;
    $args->{key} ||= '#default';
    my $key = join '::', __PACKAGE__, $args->{key};
    $args->{odd}  ||= 'odd';
    $args->{even} ||= 'even';
    defined($ctx->stash($key))
      ? $ctx->stash($key, !$ctx->stash($key))
      : $ctx->stash($key, 0);
    $ctx->stash($key) ? $args->{even} : $args->{odd};
}

sub auto_title {    # use this for breadcrumbs method
    my ($ctx, $args) = @_;
    my @crumbs;
    my @cats;
    my $e = $ctx->stash('entry');
    my $cat =
        $e
      ? $ctx->stash('entry')->category
      : $ctx->stash('category') || $ctx->stash('archive_category');
    unshift @crumbs, map { $_->label } ($cat, $cat->parent_categories)
      if $cat;
    push @crumbs, $e->title if $e;    # timestamp if no title?
    unshift @crumbs, $ctx->stash('blog')->name;
    $args->{glue} ||= ' < ';
    $args->{'reverse'}
      ? join($args->{glue}, reverse @crumbs)
      : join($args->{glue}, @crumbs);
}

sub encode_block {
    my ($ctx, $args, $cond) = @_;
    my $out;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    defined($out = $builder->build($ctx, $tokens, $cond))
      or return $ctx->error($builder->errstr);
    require MT::Util;
    my $meth =
      lc $ctx->stash('tag') eq 'xmlencodeblock'
      ? 'encode_xml'
      : 'encode_html';
    no strict 'refs';
    &{"MT::Util::$meth"}($out);
}

sub xlink {
    my ($ctx, $args, $cond) = @_;
    my $blog;
    require MT::Template::ContextHandlers;
    my $blog_id = $args->{blog_id};
    return MT::Template::Context::_hdlr_link(@_) unless defined $blog_id;
    $blog = MT::Blog->load($blog_id)
      or return $ctx->error($blog_id . ' could not be found.'); #LOCALIZATION!
    local $ctx->{__stash}{'blog'}    = $blog;
    local $ctx->{__stash}{'blog_id'} = $blog_id;
    $args->{template} ||= 'main_index';
    delete $args->{blog_id};
    return MT::Template::Context::_hdlr_link(@_);
}

sub js_include {
    my ($ctx, $args, $cond) = @_;
    my $out;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    defined($out = $builder->build($ctx, $tokens, $cond))
      or return $ctx->error($builder->errstr);
    require MT::Util;
    $out = MT::Util::encode_js($out);
    return qq{ document.writeln('$out'); };
}

sub block { $_[0]->slurp($_[1], $_[2]) }

#--- deprecated

sub tmpl_comment {''}

sub entry_comment_count {
    $_[1]->{class_type} = 'entry';
    smart_count(@_);
}

#--- utility

sub _check_page {
    require MT::Template::ContextHandlers;    # yuck.
    MT::Template::Context::_check_page(@_);
}

1;

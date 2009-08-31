#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 15;

my $xml_encode = qq{
<MTSetVarBlock name="xml"><![CDATA[<a href="http://example.com/test">'Foo & Bar'</a>]]></MTSetVarBlock>
<MTTestIs test_name="XML Encode" var="xml"><MTXMLEncodeBlock><a href="http://example.com/test">'Foo & Bar'</a></MTXMLEncodeBlock></MTTestIs>
};

my $html_encode = qq{
<MTSetVarBlock name="html">&lt;a href=&quot;http://example.com/test&quot;&gt;'Foo &amp; Bar'&lt;/a&gt;</MTSetVarBlock>
<MTTestIs test_name="HTML Encode" var="html"><MTHTMLEncodeBlock><a href="http://example.com/test">'Foo & Bar'</a></MTHTMLEncodeBlock></MTTestIs>
};

my $alt = qq{
<MTTestIs value="odd"><MTAlternator></MTTestIs>
<MTTestIs value="even"><MTAlternator></MTTestIs>
<MTTestIs value="odd"><MTAlternator></MTTestIs>
<MTTestIs value="even"><MTAlternator></MTTestIs>
<MTTestIs value="foo"><MTAlternator id="hello" odd="foo" even="bar"></MTTestIs>
<MTTestIs value="bar"><MTAlternator id="hello" odd="foo" even="bar"></MTTestIs>
<MTTestIs value="foo"><MTAlternator id="hello" odd="foo" even="bar"></MTTestIs>
<MTTestIs value="bar"><MTAlternator id="hello" odd="foo" even="bar"></MTTestIs>
};

my $comm = qq{
<MTTestIs blank="1"><MTTemplateComment>This is not here</MTTemplateComment></MTTestIs>
};

use MT::Blog;
my $blog    = MT::Blog->load();
my $blog_id = $blog->id;

my $xlink = qq {
<MTTestIs value="http://127.0.0.1/"><MTLink blog_id="$blog_id" template="main_index"></MTTestIs>
<MTTestIs value="http://127.0.0.1/"><MTLink blog_id="$blog_id"></MTTestIs>
};

my $block = qq {
<MTTestIs value="Hello World"><MTBlock>Hello World</MTBlock></MTTestIs>
<MTTestIs value="hello world"><MTBlock remove_html="1" lower_case="1"><h1>Hello <em>World</em></h1></MTBlock></MTTestIs>
};

run_test_tmpl(sub {$xml_encode});
run_test_tmpl(sub {$html_encode});
run_test_tmpl(sub {$alt});
run_test_tmpl(sub {$comm});         # deprecated
run_test_tmpl(sub {$xlink});        # note: we aren't creating a blog context;
run_test_tmpl(sub {$block});

# TO DO: autotitle, Preformatted Text filter, js_include

__END__

sub init {
    my ($cb, $ctx) = @_;
    $ctx->stash('blog',    $blog);
    $ctx->stash('blog_id', 1);
    
}

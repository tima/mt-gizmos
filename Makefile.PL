use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    'NAME'             => 'MT-Gizmos',
    'MIN_PERL_VERSION' => '5.8.1',
    'LICENSE'          => 'perl',
    'AUTHOR'           => 'Timothy Appnel <tim@appnel>',
    'PREREQ_PM'        => {'Test::More' => 0,},
    'META_MERGE'       => {
        'resources' => {
            'license'    => 'http://dev.perl.org/licenses/',
            'repository' => 'http://github.com/tima/mt-gizmos',
            'bugtracker' => 'http://github.com/tima/mt-gizmos',
        },
    },
);

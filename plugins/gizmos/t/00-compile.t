#!perl
use strict;
use warnings;

use MT::Bootstrap;
use MT::Test tests => 5;

use_ok('MT::Gizmos::Callbacks');
use_ok('MT::Gizmos::Tags');
use_ok('MT::Gizmos::Modifiers');
use_ok('MT::Gizmos::TextFilters');
use_ok('MT::Gizmos::Util');

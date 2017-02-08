package Settings;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just needed because this file is utf8)

our $blog_title = "Test";

our $posts_per_page = 5; # to disable pagination

our $template_toolkit_config = {
	INCLUDE_PATH => 'templates/',  # or list ref
	INTERPOLATE  => 1,               # expand "$var" in plain text
	POST_CHOMP   => 1,               # cleanup whitespace
	OUTPUT_PATH => 'posts/',
	DEBUG => 1
};

1;

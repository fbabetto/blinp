package Pages;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

use Hash::MultiValue;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
#our @EXPORT = qw();
our @EXPORT_OK = qw(addPost editPost deletePost listPosts);  # symbols to export on request

use Template;
use Encode;
use Time::Piece;
use JSON::PP;

use Metadata;

my $config = {
	INCLUDE_PATH => 'templates/',  # or list ref
	INTERPOLATE  => 1,               # expand "$var" in plain text
	POST_CHOMP   => 1,               # cleanup whitespace
	OUTPUT_PATH => 'posts/',
	DEBUG => 1
};

my $template = Template->new($config);

# listPosts($posts_per_page)
# generate and paginate the post's list
sub listPosts {
	my $posts_per_page = shift;
	# TODO METADATA MODULE FOR MANAGING METADATA!
	my $posts_count = Metadata::getPostsCount(); # USEFUL FOR PAGINATION
	my $posts_metadata = Metadata::getPostsMetadata();
	my $posts_list = $posts_metadata;
	# TODO ADD A SNIPPET OF CONTENT TO POSTS_LIST
	foreach my $key (keys %{ $posts_list }) {
		$posts_list->{$key}{'content'}='TODO'; # TODO
		# TODO PAGINATION
	}
	
	my $title = 'Index';
	my $vars = {
		pagetype => 'postslist',
		title => $title,
		blogtitle => 'test',
		posts => $posts_list,
	};
	
	my $page = 'index.html';
	$template->process('main.tt', $vars, $page) || die $template->error(), "\n";
	return $page;
}

sub addPost {
	my $title = 'Add a new post';
	my $vars = {
		pagetype => 'add',
		title => $title,
		blogtitle => 'test'
	};
	# the html header is sent by the caller of this function
	my $page;
	$template->process('main.tt', $vars, \$page) || die $template->error(), "\n";
	return $page;
}

sub editPost {
...
}

sub deletePost {
...
}

sub processPost {
	my $params = shift;
	
	print Dumper($params);
	my $title = $params->{'post_title'};
	my $content = $params->{'post_content'};
	my $tags = $params->{'tags'};
	my $modified = 0; # TODO this var will be used in case of post's modification
	
	my $current_datetime = getCurrentDateTime();
	# we calculate the datetime/date only once to avoid differences beetween the date in current_datetime and the date in current_date
	my $current_date = getCurrentDate($current_datetime);
	
	# save post's source content in multimarkdown format
	my $found=0;
	my $index=0;
	my $id=0;
	while(!$found) {
		if(!-e "posts-src/$current_date-$index.markdown") {
			$found=1;
			$id="$current_date-$index";
			#save
			open(OUTFILE, ">", "posts-src/$current_date-$index.markdown");
			print OUTFILE $content;
			close (OUTFILE);
		}
		else {
			$index++;
		}
	}
	
	print Dumper($index);

	# save metadata
	my $decoded_hashref = {};
# 		print Dumper($decoded_hashref);
	$decoded_hashref->{$id}{'title'}=decode('utf8', $title);
	$decoded_hashref->{$id}{'created'}=$current_datetime;
	if($tags) {
		$decoded_hashref->{$id}{'tags'}=decode('utf8', $tags);
	}
	if($modified) {
		$decoded_hashref->{$id}{'modified'}=$modified;
	}
	# TODO SESSION AND AUTHOR implementation
	
	print Dumper($decoded_hashref);
	
	Metadata::addPostMetadata( $decoded_hashref );
	
	# save generated html page
	my $vars = {
		pagetype => 'post',
		title => $title,
		content => $content,
		blogtitle => 'test',
		created => $current_datetime,
		modified => $modified,
		tags => $tags
	};
	$template->process('main.tt', $vars, "$id.html") || die $template->error(), "\n";
	
	listPosts();
	
	return "$id.html";
	
}

sub getCurrentDateTime {
	my $current_datetime = (localtime)->datetime;
	return $current_datetime;
}

sub getCurrentDate {
	my $current_datetime = shift;
	my $current_date = substr $current_datetime, 0, 10;
	return $current_date;
}

1;
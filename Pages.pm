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
use File::Copy "mv";

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
		blogtitle => 'test',
		pagetype => 'add',
		title => $title,
		id => 0
	};
	# the html header is sent by the caller of this function
	my $page;
	$template->process('main.tt', $vars, \$page) || die $template->error(), "\n";
	return $page;
}

sub editPost {
	my $params=shift;
	my $post_id=$params->{'post'}; # post's id to be edited
	
	my $metadata=Metadata::getPostsMetadata();
	my $title=$metadata->{$post_id}{'title'};
	my $tags=$metadata->{$post_id}{'tags'};
	# TODO add all the missing metadata (some are optional!)
	
	my $page;
	if(-e "posts-src/$post_id.markdown" and -s "posts-src/$post_id.markdown") { # if exists and is not empty
		open(FILE, "<", "posts-src/$post_id.markdown");
		my $content=<FILE>;
		close(FILE);

		my $vars = {
			blogtitle => 'test',
			pagetype => 'edit',
			title => $title,
			content => $content,
			tags => $tags,
			id => $post_id
		};
		# the html header is sent by the caller of this function
		
		$template->process('main.tt', $vars, \$page) || die $template->error(), "\n";
	}
	else {
		$page = "Post not found!";
	}
	return $page;
}

sub deletePostConfirm {
	my $params=shift;
	my $post_id=$params->{'post'};
	my $page;
	my $metadata=Metadata::getPostsMetadata();
	my $title=$metadata->{$post_id}{'title'};
	my $created=$metadata->{$post_id}{'created'};
	if(-e "posts-src/$post_id.markdown" and -s "posts-src/$post_id.markdown") { # if exists and is not empty
		my $vars = {
				blogtitle => 'test',
				pagetype => 'confirm_delete',
				title => $title,
				created => $created,
	# 			content => $content,
	# 			tags => $tags,
				id => $post_id
		};
		$template->process('main.tt', $vars, \$page) || die $template->error(), "\n";
	}
	else {
		$page = "Post not found!";
	}
	return $page;
}

# NOTE: the post source in markdown is not deleted, only the generated html is deleted.
sub deletePost {
	my $params=shift;
	my $post_id=$params->{'post'}; # post's id to be deleted
	# maybe the deleted posts' metadata should be saved on a separate json file, instead of deleting it
	# the post src (post_id.markdown) should be moved to a special folder called deleted
	
	# delete post's html file
	unlink "posts/$post_id.html";
	
	# move post's markdown file
	if(!-d 'posts-src/deleted') {
		mkdir 'posts-src/deleted';
	}
	mv("posts-src/$post_id.markdown","posts-src/deleted/");
	
	# move post's metadata
	Metadata::moveDeletedPostMetadata( $post_id );
	
	listPosts();
	
	my $page;
	my $vars = {
		blogtitle => 'test',
		pagetype => 'delete',
# 		title => $title,
# 		created => $created,
# 			content => $content,
# 			tags => $tags,
		id => $post_id
	};
	$template->process('main.tt', $vars, \$page) || die $template->error(), "\n";
	return $page;# TODO add deletion/move tests in case something go wrong
}



sub processPost {
	my $params = shift;
	
	print Dumper($params);
	my $title = $params->{'post_title'};
	my $content = $params->{'post_content'};
	my $tags = $params->{'tags'};
	my $post_id = $params->{'id'}; # TODO this var will be used in case of post's modification
	
	my $current_datetime = getCurrentDateTime();
	# we calculate the datetime/date only once to avoid differences beetween the date in current_datetime and the date in current_date
	my $current_date = getCurrentDate($current_datetime);
	
	if($post_id==0) {
		# save post's source content in multimarkdown format
		my $found=0;
		my $index=0;
		while(!$found) {
			if(!-e "posts-src/$current_date-$index.markdown") {
				$found=1;
				$post_id="$current_date-$index";
				#save
				open(OUTFILE, ">", "posts-src/$post_id.markdown");
				print OUTFILE $content;
				close (OUTFILE);
			}
			else {
				$index++;
			}
		}
	}
	else {
		open(OUTFILE, ">", "posts-src/$post_id.markdown");
		print OUTFILE $content;
		close (OUTFILE);
	}
	
# 	print Dumper($index);

	my $created = 0;
	my $modified = 0;
	if($post_id) {
		my $posts_metadata=Metadata::getPostsMetadata();
		$created = $posts_metadata->{$post_id}{'created'};# FIXME maybe add a check if the key exists
		$modified = $current_datetime;
	}
	else {
		$created = $current_datetime;
	}

	# save metadata
	my $decoded_hashref = {};
	$decoded_hashref->{$post_id}{'title'}=decode('utf8', $title);
	if($tags) {
		$decoded_hashref->{$post_id}{'tags'}=decode('utf8', $tags);
	}
	if($created) {
		$decoded_hashref->{$post_id}{'created'}=$created;
	}
	if($modified) {
		$decoded_hashref->{$post_id}{'modified'}=$modified;
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
		created => $created,
		modified => $modified,
		tags => $tags
	};
	$template->process('main.tt', $vars, "$post_id.html") || die $template->error(), "\n";
	
	listPosts();
	
	return "$post_id.html";
	
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
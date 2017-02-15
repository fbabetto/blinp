package PostPages;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

use Hash::MultiValue;
use Data::Dumper;

#require Exporter;
#our @ISA = qw(Exporter);
#our @EXPORT = qw();
#our @EXPORT_OK = qw(add edit delete list);  # symbols to export on request

use Template;
use Encode;
use Time::Piece;
use JSON::PP;
use File::Copy "mv";
use POSIX;

use Metadata;
use Settings;

my $template_f = Template->new($Settings::template_toolkit_config_write_on_file);
my $template_s = Template->new($Settings::template_toolkit_config_write_on_scalar);

sub _generate_index {
	my @posts_ids = @{$_[0]};
	my $page = $_[1]; # if null we don't write to file but we return the generated page
	my $prev_index = $_[2];
	my $next_index = $_[3];
	print "posts_ids: ".Dumper(@posts_ids)."\n";
	print "page name: ".Dumper($page)."\n";
	my $post_count = scalar @posts_ids;
	my $posts_list = {}; # ref to an empty hash
	foreach my $post_id (@posts_ids) {
		my($metadata, $content) = Metadata::getPostMetadataAndContentSnippet($post_id);
		if(!$metadata) {
			print "\nWARNING: no metadata for post id: ".$post_id."\n";
		} else {
			$posts_list->{$post_id}=$metadata->{$post_id};
			$posts_list->{$post_id}{'content'}=$content;
		}
	}
	
	# the posts are ordered by template-toolkit in the output file
	# because we can't sort the hash keys directly
	my $title = 'Index';
	my $pagetype = 'postslist';
	if($page eq '') {
		$pagetype = 'admin_postslist';
	}
	my $vars = {
		pagetype => $pagetype,
		title => $title,
		blogtitle => $Settings::blog_title,
		posts => $posts_list,
		prev_index => $prev_index,
		next_index => $next_index,
	};
	if($page ne '') {
		$template_f->process('main.tt', $vars, $page) || die $template_f->error(), "\n";
	} else {
		$template_s->process('main.tt', $vars, \$page) || die $template_f->error(), "\n";
		return $page;
	}
}

sub list {
	my $posts_per_pages= $Settings::posts_per_page;
	my @posts_ids = Metadata::getPostsIDs();
	# should be ordered because, later, it could be splitted for pagination
	@posts_ids = sort {$b cmp $a} @posts_ids;
	my $post_count = scalar @posts_ids;
	# if pagination is disabled we put all posts in one index file
	if ($posts_per_pages == 0) {
		$posts_per_pages = $post_count;
	}
	my $index_pages = ceil($post_count / $posts_per_pages);
	my $generated_pages = 0;
	my $start_index = 0;
	my $end_index = $posts_per_pages-1;
	my $index_page_name='index.html';
	my $prev_page = '';
	my $next_page = '';
	while($end_index <= ($post_count-1)) {
		if($end_index > ($post_count-1)) {
			$end_index = $post_count-1;
		} else {
			$next_page = 'index-'.($generated_pages+1).'.html';
		}
		if($generated_pages > 1) {
			$prev_page = 'index-'.($generated_pages-1).'.html';
		} elsif($generated_pages == 1) {
			$prev_page = 'index.html';
		}
		my @current_posts_ids = @posts_ids[$start_index..$end_index];
		_generate_index(\@current_posts_ids, $index_page_name, $prev_page, $next_page);
		$generated_pages++;
		$start_index+=$posts_per_pages;
		$end_index+=$posts_per_pages;
		$index_page_name = 'index-'.$generated_pages.'.html';
	}
	if($generated_pages < $index_pages) {
		# we miss the last index files
		$next_page = '';
		$prev_page = 'index-'.($generated_pages-1).'.html';
		$end_index = ($post_count-1);
		my @current_posts_ids = @posts_ids[$start_index..$end_index];
		_generate_index(\@current_posts_ids, $index_page_name, $prev_page, $next_page);
	}
}

sub index {
	my $index_name = shift;
	my $index_offset=substr($index_name, -1, 1); # take the last character
	# if 0 it's the first page, if 1 it's the second one...
	if($index_offset eq '') {
		$index_offset=0;
	}
	my $posts_per_pages= $Settings::posts_per_page;
	my @posts_ids = Metadata::getPostsIDs(); # FIXME we can optimize here and get
	# ...only the needed ids
	my $post_count = scalar @posts_ids;
	my $max_index_offset = ceil($post_count / $posts_per_pages);
	if($index_offset > $max_index_offset or $index_offset < 0) {
		return 0; # 404 not found
	}
	# the lasts "$posts_per_pages" posts_ids
	# should be ordered because, later, it could be splitted for pagination
	@posts_ids = sort {$b cmp $a} @posts_ids;
	# if pagination is disabled we put all posts in one index file
	if ($posts_per_pages == 0) {
		$posts_per_pages = $post_count;
	}
	my $start_index=$posts_per_pages*$index_offset;
	my $end_index=$posts_per_pages*($index_offset+1)-1;
	my $prev_page = '';
	my $next_page = '';
	if($index_offset > 0) {
		my $n = $index_offset-1;
		$prev_page = "index-$n";
	}
	if($end_index >= $post_count) {
		$end_index = $post_count-1;
	} else {
		my $n = $index_offset+1;
		$next_page = "index-$n"
	}
	my @current_posts_ids = @posts_ids[$start_index..$end_index];
	return _generate_index(\@current_posts_ids, '', $prev_page, $next_page);
}

# show the generated post without writing to file
sub view {
	my $post_id = shift;
	my($metadata, $content) = Metadata::getPostMetadataAndContent($post_id);
	#my $title = $metadata->{$post_id}{'title'};
	my $vars = {
		pagetype => 'post',
		title => $metadata->{$post_id}{'title'},
		content => $content,
		blogtitle => $Settings::blog_title,
		created => $metadata->{$post_id}{'created'},
		modified => $metadata->{$post_id}{'modified'},
		tags => $metadata->{$post_id}{'tags'}
	};
	my $page;
	$template_s->process('main.tt', $vars, \$page) || die $template_f->error(), "\n";
	return $page;
}

sub add {
	my $title = 'Add a new post';
	my $vars = {
		blogtitle => $Settings::blog_title,
		pagetype => 'add',
		title => $title,
		id => 0
	};
	
	my $page;
	$template_s->process('main.tt', $vars, \$page) || die $template_f->error(), "\n";
	return $page;
}

sub edit {
	#my $params=shift;
	#my $post_id=$params->{'post'}; # post's id to be edited
	my $post_id = shift;
	my $page;
	my ($metadata, $content) = Metadata::getPostMetadataAndContent($post_id);
	if($metadata) {
		my $title=$metadata->{$post_id}{'title'};
		my $tags=$metadata->{$post_id}{'tags'};
		# TODO add all the missing metadata (some are optional!)
		my $vars = {
			blogtitle => $Settings::blog_title,
			pagetype => 'edit',
			title => $title,
			content => $content,
			tags => $tags,
			id => $post_id
		};
		$template_s->process('main.tt', $vars, \$page) || die $template_f->error(), "\n";
	}
	else {
		$page = "Post not found!";
	}
	print Dumper($page);
	return $page;
}

sub deleteConfirm {
	my $post_id_in_query = shift;
	my $params=shift;
	#my $post_id=$params->{'post'};
	my $post_id = $post_id_in_query;
	my $page;
	my $metadata = Metadata::getPostMetadata($post_id);
	if($metadata) {
		my $title=$metadata->{$post_id}{'title'};
		my $created=$metadata->{$post_id}{'created'};
		my $vars = {
				blogtitle => $Settings::blog_title,
				pagetype => 'confirm_delete',
				title => $title,
				created => $created,
	# 			content => $content,
	# 			tags => $tags,
				id => $post_id
		};
		$template_s->process('main.tt', $vars, \$page) || die $template_f->error(), "\n";
	}
	else {
		$page = "Post not found!";
	}
	return $page;
}

# NOTE: the post source in markdown is not deleted (just moved in deleted/), only the generated html is deleted.
sub delete {
	my $post_id_in_query = shift; # IGNORED
	my $params=shift;
	my $post_id=$params->{'post'}; # post's id to be deleted
	
	# delete post's html file
	unlink "posts/$post_id.html";
	
	# move post's markdown file
	if(!-d 'posts-src/deleted') {
		mkdir 'posts-src/deleted';
	}
	# FIXME: if the destination directory contains a file with the same name, the file will be overwritten?
	mv("posts-src/$post_id.markdown","posts-src/deleted/");
	
	list();
	
	my $page;
	my $vars = {
		blogtitle => $Settings::blog_title,
		pagetype => 'delete',
# 		title => $title,
# 		created => $created,
# 			content => $content,
# 			tags => $tags,
		id => $post_id
	};
	$template_s->process('main.tt', $vars, \$page) || die $template_f->error(), "\n";
	return $page;# TODO add deletion/move tests in case something goes wrong
}

sub process {
	my $post_id_in_query = shift; # IGNORED
	my $params = shift;
	
	print Dumper($params);
	
	my $title = $params->{'post_title'};
	my $content = $params->{'post_content'};
	my $tags = $params->{'tags'};
	my $post_id = $params->{'id'}; # TODO this var will be used in case of post's modification
	
	my $current_datetime = getCurrentDateTime();
	# we calculate the datetime/date only once to avoid differences beetween the date in current_datetime and the date in current_date
	my $current_date = getCurrentDate($current_datetime);
	
	# TODO ADD "added" datetime metadata even if the date is in its post_id
	
# 	print Dumper($index);

	# FIXME MOVE THIS FS STUFF IN ANOTHER MODULE (maybe)

	# generate post_id if it's a new post
	if($post_id==0) {
		my $found=0;
		my $index=0;
		while(!$found) {
			my $padded_index = sprintf("%02d", $index);
			if(!-e "posts-src/$current_date-$padded_index.markdown") {
				$found=1;
				$post_id="$current_date-$padded_index";
			}
			else {
				$index++;
				die "index greater than 99" unless $index<=99;
			}
		}
	}

	# prepare the metadata hash

	my $created = 0;
	my $modified = 0;
	my $metadata = Metadata::getPostMetadata($post_id);
	if(exists $metadata->{$post_id}{'created'}) {
		$created = $metadata->{$post_id}{'created'};
		$modified = $current_datetime;
	} else {
		$created = $current_datetime;
		$modified = $current_datetime;
	}
# save post
#open(OUTFILE, ">", "posts-src/$post_id.markdown");
#				debug
#				print encode_json($decoded_hashref)."\n".$content;
#				print OUTFILE encode_json($decoded_hashref)."\n".$content;
#				close (OUTFILE);

	# 
	#my $decoded_hashref = {};
#	$metadata->{$post_id}{'title'}=decode('utf8', $title);
	$metadata->{$post_id}{'title'}=$title;
	if($tags) {
#		$metadata->{$post_id}{'tags'}=decode('utf8', $tags);
		$metadata->{$post_id}{'tags'}=$tags;
	}
	if($created) {
		$metadata->{$post_id}{'created'}=$created;
	}
	if($modified) {
		$metadata->{$post_id}{'modified'}=$modified;
	}
	# TODO SESSION AND AUTHOR implementation
	
	#print Dumper($decoded_hashref);
	
	# save the markdown source file with the metadata
	Metadata::writePost($metadata, $content);
	
	# save generated html page
	my $vars = {
		pagetype => 'post',
		title => $title,
		content => $content,
		blogtitle => $Settings::blog_title,
		created => $created,
		modified => $modified,
		tags => $tags
	};
	$template_f->process('main.tt', $vars, "$post_id.html") || die $template_f->error(), "\n";
	
	list();
	
	return "$post_id.html";
	
}

# TODO MOVE THOSE FUNCTION IN ANOTHER MODULE DATE-TIME...
 
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

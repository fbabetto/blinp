package Metadata;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just needed because this file is utf8)

use Hash::MultiValue;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
#our @EXPORT = qw();
our @EXPORT_OK = qw(getPostsCount getPostsMetadata addPostMetadata);  # symbols to export on request

use Template;
use Encode;
use Time::Piece;
use JSON::PP;
use Cwd;

sub getPostMetadata {
	my $post_id = shift;
	my $metadata = {};
	$metadata->{$post_id}={};
	# if file exists and is not empty
	if(-e "posts-src/$post_id.markdown" and -s "posts-src/$post_id.markdown") {
		open(FILE, "<", "posts-src/$post_id.markdown"); # TODO OR DIE
		my $encoded_metadata = <FILE>; # the first line cointains the metadata
		$encoded_metadata = _removeMarkdownCommentTags($encoded_metadata);
#		print "after: ".$encoded_metadata."\n";
		$metadata = decode_json($encoded_metadata); #FIXME this could fail
		close(FILE);
	} else {
		# TODO ERROR maybe
	}
	return $metadata;
}

sub getPostMetadataAndContent {
	my $post_id = shift;
	my $metadata = 0;
	my $markdown_content = 0;
	if(-e "posts-src/$post_id.markdown" and -s "posts-src/$post_id.markdown") {
		open(FILE, "<", "posts-src/$post_id.markdown"); # TODO OR DIE
		my $encoded_metadata = <FILE>; # the first line cointains the metadata
		$encoded_metadata = _removeMarkdownCommentTags($encoded_metadata);
#		print "after: ".$encoded_metadata."\n";
		$metadata = decode_json($encoded_metadata); #FIXME this could fail
		$markdown_content = do { local $/; <FILE> };
		close(FILE);
	} else {
		# TODO ERROR maybe
	}
#	print Dumper($metadata);
	return ($metadata, $markdown_content);
}

# same as the previous but get only a content snippet
sub getPostMetadataAndContentSnippet {
	my $post_id = shift;
	my $metadata = 0;
	my $markdown_content = 0;
	# FIXME for the moment we just return the whole content
	return getPostMetadataAndContent($post_id);
}

sub writePost {
	my $metadata = shift;
	my $markdown_content = shift;
	my $post_id = (keys %$metadata)[0];
	open(OUTFILE, ">", "posts-src/$post_id.markdown");
	#debug
#	print _addMarkdownCommentTags(encode_json($metadata))."\n".$markdown_content;
	my $encoded_metadata = _addMarkdownCommentTags(encode_json($metadata));
	print OUTFILE $encoded_metadata."\n".$markdown_content;

	close (OUTFILE);
}

# https://stackoverflow.com/questions/32432301/counting-the-number-of-files-in-a-directory-of-special-type-in-perl
sub getPostsIDs {
	my @posts_ids;
	my $dir = getcwd().'/posts';
	#print "\ndir: ".$dir."\n";
	opendir(my $dh, $dir) or die "opendir($dir): $!\n";
	while (my $file = readdir($dh)) {
		 # We only want files
		 next unless (-f "$dir/$file");
		 # Use a regular expression to find files ending in .html
		# FIXME maybe use a stricter regex to filter date-number.html files only
		next unless ($file =~ m/^[0-9]{4,4}-[0-9]{2,2}-[0-9]{2,2}-[0-9]+\.html$/);
		push @posts_ids, substr($file, 0, -5);
	}
	closedir($dh);
	return @posts_ids
}

sub _addMarkdownCommentTags {
	my $string_to_enclose = shift;
#	print "before: ".$string_to_enclose."\n";
	return '<!---'.$string_to_enclose.'-->';
}

sub _removeMarkdownCommentTags {
	my $string_to_clean = shift;
#	print "before: ".$string_to_clean."\n";
	return substr($string_to_clean, 5, -4);
}

1;

package Metadata;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

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

# return all the posts metadata hash ref
sub _readMetadataFile {
	my $json;
	my $decoded_hashref = {};
	if(-e "posts-metadata.json" and -s "posts-metadata.json") { # if exists and is not empty
		# let's read its content
# 		print "OK!";
		open(JSONFILE, "<", "posts-metadata.json");
		$json= <JSONFILE>;
		close(JSONFILE);
		$decoded_hashref=decode_json($json);
	}
	return $decoded_hashref;
}

# sub _writeMetadataFile {
# 	my $metadata_hash_ref = shift;
# 	
# 	print "ref hash passato";
# 	print Dumper($metadata_hash_ref);
# 	
# 	my $decoded_hashref = _readMetadataFile();
# 	@{$decoded_hashref}{keys %{$metadata_hash_ref}} = values %{$metadata_hash_ref};
# 	print "hash letto da file e forse cambiato";
# 	print Dumper($decoded_hashref);
# 	open(JSONFILE, ">", "posts-metadata.json");
# 	print JSONFILE encode_json($decoded_hashref);
# # 	print JSONFILE encode_json($metadata_hash_ref);
# 	close(JSONFILE);
# }

# write all the metadata file with the passed hash ref to be saved
# argument: the all hash ref of all metadata
sub _writeMetadataFile {
	my $decoded_hashref = shift;
	print "hash ricevuto da scrivere dalla write\n";
	print Dumper($decoded_hashref);
	open(JSONFILE, ">", "posts-metadata.json");
	print JSONFILE encode_json($decoded_hashref);
# 	print JSONFILE encode_json($metadata_hash_ref);
	close(JSONFILE);
}

# add a single post metadata to the metadata file
# argument: a hash ref to a single post metadata
sub _addMetadataToFile {
	my $metadata_hash_ref = shift;
	
	print "ref hash passato\n";
	print Dumper($metadata_hash_ref);
	
	my $decoded_hashref = _readMetadataFile();
	@{$decoded_hashref}{keys %{$metadata_hash_ref}} = values %{$metadata_hash_ref};
	print "hash letto da file e forse cambiato\n";
	print Dumper($decoded_hashref);
	open(JSONFILE, ">", "posts-metadata.json");
	print JSONFILE encode_json($decoded_hashref);
# 	print JSONFILE encode_json($metadata_hash_ref);
	close(JSONFILE);
}

# remove a single post metadata from the metadata file
# argument: the post id
sub _removeMetadataFromFile {
	#my $metadata_hash_ref = shift;
	my $post_id = shift;
	
	#print "ref hash passato (remove)\n";
	#print Dumper($metadata_hash_ref);
	
	my $decoded_hashref = _readMetadataFile();
	delete $decoded_hashref->{$post_id};
	#@{$decoded_hashref}{keys %{$metadata_hash_ref}} = values %{$metadata_hash_ref};
	print "hash cambiato dalla remove\n";
	print Dumper($decoded_hashref);
	_writeMetadataFile($decoded_hashref);
	#open(JSONFILE, ">", "posts-metadata.json");
	#print JSONFILE encode_json($decoded_hashref);
	#close(JSONFILE);
}

sub getPostsCount {
	my $decoded_hashref = _readMetadataFile();
	my $postCount = scalar keys %{$decoded_hashref};
	return $postCount
}

sub getPostsMetadata {
	my $decoded_hashref = _readMetadataFile();
	return $decoded_hashref;
}

sub addPostMetadata {
	my $metadata_hash_ref = shift;
	_addMetadataToFile( $metadata_hash_ref );
}

 sub removePostMetadata {
	my $post_id = shift;
	_removeMetadataFromFile($post_id);
 }

sub moveDeletedPostMetadata {
	my $post_id = shift;
	my $metadata = getPostsMetadata;
	
	print "metadata passati alla move deleted...\n";
	print Dumper($metadata);
	
	my $post_metadata = $metadata;
	my $deleted_metadata={};
	if(-e 'deleted-post-metadata.json') {
		open(JSONFILE, "<", "deleted-posts-metadata.json");
		my $json= <JSONFILE>;
		close(JSONFILE);
		$deleted_metadata=decode_json($json);
	}
	@{$deleted_metadata}{keys %{$post_metadata}} = values %{$post_metadata};
	delete $metadata->{$post_id};
	
	print "metadata passati alla move deleted dopo cancellazione\n";
	print Dumper($metadata);
	
	#_removeMetadataFromFile($metadata);
	_removeMetadataFromFile($post_id);
	# TODO addToMetadataFileDeleted() or something like that
	# FIXME buggy (it does not delete properly)
	open(JSONFILE, ">", "deleted-posts-metadata.json");
	print JSONFILE encode_json($deleted_metadata);
	close(JSONFILE);
}

1;

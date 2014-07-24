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

sub _readMetadataFile {
	my $json;
	my $decoded_hashref = {};
	if(-e "posts-metadata.json" and -s "posts-metadata.json") { # if exists and is not empty
		# let's read its content
		print "OK!";
		open(JSONFILE, "<", "posts-metadata.json");
		$json= <JSONFILE>;
		close(JSONFILE);
		$decoded_hashref=decode_json($json);
	}
	return $decoded_hashref;
}

sub _writeMetadataFile {
	my $metadata_hash_ref = shift;
	my $decoded_hashref = _readMetadataFile();
	@{$decoded_hashref}{keys %{$metadata_hash_ref}} = values %{$metadata_hash_ref};
	print Dumper($decoded_hashref);
	open(JSONFILE, ">", "posts-metadata.json");
	print JSONFILE encode_json($decoded_hashref);
	close(JSONFILE);
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
	_writeMetadataFile( $metadata_hash_ref );
}

1;
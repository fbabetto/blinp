package Users;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

require Exporter;
our @ISA = qw(Exporter);
#our @EXPORT = qw();
our @EXPORT_OK = qw(authenticate);  # symbols to export on request

# http://blog.kablamo.org/2013/12/18/authen-passphrase/
#use Authen::Passphrase::BlowfishCrypt;
# http://perlmaven.com/storing-passwords-in-a-an-easy-but-secure-way
# http://advent.perldancer.org/2011/4
use Crypt::PBKDF2;

use Data::Dumper;
use JSON::PP;

use Plack::Session;

# uncomment the next line for initializing the admin password; put a strong password!
# after that launch the application with "plackup blinp.psgi" (without quotes) in console
# for generating the initial password file.
# Then stop the application and comment again the following line
#  _hash_password('admin', 'admin');

sub _hash_password {
	my ($username, $password) = @_;
# 	my $blowfish = Authen::Passphrase::BlowfishCrypt->new(
# 		passphrase  => $password,
# 		salt_random => 1,
# 		cost        => 16,
# 	);

	my $pbkdf2 = Crypt::PBKDF2->new(
		hash_class => 'HMACSHA2',
		hash_args => {
			sha_size => 512,
		},
		salt_len => 10,
	);
	
	my $decoded_hashref = _get_users_data();
	
#	$decoded_hashref->{$username}{'hashed_password'}=$blowfish->as_rfc2307;
	my $hashed_password = $pbkdf2->generate($password);
	$decoded_hashref->{$username}{'hashed_password'}=$hashed_password;
	
	# FIXME JSON stuff refactor needed
	open(JSONFILE, ">", "users.json");
	print JSONFILE encode_json($decoded_hashref);
	close(JSONFILE);
	print "Password generated!\n";
}

sub _get_users_data {
	my $json;
	my $decoded_hashref = {};
	if(-e "users.json" and -s "users.json") { # if exists and is not empty
		open(JSONFILE, "<", "users.json");
		$json= <JSONFILE>;
		close(JSONFILE);
		$decoded_hashref=decode_json($json);
	}
	return $decoded_hashref;
}

sub authenticate {
	my ($username, $password, $env) = @_;
	
# 	print Dumper($username);
# 	print Dumper($password);
#  	print Dumper($env);
	
	my $users = _get_users_data();
# 	my $hashed_password = Authen::Passphrase->from_rfc2307($users->{$username}{'hashed_password'});
	my $hashed_password = $users->{$username}{'hashed_password'};
	
#	if($username eq 'admin' and $hashed_password->match($password)) {
	my $pbkdf2 = Crypt::PBKDF2->new;
	if($username eq 'admin' and $pbkdf2->validate($hashed_password, $password)) {
		my $session = Plack::Session->new($env);
		$session->set('username', 'admin');
		return Plack::Util::TRUE;
	}
	return Plack::Util::FALSE;
}

1;

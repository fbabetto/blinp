package UserPages;

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

use Hash::MultiValue;
use Data::Dumper;
use Template;

my $config = {
	INCLUDE_PATH => 'templates/',  # or list ref
	INTERPOLATE  => 1,               # expand "$var" in plain text
	POST_CHOMP   => 1,               # cleanup whitespace
	#OUTPUT_PATH => 'posts/',
	DEBUG => 1
};

my $template = Template->new($config);

sub change_password {
	my ($target_uri, $username, $params) = @_;
	# TODO informative message in case the new passwords don't match
	# TODO maybe clean post?
	print Dumper($params);
	# the username is taken from the session
	#my $username = $params;
	#print Dumper($target_uri);
	#Dumper($username);
	my $page;
	my $vars = {
					blogtitle => 'test',
					pagetype => 'change_password',
					target_url => $target_uri

			};
	if($params && exists $params->{"old_password"} && exists $params->{"new_password"} && exists $params->{"new_password_confirm"}
		&& $params->{"new_password"} eq $params->{"new_password_confirm"}) {
		my $success = Users::change_password($username, $params->{"old_password"}, $params->{"new_password"});
		if($success) {
			$vars->{pagetype} = 'change_password_successful';
		} else {
			$vars->{pagetype} = 'change_password_failed';
		}
	}
	$template->process('main.tt', $vars, \$page) || die $template->error(), "\n";
	return $page;
}

1;

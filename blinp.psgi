#!/usr/bin/env perl

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

use Pages;
use Data::Dumper;

use Plack::Request;
use Hash::MultiValue;
# http://search.cpan.org/~miyagawa/Hash-MultiValue-0.15/lib/Hash/MultiValue.pm

use Plack::Response;
use Plack::Builder;
use Plack::App::File;

use Users;# FIXME

my $app = sub {
	my $env = shift;
	my $session = $env->{'psgix.session'};
	
# 	print Dumper($env);
# 	print Dumper($session);
	
	given ($env->{PATH_INFO}) {
	
		return [ 200, [ 'Content-Type' => 'text/html' ], [ Pages::addPost() ] ]
			when '/posts/add';
			
		when('/posts/edit') {
			my $req = Plack::Request->new($env);
			my $query = $req->parameters;
			print Dumper($query);
			my $page = Pages::editPost( $query );
			print Dumper($page);
 			my $res = Plack::Response->new(200);
 			$res->content_type('text/html');
 			$res->body($page);
 			return $res->finalize;
		}
			
		return [ 200, [ 'Content-Type' => 'text/html' ], [ 'TODO' ] ]
			when '/posts/delete';
			
		when('/posts/process') {
			my $req = Plack::Request->new($env);
			my $query = $req->parameters;
# 			print Dumper($query);
			my $page_url = Pages::processPost( $query );
			my $res = Plack::Response->new(200);
			$res->content_type('text/html');
			$res->redirect("/posts/$page_url");
			return $res->finalize;
		}

		default {
			return [ 200, [ 'Content-Type' => 'text/html' ], [ 'Hello World' ]];
		}
	}
};

builder {
# http://iinteractive.github.io/OX/advent/2012-12-15.html
# 	enable 'Session';
	enable "Session::Cookie", secret=>'foobar';# FIXME secret

	enable_if {$_[0]->{REQUEST_URI} =~ /^\/posts\/(add|edit|delete|process)/ and !exists $_[0]->{'psgix.session'}{'username'}}
		"Auth::Basic", authenticator => sub {
		my($username, $password, $env) = @_;
		#return $username eq 'admin' && $password eq 'foobar';
		Dumper($username);
		if($username ne '') {
			return Users::authenticate( $username, $password, $env);
		}
	};
# 		"Auth::Digest", realm => "Secured", secret => "BlahBlah", authenticator => sub { $_[0] eq $_[1] };
# 		'Auth::Form', authenticator => sub {my $env = shift; $_[0] eq $_[1] };
# 	
# http://search.cpan.org/~miyagawa/Plack-1.0030/lib/Plack/Middleware/Static.pm
	enable "Plack::Middleware::Static",
		path => qr{^/posts/.+\.html},
		root => './';

	# https://github.com/plack/Plack/issues/93
	enable "Plack::Middleware::Static",
		path => sub { s!(^/posts/?)$!/index.html! },
		root => './posts';

	enable "Plack::Middleware::Static",
		path => qr{^/(img|js|css)/},
		root => './static/';

	$app;
};

# http://transfixedbutnotdead.com/2010/08/30/givenwhen-the-perl-switch-statement/

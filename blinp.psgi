#!/usr/bin/env perl

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just neede because this file is utf8)

use PostPages;
use Data::Dumper;

use Plack::Request;
use Hash::MultiValue;
# http://search.cpan.org/~miyagawa/Hash-MultiValue-0.15/lib/Hash/MultiValue.pm

use Plack::Response;
use Plack::Builder;
use Plack::App::File;
use Plack::App::URLMap;

use Users;# FIXME
use Requests;

# FIXME MAYBE TEMPLATE FOR DEFAULT STATUS 404 403 ECC.

my $blog_impl = sub {
	#my $env = shift;
	my($action, $arguments, $post) = @_;

	my %ROUTING = (
		"/"			=> \&home,
		"/add"		=> \&PostPages::add,
		"/edit"		=> \&PostPages::edit,
		"/delete"	=> \&PostPages::deleteConfirm,
		"/deleted"	=> \&PostPages::delete,
		"/process"	=> \&PostPages::process,
		
		"/changepassword" => \&UserPages::change_password,
	);
 	if($ROUTING{$action}) {
 		my $page = $ROUTING{$action}->($arguments, $post);
		my $res = Plack::Response->new(200);
		$res->content_type('text/html');
		$res->body($page);
		return $res->finalize;
 	} else {
		return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Page not found: admin page not found.' ]]; # FIXME
 	}

};

# the prefix here is stripped by plack: /posts/add -> /add
my $admin_blog = sub {
	my $env = shift;
	
	my $req = Plack::Request->new($env);
	my $uri = $req->path_info;
	my $function_regex = qr/\/[a-z]+/;
	my $argument_regex = qr/.*/;
	if ($uri =~ /(?<function>$function_regex)\/?(?<argument>$argument_regex)/) {
		my $function = $+{function};
 		my $argument = $+{argument};
 		my $params_in_posts = $req->parameters;
 		print Dumper($function);
		return $blog_impl->($function, $argument, $params_in_posts);
	}
	return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Page not found on admin blog' ]]; #
};


my $main = sub {
	# FIXME
	return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Page not found on /' ]]; #
};

my $posts = Plack::App::File->new(root => "./posts")->to_app;

builder {
	enable "Session::Cookie", secret=>'foobar';# FIXME secret

	my $prefix = "/blog";
	
	if(!($prefix =~ /\/[a-z]*/)) {
		die "Prefix should have a leading slash (\"/\").";
	}
	
	my $urlmap = Plack::App::URLMap->new;
	
	$urlmap->map("/" => $main);
	#$urlmap->map("/posts" => $blog);
	#$urlmap->map($prefix => $posts);
	#$urlmap->map($prefix => Plack::App::File->new(file => $prefix."/index.html"););
	$urlmap->map("$prefix" => builder {
		enable "Plack::Middleware::Static",
		path => sub { s!(^/?)$!/index.html! }, # for mapping /posts and /posts/ to /posts/index.html
		root => "./posts";
		$posts; # all other url different from /posts will be passed to the static file middleware
	});
	
	$urlmap->map($prefix."/admin" => builder {
		enable "Auth::Basic", authenticator => sub {
			my($username, $password, $env) = @_;
			Dumper($username);
			if($username ne '') {
				return Users::authenticate( $username, $password, $env);
			}
		};
		$admin_blog;
	});
	my $app = $urlmap->to_app;
};

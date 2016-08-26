#!/usr/bin/env perl

use 5.016; # implies "use strict;"
use warnings;
use autodie;
use utf8; # http://perldoc.perl.org/perluniintro.html (just needed because this file is utf8)

use PostPages;
use UserPages;
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
# FIXME reduce code duplication

my $post_admin_impl = sub {
	my($action, $arguments, $post) = @_;
	my %ROUTING = (
		"/"			=> \&home,
		"/add"		=> \&PostPages::add,
		"/edit"		=> \&PostPages::edit,
		"/delete"	=> \&PostPages::deleteConfirm,
		"/deleted"	=> \&PostPages::delete,
		"/process"	=> \&PostPages::process,
	);
 	if($ROUTING{$action}) {
 		my $page = $ROUTING{$action}->($arguments, $post);
		my $res = Plack::Response->new(200);
		$res->content_type('text/html');
		$res->body($page);
		return $res->finalize;
 	} else {
		return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Page not found: post admin page not found.' ]]; # FIXME
 	}
};

my $user_admin_impl = sub {
	my($action, $req_uri, $username, $params) = @_;
	my %ROUTING = (
		"/"			=> \&home,
		"/changepassword"		=> \&UserPages::change_password,
	);
 	if($ROUTING{$action}) {
 		my $page = $ROUTING{$action}->($req_uri, $username, $params);
		my $res = Plack::Response->new(200);
		$res->content_type('text/html');
		$res->body($page);
		return $res->finalize;
 	} else {
		return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Page not found: user admin page not found.' ]]; # FIXME
 	}
};

# Here we manage
# /blog/admin/user{/,change_password}
my $user_admin = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $uri = $req->path_info;
	my $req_uri = $req->request_uri;
	my $session = Plack::Session->new($env);
	my $username = $session->get('username');
	my $function_regex = qr/\/[a-z]+/;
	my $argument_regex = qr/.*/;
	if ($uri =~ /(?<function>$function_regex)\/?(?<argument>$argument_regex)/) {
		my $function = $+{function};
 		my $argument = $+{argument};
 		my $params_in_posts = $req->parameters;
		return $user_admin_impl->($function, $req_uri, $username, $params_in_posts);
	}
};

# Here we manage
# /blog/admin/post{/,/add,/edit,/delete,/deleted,/process}
my $post_admin = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $uri = $req->path_info;
	my $req_uri = $req->request_uri;
	my $function_regex = qr/\/[a-z]+/;
	my $argument_regex = qr/.*/;
	if ($uri =~ /(?<function>$function_regex)\/?(?<argument>$argument_regex)/) {
		my $function = $+{function};
 		my $argument = $+{argument};
 		my $params_in_posts = $req->parameters;
		return $post_admin_impl->($function, $argument, $params_in_posts);
	}
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
			#Dumper($username);
			if($username ne '') {
				return Users::authenticate( $username, $password, $env);
			}
		};
		mount "/user" => $user_admin;
		mount "/post" => $post_admin;
	});
	my $app = $urlmap->to_app;
};

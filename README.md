Blinp
=====

Blinp is a small and simple blog platform that generates static pages and it's written in perl.

This is in early development stage! Don't use it in production!

Dependencies
------------

* Plack;
* Template-Toolkit for the HTML templates;
* Template::Plugin::MultiMarkdown for posting blog's posts written in MultiMarkdown;
* Authen::Passphrase::BlowfishCrypt;

TODO
----
* ~~Authentication (using Plack::Middleware::Auth::Basic or Plack::Middleware::Auth::Digest)~~;
* ~~CSS, javascript, images folders fixes~~;
* tags management (view posts by tag, by date, etc.);
* a decent default theme;
* users management;
* improvements in the posting form:
	* preview using javascript;
	* tags autocompletion with AJAX;
* a function/page for rebuilding some or all the static pages.
* maybe use Plack::Middleware::Auth::Form instead of Plack::Middleware::Auth::Basic

# Blinp
Blinp is a small and simple blog platform written in perl that generates static pages.

This is in early development stage! Don't use it in production!

## Dependencies
* Plack;
* Plack::Session;
* Template-Toolkit for the HTML templates;
* Template::Plugin::MultiMarkdown for posting blog's posts written in MultiMarkdown;
* ~~Authen::Passphrase::BlowfishCrypt.~~
* Crypt::PBKDF2 for user authentication

## TODO
* ~~Authentication (using Plack::Middleware::Auth::Basic or Plack::Middleware::Auth::Digest)~~;
* ~~CSS, javascript, images folders fixes~~;
* tags management (view posts by tag, by date, etc.);
* pagination in posts' or tag's list;
* a decent default theme;
* users management;
* improvements in the posting form:
	* preview using javascript;
	* tags autocompletion with AJAX;
* a function/page for rebuilding some or all the static pages;
* ~~maybe use Plack::Middleware::Auth::Form instead of Plack::Middleware::Auth::Basic~~
* maybe use Plack::Middleware::Auth::Digest (same author of Plack);
* __maybe save posts' metadata in the same markdown file, so every post source is self contained and you shouldn't manage metadata separately, specially on deletion/undeletion.__
* rename posts sources from .markdown to .md
* CPAN stuff

## Roadmap
### 0.1
* Posts management (duh); ✔
* user authentication (only one user supported); ✔
* a page for changing user password and configuring displayed name;
* pagination of the main page (show the last X posts on the main page);
* a nice and basic default theme using HTML 5 and CSS 3;

### 0.2
* User management (multiple users) maybe?
* Tags management and "pages per tag" support;
* Support for posts snippets in main page instead of showing the entire post;
* __a configution file__


### 0.3
* An admin page with functions for rebuilding posts and other utilities;
* post preview while adding/editing;
* tags autocompletion;
* "posts per user" or "posts per date" or other special pages (maybe).

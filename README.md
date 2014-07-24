Blinp
=====

Blinp is a small and simple blog platform that generates static pages and it's written in perl.

This is in early development stage! Don't use it in production!

Dependencies:
------------

* Plack;
* Template-Toolkit for the HTML templates;
* Template::Plugin::MultiMarkdown for posting blog's posts written in MultiMarkdown.

TODO
----
* Authentication (using Plack::Middleware::Auth::Basic or Plack::Middleware::Auth::Digest);
* CSS, javascript, images folders fixes;
* tags management;
* a decent default theme;
* users management;
* post's preview using javascript.

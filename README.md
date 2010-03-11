Description
===========

CRToDo is a to-do managing application similar to [RememberTheMilk][1] but
restricted to basic features.

**CRToDo** consists of two parts:

1. The server is written in **Ruby** and offers a **REST**ful webservice.
2. The client is written in **JavaScript** and runs in the browser.

Features
========

* Managing multiple to-do lists
* Adding simple, one-line to-do entries
* Ordering to-do entries by drag-and-drop
* Finishing and deleting to-do entries by drag-and-drop
* History of finished to-do entries

Usage
=====

To use the service you can either go to
[http://todo.livoris.de/](http://todo.livoris.de/) or
install it on your own server.

Requirements
============

* Ruby 1.8.6 or newer
* RubyGems 1.3.5 or newer
* Sinatra 0.9.6
* Ruby JSON implementation 1.2.0
* RSpec 1.2.9 *for running the tests*
* RCov 0.9.7.1 *for test coverage*
* Reek 1.2.1 *for code style*
* fcgi 0.8.8 *for FastCGI*
* fcgiwrap 0.1.6 *for FastCGI*

Installation
============

The service is implemented with [Sinatra][2] and runs
either stand-alone or in a webserver with [FastCGI][3].

Stand-alone
-----------

To start the *CRToDo* server with the built-in webserver, start a terminal and
change to the directory where you downloaded *CRToDo* and type the following
command:

    $ rake run

As can be seen by the ouput of the command, the WEBrick webserver starts on
port 4567. The web interface can now be accessed by typing
[http://localhost:4567/](http://localhost:4567/) into the browser.

FastCGI
-------

In a production environment you typically have a webserver like
[Apache HTTP Server][4] or
[lighttpd][5].

To configure *FastCGI* in your webserver please refer to your
webserver's documentation. An example configuration for Apache might look like
below.

*httd.conf*:

    VirtualHost myhost:80
        ServerName todo.livoris.de
        DocumentRoot /.../crtodo
    /VirtualHost

*.htaccess*:

    RewriteEngine on
    AddHandler fastcgi-script .fcgi
    Options +FollowSymLinks +ExecCGI
    RewriteRule ^(.*)$ dispatch.fcgi [QSA,L]

Acknowledgement
===============

Apart from all the other components, this project is notably inspired by the
simplicity and power of [Sinatra][2] and [jQuery][6]. The icons were provided
under the [Creative Commons Attribution License][7] by the [Axialis Team][8].

[1]: http://www.rememberthemilk.com/
[2]: http://www.sinatrarb.com/
[3]: http://www.fastcgi.com/
[4]: http://httpd.apache.org/
[5]: http://www.lighttpd.net/
[6]: http://jquery.com/
[7]: http://creativecommons.org/licenses/by/2.5/
[8]: http://axialis.com/

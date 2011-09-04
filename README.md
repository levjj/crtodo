Description
===========

CRToDo is a to-do managing application similar to [RememberTheMilk][1] but
restricted to basic features.

**CRToDo** consists of two parts:

1. The server is written in **Ruby** and offers a **REST**ful webservice.
2. The client is written in **JavaScript** and runs in the browser.

Features
========

* Multiuser login by using OpenID
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
* Redis 2.2.2
* Ruby-OpenID 2.1.8
* RSpec 2.3.0 *for running the tests*
* Rake 0.8.7 *for running the tests*
* RCov 0.9.7.1 *for test coverage*
* Reek 1.2.1 *for code style*
* fcgi 0.8.8 *for FastCGI*
* fcgiwrap 0.1.6 *for FastCGI*
* thin 1.2.11 for *thin*

Installation
============

The service is implemented with [Sinatra][2] and runs
either stand-alone, in a webserver with [FastCGI][3] or with the help of [thin][9].
The data backend is a [redis][10] database.

Redis
-----

Install a redis database so that it is accessible from the CRToDo application.
Then configure the CRToDo application by copying the example.config.yml to
config.yml and making appropiate adjustments to the config. It is not
recommended to use the same database number for other applications since
it might cause conflicts.

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

Due to a Bug in the FCGI wrapper, the return_to request for OpenID does not
exactly match the original request. When you get the error message

    Sorry, we could not authenticate you. return_to_path does not match

the easiest way to fix it, is by replacing line 197 in the file /usr/lib/ruby/gems/1.8/gems/ruby-openid-2.1.8/lib/openid/consumer/idres.rb

    [:scheme, :host, :port, :path].each do |meth|

with:

    [:scheme, :host, :port].each do |meth|

Thin
----

Write a thin.yml file for configuring *thin*:

    ---
        environment: production
        chdir: /path/to/crtodo/
        address: 127.0.0.1
        port: 4567
        pid: /.../thin.pid
        rackup: /path/to/crtodo/config.ru
        log: /.../thin.log
        max_conns: 64
        timeout: 30
        max_persistent_conns: 32
        daemonize: true

Start it either by

    $ thin -C thin.yml -R config.ru start
    
or by putting the thin.yml file in the /etc/thin directory if thin is
configured as a service.

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
[9]: http://code.macournoyer.com/thin/
[10]: http://redis.io/

#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

fastcgi_log = File.open("/srv/fastcgi/todo.log", "a")
STDOUT.reopen fastcgi_log
STDERR.reopen fastcgi_log
STDOUT.sync = true

ENV['RACK_ENV'] = "production"
module Rack
	class Request
		def path_info
			@env["REDIRECT_URL"].to_s
		end
		def path_info=(s)
			@env["REDIRECT_URL"] = s.to_s
		end
	end
end

$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
load 'crtodo_app.rb'

builder = Rack::Builder.new do
	map '/' do
		run CRToDo::Application.new
	end
end

Rack::Handler::FastCGI.run(builder)

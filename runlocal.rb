#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
load 'crtodo_app.rb'

builder = Rack::Builder.new do
  map '/' do
    run CRToDo::Application.new
  end
end

Rack::Handler::WEBrick.run(builder, {:Port => 4567})


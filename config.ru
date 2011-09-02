require 'rubygems'

ENV['RACK_ENV'] = "production"

$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
load 'crtodo_app.rb'
 
run CRToDo::Application.new


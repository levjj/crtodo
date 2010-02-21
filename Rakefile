#!/usr/bin/env rake

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'spec/rake/spectask'

PROJECT_NAME = 'CRToDo'

SRC_FILES = FileList.new('lib/*.rb')
TEST_FILES = FileList.new('spec/*_spec.rb')

desc "Runs CRToDo server with built-in webserver"
task :run do |t|
	ARGV.shift()
	exec "ruby -Ilib runlocal.rb #{ARGV.join(' ')}"
end

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |spec|
	spec.spec_files = TEST_FILES
	spec.rcov = false
	spec.ruby_opts = ["-Ilib"]
	spec.spec_opts = ["--format", "specdoc", "--color", "--backtrace"]
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec_rcov') do |spec|
	spec.spec_files = TEST_FILES
	spec.rcov = true
	spec.ruby_opts = ["-Ilib"]
	spec.rcov_opts = ["--no-html", "--no-rcovrt", "--gcc", "--exclude", TEST_FILES]
	spec.spec_opts = ["--format", "specdoc", "--color", "--backtrace"]
end

desc "Performs a static check of the CRToDo code"
task :check do |check|
	exec "reek -q #{TEST_FILES} #{SRC_FILES}"
	exec "ruby -c -w #{SRC_FILES}}"
end

Rake::RDocTask.new('doc') do |rdoc|
	rdoc.name = :doc
	rdoc.title = "CRToDo"
	rdoc.main = 'README.markdown'
	rdoc.rdoc_dir = 'doc'
	rdoc.rdoc_files.include #{lib/*.rb README.markdown}
	rdoc.options += [
		'-SHN',
		'-A', 'property=Property',
		"--opname=index.html",
		"--line-numbers",
	]
end

task :default => :run

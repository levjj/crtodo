#!/usr/bin/env rake

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rspec'
require 'rspec/core/rake_task'

PROJECT_NAME = 'CRToDo'

SRC_FILES = FileList.new('lib/*.rb')
TEST_FILES = FileList.new('spec/*_spec.rb')

desc "Runs CRToDo server with built-in webserver"
task :run do |t|
	ARGV.shift()
	exec "ruby -Ilib runlocal.rb #{ARGV.join(' ')}"
end

desc "Run all examples"
RSpec::Core::RakeTask.new(:rspec) do |rspec|
	rspec.pattern = TEST_FILES
	rspec.rcov = false
	rspec.ruby_opts = ["-Ilib"]
	rspec.rspec_opts = ["--format", "documentation", "--color", "--backtrace"]
end

desc "Run all examples with RCov"
RSpec::Core::RakeTask.new(:rcov) do |rspec|
	rspec.pattern = TEST_FILES
	rspec.rcov = true
	rspec.ruby_opts = ["-Ilib"]
	rspec.rcov_opts = ["--no-html", "--no-rcovrt", "--gcc", "--exclude", TEST_FILES]
	rspec.rspec_opts = ["--format", "documentation", "--color", "--backtrace"]
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


require 'rubygems'
require 'sinatra'
require 'erb'

class CRToDoApp < Sinatra::Application

before do
  @entries = Backup.backups.map { |b| b.name }
end

get '/' do
  erb :index
end

get '/:name/log' do
  @backup = Backup.find(params[:name])
  erb :log
end

post '/:name' do
  @backup = Backup.find(params[:name])
  @backup.backup
  erb :view
end

get '/:name' do
  @backup = Backup.find(params[:name])
  erb :view
end
end

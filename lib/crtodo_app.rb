require 'rubygems'
require 'sinatra'
require 'erb'
require 'crtodo'

module CRToDo
	class Application < Sinatra::Application
		before do
			@model = CRToDo::ToDoDB.new
			@listnames = @model.lists.keys
		end

		get '/' do
			erb :index
		end

		get '/api/' do
			@model.to_json
		end

		post '/api/' do
			@model.add_list params[:list]
		end

		get '/api/:name' do
			@model.lists[params[:name]].to_json
		end

		post '/api/:name' do
			list = @model.lists[params[:name]]
			if params.key? :pos then
				list.add_todo(params[:todo], params[:pos])
			else
				list.add_todo params[:todo]
			end
		end

		put '/api/:name' do
			if params.key? :newname then
				@model.rename_list(params[:name], params[:newname])
			else
				@model.lists[params[:name]].finish
			end
		end

		delete '/api/:name' do
			@model.delete_list params[:name]
		end

		get '/api/:name/:todo' do
			@model.lists[params[:name]].entries[params[:todo]].to_json
		end

		put '/api/:name/:todo' do
			@model.lists[params[:name]].entries[params[:todo]].finish
		end

		delete '/api/:name/:todo' do
			@model.lists[params[:name]].delete_at params[:todo]
		end
	end
end

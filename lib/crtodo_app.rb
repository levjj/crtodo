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

		get '/api/:name' do |name|
			@model.lists[name].to_json
		end

		post '/api/:name' do |name|
			list = @model.lists[name]
			if params.key? :pos then
				list.add_todo(params[:todo], params[:pos])
			else
				list.add_todo params[:todo]
			end
		end

		put '/api/:name' do |name|
			if params.key? "newname" then
				@model.rename_list(name, params["newname"])
			else
				@model.lists[name].finish
			end
		end

		delete '/api/:name' do |name|
			@model.delete_list name
		end

		get '/api/:name/:todo' do |name, todo|
			@model.lists[name].entries[todo.to_i].to_json
		end

		put '/api/:name/:todo' do |name, todo|
			if params.key? "newindex" then
				@model.lists[name].
					move_todo(todo.to_i, params["newindex"].to_i)
			else
				@model.lists[name].entries[todo.to_i].finish
			end
		end

		delete '/api/:name/:todo' do |name, todo|
			@model.lists[name].delete_at(todo.to_i)
		end
	end
end

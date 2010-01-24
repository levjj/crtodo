require 'rubygems'
require 'sinatra'
require 'erb'
require 'crtodo'

module CRToDo
	class Application < Sinatra::Application
		before do
			@model = ToDoDB.new
			@listnames = @model.lists.keys
		end

		get '/www' do
			erb :index
		end

		get '/' do
			@model.to_json
		end

		post '/' do
			@model.add_list params[:list]
		end

		get '/:name' do
			@model.lists[params[:name]].to_json
		end

		post '/:name' do
			list = @model.lists[params[:name]]
			if params.key? :pos then
				list.add_todo(params[:todo], params[:pos])
			else
				list.add_todo params[:todo]
			end
		end

		put '/:name' do
			@model.lists[params[:name]].finish
		end

		delete '/:name' do
			@model.delete_list params[:name]
		end

		get '/:name/:todo' do
			@model.lists[params[:name]].entries[params[:todo]].to_json
		end

		put '/:name/:todo' do
			@model.lists[params[:name]].entries[params[:todo]].finish
		end

		delete '/:name/:todo' do
			@model.lists[params[:name]].delete_at params[:todo]
		end
	end
end

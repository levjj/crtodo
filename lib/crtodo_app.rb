require 'rubygems'
require 'sinatra'
require 'erb'
require 'openid'
require 'openid/store/memory'
require 'openid/extensions/ax'
require 'crtodo'

PROVIDERS = {"google" => "https://www.google.com/accounts/o8/id",
            "yahoo" => "http://www.yahoo.com/"}

EMAIL_URI = "http://axschema.org/contact/email"

module CRToDo
	class Application < Sinatra::Application
		def initialize
			super
			@model = CRToDo::ToDoDB.new
		end

		def openid_consumer
			@openid_consumer ||= OpenID::Consumer.new(session,
				OpenID::Store::Memory.new)
		end

		def root_url
			request.url.match(/(^.*\/{2}[^\/]*)/)[1]
		end

		error do
			@error = env['sinatra.error'].message
			erb :error
		end

		enable :sessions

		get '/login' do
			erb :login
		end

		post '/login' do
			provider = PROVIDERS[params[:provider]]
			raise "Invalid Service" if provider.nil?
			begin
				req = openid_consumer.begin provider
				ax = OpenID::AX::FetchRequest.new
				ax.add OpenID::AX::AttrInfo.new(
					"http://axschema.org/contact/email", nil, true)
				req.add_extension(ax)
			rescue OpenID::DiscoveryFailure => why
				raise "Sorry, we couldn't find your identifier '#{provider}'"
			else
				redirect req.redirect_url(root_url,
				                           root_url + "/login/complete")
			end
		end

		get '/login/complete' do
			res = openid_consumer.complete(params, request.url)
			case res.status
				when OpenID::Consumer::FAILURE
					raise "Sorry, we could not authenticate you."
				when OpenID::Consumer::SETUP_NEEDED
					raise "Immediate request failed - Setup Needed"
				when OpenID::Consumer::CANCEL
					raise "Login cancelled."
				when OpenID::Consumer::SUCCESS
					ax = OpenID::AX::FetchResponse.from_success_response res
					if ax.data[EMAIL_URI].nil? || ax.data[EMAIL_URI].empty?
						raise "Email address couldn't be obtained"
					end
					session[:user] = ax.data[EMAIL_URI][0]
					redirect '/'
			end
		end

		def logged_in?
			!session[:user].nil?
		end

		get '/logout' do
			session[:user] = nil
			redirect '/login'
		end

		before do
			@listnames = @model.lists.keys
		end

		get '/*' do
			if logged_in? then
				pass
			else
				redirect '/login'
			end
		end

		get '/' do
			@username = session[:user]
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
				@model.lists[name].move_todo(todo.to_i,
				                             params["newindex"].to_i)
			else
				entry = @model.lists[name].entries[todo.to_i]
				entry.done? ? entry.reopen : entry.finish
			end
		end

		delete '/api/:name/:todo' do |name, todo|
			@model.lists[name].delete_at(todo.to_i)
		end
	end
end

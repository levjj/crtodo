require 'rubygems'
require 'sinatra'
require 'erb'
require 'yaml'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/ax'
require 'crtodo'

PROVIDERS = {"google" => "https://www.google.com/accounts/o8/id",
            "yahoo" => "http://www.yahoo.com/"}

EMAIL_URI = "http://axschema.org/contact/email"
CONFIGFILENAME = "config.yml"
LIBDIR = File.dirname(File.expand_path(__FILE__))
CONFIGFILE = File.join(LIBDIR, "..", CONFIGFILENAME)
OPENIDDIR =  File.join(LIBDIR, "..", "openid")

module CRToDo
	class Application < Sinatra::Application
		def initialize
			super
			if !File.exists?(CONFIGFILE) then
				@configerror = "Required #{CONFIGFILENAME} does not exists"
			else
				cnf = YAML.load_file CONFIGFILE
				if !cnf["redis"] || !cnf["redis"]["host"] || !cnf["redis"]["port"] ||
					!cnf["redis"]["db"] then
					@configerror = '<pre>#{CONFIGFILENAME}</pre> malformed.'
				else
					rcnf = cnf["redis"]
					begin
						@redis = Redis.new :host => rcnf["host"],
						                   :port => rcnf["port"],
						                   :db => rcnf["db"]
						@store = OpenID::Store::Filesystem.new(OPENIDDIR)
					rescue Exception => e
						@configerror = e.to_s
					end
				end
			end
		end

		def openid_consumer
			@openid_consumer ||= OpenID::Consumer.new(session, @store)
		end

		def root_url
			request.url.match(/(^.*\/{2}[^\/]*)/)[1]
		end
		
		def userblock
			if @error then
				''
			elsif session[:user] then
				ERB::Util.h(session[:user]) + ', <a href="/logout">Sign out</a>'
			else
				'Not logged in'
			end
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
				                           root_url + "/logincomplete")
			end
		end

		get '/logincomplete' do
			res = openid_consumer.complete(params, request.url)
			case res.status
				when OpenID::Consumer::FAILURE
					raise "Sorry, we could not authenticate you.\n" + res.message
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

		get '/*' do
			if logged_in? then
				pass
			else
				redirect '/login'
			end
		end
		
		before do
			if @configerror then
				@error = @configerror.to_s
				halt erb :error
			else
				if logged_in? then
					@db = CRToDo::ToDoDB.new @redis
					@model = @db.get_user session[:user]
					@listnames = @model.lists.keys
				end
			end
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

		get '/api/:name/open' do |name|
			@model.lists[name].open_entries.to_json
		end

		get '/api/:name/done' do |name|
			@model.lists[name].done_entries.to_json
		end

		post '/api/:name/open' do |name|
			list = @model.lists[name]
			if params.key? :pos then
				list.add_todo(params[:todo], params[:pos])
			else
				list.add_todo params[:todo]
			end
		end

		put '/api/:name' do |name|
			@model.rename_list(name, params["newname"])
		end

		delete '/api/:name' do |name|
			@model.delete_list name
		end

		put '/api/:name/open/:todo' do |name, todo|
			if params.key? "newindex" then
				@model.lists[name].move_todo(todo.to_i,
				                             params["newindex"].to_i)
			else
				@model.lists[name].finish todo.to_i
			end
		end

		put '/api/:name/done/:todo' do |name, todo|
			entry = @model.lists[name].reopen todo.to_i
		end

		delete '/api/:name/open/:todo' do |name, todo|
			@model.lists[name].delete_todo_at(todo.to_i)
		end
	end
end


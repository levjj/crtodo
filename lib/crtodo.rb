require 'json'
require 'redis'

THISDIR = File.expand_path(File.dirname(__FILE__))

module CRToDo

	NEW_LIST_NAME = "New list"
	
	LASTID_SUFFIX = "_lastid"
	NAME_SUFFIX = "_name"
	OPEN_SUFFIX = "_open"
	DONE_SUFFIX = "_done"
	LISTS_SUFFIX = "_lists"
	USERS_KEY = "users"
	
	def self.next_id(redis, scheme)
		scheme + "_" + redis.incr(scheme + LASTID_SUFFIX).to_s
	end
	
	def self.del_idcounters(redis)
		redis.del "todolist" + LASTID_SUFFIX
		redis.del "user" + LASTID_SUFFIX
	end
	
	class ToDoList
		attr_reader :id, :name, :open_entries, :done_entries

		def initialize(redis, id, new = false)
			@redis = redis
			@id = id
			if new then create id else load end
		end
		
		def create(name)
			@id = CRToDo::next_id(@redis, "todolist")
			self.name = name
			@open_entries = []
			@done_entries = []
			save
		end
		
		def load
			@name = @redis[@id + NAME_SUFFIX]
			@open_entries = JSON.parse(@redis[@id + OPEN_SUFFIX])
			@done_entries = JSON.parse(@redis[@id + DONE_SUFFIX])
		end
		
		def save
			@redis[@id + NAME_SUFFIX] = @name
			@redis[@id + OPEN_SUFFIX] = @open_entries.to_json
			@redis[@id + DONE_SUFFIX] = @done_entries.to_json
		end
		
		def name=(newname)
			@redis[@id + NAME_SUFFIX] = @name = newname
		end
		
		def add_todo(name, position = nil)
			position ||= @open_entries.size
			@open_entries.insert(position, name)
			@redis[@id + OPEN_SUFFIX] = @open_entries.to_json
			return position
		end

		def move_todo(from_index, to_index)
			todo = @open_entries[from_index]
			return if todo.nil?
			@open_entries.delete_at from_index
			@open_entries.insert(to_index, todo)
			@redis[@id + OPEN_SUFFIX] = @open_entries.to_json
			return to_index
		end

		def finish(pos)
			todo = @open_entries[pos]
			return if todo.nil?
			@open_entries.delete_at pos
			@done_entries << todo
			save
			return @done_entries.size - 1
		end

		def delete_todo_at(index)
			@open_entries.delete_at index
			@redis[@id + OPEN_SUFFIX] = @open_entries.to_json
			return index
		end

		def delete
			@redis.del @id + NAME_SUFFIX
			@redis.del @id + OPEN_SUFFIX
			@redis.del @id + DONE_SUFFIX
		end
		
		def entries
			@open_entries + @done_entries
		end

		def done?
			@open_entries.empty?
		end

		def to_json(*a)
			{:open => @open_entries, :done => @done_entries}.to_json
		end
	end

	class ToDoUser
		attr_reader :id, :lists, :name

		def initialize(redis, id, new = false)
			@redis = redis
			@id = id
			@lists = {}
			if new then create id else load end
		end
		
		def create(name)
			@id = CRToDo::next_id(@redis, "user")
			self.name = name
		end
		
		def load
			@name = @redis[@id + NAME_SUFFIX]
			@redis.hvals(@id + LISTS_SUFFIX).each do |list_id|
			  list = ToDoList.new @redis, list_id, false
				@lists[list.name] = list
			end
		end
		
		def name=(newname)
			@redis[@id + NAME_SUFFIX] = @name = newname
		end

		def self.safe_name?(name)
			return name.length > 0 &&
			       name.length < 255 &&
			       !name.include?('/') &&
			       !name.include?('\0')
		end

		def add_list(name)
			return nil unless ToDoUser.safe_name? name
			list = ToDoList.new @redis, name, true
			@lists[list.name] = list
			@redis.hset @id + LISTS_SUFFIX, list.name, list.id
			return name
		end

		def delete_list(name)
			@lists[name].delete
			@lists.delete(name)
			@redis.hdel @id + LISTS_SUFFIX, name
			return name
		end

		def rename_list(oldname, newname)
			return nil unless ToDoUser.safe_name? newname
			list = @lists.delete(oldname)
			list.name = newname
			@lists[newname] = list
			@redis.hdel @id + LISTS_SUFFIX, oldname
			@redis.hset @id + LISTS_SUFFIX, newname, list.id
			return newname
		end

		def to_json(*a)
			@lists.keys.sort.to_json(*a)
		end

		def delete
			@lists.values.each {|l| l.delete}
			@redis.del @id + NAME_SUFFIX
			@redis.del @id + LISTS_SUFFIX
		end
	end

	class ToDoDB
		attr_reader :users, :redis

		def initialize(host, port, db)
			@redis = Redis.new :host => host, :port => port, :db => db
			@users = {}
			@redis.hvals(USERS_KEY).each do |userid|
				user = ToDoUser.new(@redis, userid)
				@users[user.name] = user
			end
			if File.directory? File.join(THISDIR, "..", "data") then
				import_old_data
			end
		end
		
		def import_old_data
			Dir.new(File.join(THISDIR, "..", "data")).each do |userdir|
				if userdir =~ /^[^\.]/ then
					user = get_user(userdir)
					Dir.new(File.join(THISDIR, "..", "data", userdir)).each do |listfile|
						if listfile  =~ /^[^\.].*\.json$/ && !user.lists.key?(listfile) then
							list = user.lists[user.add_list listfile]
							listfilename = File.join(THISDIR, "..", "data", userdir, listfile)
							json = JSON.parse(IO.read(listfilename))
							(json["done"] | json["open"]).each {|t| list.add_todo(t["name"])}
							json["done"].each { |t| list.finish 0 }
						end
					end
				end
			end
		end

		def get_user(username)
			unless @users.key? username
				add_user username
			end
			return @users[username]
		end

		def add_user(username)
			return nil unless ToDoUser.safe_name? username
			@users[username] = ToDoUser.new(@redis, username, true)
			@redis.hset USERS_KEY, username, @users[username].id
			return username
		end

		def delete_user(username)
			@users[username].delete
			@users.delete(username)
			@redis.hdel USERS_KEY, username
			return username
		end
		
		def delete
			@users.values.each {|u| u.delete}
			@redis.del USERS_KEY
		end
	end
end


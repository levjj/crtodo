require 'pathname'
require 'json'
require 'fileutils'

module CRToDo
	class ToDo
		attr_reader :name

		def initialize(name)
			super()
			@name = name
			@done = false
		end

		def self.from_hash(hash)
			self.new hash["name"]
		end

		def self.from_json(json)
			self.from_hash JSON.parse(json)
		end

		def to_json(*a)
			{ :name => self.name }.to_json(*a)
		end
	end

	class ToDoList
		attr_reader :path

		def initialize(path)
			super()
			@open_entries = []
			@done_entries = []
			@loaded = false
			self.path = path
		end

		def name
			@path.basename.to_s.chomp ".json"
		end

		def loaded?
			@loaded
		end

		def path=(path)
			@path = path
			self.save_list unless @path.exist?
		end

		def ensure_loaded
			if !@loaded then
				load_list
			end
		end

		def read_op(&block)
			ensure_loaded
			yield
		end

		def write_op(&block)
			ensure_loaded
			yield
			save_list
		end

		def add_todo(name, position = nil)
			write_op do
				position ||= @open_entries.size
				@open_entries.insert(position, ToDo.new(name))
			end
			return position
		end

		def move_todo(from_index, to_index)
			write_op do
				todo = @open_entries[from_index]
				return if todo.nil?
				@open_entries.delete_at from_index
				@open_entries.insert(to_index, todo)
			end
			return to_index
		end

		def finish(pos)
			write_op do
				todo = @open_entries[pos]
				return if todo.nil?
				@open_entries.delete_at pos
				@done_entries << todo
			end
			return pos
		end

		def reopen(pos)
			write_op do
				todo = @done_entries[pos]
				return if todo.nil?
				@done_entries.delete_at pos
				@open_entries << todo
			end
			return pos
		end

		def delete
			@path.delete
		end

		def delete_at(index)
			write_op do
				@open_entries.delete_at index
			end
			return index
		end

		def open_entries
			read_op do
				@open_entries
			end
		end

		def done_entries
			read_op do
				@done_entries
			end
		end

		def entries
			read_op do
				@open_entries + @done_entries
			end
		end

		def done?
			read_op do
				@open_entries.empty?
			end
		end

		def load_list
			@open_entries = []
			@done_entries = []
			json = JSON.parse @path.read
			json["open"].each do |todo|
				@open_entries << ToDo.from_hash(todo)
			end
			json["done"].each do |todo|
				@done_entries << ToDo.from_hash(todo)
			end
			@loaded = true
		end

		def save_list
			@path.open('w') {|f| f.write self.to_json}
		end

		def to_json(*a)
			{:open => @open_entries, :done => @done_entries}.to_json
		end
	end

	class ToDoUser
		attr_reader :lists

		def initialize(path)
			@lists = {}
			self.path = path
		end

		def name
			@path.basename.to_s
		end

		def path=(newpath)
			@path = newpath
			@path.mkdir unless @path.exist?
			load_lists
		end

		def add_list(name)
			list = ToDoList.new @path + (name + ".json")
			@lists[list.name] = list
			return name
		end

		def delete_list(name)
			@lists[name].delete
			@lists.delete(name)
			return name
		end

		def rename_list(oldname, newname)
			list = @lists[oldname]
			@lists.delete(oldname)
			newpath = @path + (newname + ".json")
			FileUtils::mv(list.path, newpath)
			list.path = newpath
			@lists[newname] = list
			return newname
		end

		def load_lists
			@path.children(false).each do |listpath|
				if listpath.extname == ".json" then
					list = ToDoList.new @path + listpath.basename.to_s
					@lists[list.name] = list
				end
			end
		end

		def to_json(*a)
			@lists.keys.sort.to_json(*a)
		end

		def delete
			@path.delete
		end
	end

	class ToDoDB
		attr_reader :users

		def initialize(path = nil)
			path ||= File.join(File.dirname(__FILE__), "..", "data")
			@path = Pathname.new(path)
			@path.mkdir unless @path.exist?
			@users = {}
			load_users
		end

		def get_user(username)
			unless @users.key? username
				add_user username
			end
			return @users[username]
		end

		def add_user(username)
			user = ToDoUser.new @path + username
			@users[username] = user
			return username
		end

		def delete_user(username)
			@users[username].delete
			@users.delete(username)
			return username
		end

		def load_users
			@path.children(true).each do |userpath|
				if userpath.directory? then
					add_user userpath.basename.to_s
				end
			end
		end
	end
end

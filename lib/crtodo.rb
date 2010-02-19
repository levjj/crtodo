require 'pathname'
require 'csv'
require 'json'
require 'fileutils'

module CRToDo
	class ToDo
		attr_reader :name
		attr_accessor :list

		def initialize(name)
			super()
			@name = name
			@done = false
		end

		def finish
			@done = true
			if (!@list.nil?) then
				@list.save_list
			end
			@name
		end

		def reopen
			@done = false
			if (!@list.nil?) then
				@list.save_list
			end
			@name
		end

		def done?
			@done
		end

		def self.from_array(array)
			todo = self.new array[1]
			if (array[0].to_s == "1") then
				todo.finish
			end
			return todo
		end

		def to_array
			[@done ? 1 : 0, @name]
		end

		def to_json(*a)
			{ :name => self.name, :done => @done}.to_json(*a)
		end
	end

	class ToDoList
		attr_reader :name

		def initialize(name)
			super()
			@name = name
			@entries = []
			@loaded = false
		end

		def name=(newname)
			write_op do
				@name = newname
				if !@path.nil? then
					newpath = Pathname.new(@path).parent + (@name + ".csv")
					FileUtils::mv(@path, newpath)
					@path = newpath
				end
			end
		end

		def loaded?
			@loaded
		end

		def path=(path)
			@path = path
			File.open(@path, 'w') {} unless File.exist? @path
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
				position ||= @entries.size
				todo = ToDo.new(name)
				todo.list = self
				@entries.insert(position, todo)
			end
			return position
		end

		def move_todo(from_index, to_index)
			write_op do
				todo = @entries[from_index]
				return if todo.nil?
				@entries.delete_at from_index
				@entries.insert(to_index, todo)
			end
			return to_index
		end

		def delete
			File.delete @path
		end

		def delete_at(index)
			write_op do
				@entries.delete_at index
			end
			return index
		end

		def entries
			ensure_loaded
			return @entries
		end

		def done?
			read_op do
				@entries.all? {|entry| entry.done?}
			end
		end

		def load_list
			CSV.foreach @path do |row|
				todo = ToDo.from_array(row)
				todo.list = self
				@entries << todo
			end
			@loaded = true
		end

		def save_list
			CSV.open(@path, 'w') do |writer|
				@entries.each do |entry|
					writer << entry.to_array
				end
			end
		end

		def to_json(*a)
			entries.to_json(*a)
		end
	end


	class ToDoUser
		attr_reader :lists
		attr_reader :name

		def initialize(name)
			@name = name
			@lists = {}
		end

		def path=(newpath)
			@path = newpath
			@path.mkdir unless @path.exist?
			load_lists
		end

		def add_list(name)
			list = ToDoList.new(name)
			list.path = (@path + (name + ".csv")).to_s
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
			list.name = newname
			@lists[newname] = list
			return newname
		end

		def load_lists
			@path.children(false).each do |listpath|
				if listpath.file? && listpath.extname == ".csv" then
					list = ToDoList.new(listpath.basename.to_s.chomp(".csv"))
					list.path = (@path + listpath.to_s).to_s
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
			user = ToDoUser.new(username)
			user.path = @path + username
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

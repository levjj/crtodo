require 'rubygems'
require 'json'
require 'crtodo'

TESTUSER = "user@example.com"

LIST1    = "Test List"
LIST2    = "Second List"

TODO1    = "Go shopping"
TODO2    = "Clean the car"
TODO3    = "Making homework"

TODO2_JSON = '{"name":"%s"}' % TODO2

EMPTY_JSON = '{"done":[],"open":[]}'

describe CRToDo::ToDoList do
	before(:each) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		@redis.flushdb
		@todolist = CRToDo::ToDoList.new @redis, LIST1, true
	end

	after(:each) do
		@todolist.delete
		CRToDo::del_idcounters(@redis)
		@redis.dbsize.should == 0
	end

	it "stores the name" do
		@todolist.name.should == LIST1
		@redis.dbsize.should == 4
	end

	it "has no entries after creation" do
		@todolist.entries.empty?.should == true
		@todolist.open_entries.empty?.should == true
		@todolist.done_entries.empty?.should == true
		@todolist.to_json.should ==  EMPTY_JSON
	end

	it "stores newly added todo entries" do
		pos = @todolist.add_todo TODO1
		pos.should == 0
		@todolist.done?.should == false
		@todolist.entries.empty?.should == false
		@todolist.open_entries.empty?.should == false
		@todolist.done_entries.empty?.should == true
		@todolist.entries[0].should == TODO1
		json = JSON.parse @todolist.to_json
		json["open"].size.should == 1
		json["done"].empty?.should == true
		json["open"][0] == TODO1
	end

	it "supports the insertion of todo entries" do
		@todolist.add_todo TODO1
		@todolist.add_todo TODO3
		@todolist.entries.size.should == 2
		@todolist.entries[0].should == TODO1
		@todolist.entries[1].should == TODO3
		pos = @todolist.add_todo(TODO2, 1)
		pos.should == 1
		@todolist.entries.size.should == 3
		@todolist.entries[0].should == TODO1
		@todolist.entries[1].should == TODO2
		@todolist.entries[2].should == TODO3
		json = JSON.parse @todolist.to_json
		json["open"].size.should == 3
		json["done"].empty?.should == true
		json["open"][0] == TODO1
		json["open"][1] == TODO2
		json["open"][2] == TODO3
	end

	it "supports moving todo entries" do
		@todolist.add_todo TODO1
		@todolist.add_todo TODO2
		@todolist.entries.size.should == 2
		@todolist.entries[0].should == TODO1
		@todolist.entries[1].should == TODO2
		json = JSON.parse @todolist.to_json
		json["open"].size.should == 2
		json["done"].empty?.should == true
		json["open"][0] == TODO1
		json["open"][1] == TODO2
		@todolist.move_todo(1, 0)
		@todolist.entries.size.should == 2
		@todolist.entries[0].should == TODO2
		@todolist.entries[1].should == TODO1
		json = JSON.parse @todolist.to_json
		json["open"].size.should == 2
		json["done"].empty?.should == true
		json["open"][0] == TODO2
		json["open"][1] == TODO1
	end

	it "should ignore bad move operations" do
		@todolist.move_todo(1, 0)
		@todolist.entries.empty?.should == true
		@todolist.to_json.should == EMPTY_JSON
	end

	it "supports the deletion of todo entries" do
		@todolist.add_todo TODO1
		@todolist.delete_todo_at 0
		@todolist.done?.should == true
		@todolist.entries.empty?.should == true
		@todolist.to_json.should == EMPTY_JSON
	end

	it "is done after finishing all entries" do
		@todolist.add_todo TODO1
		@todolist.finish 0
		@todolist.done?.should == true
		json = JSON.parse @todolist.to_json
		json["open"].empty?.should == true
		json["done"].size.should == 1
		json["done"][0] == TODO1
	end

	it "serializes to JSON" do
		@todolist.open_entries.to_json.should ==  '[]'
		@todolist.done_entries.to_json.should ==  '[]'
		@todolist.add_todo TODO1
		json = JSON.parse @todolist.open_entries.to_json
		json.size.should == 1
		json[0].should == TODO1
		json = JSON.parse @todolist.done_entries.to_json
		json.empty?.should == true
	end

	it "serializes multiple entries in the order of insertion to JSON" do
		@todolist.add_todo TODO3
		@todolist.add_todo TODO1
		@todolist.add_todo TODO2
		json = JSON.parse @todolist.open_entries.to_json
		json.size.should == 3
		json[0].should == TODO3
		json[1].should == TODO1
		json[2].should == TODO2
	end
end

describe CRToDo::ToDoUser do
	before(:each) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		@redis.flushdb
		@todouser = CRToDo::ToDoUser.new @redis, TESTUSER, true
	end

	after(:each) do
		@todouser.delete
		CRToDo::del_idcounters(@redis)
		@redis.dbsize.should == 0
	end

	it "has no lists after creation" do
		@todouser.lists.empty?.should == true
		@redis.dbsize.should == 2
	end

	it "stores newly created empty todo lists" do
		name = @todouser.add_list LIST1
		name.should == LIST1
		@todouser.lists.size.should == 1
		list = @todouser.lists[LIST1]
		list.name.should == LIST1
		list.entries.empty?.should == true
		@redis.dbsize.should == 7
	end

	it "rejects list names with slashes" do
		name = @todouser.add_list('/' + LIST1)
		name.nil?.should == true
		@todouser.lists.empty?.should == true
	end

	it "rejects list names with nullbytes" do
		name = @todouser.add_list('\0' + LIST1)
		name.nil?.should == true
		@todouser.lists.empty?.should == true
	end

	it "rejects empty list names" do
		name = @todouser.add_list ''
		name.nil?.should == true
		@todouser.lists.empty?.should == true
	end

	it "rejects too long list names" do
		name = @todouser.add_list('.' * 256)
		name.nil?.should == true
		@todouser.lists.empty?.should == true
	end

	it "stores newly created todolists with one entry" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		list = @todouser.lists[LIST1]
		list.add_todo TODO2
		list.name.should == LIST1
		list.entries.size.should == 1
	end

	it "supports renaming of todo lists" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		@todouser.lists.values[0].name.should == LIST1
		@todouser.rename_list(LIST1, LIST1 + "2")
		@todouser.lists.size.should == 1
		@todouser.lists.values[0].name.should == LIST1 + "2"
		@redis.dbsize.should == 7
	end

	it "supports deletion of todo lists" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		@todouser.delete_list LIST1
		@todouser.lists.empty?.should == true
		@redis.dbsize.should == 3
	end

	it "serializes to JSON" do
		@todouser.to_json.should ==  '[]'
		@todouser.add_list LIST1
		@todouser.to_json.should ==  '["%s"]' % LIST1
	end

	it "serializes multiple lists in alphabetic order to JSON" do
		@todouser.add_list LIST1
		@todouser.add_list LIST2
		json = JSON.parse @todouser.to_json
		json.size.should == 2
		json[0].should == LIST2
		json[1].should == LIST1
		@redis.dbsize.should == 10
	end
end

describe CRToDo::ToDoDB do
	before(:each) do
		@tododb = CRToDo::ToDoDB.new '127.0.0.1', '6379', 3
		@redis = @tododb.redis
		@redis.flushdb
	end

	after(:each) do
		@tododb.delete
		CRToDo::del_idcounters(@redis)
		@redis.dbsize.should == 0
	end

	it "has no users after creation" do
		@tododb.users.empty?.should == true
		@redis.dbsize.should == 0
	end

	it "stores newly added users" do
		user = @tododb.add_user TESTUSER
		user.should == TESTUSER
		@tododb.users.size.should == 1
		user = @tododb.users[TESTUSER]
		user.name.should == TESTUSER
		user.lists.empty?.should == true
		@redis.dbsize.should == 3
	end

	it "rejects usernames with slashes" do
		user = @tododb.add_user('/' + TESTUSER)
		user.nil?.should == true
		@tododb.users.empty?.should == true
	end

	it "rejects usernames with nullbytes" do
		user = @tododb.add_user('\0' + TESTUSER)
		user.nil?.should == true
		@tododb.users.empty?.should == true
	end

	it "rejects empty usernames" do
		user = @tododb.add_user ''
		user.nil?.should == true
		@tododb.users.empty?.should == true
	end

	it "rejects too long usernames" do
		user = @tododb.add_user('.' * 256)
		user.nil?.should == true
		@tododb.users.empty?.should == true
	end

	it "creates users automatically when not present" do
		user = @tododb.get_user TESTUSER
		user.name.should == TESTUSER
		@tododb.users.size.should == 1
		@redis.dbsize.should == 3
		user2 = @tododb.get_user TESTUSER
		user2.name.should == TESTUSER
		@tododb.users.size.should == 1
		user.should == user2
	end

	it "supports deletion of users" do
		@tododb.add_user TESTUSER
		@tododb.users.size.should == 1
		@tododb.delete_user TESTUSER
		@tododb.users.empty?.should == true
		@redis.dbsize.should == 1
	end
end


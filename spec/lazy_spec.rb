require 'rubygems'
require 'crtodo'

USER   = "user@example.com"
LIST   = "Test List"
TODO_1 = "Go shopping"
TODO_2 = "Clean the car"

describe CRToDo, "lazy loading" do
	before(:all) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		db = CRToDo::ToDoDB.new @redis
		@redis.flushdb
		user = db.get_user USER
		user.add_list LIST
		user.lists[LIST].add_todo TODO_1
		user.lists[LIST].add_todo TODO_2
		user.lists[LIST].finish 0
	end
	
	before(:each) do
		@redis.client.disconnect
		@db = CRToDo::ToDoDB.new @redis
	end
	
	it "loads the user list" do
		@db.users.empty?.should == false
		@db.users.size.should == 1
	end

	it "does not load individual users" do
		@db.users[USER].loaded?.should == false
	end

	it "loads the user upon accessing the todo lists" do
		user1 = @db.users[USER]
		user1.lists.empty?.should == false
		user1.loaded?.should == true
	end

	it "does not load individual todo lists" do
		@db.users[USER].lists[LIST].loaded?.should == false
	end

	it "loads the todo list upon accessing the open entries" do
		list = @db.users[USER].lists[LIST]
		list.open_entries.empty?.should == false
		list.loaded?.should == true
	end

	it "loads the todo list upon accessing the open entries" do
		list = @db.users[USER].lists[LIST]
		list.done_entries.empty?.should == false
		list.loaded?.should == true
	end
end


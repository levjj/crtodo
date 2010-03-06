require 'rubygems'
require 'json'
require 'crtodo'
require 'tempfile'

TESTUSER = "user@example.com"

LIST1    = "Test List"
LIST2    = "Second List"

TODO1    = "Go shopping"
TODO2    = "Clean the car"
TODO3    = "Making homework"

TODO2_JSON = '{"name":"%s"}' % TODO2

EMPTY_JSON = '{"open":[],"done":[]}'

JSONFILE = File.join(File.dirname(__FILE__), "testlist.json")

describe CRToDo::ToDo do
	before(:each) do
		@new_todo = CRToDo::ToDo.new TODO1
		@imported_todo = CRToDo::ToDo.from_json TODO2_JSON
	end

	it "stores the name" do
		@new_todo.name.should == TODO1
		@imported_todo.name.should == TODO2
	end

	it "serializes to JSON" do
		json = JSON.parse @new_todo.to_json
		json["name"].should == TODO1
		json = JSON.parse @imported_todo.to_json
		json["name"].should == TODO2
	end
end

describe CRToDo::ToDoList do
	before(:each) do
		@tempdir = Pathname.new(Dir.tmpdir) + rand(1048576).to_s
		@tempdir.mkdir
		@tempfile = @tempdir + LIST1
		@todolist = CRToDo::ToDoList.new @tempfile
	end

	after(:each) do
		@tempdir.rmtree
	end

	it "stores the name" do
		@todolist.name.should == LIST1
	end

	it "has no entries after creation" do
		@todolist.loaded?.should == false
		@todolist.entries.empty?.should == true
		@todolist.open_entries.empty?.should == true
		@todolist.done_entries.empty?.should == true
		@todolist.loaded?.should == true
		@tempfile.read.should ==  EMPTY_JSON
	end

	it "stores newly added todo entries" do
		@todolist.loaded?.should == false
		pos = @todolist.add_todo TODO1
		pos.should == 0
		@todolist.loaded?.should == true
		@todolist.done?.should == false
		@todolist.entries.empty?.should == false
		@todolist.open_entries.empty?.should == false
		@todolist.done_entries.empty?.should == true
		@todolist.entries[0].name.should == TODO1
		json = JSON.parse @tempfile.read
		json["open"].size.should == 1
		json["done"].empty?.should == true
		json["open"][0]["name"] == TODO1
	end

	it "supports the insertion of todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.add_todo TODO3
		@todolist.loaded?.should == true
		@todolist.entries.size.should == 2
		@todolist.entries[0].name.should == TODO1
		@todolist.entries[1].name.should == TODO3
		pos = @todolist.add_todo(TODO2, 1)
		pos.should == 1
		@todolist.entries.size.should == 3
		@todolist.entries[0].name.should == TODO1
		@todolist.entries[1].name.should == TODO2
		@todolist.entries[2].name.should == TODO3
		json = JSON.parse @tempfile.read
		json["open"].size.should == 3
		json["done"].empty?.should == true
		json["open"][0]["name"] == TODO1
		json["open"][1]["name"] == TODO2
		json["open"][2]["name"] == TODO3
	end

	it "supports moving todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.add_todo TODO2
		@todolist.loaded?.should == true
		@todolist.entries.size.should == 2
		@todolist.entries[0].name.should == TODO1
		@todolist.entries[1].name.should == TODO2
		json = JSON.parse @tempfile.read
		json["open"].size.should == 2
		json["done"].empty?.should == true
		json["open"][0]["name"] == TODO1
		json["open"][1]["name"] == TODO2
		@todolist.move_todo(1, 0)
		@todolist.entries.size.should == 2
		@todolist.entries[0].name.should == TODO2
		@todolist.entries[1].name.should == TODO1
		json = JSON.parse @tempfile.read
		json["open"].size.should == 2
		json["done"].empty?.should == true
		json["open"][0]["name"] == TODO2
		json["open"][1]["name"] == TODO1
	end

	it "should ignore bad move operations" do
		@todolist.move_todo(1, 0)
		@todolist.entries.empty?.should == true
		@tempfile.read.should == EMPTY_JSON
	end

	it "supports the deletion of todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.delete_at 0
		@todolist.loaded?.should == true
		@todolist.done?.should == true
		@todolist.entries.empty?.should == true
		@tempfile.read.should == EMPTY_JSON
	end

	it "is done after finishing all entries" do
		@todolist.add_todo TODO1
		@todolist.finish 0
		@todolist.done?.should == true
		json = JSON.parse @tempfile.read
		json["open"].empty?.should == true
		json["done"].size.should == 1
		json["done"][0]["name"] == TODO1
	end

	it "is not done if an entry was reopened" do
		@todolist.add_todo TODO1
		@todolist.finish 0
		@todolist.reopen 0
		@todolist.done?.should == false
		json = JSON.parse @tempfile.read
		json["open"].size.should == 1
		json["done"].empty?.should == true
		json["open"][0]["name"] == TODO1
	end

	it "imports entries from the filesystem" do
		@todolist.loaded?.should == false
		@todolist.path = Pathname.new JSONFILE
		@todolist.loaded?.should == false
		@todolist.done?.should == false
		@todolist.loaded?.should == true
		@todolist.entries.size.should == 2
		@todolist.open_entries.size.should == 1
		@todolist.done_entries.size.should == 1
		entry1 = @todolist.open_entries[0]
		entry1.name.should == TODO1
		entry2 = @todolist.done_entries[0]
		entry2.name.should == TODO2
	end

	it "serializes to JSON" do
		@todolist.open_entries.to_json.should ==  '[]'
		@todolist.done_entries.to_json.should ==  '[]'
		@todolist.add_todo TODO1
		json = JSON.parse @todolist.open_entries.to_json
		json.size.should == 1
		json[0]["name"].should == TODO1
		json = JSON.parse @todolist.done_entries.to_json
		json.empty?.should == true
	end

	it "serializes multiple entries in the order of insertion to JSON" do
		@todolist.add_todo TODO3
		@todolist.add_todo TODO1
		@todolist.add_todo TODO2
		json = JSON.parse @todolist.open_entries.to_json
		json.size.should == 3
		json[0]["name"].should == TODO3
		json[1]["name"].should == TODO1
		json[2]["name"].should == TODO2
	end
end

describe CRToDo::ToDoUser do
	before(:each) do
		@tempdir = Pathname.new(Dir.tmpdir) + rand(1048576).to_s
		@tempdir.mkdir
		@tempuserdir = @tempdir + TESTUSER
		@todouser = CRToDo::ToDoUser.new @tempuserdir
	end

	after(:each) do
		@tempuserdir.rmtree
	end

	it "has no lists after creation" do
		@todouser.lists.empty?.should == true
		@tempuserdir.children.empty?.should == true
	end

	it "stores newly created empty todo lists" do
		name = @todouser.add_list LIST1
		name.should == LIST1
		@todouser.lists.size.should == 1
		list = @todouser.lists[LIST1]
		list.name.should == LIST1
		list.entries.empty?.should == true
		@tempuserdir.children.size.should == 1
		listfile = @tempuserdir.children[0]
		listfile.should == @tempuserdir + (LIST1 + ".json")
		listfile.read.should == EMPTY_JSON
	end

	it "stores newly created todolists with one entry" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		list = @todouser.lists[LIST1]
		list.add_todo TODO2
		list.name.should == LIST1
		list.entries.size.should == 1
		@tempuserdir.children.size.should == 1
		listfile = @tempuserdir.children[0]
		listfile.file?.should == true
		listfile.should == @tempuserdir + (LIST1 + ".json")
		listfile.read.should == '{"open":[%s],"done":[]}' % TODO2_JSON
	end

	it "supports renaming of todo lists" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		@todouser.lists.values[0].name.should == LIST1
		@tempuserdir.children.size.should == 1
		@tempuserdir.children[0].should == @tempuserdir + (LIST1 + ".json")
		@todouser.rename_list(LIST1, LIST1 + "2")
		@todouser.lists.size.should == 1
		@todouser.lists.values[0].name.should == LIST1 + "2"
		@tempuserdir.children.size.should == 1
		@tempuserdir.children[0].should == @tempuserdir + (LIST1 + "2.json")
	end

	it "supports deletion of todo lists" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		@todouser.delete_list LIST1
		@todouser.lists.empty?.should == true
		@tempuserdir.children.empty?.should == true
	end

	it "loads present lists from filesystem" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		@tempuserdir.children.size.should == 1
		todouser2 = CRToDo::ToDoUser.new @tempuserdir
		todouser2.lists.size.should == 1
		todouser2.lists[LIST1].name.should == LIST1
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
	end
end

describe CRToDo::ToDoDB do
	before(:each) do
		@tempdir = Pathname.new(Dir.tmpdir) + rand(1048576).to_s
		@tododb = CRToDo::ToDoDB.new @tempdir.to_s
	end

	after(:each) do
		@tempdir.rmtree
	end

	it "has no users after creation" do
		@tododb.users.empty?.should == true
		@tempdir.children.empty?.should == true
	end

	it "stores newly added users" do
		user = @tododb.add_user TESTUSER
		user.should == TESTUSER
		@tododb.users.size.should == 1
		user = @tododb.users[TESTUSER]
		user.name.should == TESTUSER
		user.lists.empty?.should == true
		@tempdir.children.size.should == 1
		userdir = @tempdir.children[0]
		userdir.directory?.should == true
		userdir.should == @tempdir + TESTUSER
		userdir.children.empty?.should == true
	end

	it "loads present users from filesystem" do
		@tododb.add_user TESTUSER
		@tododb.users.size.should == 1
		@tempdir.children.size.should == 1
		tododb2 = CRToDo::ToDoDB.new @tempdir.to_s
		tododb2.users.size.should == 1
	end

	it "loads present users with lists from filesystem" do
		user = @tododb.get_user TESTUSER
		user.add_list LIST1
		user.lists.size.should == 1
		@tododb.users.size.should == 1
		@tempdir.children.size.should == 1
		@tempdir.children[0].children.size.should == 1
		tododb2 = CRToDo::ToDoDB.new @tempdir.to_s
		tododb2.users.size.should == 1
		user2 = tododb2.get_user TESTUSER
		user2.lists.size.should == 1
	end

	it "creates users automatically when not present" do
		user = @tododb.get_user TESTUSER
		user.name.should == TESTUSER
		@tododb.users.size.should == 1
		@tempdir.children.size.should == 1
		user2 = @tododb.get_user TESTUSER
		user2.name.should == TESTUSER
		@tododb.users.size.should == 1
		@tempdir.children.size.should == 1
		user.should == user2
	end

	it "supports deletion of users" do
		@tododb.add_user TESTUSER
		@tododb.users.size.should == 1
		@tododb.delete_user TESTUSER
		@tododb.users.empty?.should == true
		@tempdir.children.empty?.should == true
	end
end

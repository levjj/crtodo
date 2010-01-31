require 'rubygems'
require 'crtodo'
require 'tempfile'

LIST1   = "Test List"
LIST2   = "Second List"

TODO1   = "Go shopping"
TODO2   = "Clean the car"
TODO3   = "Making homework"

CSVFILE = File.join(File.dirname(__FILE__), "testlist.csv")

describe CRToDo::ToDo do
	before(:each) do
		@new_todo = CRToDo::ToDo.new(TODO1)
		@imported_todo = CRToDo::ToDo.from_array([1, TODO2])
	end

	it "stores the name" do
		@new_todo.name.should == TODO1
		@imported_todo.name.should == TODO2
	end

	it "is open after creation" do
		@new_todo.done?.should == false
		@imported_todo.done?.should == true
	end

	it "serializes to an array" do
		@new_todo.to_array.should ==  [0, TODO1]
		@imported_todo.to_array.should ==  [1, TODO2]
	end

	it "serializes to JSON" do
		json = JSON.parse @new_todo.to_json
		json.size.should == 2
		json["name"].should ==  TODO1
		json["done"].should == false
		json = JSON.parse @imported_todo.to_json
		json.size.should == 2
		json["name"].should ==  TODO2
		json["done"].should == true
	end

	it "is done after finishing it" do
		@new_todo.finish
		@new_todo.done?.should == true
	end
end

describe CRToDo::ToDoList do
	before(:each) do
		@tempfile = Tempfile.open("testlist")
		@todolist = CRToDo::ToDoList.new LIST1
		@todolist.path = @tempfile.path
	end

	after(:each) do
		@tempfile.close
	end

	it "stores the name" do
		@todolist.name.should == LIST1
	end

	it "has no entries after creation" do
		@todolist.loaded?.should == false
		@todolist.entries.empty?.should == true
		@todolist.loaded?.should == true
		IO.read(@tempfile.path).should ==  ""
	end

	it "stores newly added todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.loaded?.should == true
		@todolist.done?.should == false
		@todolist.entries.empty?.should == false
		entry = @todolist.entries[0]
		entry.name.should == TODO1
		entry.done?.should == false
		@tempfile.flush
		IO.read(@tempfile.path).should ==  "0,%s\n" % [TODO1]
	end

	it "supports the insertion of todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.add_todo TODO3
		@todolist.loaded?.should == true
		@todolist.entries.size.should == 2
		@todolist.entries[0].name.should == TODO1
		@todolist.entries[1].name.should == TODO3
		@todolist.add_todo(TODO2, 1)
		@todolist.entries.size.should == 3
		@todolist.entries[0].name.should == TODO1
		@todolist.entries[1].name.should == TODO2
		@todolist.entries[2].name.should == TODO3
		@tempfile.flush
		IO.read(@tempfile.path).should ==
				"0,%s\n0,%s\n0,%s\n" % [TODO1, TODO2, TODO3]
	end

	it "supports moving todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.add_todo TODO2
		@todolist.loaded?.should == true
		@todolist.entries.size.should == 2
		@todolist.entries[0].name.should == TODO1
		@todolist.entries[1].name.should == TODO2
		@tempfile.flush
		IO.read(@tempfile.path).should ==
				"0,%s\n0,%s\n" % [TODO1, TODO2]
		@todolist.move_todo(1, 0)
		@todolist.entries.size.should == 2
		@todolist.entries[0].name.should == TODO2
		@todolist.entries[1].name.should == TODO1
		@tempfile.flush
		IO.read(@tempfile.path).should ==
				"0,%s\n0,%s\n" % [TODO2, TODO1]
	end

	it "supports the deletion of todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.delete_at 0
		@todolist.loaded?.should == true
		@todolist.done?.should == true
		@todolist.entries.empty?.should == true
		IO.read(@tempfile.path).should ==  ""
	end

	it "is done after finishing all entries" do
		@todolist.add_todo TODO1
		entry = @todolist.entries[0]
		entry.finish
		entry.done?.should == true
		@todolist.done?.should == true
		IO.read(@tempfile.path).should ==  "1,%s\n" % [TODO1]
	end

	it "is done after finishing it" do
		@todolist.add_todo TODO1
		entry = @todolist.entries[0]
		@todolist.finish
		@todolist.done?.should == true
		entry.done?.should == true
		IO.read(@tempfile.path).should ==  "1,%s\n" % [TODO1]
	end

	it "imports entries from the filesystem" do
		@todolist.loaded?.should == false
		@todolist.path = Pathname.new(CSVFILE)
		@todolist.loaded?.should == false
		@todolist.done?.should == false
		@todolist.loaded?.should == true
		@todolist.entries.empty?.should == false
		@todolist.entries.size.should == 2
		entry1 = @todolist.entries[0]
		entry1.name.should == TODO1
		entry1.done?.should == false
		entry1.list.nil?.should == false
		entry2 = @todolist.entries[1]
		entry2.name.should == TODO2
		entry2.done?.should == true
		entry1.nil?.should == false
	end

	it "serializes to JSON" do
		@todolist.to_json.should ==  '[]'
		@todolist.add_todo TODO1
		json = JSON.parse @todolist.to_json
		json.size.should == 1
		json[0].size.should == 2
		json[0]["name"].should == TODO1
		json[0]["done"].should == false
	end

	it "serializes multiple entries in the order of insertion to JSON" do
		@todolist.add_todo TODO3
		@todolist.add_todo TODO1
		@todolist.add_todo TODO2
		json = JSON.parse @todolist.to_json
		json.size.should == 3
		json[0]["name"].should == TODO3
		json[1]["name"].should == TODO1
		json[2]["name"].should == TODO2
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
	
	it "has no lists after creation" do
		@tododb.lists.empty?.should == true
		@tempdir.children.empty?.should == true
	end

	it "stores newly created empty todo lists" do
		@tododb.add_list LIST1
		@tododb.lists.size.should == 1
		list = @tododb.lists[LIST1]
		list.name.should == LIST1
		list.entries.empty?.should == true
		@tempdir.children.size.should == 1
		listfile = @tempdir.children[0]
		listfile.should == @tempdir + (LIST1 + ".csv")
		listfile.read.should ==  ""
	end

	it "stores newly created todolists with one entry" do
		@tododb.add_list LIST1
		@tododb.lists.size.should == 1
		list = @tododb.lists[LIST1]
		list.add_todo TODO1
		list.name.should == LIST1
		list.entries.size.should == 1
		@tempdir.children.size.should == 1
		listfile = @tempdir.children[0]
		listfile.should == @tempdir + (LIST1 + ".csv")
		listfile.read.should == "0,%s\n" % [TODO1]
	end

	it "supports renaming of todo lists" do
		@tododb.add_list LIST1
		@tododb.lists.size.should == 1
		@tododb.lists.values[0].name.should == LIST1
		@tempdir.children.size.should == 1
		@tempdir.children[0].should == @tempdir + (LIST1 + ".csv")
		@tododb.rename_list(LIST1, LIST1 + "2")
		@tododb.lists.size.should == 1
		@tododb.lists.values[0].name.should == LIST1 + "2"
		@tempdir.children.size.should == 1
		@tempdir.children[0].should == @tempdir + (LIST1 + "2.csv")
	end

	it "supports deletion of todo lists" do
		@tododb.add_list LIST1
		@tododb.lists.size.should == 1
		@tododb.delete_list LIST1
		@tododb.lists.empty?.should == true
		@tempdir.children.empty?.should == true
	end

	it "serializes to JSON" do
		@tododb.to_json.should ==  '[]'
		@tododb.add_list LIST1
		@tododb.to_json.should ==  '["%s"]' % LIST1
	end

	it "serializes multiple lists in alphabetic order to JSON" do
		@tododb.add_list LIST1
		@tododb.add_list LIST2
		json = JSON.parse @tododb.to_json
		json.size.should == 2
		json[0].should == LIST2
		json[1].should == LIST1
	end
end

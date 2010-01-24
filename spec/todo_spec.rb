require 'crtodo'
require 'tempfile'

LIST    = "Test List"
TODO1   = "Go shopping"
TODO2   = "Clean the car"
TODO3   = "Making homework"

CSVFILE = File.join(File.dirname(__FILE__), "testlist.csv")

JSONTODO = '{"name":"%s","done":%s}'

describe CRToDo::ToDo do
	before(:each) do
		@new_todo = CRToDo::ToDo.new(TODO1)
		@imported_todo = CRToDo::ToDo.from_array([1, TODO2])
	end

	it "should store the name" do
		@new_todo.name.should == TODO1
		@imported_todo.name.should == TODO2
	end

	it "should be open after creation" do
		@new_todo.done?.should == false
		@imported_todo.done?.should == true
	end

	it "should be serialized to arrays" do
		@new_todo.to_array.should ==  [0, TODO1]
		@imported_todo.to_array.should ==  [1, TODO2]
	end

	it "should be serialized to JSON" do
		@new_todo.to_json.should ==  JSONTODO % [TODO1, false]
		@imported_todo.to_json.should ==  JSONTODO % [TODO2, true]
	end

	it "should be done after finishing it" do
		@new_todo.finish
		@new_todo.done?.should == true
	end
end

describe CRToDo::ToDoList do
	before(:each) do
		@tempfile = Tempfile.open("testlist")
		@todolist = CRToDo::ToDoList.new LIST
		@todolist.path = @tempfile.path
	end

	after(:each) do
		@tempfile.close
	end

	it "should store the name" do
		@todolist.name.should == LIST
	end

	it "should have no entries after creation" do
		@todolist.loaded?.should == false
		@todolist.entries.empty?.should == true
		@todolist.loaded?.should == true
		IO.read(@tempfile.path).should ==  ""
	end

	it "should be possible to add todo entries" do
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

	it "should be possible to insert todo entries" do
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

	it "should be possible to delete todo entries" do
		@todolist.loaded?.should == false
		@todolist.add_todo TODO1
		@todolist.delete_at 0
		@todolist.loaded?.should == true
		@todolist.done?.should == true
		@todolist.entries.empty?.should == true
		IO.read(@tempfile.path).should ==  ""
	end

	it "should be done after finishing all entries" do
		@todolist.add_todo TODO1
		entry = @todolist.entries[0]
		entry.finish
		entry.done?.should == true
		@todolist.done?.should == true
		IO.read(@tempfile.path).should ==  "1,%s\n" % [TODO1]
	end

	it "should be done after finishing it" do
		@todolist.add_todo TODO1
		entry = @todolist.entries[0]
		@todolist.finish
		@todolist.done?.should == true
		entry.done?.should == true
		IO.read(@tempfile.path).should ==  "1,%s\n" % [TODO1]
	end

	it "should be possible to import entries" do
		@todolist.loaded?.should == false
		@todolist.path = Pathname.new(CSVFILE)
		@todolist.loaded?.should == false
		@todolist.done?.should == false
		@todolist.loaded?.should == true
		@todolist.entries.empty?.should == false
		entry1 = @todolist.entries[0]
		entry1.name.should == TODO1
		entry1.done?.should == false
		entry2 = @todolist.entries[1]
		entry2.name.should == TODO2
		entry2.done?.should == true
	end

	it "should be serialized to JSON" do
		@todolist.to_json.should ==  '[]'
		@todolist.add_todo TODO1
		@todolist.to_json.should ==  '['+ (JSONTODO % [TODO1, false]) + ']'
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
	
	it "should have no lists after creation" do
		@tododb.lists.empty?.should == true
		@tempdir.children.empty?.should == true
	end

	it "should be possible to add an empty todo list" do
		@tododb.add_list LIST
		@tododb.lists.size.should == 1
		list = @tododb.lists[LIST]
		list.name.should == LIST
		list.entries.empty?.should == true
		@tempdir.children.size.should == 1
		listfile = @tempdir.children[0]
		listfile.should == @tempdir + (LIST + ".csv")
		listfile.read.should ==  ""
	end

	it "should be possible to add a todo list with one entry" do
		@tododb.add_list LIST
		@tododb.lists.size.should == 1
		list = @tododb.lists[LIST]
		list.add_todo TODO1
		list.name.should == LIST
		list.entries.size.should == 1
		@tempdir.children.size.should == 1
		listfile = @tempdir.children[0]
		listfile.should == @tempdir + (LIST + ".csv")
		listfile.read.should == "0,%s\n" % [TODO1]
	end

	it "should be possible to rename a todo list" do
		@tododb.add_list LIST
		@tododb.lists.size.should == 1
		@tododb.lists.values[0].name.should == LIST
		@tempdir.children.size.should == 1
		@tempdir.children[0].should == @tempdir + (LIST + ".csv")
		@tododb.rename_list(LIST, LIST + "2")
		@tododb.lists.size.should == 1
		@tododb.lists.values[0].name.should == LIST + "2"
		@tempdir.children.size.should == 1
		@tempdir.children[0].should == @tempdir + (LIST + "2.csv")
	end

	it "should be possible to delete todo lists" do
		@tododb.add_list LIST
		@tododb.lists.size.should == 1
		@tododb.delete_list LIST
		@tododb.lists.empty?.should == true
		@tempdir.children.empty?.should == true
	end

	it "should be serialized to JSON" do
		@tododb.to_json.should ==  '[]'
		@tododb.add_list LIST
		@tododb.to_json.should ==  '["%s"]' % LIST
	end
end

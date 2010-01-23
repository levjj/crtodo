require 'crtodo'
require 'tempfile'

LIST    = "Test List"
TODO1   = "Go shopping"
TODO2   = "Clean the car"
TODO3   = "Making homework"

CSVFILE = File.join(File.dirname(__FILE__), "testlist.csv")

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

	it "should be serialized to CSV" do
		@new_todo.to_array.should ==  [0, TODO1]
		@imported_todo.to_array.should ==  [1, TODO2]
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
end

describe CRToDo::ToDoApp do
	before(:each) do
		@tempdir = Pathname.new(Dir.tmpdir) + rand(1048576).to_s
		@todoapp = CRToDo::ToDoApp.new @tempdir.to_s
	end

	after(:each) do
		@tempdir.rmtree
	end
	
	it "should have no lists after creation" do
		@todoapp.lists.empty?.should == true
		@tempdir.children.empty?.should == true
	end

	it "should be possible to add an empty todo list" do
		@todoapp.add_list LIST
		@todoapp.lists.size.should == 1
		list = @todoapp.lists[LIST]
		list.name.should == LIST
		list.entries.empty?.should == true
		@tempdir.children.size.should == 1
		listfile = @tempdir.children[0]
		listfile.should == @tempdir + (LIST + ".csv")
		listfile.read.should ==  ""
	end

	it "should be possible to add a todo list with one entry" do
		@todoapp.add_list LIST
		@todoapp.lists.size.should == 1
		list = @todoapp.lists[LIST]
		list.add_todo TODO1
		list.name.should == LIST
		list.entries.size.should == 1
		@tempdir.children.size.should == 1
		listfile = @tempdir.children[0]
		listfile.should == @tempdir + (LIST + ".csv")
		listfile.read.should == "0,%s\n" % [TODO1]
	end

	it "should be possible to delete todo entries" do
		@todoapp.add_list LIST
		@todoapp.lists.size.should == 1
		@todoapp.delete_list LIST
		@todoapp.lists.empty?.should == true
		@tempdir.children.empty?.should == true
	end
end

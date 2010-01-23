require 'crtodo'
require 'tmpdir'

LIST    = "Test List"
TODO1   = "Go shopping"
TODO2   = "Clean the car"
TODO3   = "Making homework"

describe CRToDo::ToDo do
	before(:each) do
		@link = CRToDo::ToDo.new(TODO1)
	end

	it "should be open after creation" do
		@link.done.should == false
	end
end

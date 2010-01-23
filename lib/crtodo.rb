require 'pathname'

module CRToDo
	class ToDo
		attr_reader :name
		attr_reader :done

		def initialize(name)
			super()
			@name = name
			@done = false
		end
	end
end

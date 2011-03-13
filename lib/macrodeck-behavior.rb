require "behaviors/abbreviation_behavior"
require "behaviors/title_behavior"

module MacroDeck
	class Behavior
		# Pass in the data object.
		def initialize(data_object)
			@data_object = data_object
		end

		# Default to_html method. Override this in subclasses.
		def to_html
			""
		end
	end
end

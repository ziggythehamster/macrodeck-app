require "behaviors/abbreviation_behavior"
require "behaviors/title_behavior"

module MacroDeck
	class Behavior
		# Pass in the field value.
		def initialize(value)
			@value = value
		end

		# Default to_html method. Override this in subclasses.
		def to_html
			value.to_s
		end
	end
end

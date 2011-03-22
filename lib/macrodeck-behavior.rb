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

		# Default form field method. Override this in subclasses.
		# You probably want something like form_label(:whatever)
		# combined with form_input(:whatever).
		def to_form_field
			""
		end


		private
			# Function to generate a form input tag.
			def form_input(field, type = "text")
				return "<input type=\"#{type}\" name=\"#{field.to_s}\" value=\"#{Rack::Utils.escape_html(@data_object.send(field.to_sym)}\" />"
			end

			# Function to generate a form label. Can probably be modified to accept a block,
			# in which case we should include the input inside the label tag.
			def form_label(field)
				return "<label for=\"#{field.to_s}\">#{Rack::Utils.escape_html(@data_object.class.human_attribute_name(field.to_sym))}</label>"
			end
	end
end

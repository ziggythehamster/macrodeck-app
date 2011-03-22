module MacroDeck
	# Renders a description as a paragraph
	class DescriptionBehavior < Behavior
		def to_html
			"<p>#{Rack::Utils.escape_html(@data_object.description)}</p>"
		end

		# Return a textarea.
		def to_form_field
			output = ""
			output << form_label(:description)
			output << "<textarea rows=\"3\" name=\"description\">"
			output << Rack::Utils.escape_html(@data_object.description)
			output << "</textarea>"
			return output
		end
	end
end

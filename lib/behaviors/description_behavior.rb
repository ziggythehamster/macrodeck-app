module MacroDeck
	# Renders a description as a paragraph
	class DescriptionBehavior < Behavior
		def to_html
			"<p>#{Rack::Utils.escape_html(@data_object.description)}</p>"
		end

		# Return a textarea.
		def to_form_field(field_name = :description, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << form_label(field_name, :name => name)
			output << "<textarea rows=\"3\" name=\"#{Rack::Utils.escape_html(name.to_s)}\">"
			output << Rack::Utils.escape_html(@data_object.send(field_name.to_sym))
			output << "</textarea>"
			return output
		end
	end
end

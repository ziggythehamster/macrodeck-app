module MacroDeck
	# Renders a title as a heading.
	class TitleBehavior < Behavior
		# Pass in :append or :prepend with code that will be inserted before the title text or after it
		def to_html(options = {})
			if @data_object[:abbreviation]
				html =  "<h2>"
				html << options[:prepend] unless options[:prepend].nil?
				html << "#{Rack::Utils.escape_html(@data_object.title)} (#{Rack::Utils.escape_html(@data_object.abbreviation)})"
				html << options[:append] unless options[:append].nil?
				html << "</h2>"
				return html
			else
				html =  "<h2>"
				html << options[:prepend] unless options[:prepend].nil?
				html << "#{Rack::Utils.escape_html(@data_object.title)}"
				html << options[:append] unless options[:append].nil?
				html << "</h2>"
				return html
			end
		end

		def to_form_field
			output = ""
			output << form_label(:title)
			output << form_input(:title)
			return output
		end
	end
end

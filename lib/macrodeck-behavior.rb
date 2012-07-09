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
			# Also handles an array. If it's an array though, options are sent to each input created.
			def form_input(field, type = :text, options = {})
				if @data_object.send(field.to_sym).is_a?(Array)
					input = "<!-- begin array -->\n"

					# Support having a different field name and HTML name.
					if options[:name].nil?
						name = field
					else
						name = options.delete(:name)
					end

					@data_object.send(field.to_sym).each do |val|
						input << "<input type=\"#{Rack::Utils.escape_html(type.to_s)}\" name=\"#{Rack::Utils.escape_html(name.to_s)}[]\" value=\"#{Rack::Utils.escape_html(val)}\" "
						options.each do |k,v|
							input << "#{Rack::Utils.escape_html(k.to_s)}=\"#{Rack::Utils.escape_html(v.to_s)}\" "
						end
						input << "/><br />\n"
					end

					# Build a blank input for the add button.
					blank_input  = "<input type=\"#{Rack::Utils.escape_html(type.to_s)}\" name=\"#{Rack::Utils.escape_html(name.to_s)}[]\" "
					options.each do |k,v|
						blank_input << "#{Rack::Utils.escape_html(k.to_s)}=\"#{Rack::Utils.escape_html(v.to_s)}\" "
					end
					blank_input << "/><br />"

					# Escape the blank input for JavaScript insertion.
					blank_input.gsub!('"', "\\\\'")

					input << "<a id=\"addbutton-#{Rack::Utils.escape_html(name.to_s)}\" href=\"#\" onclick=\"$(this).before('#{blank_input}');\">add item to list</a>\n"
					input << "<!-- end array -->\n"
				else
					# Support having a different field name and HTML name.
					if options[:name].nil?
						name = field
					else
						name = options.delete(:name)
					end

					input = "<input type=\"#{Rack::Utils.escape_html(type.to_s)}\" name=\"#{Rack::Utils.escape_html(name.to_s)}\" value=\"#{Rack::Utils.escape_html(@data_object.send(field.to_sym))}\" "
					options.each do |k,v|
						input << "#{Rack::Utils.escape_html(k.to_s)}=\"#{Rack::Utils.escape_html(v.to_s)}\" "
					end

					input << "/>"
				end

				return input
			end

			# Function to generate a form label. Can probably be modified to accept a block,
			# in which case we should include the input inside the label tag.
			def form_label(field, params = {})
				if params[:name].nil?
					field_name = field
				else
					field_name = params[:name]
				end

				if @data_object.send(field.to_sym).is_a?(Array)
					return "<label for=\"#{Rack::Utils.escape_html(field_name.to_s)}[]\">#{Rack::Utils.escape_html(@data_object.class.human_attribute_name(field.to_sym))}</label>"
				else
					return "<label for=\"#{Rack::Utils.escape_html(field_name.to_s)}\">#{Rack::Utils.escape_html(@data_object.class.human_attribute_name(field.to_sym))}</label>"
				end
			end
	end
end

module MacroDeck
	# Renders a drop down that has the days of the week.
	class DayOfWeekBehavior < Behavior
		def to_form_field(field_name = :day_of_week, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			out  = form_label(field_name, :name => name)
			out << "<br />"

			if @data_object.send(field_name.to_sym).is_a?(Array)
				@data_object.send(field_name.to_sym).each do |val|
					out << day_selector("#{name}[]", val)
				end

				# Build a blank input.
				blank_input = day_selector("#{name}[]", -1)
				blank_input << "<a href=\"#\" onclick=\"$(this).prev().remove(); $(this).next().remove(); $(this).remove();\">remove</a><br />"
				blank_input.gsub!('"', "\\\\'") # for JavaScript.

				# Add an add button.
				out << "<a id=\"addbutton-#{Rack::Utils.escape_html(name.to_s)}\" href=\"#\" onclick=\"$(this).before('#{blank_input}');\">add item to list</a>\n"
			else
				out << day_selector(name, @data_object.send(field_name.to_sym))
			end

			return out
		end

		def to_html(field = :day_of_week)
			if @data_object.send(field).is_a?(Array)
				out =  "<ul>"

				@data_object.send(field).each do |wkd|
					out << "<li>#{Rack::Utils.escape_html(get_day_string(@data_object.send(field)))}</li>"
				end

				out << "</ul>"

				return out
			else
				return "<p>#{Rack::Utils.escape_html(@data_object.send(field))}</p>"
			end
		end

		def to_human_string(value)
			return get_day_string(value.to_i)
		end

		private
			# TODO: I18n this by looking up the translation for these.
			def get_day_string(int)
				case int
				when 0 then "Sunday"
				when 1 then "Monday"
				when 2 then "Tuesday"
				when 3 then "Wednesday"
				when 4 then "Thursday"
				when 5 then "Friday"
				when 6 then "Saturday"
				else nil
				end
			end

			def day_selector(name, value)
				out = ""
				out << "<select name=\"#{name.to_s}\">"
				out << "<option value=\"0\"#{selected_if(0,value)}>#{get_day_string(0)}</option>"
				out << "<option value=\"1\"#{selected_if(1,value)}>#{get_day_string(1)}</option>"
				out << "<option value=\"2\"#{selected_if(2,value)}>#{get_day_string(2)}</option>"
				out << "<option value=\"3\"#{selected_if(3,value)}>#{get_day_string(3)}</option>"
				out << "<option value=\"4\"#{selected_if(4,value)}>#{get_day_string(4)}</option>"
				out << "<option value=\"5\"#{selected_if(5,value)}>#{get_day_string(5)}</option>"
				out << "<option value=\"6\"#{selected_if(6,value)}>#{get_day_string(6)}</option>"
				out << "</select>"
				return out
			end

			def selected_if(val1, val2)
				if val1 == val2
					' selected="selected"'
				else
					""
				end
			end
	end
end

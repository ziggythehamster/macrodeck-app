module MacroDeck
	# Renders a drop down that has the days of the week.
	class DayOfWeekBehavior < Behavior
		def to_form_field(name = :day_of_week)
			out  = form_label(name)
			out << "<select name=\"#{name.to_s}\">"
			out << "<option value=\"0\">#{get_day_string(0)}</option>"
			out << "<option value=\"1\">#{get_day_string(1)}</option>"
			out << "<option value=\"2\">#{get_day_string(2)}</option>"
			out << "<option value=\"3\">#{get_day_string(3)}</option>"
			out << "<option value=\"4\">#{get_day_string(4)}</option>"
			out << "<option value=\"5\">#{get_day_string(5)}</option>"
			out << "<option value=\"6\">#{get_day_string(6)}</option>"
			out << "</select>"
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
	end
end

require "behaviors/date_behavior"
require "time"

module MacroDeck
	# Ask the user to set a date and a time.
	class TimeBehavior < DateBehavior
		def to_html
			return Rack::Utils.escape_html(@data_object.time)
		end

		def to_form_field
			output = ""
			output << "<label for=\"time_date\">Date</label>"
			output << date_picker_field("time", Time.new.strftime("%F")) if @data_object.time.nil?
			output << date_picker_field("time", Time.parse(@data_object.time).strftime("%F")) unless @data_object.time.nil?
			output << "<label for=\"time_time\">Time</label>"
			output << time_picker_field("time", Time.new.strftime("%H:%M")) if @data_object.time.nil?
			output << time_picker_field("time", Time.parse(@data_object.time).strftime("%H:%M")) unless @data_object.time.nil?
			return output
		end

		def parse_result(result)
			return parse_time_result(result)
		end

		private
			def parse_time_result(result)
				return Time.parse("#{parse_date_result(result)} #{result["time"]}").utc.iso8601
			end

			def time_picker_field(name, value)
				output = "<select id=\"#{Rack::Utils.escape_html(name)}_time\" name=\"#{Rack::Utils.escape_html(name)}[time]\">"
				t = Time.parse("00:00:00")
				48.times do |x|
					new_t = (t + (x * 1800))
					if new_t.strftime("%H:%M") == value
						output << "<option value=\"#{new_t.strftime("%H:%M")}\" selected=\"selected\">#{new_t.strftime("%I:%M %p")}</option>"
					else
						output << "<option value=\"#{new_t.strftime("%H:%M")}\">#{new_t.strftime("%I:%M %p")}</option>"
					end
				end
				output << "</select>"
			end
	end
end

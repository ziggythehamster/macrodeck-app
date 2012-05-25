require "behaviors/date_behavior"
require "time"

module MacroDeck
	# Ask the user to set a date and a time.
	class TimeBehavior < DateBehavior
		def to_html
			return Rack::Utils.escape_html(@data_object.time)
		end

		def to_form_field(field_name = :time, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << "<label for=\"#{Rack::Utils.escape_html(name.to_s)}_date\">Date</label>"
			output << date_picker_field(name, Time.new.strftime("%F")) if @data_object.send(field_name.to_sym).nil?
			output << date_picker_field(name, Time.parse(@data_object.send(field_name.to_sym)).strftime("%F")) unless @data_object.send(field_name.to_sym).nil?
			output << "<label for=\"#{Rack::Utils.escape_html(name.to_s)}_time\">Time</label>"
			output << time_picker_field(name, Time.new.strftime("%H:%M")) if @data_object.send(field_name.to_sym).nil?
			output << time_picker_field(name, Time.parse(@data_object.send(field_name.to_sym)).strftime("%H:%M")) unless @data_object.send(field_name.to_sym).nil?
			return output
		end

		def parse_result(result)
			if !result["noend"].nil?
				return nil
			else
				return parse_time_result(result)
			end
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

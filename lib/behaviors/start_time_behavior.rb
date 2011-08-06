require "behaviors/time_behavior"

module MacroDeck
	# Start Time is the time that the event would start.
	class StartTimeBehavior < TimeBehavior
		def to_html
			return "<abbr title=\"#{@data_object.start_time}\" class=\"dtstart\">#{Time.parse(@data_object.start_time).getlocal.strftime("%b %e, %Y @ %l%P")}</abbr>"
		end

		def to_form_field
			output = ""
			output << "<label for=\"start_time_date\">Date</label>"
			output << date_picker_field("start_time", Time.new.strftime("%F")) if @data_object.start_time.nil?
			output << date_picker_field("start_time", Time.parse(@data_object.start_time).getlocal.strftime("%F")) unless @data_object.start_time.nil?
			output << "<label for=\"start_time_time\">Time</label>"
			output << time_picker_field("start_time", Time.new.strftime("%H:%M")) if @data_object.start_time.nil?
			output << time_picker_field("start_time", Time.parse(@data_object.start_time).getlocal.strftime("%H:%M")) unless @data_object.start_time.nil?
			return output
		end
	end
end

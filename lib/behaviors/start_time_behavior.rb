require "time_behavior"

module MacroDeck
	# Start Time is the time that the event would start.
	class StartTimeBehavior < TimeBehavior
		def to_html
			return "<abbr title=\"#{@data_object.start_time}\" class=\"dtstart\">#{Time.parse(@data_object.start_time).getlocal.strftime("%b %e, %Y @ %l%P")}</abbr>"
		end

		def to_form_field
			output = ""
			output << "<label for=\"start_time_date\">Date</label>"
			output << date_picker_field("start_time", @data_object.start_time.strftime("%F"))
			output << "<label for=\"start_time_time\">Time</label>"
			output << time_picker_field("start_time", @data_object.start_time.strftime("%H:%M"))
			return output
		end
	end
end

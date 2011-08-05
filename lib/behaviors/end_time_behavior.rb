require "time_behavior"

module MacroDeck
	# End Time is the time that the event would end.
	class EndTimeBehavior < TimeBehavior
		def to_html
			return "&mdash; <abbr title=\"#{@data_object.end_time}\" class=\"dtend\">#{Time.parse(@data_object.end_time).getlocal.strftime("%l%P")}</abbr>"
		end

		def to_form_field
			output = ""
			output << "<label for=\"end_time_date\">Date</label>"
			output << date_picker_field("end_time", @data_object.end_time.strftime("%F"))
			output << "<label for=\"end_time_time\">Time</label>"
			output << time_picker_field("end_time", @data_object.end_time.strftime("%H:%M"))
			return output
		end
	end
end

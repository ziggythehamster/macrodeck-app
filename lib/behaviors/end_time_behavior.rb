require "behaviors/time_behavior"

module MacroDeck
	# End Time is the time that the event would end.
	class EndTimeBehavior < TimeBehavior
		def to_html
			if @data_object.end_time.nil?
				return ""
			else
				return "&mdash; <abbr title=\"#{@data_object.end_time}\" class=\"dtend\">#{Time.parse(@data_object.end_time).getlocal.strftime("%l%P")}</abbr>"
			end
		end

		def to_form_field
			output = ""
			output << "<label for=\"end_time_date\">Date</label>"
			output << date_picker_field("end_time", Time.new.strftime("%F")) if @data_object.end_time.nil?
			output << date_picker_field("end_time", Time.parse(@data_object.end_time).getlocal.strftime("%F")) unless @data_object.end_time.nil?
			output << "<label for=\"end_time_time\">Time</label>"
			output << time_picker_field("end_time", Time.new.strftime("%H:%M")) if @data_object.end_time.nil?
			output << time_picker_field("end_time", Time.parse(@data_object.end_time).getlocal.strftime("%H:%M")) unless @data_object.end_time.nil?
			return output
		end
	end
end

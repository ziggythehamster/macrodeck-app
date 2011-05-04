module MacroDeck
	# Start Time is the time that the event would start.
	class StartTimeBehavior < Behavior
		def to_html
			return "<abbr title=\"#{@data_object.start_time}\" class=\"dtstart\">#{Time.parse(@data_object.start_time).getlocal.strftime("%b %e, %Y @ %l%P")}</abbr>"
		end

		def to_form_field
			output = ""
			output << form_label(:start_time)
			output << form_input(:start_time, :text)
			return output
		end
	end
end

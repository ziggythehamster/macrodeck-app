module MacroDeck
	# End Time is the time that the event would end.
	class EndTimeBehavior < Behavior
		def to_html
			return "&mdash; <abbr title=\"#{@data_object.end_time}\" class=\"dtend\">#{Time.parse(@data_object.end_time).getlocal.strftime("%l%P")}</abbr>"
		end

		def to_form_field
			output = ""
			output << form_label(:end_time)
			output << form_input(:end_time, :text)
			return output
		end
	end
end

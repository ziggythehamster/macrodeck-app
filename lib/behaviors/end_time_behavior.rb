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

		def to_form_field(field_name = :end_time, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << "<label for=\"#{Rack::Utils.escape_html(name.to_s)}_date\">End Date</label>"
			output << no_end_picker_field(name, @data_object.send(field_name.to_sym).nil?, "This event does not have an end time")
			output << date_picker_field(name, Time.new.strftime("%F")) if @data_object.send(field_name.to_sym).nil?
			output << date_picker_field(name, Time.parse(@data_object.send(field_name.to_sym)).getlocal.strftime("%F")) unless @data_object.send(field_name.to_sym).nil?
			output << "<label for=\"#{Rack::Utils.escape_html(name.to_s)}_time\">End Time</label>"
			output << time_picker_field(name, Time.new.strftime("%H:%M")) if @data_object.send(field_name.to_sym).nil?
			output << time_picker_field(name, Time.parse(@data_object.send(field_name.to_sym)).getlocal.strftime("%H:%M")) unless @data_object.send(field_name.to_sym).nil?
			return output
		end
	end
end

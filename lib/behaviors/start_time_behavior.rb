require "behaviors/time_behavior"

module MacroDeck
	# Start Time is the time that the event would start.
	class StartTimeBehavior < TimeBehavior
		def to_html
			return "<abbr title=\"#{@data_object.start_time}\" class=\"dtstart\">#{Time.parse(@data_object.start_time).getlocal.strftime("%b %e, %Y @ %l%P")}</abbr>"
		end

		def to_form_field(field_name = :start_time, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << "<label for=\"#{Rack::Utils.escape_html(name.to_s)}_date\">Start Date</label>"
			output << date_picker_field(name, Time.new.strftime("%F")) if @data_object.send(field_name.to_sym).nil?
			output << date_picker_field(name, Time.parse(@data_object.send(field_name.to_sym)).getlocal.strftime("%F")) unless @data_object.send(field_name.to_sym).nil?
			output << "<label for=\"#{Rack::Utils.escape_html(name.to_s)}_time\">Start Time</label>"
			output << time_picker_field(name, Time.new.strftime("%H:%M")) if @data_object.send(field_name.to_sym).nil?
			output << time_picker_field(name, Time.parse(@data_object.send(field_name.to_sym)).getlocal.strftime("%H:%M")) unless @data_object.send(field_name.to_sym).nil?
			return output
		end
	end
end

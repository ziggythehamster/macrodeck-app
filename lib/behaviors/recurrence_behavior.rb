module MacroDeck
	# Renders the recurrence (hidden from HTML, but appears in a form)
	class RecurrenceBehavior < Behavior
		def to_form_field(field_name = :recurrence, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			out  = form_label(field_name, :name => name)
			out << "<select name=\"#{Rack::Utils.escape_html(name.to_s)}\">"
			out << "<option value=\"none\">None</option>"
			out << "<option value=\"weekly\">Weekly</option>"
			out << "<option value=\"monthly\">Monthly (same day of month)</option>"
			out << "<option value=\"monthly_nth_nday\">Monthly (same position in month, e.g. third Friday)</option>"
			out << "<option value=\"yearly\">Yearly</option>"
			out << "</select>"
			return out
		end
	end
end

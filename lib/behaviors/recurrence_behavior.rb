module MacroDeck
	# Renders the recurrence (hidden from HTML, but appears in a form)
	class RecurrenceBehavior < Behavior
		def to_form_field
			out  = form_label(:recurrence)
			out << "<select name=\"recurrence\">"
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

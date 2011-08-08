module MacroDeck
	# Renders the event type as a paragraph.
	class EventTypeBehavior < Behavior
		def to_form_field
			out  = form_label(:event_type)
			out << "<select name=\"event_type\">"
			out << "<option>Drink Special</option>"
			out << "<option>Drink Special and Entertainment</option>"
			out << "<option>Entertainment</option>"
			out << "<option>Food and Drink Special</option>"
			out << "<option>Food Special</option>"
			out << "</select>"
			return out
		end

		def to_html
			return "<p>#{Rack::Utils.escape_html(@data_object.event_type)}</p>"
		end
	end
end

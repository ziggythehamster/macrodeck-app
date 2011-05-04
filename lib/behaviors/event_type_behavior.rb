module MacroDeck
	# Renders the event type as a paragraph.
	class EventTypeBehavior < Behavior
		def to_form_field
			out  = form_label(:event_type)
			out << form_input(:event_type) # really needs to be a select.
			return out
		end

		def to_html
			return "<p>#{Rack::Utils.escape_html(@data_object.event_type)}</p>"
		end
	end
end

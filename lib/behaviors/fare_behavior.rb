module MacroDeck
	# Renders a list of fares as a list of items, concatenated by commas.
	class FareBehavior < Behavior
		def to_form_field
			out  = form_label(:fare)
			out << form_input(:fare)
			return out
		end

		def to_html
			Rack::Utils.escape_html(@data_object.fare.join(", "))
		end
	end
end

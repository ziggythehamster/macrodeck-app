module MacroDeck
	# Renders a phone number.
	class PhoneNumberBehavior < Behavior
		def to_html
			"<p><a href=\"tel:#{Rack::Utils.escape_html(@data_object.phone_number)}\">#{Rack::Utils.escape_html(@data_object.phone_number)}</a></p>"
		end

		def to_form_field
			output = ""
			output << form_label(:phone_number)
			output << form_input(:phone_number, :tel)
			return output
		end
	end
end

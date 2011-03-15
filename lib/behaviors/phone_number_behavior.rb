module MacroDeck
	# Renders a phone number.
	class PhoneNumberBehavior < Behavior
		def to_html
			"<p><a href=\"tel:#{Rack::Utils.escape_html(@data_object.phone_number)}\">#{Rack::Utils.escape_html(@data_object.phone_number)}</a></p>"
		end
	end
end

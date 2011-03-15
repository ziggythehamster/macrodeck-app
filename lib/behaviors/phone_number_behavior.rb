module MacroDeck
	# Renders a phone number.
	class PhoneNumberBehavior < Behavior
		def to_html
			"<p><a href=\"tel:#{@data_object.phone_number}\">#{@data_object.phone_number}</a></p>"
		end
	end
end

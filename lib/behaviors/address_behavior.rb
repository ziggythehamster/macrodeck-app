module MacroDeck
	# Renders an address.
	class AddressBehavior < Behavior
		def to_html
			if @data_object[:postal_code]
				return "<p class=\"adr\"><span class=\"street-address\">#{Rack::Utils.escape_html(@data_object.address)}</span><br /><span class=\"postal-code\">#{Rack::Utils.escape_html(@data_object.postal_code)}</span></p>"
			else
				return "<p class=\"adr\"><span class=\"street-address\">#{Rack::Utils.escape_html(@data_object.address)}</span></p>"
			end
		end

		def to_form_field
			output = ""
			output << form_label(:address)
			output << form_input(:address)
			return output
		end
	end
end

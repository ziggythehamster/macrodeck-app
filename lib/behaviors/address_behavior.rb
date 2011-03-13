module MacroDeck
	# Renders an address.
	class AddressBehavior < Behavior
		def to_html
			if @data_object[:postal_code]
				return "<p class=\"adr\"><span class=\"street-address\">#{@data_object.address}</span><br /><span class=\"postal-code\">#{@data_object.postal_code}</span></p>"
			else
				return "<p class=\"adr\"><span class=\"street-address\">#{@data_object.address}</span></p>"
			end
		end
	end
end

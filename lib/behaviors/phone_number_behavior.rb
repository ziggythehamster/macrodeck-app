module MacroDeck
	# Renders a phone number.
	class PhoneNumberBehavior < Behavior
		def to_html
			"<p><a href=\"tel:#{Rack::Utils.escape_html(@data_object.phone_number)}\">#{Rack::Utils.escape_html(@data_object.phone_number)}</a></p>"
		end

		def to_form_field(field_name = :phone_number, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << form_label(field_name, :name => name)
			output << form_input(field_name, :tel, { :name => name })
			return output
		end
	end
end

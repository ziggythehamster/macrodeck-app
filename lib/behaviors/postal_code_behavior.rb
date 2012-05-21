module MacroDeck
	# Postal codes shouldn't be shown (they're part of addresses)
	# Except they're perfectly valid to edit.
	class PostalCodeBehavior < Behavior
		def to_form_field(field_name = :postal_code, params = {})
			if params[:name].nil?
				name = field_name
			else
				name = params[:name]
			end

			output = ""
			output << form_label(name)
			output << form_input(name, :text, { :size => 10 })
			return output
		end
	end
end
